"""Drives the installed app on an emulator and prints what happens."""
import re, subprocess, sys, time, xml.etree.ElementTree as ET

PKG = "com.example.documentreader"

def adb(*a, check=False):
    r = subprocess.run(["adb", *a], capture_output=True, text=True)
    return r.stdout + r.stderr

def sh(cmd):
    return adb("shell", cmd)

def dump(label):
    sh("uiautomator dump /sdcard/ui.xml >/dev/null 2>&1")
    xml = sh("cat /sdcard/ui.xml")
    nodes = []
    try:
        root = ET.fromstring(xml[xml.index("<?xml"):])
        for n in root.iter("node"):
            t = (n.get("text") or "").strip()
            d = (n.get("content-desc") or "").strip()
            if t or d:
                nodes.append((t, d, n.get("bounds"), n.get("package")))
    except Exception as e:
        print("dump failed", e, xml[:300])
    print(f"\n===== SCREEN: {label} =====")
    for t, d, b, p in nodes:
        print(f"  [{p}] text={t!r} desc={d!r} {b}")
    return nodes

def tap_node(nodes, pattern, label):
    rx = re.compile(pattern, re.I | re.S)
    for t, d, b, p in nodes:
        if rx.search(t) or rx.search(d):
            x1, y1, x2, y2 = map(int, re.findall(r"\d+", b))
            print(f">>> TAP {label}: {t or d!r}")
            sh(f"input tap {(x1+x2)//2} {(y1+y2)//2}")
            return True
    print(f"!!! NOT FOUND: {label} /{pattern}/")
    return False

def crashed(label):
    out = adb("logcat", "-d", "-b", "crash")
    alive = sh(f"pidof {PKG}").strip()
    print(f"--- after {label}: app pid={alive or 'DEAD'}")
    if out.strip():
        print("--- CRASH BUFFER ---\n" + out[-6000:])
        adb("logcat", "-b", "crash", "-c")
    return not alive

def step(label, wait=4):
    time.sleep(wait)
    crashed(label)
    return dump(label)

def launch():
    sh(f"am force-stop {PKG}")
    sh(f"monkey -p {PKG} -c android.intent.category.LAUNCHER 1")

scenario = sys.argv[1] if len(sys.argv) > 1 else "all"

# 1. Fresh launch, no permission granted yet
launch()
n = step("first launch (no permission)", 10)
for _ in range(3):
    if tap_node(n, r"^(allow|ok|grant|continue)$|allow access|permit", "permission prompt"):
        n = step("after permission tap", 4)
        # system settings toggle for all-files access
        if tap_node(n, r"allow access to manage all files|permit|all files", "all-files toggle"):
            n = step("after toggle", 3)
            sh("input keyevent KEYCODE_BACK")
            n = step("back to app", 5)
    else:
        break

# 2. Grant all-files access directly and relaunch
sh(f"appops set --uid {PKG} MANAGE_EXTERNAL_STORAGE allow")
launch()
n = step("relaunch with all-files access", 12)

# 3. Open a PDF from the home list
if tap_node(n, r"sample\.pdf", "open sample.pdf"):
    n = step("pdf opened", 12)
    sh("input keyevent KEYCODE_BACK"); n = step("back from pdf", 4)

# 4. Open a docx from the home list
launch(); n = step("relaunch", 10)
tap_node(n, r"^Word|WORD", "word tab"); n = step("word tab", 3)
if tap_node(n, r"sample\.docx", "open sample.docx"):
    n = step("docx opened", 12)
    sh("input keyevent KEYCODE_BACK"); n = step("back from docx", 4)

# 5. Tools tab and file pickers
launch(); n = step("relaunch for tools", 10)
tap_node(n, r"^Tools", "tools tab"); n = step("tools tab", 3)
tools = [t or d for t, d, b, p in n if p == PKG and (t or d)]
for name in tools:
    if not re.search(r"to (pdf|word)|image|merge|split|compress|convert|scan", name, re.I):
        continue
    launch(); nn = step("relaunch", 8)
    tap_node(nn, r"^Tools", "tools tab"); nn = step("tools", 3)
    if not tap_node(nn, re.escape(name), f"tool {name!r}"):
        continue
    nn = step(f"tool {name!r} opened", 4)
    tap_node(nn, r"select|choose|pick|upload|browse|add", "select file button")
    nn = step(f"picker for {name!r}", 6)
    if any(p and "documentsui" in p for _, _, _, p in nn):
        if not tap_node(nn, r"sample\.", "pick sample file"):
            tap_node(nn, r"show roots|Downloads", "roots")
            nn = step("roots", 3)
            tap_node(nn, r"^Download", "downloads"); nn = step("downloads", 3)
            tap_node(nn, r"sample\.", "pick sample file")
        nn = step(f"after picking for {name!r}", 10)
        tap_node(nn, r"convert|start|create|merge|compress|split|save", "action button")
        nn = step(f"after action for {name!r}", 15)
    sh("input keyevent KEYCODE_BACK")

print("\n===== FLUTTER / RUNTIME ERRORS =====")
log = adb("logcat", "-d")
for line in log.splitlines():
    if re.search(r"AndroidRuntime|FATAL|flutter|E/PDFNet|Exception|Error:", line) and "chatty" not in line:
        print(line[:400])
