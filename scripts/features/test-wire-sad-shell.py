#!/usr/bin/env python3
"""Regression guard for wire_sad_shell.py, the shared idempotent wiring used
by update-sad.sh to mount Display Manager, Gaming Center and CaeRice
Updater into the live shell.

Proves the three properties update-sad.sh now depends on:
1. A clean tree (only Hardware Center wired - the documented prerequisite,
   see docs/SAD_SCOPE.md) ends up with all three centers fully wired after
   one wire_all() call, and diagnose_sad.check_wiring() independently
   agrees. This is the "does not require the standalone installers to have
   run first" requirement.
2. Running wire_all() again on the now-wired tree changes nothing and
   produces byte-identical output - no duplicated blocks.
3. An anchor-format regression that snuck into the "already fully wired,
   run again" scenario specifically (chained OR-clauses breaking their own
   idempotency marker once a *later* feature extends the same chain) is
   caught: this exact bug was found and fixed while writing this module -
   a naive literal-string replace_once() passed step 1 but failed step 2.
"""
import importlib.util
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("wire_sad_shell", HERE / "wire_sad_shell.py")
wire_sad_shell = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wire_sad_shell)

spec2 = importlib.util.spec_from_file_location("diagnose_sad", HERE / "diagnose-sad.py")
diagnose_sad = importlib.util.module_from_spec(spec2)
spec2.loader.exec_module(diagnose_sad)


def build_hardware_only_tree(root: Path, usercfg: Path):
    (root / "components").mkdir(parents=True)
    (root / "modules" / "drawers").mkdir(parents=True)
    usercfg.parent.mkdir(parents=True, exist_ok=True)

    (root / "shell.qml").write_text(
        "ShellRoot {\n    id: root\n"
        "    OverviewController {}\n    ClipboardController {}\n    HardwareController {}\n    BatteryMonitor {}\n}\n"
    )
    (root / "components" / "ScreenState.qml").write_text(
        "QtObject {\n    property bool overview\n    property bool clipboard\n    property bool hardware\n    property bool dashboard\n}\n"
    )
    (root / "modules" / "drawers" / "Panels.qml").write_text(
        "import qs.modules.hardware as Hardware\nimport qs.modules.notifications as Notifications\n\n"
        "Item {\n"
        "    readonly property alias hardware: hardware\n    readonly property alias dashboard: dashboard\n\n"
        "    Hardware.Wrapper {\n        id: hardware\n    }\n\n"
        "    Dashboard.Wrapper {\n        id: dashboard\n    }\n}\n"
    )
    (root / "modules" / "drawers" / "ContentWindow.qml").write_text(
        "Item {\n"
        "    onHasFullscreenChanged: {\n"
        "        screenState.overview = false;\n        screenState.clipboard = false;\n        screenState.hardware = false;\n"
        "        panels.popouts.close();\n    }\n\n"
        "    WlrLayershell.layer: screenState.overview || screenState.clipboard || screenState.hardware ? WlrLayer.Overlay : WlrLayer.Top\n"
        "    WlrLayershell.keyboardFocus: screenState.overview || screenState.clipboard || screenState.hardware || screenState.launcher || screenState.session ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None\n\n"
        "    mask: screenState.overview || screenState.clipboard || screenState.hardware ? null : regions\n\n"
        "    function shouldBeVisible(s) {\n        if (s.overview || s.clipboard || s.hardware)\n                return true;\n        return false;\n    }\n\n"
        "    onSomething: {\n            root.screenState.overview = false;\n            root.screenState.hardware = false;\n            panels.popouts.hasCurrent = false;\n    }\n}\n"
    )
    usercfg.write_text('hl.bind(\n    "SUPER + H",\n    hl.dsp.global("caelestia:hardware")\n)\n')


with tempfile.TemporaryDirectory() as tmp:
    tmp = Path(tmp)
    live = tmp / "live"
    usercfg = tmp / "hypr-user.lua"
    stage1 = tmp / "stage1"
    stage2 = tmp / "stage2"
    build_hardware_only_tree(live, usercfg)

    # 1. Official rebuild wires all three centers from a Hardware-only tree.
    texts1, changed1 = wire_sad_shell.wire_all(live, usercfg)
    assert changed1 == {"display": True, "gaming": True, "updater": True}, changed1
    wire_sad_shell.write_staged(texts1, stage1)

    diagnose_sad.LIVE = stage1
    diagnose_sad.errors = []
    wired = diagnose_sad.check_wiring()
    assert wired == {"hardware": True, "display": True, "gaming": True, "updater": True}, wired
    assert diagnose_sad.errors == [], diagnose_sad.errors

    # Apply stage1 back onto the live tree (what update-sad.sh's `sudo
    # install` step does) before checking idempotency.
    for rel in ("shell.qml", "components/ScreenState.qml", "modules/drawers/Panels.qml", "modules/drawers/ContentWindow.qml"):
        (live / rel).write_text((stage1 / rel).read_text(encoding="utf-8"), encoding="utf-8")
    usercfg.write_text((stage1 / "user-config/hypr-user.lua").read_text(encoding="utf-8"), encoding="utf-8")

    # 2. Second official rebuild on an already-wired tree changes nothing.
    texts2, changed2 = wire_sad_shell.wire_all(live, usercfg)
    assert changed2 == {"display": False, "gaming": False, "updater": False}, changed2
    wire_sad_shell.write_staged(texts2, stage2)

    for key in texts1:
        assert texts1[key] == texts2[key], f"run 2 duplicated/altered {key!r} even though nothing should have changed"

    # 3. A tree where Hardware Center itself was never wired must fail
    # loudly (no anchor to chain off of), not silently produce broken QML.
    broken = tmp / "broken"
    broken_usercfg = tmp / "broken-hypr-user.lua"
    build_hardware_only_tree(broken, broken_usercfg)
    (broken / "shell.qml").write_text("ShellRoot {\n    id: root\n    BatteryMonitor {}\n}\n")
    try:
        wire_sad_shell.wire_all(broken, broken_usercfg)
        raise AssertionError("expected WiringError for a tree missing the Hardware anchor")
    except wire_sad_shell.WiringError:
        pass

print("test-wire-sad-shell: OK (clean-tree full wiring, idempotent rerun, fail-loud on missing anchor)")
