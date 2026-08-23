#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HUB = (ROOT / "caelestia/modules-owned/modules/BottomHub.qml").read_text()
MIGRATOR = (ROOT / "caelestia/bin/migrate-bottom-hub-from-main.py").read_text()
CHECKER = (ROOT / "caelestia/bin/check-bottom-hub-target.py").read_text()
HYPR = (ROOT / "caelestia/user-config/.config/caelestia/hypr-user.lua").read_text()
MANIFEST = (ROOT / "caelestia/patches/MANIFEST.tsv").read_text()


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        raise SystemExit(f"FAIL: falta {label}: {needle}")


def forbid(text: str, needle: str, label: str) -> None:
    if needle in text:
        raise SystemExit(f"FAIL: queda {label}: {needle}")


def main() -> None:
    require(HUB, "id: appSegment", "isla central")
    require(HUB, "id: traySegment", "isla tray")
    require(HUB, "id: statusSegment", "isla sistema")
    if not (HUB.index("id: appSegment") < HUB.index("id: traySegment") < HUB.index("id: statusSegment")):
        raise SystemExit("FAIL: orden visual esperado center -> tray -> system")
    require(HUB, "anchors.right: statusSegment.left", "tray separado de sistema")
    require(HUB, "sourceIndex: SystemTray.items.values.indexOf(modelData)", "indice SNI estable")
    require(HUB, "modelData.icon\n                                        || Icons.getTrayIcon", "icono SNI prioritario")
    require(HUB, "toggleUtilitiesFor", "control único de ajustes")
    forbid(HUB, "`traymenu${trayItem.index}`", "índice filtrado incorrecto")

    require(MIGRATOR, "def qml_block(", "migración QML por bloque")
    require(MIGRATOR, 'qml_block(after, "Launcher.Wrapper", "launcher")', "launcher localizado por id")
    forbid(MIGRATOR, '"anchors.horizontalCenter: parent.horizontalCenter\\n        anchors.bottom: parent.bottom\\n",', "reemplazo global ambiguo")
    require(CHECKER, 'qml_block(text, "Launcher.Wrapper", "launcher")', "validación scoped del launcher")
    require(MANIFEST, "modules__bar__BarWrapper.qml.patch", "retiro de barra nativa")
    require(HYPR, '"SUPER + I",\n    hl.dsp.global("caelestia:utilities")', "SUPER+I a Quick Settings")

    print("BottomHub v4 architecture tests: OK")


if __name__ == "__main__":
    main()
