#!/usr/bin/env python3
"""Offline regression guard for retained Hardware/Display wiring checks."""
import importlib.util
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("diagnose_sad", HERE / "diagnose-sad.py")
diag = importlib.util.module_from_spec(spec)
spec.loader.exec_module(diag)


def build(root: Path, display: bool) -> None:
    (root / "components").mkdir(parents=True)
    (root / "modules/drawers").mkdir(parents=True)
    controllers = ["HardwareController {}"] + (["DisplayController {}"] if display else [])
    flags = ["    property bool hardware"] + (["    property bool displayManager"] if display else [])
    wrappers = ["    Hardware.Wrapper {\n        id: hardware\n    }"] + (["    Display.Wrapper {\n        id: displayManager\n    }"] if display else [])
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
    build(root, False)
    wired, errors = check(root)
    assert wired == {"hardware": True, "display": False}, wired
    assert any("display: not wired" in item for item in errors), errors

with tempfile.TemporaryDirectory() as tmpdir:
    root = Path(tmpdir) / "healthy"
    build(root, True)
    wired, errors = check(root)
    assert wired == {"hardware": True, "display": True}, wired
    assert errors == [], errors

print("test-diagnose-sad-wiring: OK (missing Display detected, healthy retained wiring accepted)")
