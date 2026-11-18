"""Crash hunt: taps every button on every screen it can reach (depth-first,
replaying the path after each detour), then rotates, backgrounds, and runs
monkey. Prints every crash or ANR with the taps that led to it."""
import hashlib, re, subprocess, time, xml.etree.ElementTree as ET

PKG = "com.example.documentreader"
BUDGET_S = 28 * 60
MAX_DEPTH = 4
T0 = time.time()
CRASHES = []
visited, seen_screens = set(), set()
taps = 0


def adb(*a):
    r = subprocess.run(["adb", *a], capture_output=True, text=True, timeout=120)
    return r.stdout + r.stderr


def sh(cmd):
    return adb("shell", cmd)


def dump():
    for _ in range(3):
        sh("uiautomator dump /sdcard/ui.xml >/dev/null 2>&1")
        xml = sh("cat /sdcard/ui.xml")
        try:
            root = ET.fromstring(xml[xml.index("<?xml"):])
            break
        except Exception:
            time.sleep(1.5)
    else:
        return []
    out = []
    for n in root.iter("node"):
        t = (n.get("text") or "").strip()
        d = (n.get("content-desc") or "").strip()
        out.append(dict(t=t, d=d, b=n.get("bounds"), p=n.get("package"),
                        click=n.get("clickable") == "true",
                        long=n.get("long-clickable") == "true",
                        edit=n.get("class") == "android.widget.EditText"))
    return out


def label(n):
    return (n["t"] or n["d"]).split("\n")[0][:60] or f"@{n['b']}"


def center(b):
    x1, y1, x2, y2 = map(int, re.findall(r"\d+", b))
    return (x1 + x2) // 2, (y1 + y2) // 2


def sig(nodes):
    # Screen identity: the app's static labels, ignoring list rows that change.
    keys = sorted({label(n) for n in nodes if n["p"] == PKG and n["click"] and "\n" not in (n["d"] or "")})
    return hashlib.md5("|".join(keys).encode()).hexdigest()[:10]


def in_app(nodes):
    return any(n["p"] == PKG for n in nodes)


def alive():
    return bool(sh(f"pidof {PKG}").strip())


def crash_check(where):
    c = adb("logcat", "-d", "-b", "crash").strip()
    anr = adb("logcat", "-d", "-s", "ActivityManager:E").strip()
    anr = "\n".join(l for l in anr.splitlines() if "ANR in " + PKG in l)
    if c:
        adb("logcat", "-b", "crash", "-c")
    if anr:
        adb("logcat", "-c")
    found = c or anr
    nodes = dump()
    if any("keeps stopping" in n["t"] or "isn't responding" in n["t"] for n in nodes):
        found = found or "system crash/ANR dialog"
        for n in nodes:
            if re.match(r"Close app|Wait", n["t"]):
                x, y = center(n["b"]); sh(f"input tap {x} {y}")
    if found:
        CRASHES.append((where, found))
        print(f"\n!!!!! CRASH/ANR after: {where}\n" + "\n".join(found.splitlines()[:70]))
        tomb = sh("ls -t /data/tombstones/ 2>/dev/null | grep -v pb | head -1").strip()
        if tomb and "F DEBUG" in found:
            print("--- TOMBSTONE ---\n" + sh(f"head -80 /data/tombstones/{tomb}"))
    return bool(found), nodes


def launch():
    sh(f"am force-stop {PKG}")
    sh(f"am start -W --activity-clear-task -n {PKG}/.MainActivity")
    time.sleep(6)


def tap(n, longpress=False):
    x, y = center(n["b"])
    if longpress:
        sh(f"input swipe {x} {y} {x} {y} 900")
    else:
        sh(f"input tap {x} {y}")


def replay(path):
    launch()
    for step in path:
        nodes = dump()
        m = [n for n in nodes if n["p"] == PKG and label(n) == step.lstrip("~")]
        if not m:
            return False
        tap(m[0], step.startswith("~")); time.sleep(2.5)
    return True


def actions(nodes):
    seen, acts = set(), []
    for n in nodes:
        if n["p"] != PKG:
            continue
        if n["edit"]:
            continue
        for kind in (("tap",) if n["click"] else ()) + (("long",) if n["long"] else ()):
            k = (label(n), kind)
            if k not in seen:
                seen.add(k); acts.append((n, kind))
    return acts


def explore(path, depth):
    global taps
    nodes = dump()
    s = sig(nodes)
    for n, kind in actions(nodes):
        if time.time() - T0 > BUDGET_S:
            return
        key = (s, label(n), kind)
        if key in visited:
            continue
        visited.add(key); taps += 1
        step = ("~" if kind == "long" else "") + label(n)
        where = " > ".join(path + [step])
        print(f"[{taps:3d}] {where}")
        tap(n, kind == "long"); time.sleep(3)
        crashed, after = crash_check(where)
        if crashed or not alive():
            if not crashed:
                print("   (app closed without crash)")
            if not replay(path):
                return
            continue
        if not in_app(after):
            sh("input keyevent KEYCODE_BACK"); time.sleep(2)
            after = dump()
            if not in_app(after) or not alive():
                if not replay(path):
                    return
                continue
        s2 = sig(after)
        if s2 != s and s2 not in seen_screens and depth < MAX_DEPTH:
            seen_screens.add(s2)
            explore(path + [step], depth + 1)
        if sig(dump()) != s:
            sh("input keyevent KEYCODE_BACK"); time.sleep(2)
            if sig(dump()) != s or not alive():
                if not replay(path):
                    return


# ------------------------------------------------------------------ crawl
adb("logcat", "-c"); adb("logcat", "-b", "crash", "-c")
launch()
seen_screens.add(sig(dump()))
explore([], 0)
print(f"\ncrawl: {taps} actions, {len(seen_screens)} screens, {len(CRASHES)} crashes, {int(time.time() - T0)} s")

# ------------------------------------------------------------------ rotate & background
launch()
for i in range(3):
    for rot in (1, 0):
        sh("settings put system accelerometer_rotation 0")
        sh(f"settings put system user_rotation {rot}"); time.sleep(2)
    crash_check(f"rotate home x{i}")
nodes = dump()
pdfs = [n for n in nodes if n["p"] == PKG and ".pdf" in (n["d"] or "").lower()]
if pdfs:
    tap(pdfs[0]); time.sleep(8)
    for rot in (1, 0, 1, 0):
        sh(f"settings put system user_rotation {rot}"); time.sleep(3)
    crash_check("rotate inside viewer")
    for i in range(4):
        sh("input keyevent KEYCODE_HOME"); time.sleep(2)
        sh(f"am start -n {PKG}/.MainActivity"); time.sleep(3)
    crash_check("background/foreground x4 with viewer open")
    for i in range(3):
        sh("input keyevent KEYCODE_BACK"); time.sleep(1)
    crash_check("back out of viewer")
sh(f"am send-trim-memory {PKG} RUNNING_CRITICAL"); time.sleep(2)
crash_check("trim memory")

# ------------------------------------------------------------------ monkey
for seed in (11, 22, 33, 44):
    launch()
    out = sh(f"monkey -p {PKG} -s {seed} --pct-syskeys 0 --pct-appswitch 0 --pct-anyevent 0 "
             f"--throttle 100 --ignore-security-exceptions -v 1500")
    bad = [l for l in out.splitlines() if "CRASH" in l or "NOT RESPONDING" in l or "Exception" in l]
    print(f"\nmonkey seed {seed}: {'events injected' if 'Events injected' in out else 'aborted'}; {len(bad)} issues")
    if bad:
        print("\n".join(out.splitlines()[-60:]))
    crash_check(f"monkey seed {seed}")

print("\n===== CRAWL RESULTS =====")
print(f"actions tried: {taps}, screens reached: {len(seen_screens)}")
for where, c in CRASHES:
    first = next((l for l in c.splitlines() if "Exception" in l or "Error" in l or "signal" in l or "Abort" in l), c.splitlines()[0])
    print(f"CRASH  {where}\n       {first.strip()[:200]}")
print(f"{len(CRASHES)} crashes/ANRs")
