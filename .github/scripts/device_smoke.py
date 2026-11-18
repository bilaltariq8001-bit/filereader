"""Drives the installed app on an emulator against the mock files and prints
what happens: every screen, every crash, and a pass/fail line per check."""
import re, subprocess, sys, time, xml.etree.ElementTree as ET

PKG = "com.example.documentreader"
RESULTS = []


def adb(*a):
    r = subprocess.run(["adb", *a], capture_output=True, text=True)
    return r.stdout + r.stderr


def sh(cmd):
    return adb("shell", cmd)


def dump(label, quiet=False):
    nodes = []
    for _ in range(3):
        sh("uiautomator dump /sdcard/ui.xml >/dev/null 2>&1")
        xml = sh("cat /sdcard/ui.xml")
        try:
            root = ET.fromstring(xml[xml.index("<?xml"):])
            break
        except Exception:
            time.sleep(2)
    else:
        print("dump failed:", xml[:200]); return nodes
    for n in root.iter("node"):
        t = (n.get("text") or "").strip()
        d = (n.get("content-desc") or "").strip()
        if n.get("checkable") == "true":
            d = d or ("SWITCH checked=" + n.get("checked"))
        if not t and not d and n.get("clickable") == "true":
            d = "CLICKABLE"
        if t or d:
            nodes.append((t, d, n.get("bounds"), n.get("package")))
    if not quiet:
        print(f"\n===== SCREEN: {label} =====")
        for t, d, b, p in nodes[:40]:
            print(f"  [{p}] text={t[:80]!r} desc={d[:80]!r} {b}")
    return nodes


def box(b):
    return list(map(int, re.findall(r"\d+", b)))


def tap_box(b):
    x1, y1, x2, y2 = box(b)
    sh(f"input tap {(x1 + x2) // 2} {(y1 + y2) // 2}")


def tap_node(nodes, pattern, label):
    rx = re.compile(pattern, re.I | re.S)
    for t, d, b, p in nodes:
        if rx.search(t) or rx.search(d):
            print(f">>> TAP {label}: {(t or d)[:80]!r}")
            tap_box(b)
            return True
    print(f"!!! NOT FOUND: {label} /{pattern}/")
    return False


def crash_log():
    out = adb("logcat", "-d", "-b", "crash")
    if out.strip():
        adb("logcat", "-b", "crash", "-c")
    return out.strip()


def alive():
    return bool(sh(f"pidof {PKG}").strip())


def step(label, wait=4, quiet=False):
    time.sleep(wait)
    c = crash_log()
    if c:
        lines = c.splitlines()
        print(f"--- CRASH during {label} ---\n" + "\n".join(lines[:90]))
        tomb = sh("ls -t /data/tombstones/ 2>/dev/null | grep -v pb | head -1").strip()
        if tomb and "F DEBUG" in c:
            print("--- TOMBSTONE head ---\n" + sh(f"head -120 /data/tombstones/{tomb}"))
    n = dump(label, quiet)
    if any("keeps stopping" in t or "isn't responding" in t for t, _, _, _ in n):
        c = c or "system crash/ANR dialog"
        tap_node(n, r"Close app|Wait", "dismiss dialog")
    return n, c


def record(name, ok, detail=""):
    RESULTS.append((name, ok, detail))
    print(f"### {'PASS' if ok else 'FAIL'}: {name} {detail}")


def launch(wait=8):
    sh(f"am force-stop {PKG}")
    sh("input keyevent KEYCODE_HOME")
    out = sh(f"am start -W --activity-clear-task -n {PKG}/.MainActivity")
    m = re.search(r"TotalTime: (\d+)", out)
    n, c = step("launch", wait, quiet=True)
    return n, c, (int(m.group(1)) if m else None)


def app_screen(n):
    return any(p == PKG for _, _, _, p in n)


print(adb("root")); time.sleep(3)
# ---------------------------------------------------------------- permissions
sh(f"pm revoke {PKG} android.permission.READ_EXTERNAL_STORAGE")
sh(f"appops set --uid {PKG} MANAGE_EXTERNAL_STORAGE default")
sh(f"am force-stop {PKG}")
sh(f"am start -W --activity-clear-task -n {PKG}/.MainActivity")
n, c = step("first launch (no permission)", 10)
granted_ui = False
if tap_node(n, r"SWITCH checked=false", "all-files switch"):
    n, c = step("after switch on", 3)
    sh("input keyevent KEYCODE_BACK")
    n, c = step("back to app after granting", 12)
    granted_ui = app_screen(n) and not c and any(re.search(r"\.(pdf|docx|pptx|xlsx)", d, re.I) for _, d, _, _ in n)
record("permission prompt -> grant -> files listed", granted_ui)

# Deny path: app must not crash or hang when access is refused.
sh(f"appops set --uid {PKG} MANAGE_EXTERNAL_STORAGE deny")
sh(f"am force-stop {PKG}")
sh(f"am start -W --activity-clear-task -n {PKG}/.MainActivity")
n, c = step("launch with access denied", 8)
sh("input keyevent KEYCODE_BACK")
n, c = step("back from settings without granting", 6)
record("deny access -> no crash", not c and (app_screen(n) or not alive()), "" if not c else "crashed")

sh(f"appops set --uid {PKG} MANAGE_EXTERNAL_STORAGE allow")

# ----------------------------------------------------------- cold start + tabs
times = []
for i in range(3):
    n, c, t = launch(10)
    times.append(t)
print("cold start ms:", times)
n = dump("home (all files)")
record("cold start under 3 s", all(t and t < 3000 for t in times), str(times))
for idx, tab in [(2, "PDF"), (3, "Word"), (4, "PPT"), (5, "Excel"), (1, "All")]:
    n, c, _ = launch(8)
    if not tap_node(n, rf"Tab {idx} of 5", f"{tab} tab"):
        sh("input swipe 280 115 40 115 300"); n = dump("tabs scrolled", True)
        if not tap_node(n, rf"Tab {idx} of 5", f"{tab} tab"):
            record(f"{tab} tab lists files", False, "tab not found"); continue
    n, c = step(f"{tab} tab", 4)
    files = [d.split("\n")[0].split(", ", 1)[-1] for _, d, _, _ in n if re.search(r"\.\w{3,4}\n", d)]
    print(f"{tab} tab shows: {files}")
    record(f"{tab} tab lists files", bool(files) and not c, f"{len(files)} visible")

# ------------------------------------------------------- open files via search
def search_icon(nodes):
    cands = [(box(b), b) for t, d, b, p in nodes if p == PKG and d == "CLICKABLE"
             and box(b)[1] < 90 and box(b)[0] > 150]
    cands.sort(key=lambda x: x[0][0])
    return cands[0][1] if cands else None


def open_by_search(query, expect_name, wait=15):
    n, c, _ = launch(8)
    b = search_icon(n)
    if not b:
        record(f"open {expect_name}", False, "search icon not found"); return
    tap_box(b); time.sleep(2)
    n = dump("search screen", True)
    field = [bb for t, d, bb, p in n if p == PKG and d == "CLICKABLE" and box(bb)[1] < 90 and box(bb)[2] - box(bb)[0] > 150]
    if field: tap_box(field[0]); time.sleep(1)
    sh("input text " + query.replace(" ", "%s")); sh("input keyevent KEYCODE_BACK")
    n, c = step(f"search {query!r}", 3)
    if not tap_node(n, re.escape(expect_name), f"result {expect_name}"):
        record(f"open {expect_name}", False, "not in search results"); return
    n, c = step(f"opened {expect_name}", wait)
    viewer = any(p == PKG for _, _, _, p in n) and alive()
    sh("input keyevent KEYCODE_BACK")
    n2, c2 = step(f"back from {expect_name}", 4, quiet=True)
    msgs = [t or d for t, d, _, _ in n if re.search(r"could not|error|failed|password|not supported|no longer", t or d, re.I)]
    record(f"open {expect_name}", not c and not c2 and viewer, ("CRASH " if c or c2 else "") + "; ".join(msgs))


cases = [
    ("test_open", "test_open.pdf"), ("test_open", "test_open.docx"),
    ("test_open", "test_open.pptx"), ("test_open", "test_open.xlsx"),
    ("Big manual", "Big manual (120 pages).pdf"), ("scan_photo", "scan_photo_pdf.pdf"),
    ("UPPERCASE", "UPPERCASE.PDF"), ("Lecture", "Lecture 5.pdf"),
    ("Quarterly", "Quarterly report Q3.docx"), ("Pitch", "Pitch deck.pptx"),
    ("Budget", "Budget 2026.xlsx"), ("Locked", "Locked (password 1234).pdf"),
    ("corrupt", "corrupt.pdf"), ("corrupt", "corrupt.docx"), ("corrupt", "corrupt.pptx"),
    ("corrupt", "corrupt.xlsx"), ("empty", "empty.pdf"), ("empty", "empty.docx"),
    ("old_format", "old_format.doc"), ("old_format", "old_format.ppt"),
    ("not really", "not really a pdf.pdf"), ("nested", "nested file.pdf"),
]
for q, name in cases:
    open_by_search(q, name)

# Files that must be found / must stay hidden
for q, name, should in [("Form", "Form.pdf", True), ("secret", "secret.pdf", False),
                        ("file_249", "file_249.txt", False), ("file_248", "file_248.xlsx", True)]:
    n, c, _ = launch(8)
    b = search_icon(n)
    if b:
        tap_box(b); time.sleep(2)
        nn = dump("search screen", True)
        field = [bb for t, d, bb, p in nn if p == PKG and d == "CLICKABLE" and box(bb)[1] < 90 and box(bb)[2] - box(bb)[0] > 150]
        if field: tap_box(field[0]); time.sleep(1)
        sh("input text " + q); sh("input keyevent KEYCODE_BACK")
        n, c = step(f"search {q}", 3, quiet=True)
        found = any(name in d for _, d, _, _ in n)
        print(f"search {q}: {[d.split(chr(10))[0] for _, d, _, p in n if p == PKG and chr(10) in d]}")
        record(f"{name} {'listed' if should else 'not listed'}", found == should)

# ------------------------------------------------------------ converters
sh("touch /sdcard/.smoke_marker")
convs = [("Word to PDF", "convert_me.docx"), ("Excel to PDF", "convert_me.xlsx"),
         ("PPT to PDF", "convert_me.pptx"), ("PDF to Word", "convert_me.pdf"),
         ("Images to PDF", "convert_me.jpg"), ("Text to Word", "convert_me.txt")]
def pick_in_documentsui(n, fname):
    if tap_node(n, rf"^{re.escape(fname)}$", "pick file"):
        return True
    tap_node(n, r"^Search$", "picker search"); time.sleep(2)
    sh("input text " + fname.rsplit(".", 1)[0]); sh("input keyevent KEYCODE_ENTER")
    n, c = step("picker search results", 4)
    return tap_node(n, rf"^{re.escape(fname)}$", "pick file")


for tool, fname in convs:
    sh(f"touch /sdcard/Download/{fname}")
    n, c, _ = launch(8)
    tap_node(n, r"^Tools", "tools tab"); n, c = step("tools", 3, quiet=True)
    if not tap_node(n, rf"^{re.escape(tool)}$", tool):
        record(f"convert {tool}", False, "tile missing"); continue
    n, c = step(f"picker for {tool}", 6)
    pkgs = {p for _, _, _, p in n}
    if tool == "Text to Word":
        field = [bb for t, d, bb, p in n if p == PKG and d == "CLICKABLE"]
        if field: tap_box(field[0]); time.sleep(1)
        sh("input text Hello%sfrom%sthe%sdevice%stest"); sh("input keyevent KEYCODE_BACK")
        n, c = step("text entered", 2, quiet=True)
        tap_node(n, r"^Convert$", "Convert")
    elif any("documentsui" in (p or "") for p in pkgs):
        pick_in_documentsui(n, fname)
    elif any("photos" in (p or "") for p in pkgs):
        tap_node(n, r"^Download$", "Download album"); n, c = step("photos album", 4)
        imgs = [bb for t, d, bb, p in n if "photos" in (p or "") and re.search(r"Photo|Image|convert_me", t + d, re.I)]
        if imgs: tap_box(imgs[0]); time.sleep(1)
        if len(imgs) > 1: tap_box(imgs[1]); time.sleep(1)
        n, c = step("photos selected", 2)
        tap_node(n, r"^(Done|Add|Select|OK)$", "confirm photos")
    else:
        record(f"convert {tool}", False, "picker did not open" + (" (crash)" if c else "")); continue
    n, c = step(f"result for {tool}", 20)
    msgs = [t or d for t, d, _, _ in n if re.search(r"success|saved|complete|fail|error|could not|empty", t or d, re.I)]
    ok = not c and alive() and any(re.search(r"success", m, re.I) for m in msgs)
    record(f"convert {tool}", ok, f"msgs={msgs}")
    if ok and tap_node(n, r"^Open File$", "Open File"):
        n, c = step(f"open output of {tool}", 12)
        record(f"open output of {tool}", not c and alive())
    sh("input keyevent KEYCODE_BACK")

# Cancel the picker without choosing: must not crash
n, c, _ = launch(8)
tap_node(n, r"^Tools", "tools tab"); n, c = step("tools", 3, quiet=True)
tap_node(n, r"Word to PDF", "Word to PDF"); n, c = step("picker", 5, quiet=True)
sh("input keyevent KEYCODE_BACK"); n, c = step("picker cancelled", 4)
record("cancel file picker -> no crash", not c and alive())

# ------------------------------------------------------------ summary
print("\n===== APP LOG =====")
for line in adb("logcat", "-d", "-v", "brief").splitlines():
    if re.search(r"^[EWI]/flutter|FATAL|Process: com.example|documentreader.*(Exception|Error)", line):
        print(line[:400])
print("\n===== RESULTS =====")
for name, ok, detail in RESULTS:
    print(f"{'PASS' if ok else 'FAIL'}  {name}  {detail}")
print(f"{sum(ok for _, ok, _ in RESULTS)}/{len(RESULTS)} passed")
