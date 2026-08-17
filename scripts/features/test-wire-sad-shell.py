#!/usr/bin/env python3
"""Regression guard for Display-only SAD wiring and retired-center cleanup."""
import importlib.util
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("wire_sad_shell", HERE / "wire_sad_shell.py")
wire = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wire)


def fixture(root: Path, user: Path) -> None:
    (root / "components").mkdir(parents=True)
    (root / "modules/drawers").mkdir(parents=True)
    (root / "shell.qml").write_text("ShellRoot {\n    HardwareController {}\n    BatteryMonitor {}\n}\n")
    (root / "components/ScreenState.qml").write_text("QtObject {\n    property bool hardware\n    property bool dashboard\n}\n")
    (root / "modules/drawers/Panels.qml").write_text(
        "import qs.modules.hardware as Hardware\nimport qs.modules.notifications as Notifications\n"
        "Item {\n    readonly property alias hardware: hardware\n    readonly property alias dashboard: dashboard\n"
        "    Hardware.Wrapper {\n        id: hardware\n    }\n"
        "    Dashboard.Wrapper {\n        id: dashboard\n    }\n}\n"
    )
    (root / "modules/drawers/ContentWindow.qml").write_text(
        "Item {\n    onX: {\n        screenState.hardware = false;\n        panels.popouts.close();\n    }\n"
        "    WlrLayershell.layer: screenState.overview || screenState.clipboard || screenState.hardware ? WlrLayer.Overlay : WlrLayer.Top\n"
        "    WlrLayershell.keyboardFocus: screenState.overview || screenState.clipboard || screenState.hardware || screenState.launcher ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None\n"
        "    mask: screenState.overview || screenState.clipboard || screenState.hardware ? null : regions\n"
        "    function f(s) { if (s.overview || s.clipboard || s.hardware)\n                return true; }\n"
        "    onY: {\n            root.screenState.hardware = false;\n            panels.popouts.hasCurrent = false;\n    }\n}\n"
    )
    user.write_text('hl.bind(\n    "SUPER + H",\n    hl.dsp.global("caelestia:hardware")\n)\n')


with tempfile.TemporaryDirectory() as tmpdir:
    tmp = Path(tmpdir)
    live = tmp / "live"
    user = tmp / "hypr-user.lua"
    fixture(live, user)

    texts, changed = wire.wire_all(live, user)
    assert changed == {"retired": False, "display": True}, changed
    assert "DisplayController {}" in texts["shell"]
    assert "property bool displayManager" in texts["screen"]
    assert "id: displayManager" in texts["panels"]

    stage = tmp / "stage"
    wire.write_staged(texts, stage)
    for rel in ("shell.qml", "components/ScreenState.qml", "modules/drawers/Panels.qml", "modules/drawers/ContentWindow.qml"):
        (live / rel).write_text((stage / rel).read_text())
    user.write_text((stage / "user-config/hypr-user.lua").read_text())
    _, changed2 = wire.wire_all(live, user)
    assert changed2 == {"retired": False, "display": False}, changed2

    legacy = {
        "screen": "property bool gamingCenter\nproperty bool updaterCenter\n",
        "shell": "    GamingController {}\n    UpdaterController {}\n",
        "panels": "import qs.modules.gaming as Gaming\nimport qs.modules.updater as Updater\n",
        "content": "screenState.hardware || screenState.gamingCenter || screenState.updaterCenter ? null : regions\n",
        "user": 'hl.bind(\n    "SUPER + SHIFT + G",\n    hl.dsp.global("caelestia:gamingcenter")\n)\nhl.bind(\n    "SUPER + SHIFT + U",\n    hl.dsp.global("caelestia:updatercenter")\n)\n',
    }
    assert wire.retire_removed_centers(legacy) is True
    joined = "\n".join(legacy.values())
    for marker in ("gamingCenter", "updaterCenter", "GamingController", "UpdaterController", "caelestia:gamingcenter", "caelestia:updatercenter"):
        assert marker not in joined, marker

print("test-wire-sad-shell: OK")
