#!/usr/bin/env python3
"""Regression guard for the diagnose-sad.py wiring check.

Real bug this guards against: a SAD center's QML module files can be
byte-identical to source (diagnose-sad's MATCH check) and its IPC target can
still not exist live, because `qs ipc call <target> isOpen` exits 0 and just
prints "Target not found." when the controller was never instantiated in
shell.qml/ScreenState.qml/Panels.qml. That happened for real: update-sad.sh
copies GamingController.qml/UpdaterController.qml but only
install-gaming-center.sh/install-caerice-updater.sh perform the shell.qml +
ScreenState.qml + Panels.qml wiring, so a machine that only ever ran
update-sad.sh has a fully "MATCH"-passing, fully "validate-sad.py OK" feature
that is completely unreachable. This test proves check_wiring() would have
caught it, and that a fully-wired tree reports clean.

Fast, offline, no sudo, no live Quickshell/system calls: builds a throwaway
fake LIVE tree and calls diagnose-sad's check_wiring() directly.
"""
import importlib.util, sys, tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("diagnose_sad", HERE / "diagnose-sad.py")
diagnose_sad = importlib.util.module_from_spec(spec)
spec.loader.exec_module(diagnose_sad)  # only defines functions/constants; main() body is guarded


def build_live(root: Path, include_gaming: bool, include_updater: bool):
    (root / "components").mkdir(parents=True)
    (root / "modules" / "drawers").mkdir(parents=True)

    controllers = ["HardwareController {}", "DisplayController {}"]
    flags = ["    property bool hardware", "    property bool displayManager"]
    wrappers = ["    Hardware.Wrapper {\n        id: hardware\n    }", "    Display.Wrapper {\n        id: displayManager\n    }"]
    if include_gaming:
        controllers.append("GamingController {}")
        flags.append("    property bool gamingCenter")
        wrappers.append("    Gaming.Wrapper {\n        id: gamingCenter\n    }")
    if include_updater:
        controllers.append("UpdaterController {}")
        flags.append("    property bool updaterCenter")
        wrappers.append("    Updater.Wrapper {\n        id: updaterCenter\n    }")

    (root / "shell.qml").write_text("ShellRoot {\n    " + "\n    ".join(controllers) + "\n}\n")
    (root / "components" / "ScreenState.qml").write_text("QtObject {\n" + "\n".join(flags) + "\n}\n")
    (root / "modules" / "drawers" / "Panels.qml").write_text("Item {\n" + "\n".join(wrappers) + "\n}\n")


def run_check(root: Path):
    diagnose_sad.LIVE = root
    diagnose_sad.errors = []
    diagnose_sad.warnings = []
    wired = diagnose_sad.check_wiring()
    return wired, list(diagnose_sad.errors)


# Case 1: reproduces the real bug - gaming/updater modules present as files
# elsewhere but never wired into shell.qml/ScreenState.qml/Panels.qml.
with tempfile.TemporaryDirectory() as tmp:
    broken = Path(tmp) / "live"
    build_live(broken, include_gaming=False, include_updater=False)
    wired, errors = run_check(broken)
    assert wired == {"hardware": True, "display": True, "gaming": False, "updater": False}, wired
    assert any("gaming: not wired" in e for e in errors), errors
    assert any("updater: not wired" in e for e in errors), errors

# Case 2: fully wired tree must NOT be flagged (no false positives).
with tempfile.TemporaryDirectory() as tmp:
    healthy = Path(tmp) / "live"
    build_live(healthy, include_gaming=True, include_updater=True)
    wired, errors = run_check(healthy)
    assert all(wired.values()), wired
    assert errors == [], errors

print("test-diagnose-sad-wiring: OK (2/2)")
