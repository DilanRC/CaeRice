#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MODULES = ROOT / "cortetsu/modules"
HUB = (MODULES / "BottomHub.qml").read_text()
VIEW = (MODULES / "CortetsuBottomHubView.qml").read_text()
TRAY = (MODULES / "CortetsuTraySegment.qml").read_text()
MIGRATOR = (ROOT / "cortetsu/bin/migrate-bottom-hub-from-main.py").read_text()
CHECKER = (ROOT / "cortetsu/bin/check-bottom-hub-target.py").read_text()
HYPR = (ROOT / "caelestia/user-config/.config/caelestia/hypr-user.lua").read_text()
MANIFEST = (ROOT / "caelestia/patches/MANIFEST.tsv").read_text()
SHORTCUTS = (ROOT / "caelestia/patches/modules__Shortcuts.qml.patch").read_text()
PANELS = (ROOT / "caelestia/patches/modules__drawers__Panels.qml.patch").read_text()
POPOUT = (ROOT / "caelestia/patches/modules__bar__popouts__ClipWrapper.qml.patch").read_text()
WINDOW_CARD = (MODULES / "overview/WindowCard.qml").read_text()


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        raise SystemExit(f"FAIL: falta {label}: {needle}")


def forbid(text: str, needle: str, label: str) -> None:
    if needle in text:
        raise SystemExit(f"FAIL: queda {label}: {needle}")


def main() -> None:
    require(HUB, "CortetsuBottomHubView {", "frontera first-party")
    require(VIEW, "id: appSegment", "isla central")
    require(VIEW, "id: traySegment", "isla tray")
    require(VIEW, "id: statusSegment", "isla sistema")
    if not (VIEW.index("id: appSegment") < VIEW.index("id: traySegment") < VIEW.index("id: statusSegment")):
        raise SystemExit("FAIL: orden visual esperado center -> tray -> system")
    require(VIEW, "anchors.right: statusSegment.left", "tray separado de sistema")
    require(HUB, "const sourceIndex = SystemTray.items.values.indexOf(item);", "indice SNI estable")
    require(HUB, "item.icon || Icons.getTrayIcon(item.id, item.icon)", "icono SNI prioritario")
    require(HUB, "toggleUtilitiesFor", "control único de ajustes")
    forbid(TRAY, "SystemTray", "backend SNI dentro de la vista")
    forbid(HUB, "`traymenu${trayItem.index}`", "índice filtrado incorrecto")

    require(MIGRATOR, "def qml_block(", "migración QML por bloque")
    require(MIGRATOR, 'qml_block(after, "Launcher.Wrapper", "launcher")', "launcher localizado por id")
    forbid(MIGRATOR, '"anchors.horizontalCenter: parent.horizontalCenter\\n        anchors.bottom: parent.bottom\\n",', "reemplazo global ambiguo")
    require(CHECKER, 'qml_block(text, "Launcher.Wrapper", "launcher")', "validación scoped del launcher")
    require(MANIFEST, "modules__bar__BarWrapper.qml.patch", "retiro de barra nativa")
    require(HYPR, '"SUPER + I",\n    hl.dsp.global("cortetsu:nexus")', "SUPER+I a Nexus")
    require(HYPR, '"SUPER + H",\n    hl.dsp.global("cortetsu:hardware")', "SUPER+H a Hardware Center")
    require(HUB, "hubRoot.toggleLauncherFor(state.modelData);", "SUPER alterna el launcher")
    require(SHORTCUTS, "const open = !(screenState.sidebar || screenState.utilities);", "SUPER+N abre ambos centros")
    require(SHORTCUTS, 'Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")', "ruta XDG del launcher")
    forbid(SHORTCUTS, "/quickshell/caelestia/current", "ruta legacy del launcher")
    require(PANELS, "anchors.right: root.screenState.utilities ? utilities.left : parent.right", "centros adyacentes")
    require(POPOUT, "content.bottomAnchorCenter - content.nonAnimWidth / 2", "popup centrado en su icono")
    require(WINDOW_CARD, "import qs.utils", "Overview resuelve Icons sin ReferenceError")
    forbid(POPOUT, "\n+    Behavior on y", "viaje vertical de popup")

    print("BottomHub v4 architecture tests: OK")


if __name__ == "__main__":
    main()
