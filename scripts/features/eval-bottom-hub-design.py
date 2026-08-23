#!/usr/bin/env python3
from pathlib import Path

hub = (Path(__file__).resolve().parents[2] / "caelestia/modules-owned/modules/BottomHub.qml").read_text()

criteria = {
    "superficie exterior transparente": 'color: "transparent"\n                border.width: 0',
    "segmentos ligados al scheme": "Colours.tPalette.m3surfaceContainer",
    "launcher CachyOS": 'imageSource: "file:///usr/share/icons/cachyos.svg"',
    "esferas de workspace": "id: workspaceDots",
    "volumen Caelestia": "Icons.getVolumeIcon(Audio.volume, Audio.muted)",
    "selector de output": 'icon: "speaker_group"',
    "wifi Caelestia": "Icons.getNetworkIcon(Nmcli.active.strength ?? 0)",
    "Bluetooth con estado": '"bluetooth_connected"',
    "bateria Caelestia": "Icons.getBatteryIcon(",
    "iconos de sistema compactos": "iconFontStyle: Tokens.font.icon.medium",
    "tray del sistema": "values: SystemTray.items.values.filter(",
    "menus tray por hover": "`traymenu${trayItem.index}`",
    "centro adaptativo": "implicitWidth: Math.min(appRailContent.implicitWidth + 14, win.appRailMaxWidth)",
    "centro geometrico": "anchors.horizontalCenter: parent.horizontalCenter",
    "hover nativo unido": "showAttachedControlFor(win.modelData",
    "quick toggles por fecha": "win.screenState.utilities = !win.screenState.utilities",
}

passed = [name for name, needle in criteria.items() if needle in hub]
if "toggleOverviewFor" in hub or 'icon: "view_quilt"' in hub:
    raise SystemExit("FAIL: BottomHub conserva el control Overview retirado")
if "Layout.fillWidth: true" in hub:
    raise SystemExit("FAIL: el rail central conserva ancho fijo")

score = len(passed) / len(criteria)
print(f"BottomHub design eval: {len(passed)}/{len(criteria)} ({score:.0%})")
if score < 1:
    missing = sorted(set(criteria) - set(passed))
    raise SystemExit("FAIL: " + ", ".join(missing))
