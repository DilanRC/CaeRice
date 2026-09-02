#!/usr/bin/env python3
"""Compose all CaeRice retained panels into one staged Panels.qml."""
from pathlib import Path
import sys

root = Path(sys.argv[1])
path = root / "modules/drawers/Panels.qml"
text = path.read_text()
imports = (
    'import qs.modules.clipboard as Clipboard\n'
    'import qs.modules.hardware as Hardware\n'
    'import qs.modules.display as Display\n'
    'import qs.modules.wallpaper as Wallpaper\n'
    'import qs.modules.calendar as Calendar\n'
)
if "import qs.modules.calendar as Calendar" not in text:
    text = text.replace("import qs.modules.overview as Overview\n", "import qs.modules.overview as Overview\n" + imports)
aliases = "    readonly property alias overview: overview\n"
aliases += "    readonly property alias clipboard: clipboard\n    readonly property alias hardware: hardware\n    readonly property alias displayManager: displayManager\n    readonly property alias wallpaperManager: wallpaperManager\n    readonly property alias calendar: calendar\n"
if "readonly property alias calendar" not in text:
    text = text.replace("    readonly property alias overview: overview\n", aliases)
anchor = "    Dashboard.Wrapper {\n"
wrappers = """    Clipboard.Wrapper { id: clipboard; screen: root.screen; screenState: root.screenState; anchors.fill: parent }
    Hardware.Wrapper { id: hardware; screen: root.screen; screenState: root.screenState; anchors.fill: parent }
    Display.Wrapper { id: displayManager; screen: root.screen; screenState: root.screenState; anchors.fill: parent }
    Wallpaper.Wrapper { id: wallpaperManager; screen: root.screen; screenState: root.screenState; anchors.fill: parent }
    Calendar.Wrapper { id: calendar; screenState: root.screenState; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: bar.implicitHeight + Tokens.padding.medium }

"""
if "id: calendar" not in text:
    text = text.replace(anchor, wrappers + anchor, 1)
text = text.replace("        sidebar: sidebar\n", "")
path.write_text(text)
for marker in ("id: overview", "id: clipboard", "id: hardware", "id: displayManager", "id: wallpaperManager", "id: calendar"):
    if marker not in text:
        raise SystemExit(f"missing composed marker: {marker}")
print("PASS: unified retained panel composition")
