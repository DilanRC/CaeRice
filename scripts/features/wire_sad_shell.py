#!/usr/bin/env python3
"""Idempotent wiring for the "post-Hardware" SAD centers: Display Manager,
Gaming Center, CaeRice Updater.

Hardware Center's own live wiring is a separate, already-correct
prerequisite path via install-hardware-center.sh (see docs/SAD_SCOPE.md:
"install-sad.sh integrates the post-Hardware centers"). This module only
covers the three centers that sit on top of it.

Why this exists: install-display-manager.sh / install-gaming-center.sh /
install-caerice-updater.sh each carry their own copy of this exact
shell.qml + ScreenState.qml + Panels.qml + ContentWindow.qml +
hypr-user.lua patch logic. update-sad.sh (the official resync/rebuild
entrypoint) used to skip it entirely and only copy module *.qml files,
which let GamingController.qml/UpdaterController.qml sit on disk
byte-identical to source while never being instantiated anywhere -
diagnose-sad.py's MATCH rows and validate-sad.py both reported OK while
Super+Shift+G/U did nothing and `qs ipc call gaming/updater isOpen`
answered "Target not found." (see docs/SAD_QA.md). This module centralizes
the wiring so the official rebuild path can reproduce a complete install
without requiring a human to have separately run the standalone
installers first.

Idempotent by construction: every edit is a replace_once() keyed on a
marker string; if the marker is already present the edit is a no-op. The
Panels.qml Wrapper blocks use the same rule (checked via `id: <flag>`).
Running wire_all() twice therefore never duplicates a block - the second
call reports every feature as unchanged.

Features are chained in a fixed order (display -> gaming -> updater),
each anchored on the previous feature's freshly-wired text, exactly like
the standalone installers assume when run in sequence. That means this
module still requires Hardware Center to already be wired (its markers
are the anchor for Display) - which install-hardware-center.sh guarantees
independently and diagnose-sad.py verifies.
"""
from __future__ import annotations

import argparse
import json
import os
import re
from pathlib import Path


class WiringError(RuntimeError):
    """Raised when an expected anchor is missing - the live tree diverged
    from what this module knows how to patch. Never silently skip: fail
    loudly so update-sad.sh aborts instead of reporting false success."""


def replace_once(texts: dict[str, str], key: str, old: str, new: str, marker: str) -> bool:
    if marker in texts[key]:
        return False
    if old not in texts[key]:
        raise WiringError(f"PREFLIGHT ERROR [{key}]: missing context for {marker!r}")
    texts[key] = texts[key].replace(old, new, 1)
    return True


def _find_span(text: str, anchor: str, tail: str, what: str) -> re.Match:
    # Non-greedy: matches the *first* anchor...tail pair, i.e. the shortest
    # chain already accumulated between them (whatever earlier features
    # inserted stays inside the captured group untouched).
    pattern = re.compile(re.escape(anchor) + r"(.*?)" + re.escape(tail), re.DOTALL)
    m = pattern.search(text)
    if not m:
        raise WiringError(f"PREFLIGHT ERROR: missing anchor/tail for {what!r}")
    return m


def ensure_or_member(texts: dict[str, str], key: str, anchor: str, tail: str, member: str) -> bool:
    """Idempotently ensure `member` sits in the `anchor(...)tail` OR-chain.

    Unlike a literal replace_once() on the full old/new strings, this stays
    correct even after a *later* feature extends the same chain past this
    feature's own insertion point - which is exactly what breaks a plain
    string match here (see module docstring / commit message: the flag's
    own text is no longer immediately adjacent to `tail` once something
    else was chained in between). The idempotency check is scoped to the
    captured span, so it never collides with a different edit's marker for
    the same flag (e.g. the close-handler assignment vs. this condition).
    """
    text = texts[key]
    m = _find_span(text, anchor, tail, member)
    if member in m.group(1):
        return False
    insertion_point = m.start(1) + len(m.group(1))
    texts[key] = text[:insertion_point] + f" || {member}" + text[insertion_point:]
    return True


def ensure_statement(texts: dict[str, str], key: str, anchor: str, tail: str, statement: str) -> bool:
    """Same idea as ensure_or_member() but for a statement list (e.g. a
    `screenState.<flag> = false;` reset line) inserted right before a fixed
    tail statement, instead of an ` || member` OR-chain fragment."""
    text = texts[key]
    m = _find_span(text, anchor, tail, statement)
    if statement in m.group(1):
        return False
    insertion_point = m.start(1) + len(m.group(1))
    texts[key] = text[:insertion_point] + "\n" + statement + text[insertion_point:]
    return True


def insert_wrapper(texts: dict[str, str], flag: str, block: str, anchor: str = "    Dashboard.Wrapper {") -> bool:
    if f"id: {flag}" in texts["panels"]:
        return False
    if anchor not in texts["panels"]:
        raise WiringError(f"PREFLIGHT ERROR [panels]: missing anchor {anchor!r}")
    texts["panels"] = texts["panels"].replace(anchor, block + anchor, 1)
    return True


def insert_bind(texts: dict[str, str], bind: str, anchor: str, comment: str) -> bool:
    if bind in texts["user"]:
        return False
    if anchor not in texts["user"]:
        raise WiringError(f"PREFLIGHT ERROR [user]: missing bind anchor {anchor!r}")
    texts["user"] = texts["user"].replace(anchor, anchor + f"\n\n-- {comment}\n" + bind, 1)
    return True


def _wire_display(texts: dict[str, str]) -> bool:
    changed = False
    changed |= replace_once(texts, "screen",
        "    property bool hardware\n    property bool dashboard",
        "    property bool hardware\n    property bool displayManager\n    property bool dashboard",
        "property bool displayManager")
    changed |= replace_once(texts, "shell",
        "    HardwareController {}\n    BatteryMonitor {}",
        "    HardwareController {}\n    DisplayController {}\n    BatteryMonitor {}",
        "DisplayController {}")
    changed |= replace_once(texts, "panels",
        "import qs.modules.hardware as Hardware\nimport qs.modules.notifications as Notifications",
        "import qs.modules.hardware as Hardware\nimport qs.modules.display as Display\nimport qs.modules.notifications as Notifications",
        "import qs.modules.display as Display")
    changed |= replace_once(texts, "panels",
        "    readonly property alias hardware: hardware\n    readonly property alias dashboard: dashboard",
        "    readonly property alias hardware: hardware\n    readonly property alias displayManager: displayManager\n    readonly property alias dashboard: dashboard",
        "readonly property alias displayManager: displayManager")
    changed |= insert_wrapper(texts, "displayManager",
        "    Display.Wrapper {\n        id: displayManager\n\n        screen: root.screen\n        screenState: root.screenState\n\n        anchors.fill: parent\n    }\n\n")
    changed |= ensure_statement(texts, "content",
        "        screenState.hardware = false;", "\n        panels.popouts.close();",
        "        screenState.displayManager = false;")
    changed |= ensure_or_member(texts, "content",
        "WlrLayershell.layer: screenState.overview || screenState.clipboard || screenState.hardware", " ? WlrLayer.Overlay",
        "screenState.displayManager")
    changed |= ensure_or_member(texts, "content",
        "WlrLayershell.keyboardFocus: screenState.overview || screenState.clipboard || screenState.hardware", " || screenState.launcher",
        "screenState.displayManager")
    changed |= ensure_or_member(texts, "content",
        "mask: screenState.overview || screenState.clipboard || screenState.hardware", " ? null",
        "screenState.displayManager")
    changed |= ensure_or_member(texts, "content",
        "if (s.overview || s.clipboard || s.hardware", ")\n                return true;",
        "s.displayManager")
    changed |= ensure_statement(texts, "content",
        "            root.screenState.hardware = false;", "\n            panels.popouts.hasCurrent = false;",
        "            root.screenState.displayManager = false;")
    changed |= insert_bind(texts,
        'hl.bind(\n    "SUPER + SHIFT + O",\n    hl.dsp.global("caelestia:displaymanager")\n)',
        'hl.bind(\n    "SUPER + H",\n    hl.dsp.global("caelestia:hardware")\n)',
        "Display Manager QML nativo")
    return changed


def _wire_gaming(texts: dict[str, str]) -> bool:
    changed = False
    changed |= replace_once(texts, "screen",
        "    property bool displayManager\n    property bool dashboard",
        "    property bool displayManager\n    property bool gamingCenter\n    property bool dashboard",
        "property bool gamingCenter")
    changed |= replace_once(texts, "shell",
        "    DisplayController {}\n    BatteryMonitor {}",
        "    DisplayController {}\n    GamingController {}\n    BatteryMonitor {}",
        "GamingController {}")
    changed |= replace_once(texts, "panels",
        "import qs.modules.display as Display\nimport qs.modules.notifications as Notifications",
        "import qs.modules.display as Display\nimport qs.modules.gaming as Gaming\nimport qs.modules.notifications as Notifications",
        "import qs.modules.gaming as Gaming")
    changed |= replace_once(texts, "panels",
        "    readonly property alias displayManager: displayManager\n    readonly property alias dashboard: dashboard",
        "    readonly property alias displayManager: displayManager\n    readonly property alias gamingCenter: gamingCenter\n    readonly property alias dashboard: dashboard",
        "readonly property alias gamingCenter: gamingCenter")
    changed |= insert_wrapper(texts, "gamingCenter",
        "    Gaming.Wrapper {\n        id: gamingCenter\n        screen: root.screen\n        screenState: root.screenState\n        anchors.fill: parent\n    }\n\n")
    changed |= ensure_statement(texts, "content",
        "        screenState.hardware = false;", "\n        panels.popouts.close();",
        "        screenState.gamingCenter = false;")
    changed |= ensure_or_member(texts, "content",
        "WlrLayershell.layer: screenState.overview || screenState.clipboard || screenState.hardware", " ? WlrLayer.Overlay",
        "screenState.gamingCenter")
    changed |= ensure_or_member(texts, "content",
        "WlrLayershell.keyboardFocus: screenState.overview || screenState.clipboard || screenState.hardware", " || screenState.launcher",
        "screenState.gamingCenter")
    changed |= ensure_or_member(texts, "content",
        "mask: screenState.overview || screenState.clipboard || screenState.hardware", " ? null",
        "screenState.gamingCenter")
    changed |= ensure_or_member(texts, "content",
        "if (s.overview || s.clipboard || s.hardware", ")\n                return true;",
        "s.gamingCenter")
    changed |= ensure_statement(texts, "content",
        "            root.screenState.hardware = false;", "\n            panels.popouts.hasCurrent = false;",
        "            root.screenState.gamingCenter = false;")
    changed |= insert_bind(texts,
        'hl.bind(\n    "SUPER + SHIFT + G",\n    hl.dsp.global("caelestia:gamingcenter")\n)',
        'hl.bind(\n    "SUPER + SHIFT + O",\n    hl.dsp.global("caelestia:displaymanager")\n)',
        "Gaming Center QML nativo")
    return changed


def _wire_updater(texts: dict[str, str]) -> bool:
    changed = False
    changed |= replace_once(texts, "screen",
        "    property bool gamingCenter\n    property bool dashboard",
        "    property bool gamingCenter\n    property bool updaterCenter\n    property bool dashboard",
        "property bool updaterCenter")
    changed |= replace_once(texts, "shell",
        "    GamingController {}\n    BatteryMonitor {}",
        "    GamingController {}\n    UpdaterController {}\n    BatteryMonitor {}",
        "UpdaterController {}")
    changed |= replace_once(texts, "panels",
        "import qs.modules.gaming as Gaming\nimport qs.modules.notifications as Notifications",
        "import qs.modules.gaming as Gaming\nimport qs.modules.updater as Updater\nimport qs.modules.notifications as Notifications",
        "import qs.modules.updater as Updater")
    changed |= replace_once(texts, "panels",
        "    readonly property alias gamingCenter: gamingCenter\n    readonly property alias dashboard: dashboard",
        "    readonly property alias gamingCenter: gamingCenter\n    readonly property alias updaterCenter: updaterCenter\n    readonly property alias dashboard: dashboard",
        "readonly property alias updaterCenter: updaterCenter")
    changed |= insert_wrapper(texts, "updaterCenter",
        "    Updater.Wrapper {\n        id: updaterCenter\n        screen: root.screen\n        screenState: root.screenState\n        anchors.fill: parent\n    }\n\n")
    changed |= ensure_statement(texts, "content",
        "        screenState.hardware = false;", "\n        panels.popouts.close();",
        "        screenState.updaterCenter = false;")
    changed |= ensure_or_member(texts, "content",
        "WlrLayershell.layer: screenState.overview || screenState.clipboard || screenState.hardware", " ? WlrLayer.Overlay",
        "screenState.updaterCenter")
    changed |= ensure_or_member(texts, "content",
        "WlrLayershell.keyboardFocus: screenState.overview || screenState.clipboard || screenState.hardware", " || screenState.launcher",
        "screenState.updaterCenter")
    changed |= ensure_or_member(texts, "content",
        "mask: screenState.overview || screenState.clipboard || screenState.hardware", " ? null",
        "screenState.updaterCenter")
    changed |= ensure_or_member(texts, "content",
        "if (s.overview || s.clipboard || s.hardware", ")\n                return true;",
        "s.updaterCenter")
    changed |= ensure_statement(texts, "content",
        "            root.screenState.hardware = false;", "\n            panels.popouts.hasCurrent = false;",
        "            root.screenState.updaterCenter = false;")
    changed |= insert_bind(texts,
        'hl.bind(\n    "SUPER + SHIFT + U",\n    hl.dsp.global("caelestia:updatercenter")\n)',
        'hl.bind(\n    "SUPER + SHIFT + G",\n    hl.dsp.global("caelestia:gamingcenter")\n)',
        "CaeRice Updater QML nativo")
    return changed


# Order matters: each feature's anchors are the previous feature's freshly
# wired text, chained exactly like running the standalone installers in
# sequence would produce.
FEATURES = {"display": _wire_display, "gaming": _wire_gaming, "updater": _wire_updater}
ORDER = ("display", "gaming", "updater")


def load_texts(live: Path, usercfg: Path) -> dict[str, str]:
    paths = {
        "screen": live / "components/ScreenState.qml",
        "shell": live / "shell.qml",
        "panels": live / "modules/drawers/Panels.qml",
        "content": live / "modules/drawers/ContentWindow.qml",
        "user": usercfg,
    }
    missing = [str(p) for p in paths.values() if not p.is_file()]
    if missing:
        raise WiringError("missing live file(s): " + ", ".join(missing))
    return {k: p.read_text(encoding="utf-8") for k, p in paths.items()}


def wire_all(live: Path, usercfg: Path, features: tuple[str, ...] = ORDER) -> tuple[dict[str, str], dict[str, bool]]:
    texts = load_texts(live, usercfg)
    changed: dict[str, bool] = {}
    for name in ORDER:
        if name in features:
            changed[name] = FEATURES[name](texts)
    return texts, changed


def write_staged(texts: dict[str, str], stage: Path) -> dict[str, Path]:
    out = {
        "screen": stage / "components/ScreenState.qml",
        "shell": stage / "shell.qml",
        "panels": stage / "modules/drawers/Panels.qml",
        "content": stage / "modules/drawers/ContentWindow.qml",
        "user": stage / "user-config/hypr-user.lua",
    }
    for key, path in out.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(texts[key], encoding="utf-8")
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--live", default=os.environ.get("CAERICE_LIVE_ROOT", "/etc/xdg/quickshell/caelestia"))
    parser.add_argument("--usercfg", default=str(Path.home() / ".config/caelestia/hypr-user.lua"))
    parser.add_argument("--stage", required=True, help="directory to write the staged, patched files into")
    parser.add_argument("--features", default=",".join(ORDER), help="comma-separated subset of: " + ",".join(ORDER))
    args = parser.parse_args()
    features = tuple(f for f in args.features.split(",") if f)
    unknown = [f for f in features if f not in FEATURES]
    if unknown:
        parser.error("unknown feature(s): " + ", ".join(unknown))
    try:
        texts, changed = wire_all(Path(args.live), Path(args.usercfg), features)
        write_staged(texts, Path(args.stage))
    except WiringError as exc:
        print(json.dumps({"ok": False, "error": str(exc)}))
        return 1
    print(json.dumps({"ok": True, "changed": changed}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
