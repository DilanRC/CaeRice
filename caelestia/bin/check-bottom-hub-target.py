#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path


def has_all(text: str, needles: tuple[str, ...]) -> bool:
    return all(needle in text for needle in needles)


def check_shell(text: str) -> bool:
    return has_all(text, (
        "settings.watchFiles: false",
        "    BottomHub {}",
        "    OverviewController {}",
    )) and "    CustomDock {}" not in text


def check_screen_state(text: str) -> bool:
    return "property bool overview" in text


def check_content_window(text: str) -> bool:
    return has_all(text, (
        "screenState.overview = false;",
        "WlrLayershell.layer: screenState.overview ? WlrLayer.Overlay",
        "WlrLayershell.keyboardFocus: screenState.overview || screenState.launcher || screenState.session",
        "mask: screenState.overview ? null : (hasFullscreen ? emptyRegion : regions)",
        "if (s.overview)",
        "opacity: root.screenState.overview ? 0.58",
    ))


def check_panels(text: str) -> bool:
    return has_all(text, (
        "import qs.modules.overview as Overview",
        "readonly property alias overview: overview",
        "clip: session.visible",
        "sidebarOrSessionVisible: session.visible",
        "anchors.rightMargin: 0\n        clip: false",
        "Overview.Wrapper {",
        "anchors.bottom: sidebar.visible ? sidebar.top : utilities.top",
        "anchors.right: parent.right",
        "anchors.horizontalCenter: parent.horizontalCenter\n        anchors.bottom: parent.bottom",
    ))


def check_regions(text: str) -> bool:
    return has_all(text, (
        "y: root.win.height - height - panel.dockOffset",
        "width: panel.width * (1 - root.panels.session.offsetScale) + root.borderThickness",
        "panel: root.panels.sidebar",
        "width: panel.width\n        height: panel.height * (1 - root.panels.sidebar.offsetScale) + root.borderThickness",
    )) and "+ sidebarRegion.width" not in text


CHECKS = {
    "shell.qml": check_shell,
    "components/ScreenState.qml": check_screen_state,
    "modules/drawers/ContentWindow.qml": check_content_window,
    "modules/drawers/Panels.qml": check_panels,
    "modules/drawers/Regions.qml": check_regions,
}


def main() -> None:
    parser = argparse.ArgumentParser(description="Valida estado semántico final de BottomHub")
    parser.add_argument("root", type=Path)
    parser.add_argument("rel")
    args = parser.parse_args()

    check = CHECKS.get(args.rel)
    if check is None:
        raise SystemExit(2)

    path = args.root / args.rel
    if not path.is_file():
        raise SystemExit(1)

    text = path.read_text(encoding="utf-8")
    raise SystemExit(0 if check(text) else 1)


if __name__ == "__main__":
    main()
