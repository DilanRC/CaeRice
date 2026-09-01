#!/usr/bin/env python3
"""Offline regression guard for retained Hardware/Display/Wallpaper wiring checks."""
import importlib.util
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("diagnose_sad", HERE / "diagnose-sad.py")
diag = importlib.util.module_from_spec(spec)
spec.loader.exec_module(diag)


def build(root: Path, display: bool, wallpaper: bool) -> None:
    (root / "components").mkdir(parents=True)
    (root / "modules/drawers").mkdir(parents=True)
    controllers = ["HardwareController {}"]
    flags = ["    property bool hardware"]
    wrappers = ["    Hardware.Wrapper {\n        id: hardware\n    }"]
    if display:
        controllers.append("DisplayController {}")
        flags.append("    property bool displayManager")
        wrappers.append("    Display.Wrapper {\n        id: displayManager\n    }")
    if wallpaper:
        controllers.append("WallpaperController {}")
        flags.append("    property bool wallpaperManager")
        wrappers.append("    Wallpaper.Wrapper {\n        id: wallpaperManager\n    }")
    (root / "shell.qml").write_text("ShellRoot {\n    " + "\n    ".join(controllers) + "\n}\n")
    (root / "components/ScreenState.qml").write_text("QtObject {\n" + "\n".join(flags) + "\n}\n")
    (root / "modules/drawers/Panels.qml").write_text("Item {\n" + "\n".join(wrappers) + "\n}\n")


def check(root: Path):
    diag.LIVE = root
    diag.errors = []
    diag.warnings = []
    return diag.check_wiring(), list(diag.errors)


with tempfile.TemporaryDirectory() as tmpdir:
    root = Path(tmpdir) / "missing-display"
    build(root, False, False)
    wired, errors = check(root)
    assert wired == {"hardware": True, "display": False, "wallpaper": False}, wired
    assert any("display: not wired" in item for item in errors), errors
    assert any("wallpaper: not wired" in item for item in errors), errors

with tempfile.TemporaryDirectory() as tmpdir:
    root = Path(tmpdir) / "missing-wallpaper"
    build(root, True, False)
    wired, errors = check(root)
    assert wired == {"hardware": True, "display": True, "wallpaper": False}, wired
    assert any("wallpaper: not wired" in item for item in errors), errors

with tempfile.TemporaryDirectory() as tmpdir:
    root = Path(tmpdir) / "healthy"
    build(root, True, True)
    wired, errors = check(root)
    assert wired == {"hardware": True, "display": True, "wallpaper": True}, wired
    assert errors == [], errors

print("test-diagnose-sad-wiring: OK (missing Display/Wallpaper detected, healthy retained wiring accepted)")
