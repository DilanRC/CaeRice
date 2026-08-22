#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path


def has_all(text: str, needles: tuple[str, ...]) -> bool:
    return all(needle in text for needle in needles)


def line_starting(text: str, prefix: str) -> str | None:
    prefix = prefix.strip()
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith(prefix):
            return stripped
    return None


def block_between(text: str, start: str, end: str) -> str | None:
    start_pos = text.find(start)
    if start_pos < 0:
        return None
    end_pos = text.find(end, start_pos + len(start))
    if end_pos < 0:
        return None
    return text[start_pos:end_pos]


def retained_overlay_flags(root: Path) -> tuple[str, ...]:
    """Return retained CaeRice overlays that are actually wired in ScreenState.

    ContentWindow is intentionally a shared native surface. Clipboard, Hardware
    Center and Display Manager extend the same overview focus/layer/mask chains.
    A BottomHub check must preserve those members instead of demanding the
    byte-for-byte base overview expression.
    """
    screen_path = root / "components/ScreenState.qml"
    if not screen_path.is_file():
        return ("overview",)

    screen = screen_path.read_text(encoding="utf-8")
    flags = ["overview"]
    for flag in ("clipboard", "hardware", "displayManager"):
        if f"property bool {flag}" in screen:
            flags.append(flag)
    return tuple(flags)


def check_shell(root: Path, text: str) -> bool:
    del root
    return has_all(text, (
        "settings.watchFiles: false",
        "    BottomHub {}",
        "    OverviewController {}",
    )) and "    CustomDock {}" not in text


def check_screen_state(root: Path, text: str) -> bool:
    del root
    return "property bool overview" in text


def check_content_window(root: Path, text: str) -> bool:
    flags = retained_overlay_flags(root)

    layer = line_starting(text, "WlrLayershell.layer:")
    keyboard = line_starting(text, "WlrLayershell.keyboardFocus:")
    mask = line_starting(text, "mask:")
    focus_active = block_between(text, "HyprlandFocusGrab {", "windows: [root]")
    cleared = block_between(text, "onCleared: {", "panels.popouts.hasCurrent = false;")
    fullscreen = block_between(text, "onHasFullscreenChanged: {", "panels.popouts.close();")

    if not all((layer, keyboard, mask, focus_active, cleared, fullscreen)):
        return False

    # BottomHub's base Overview integration must remain active even when later
    # CaeRice modules extend these boolean chains.
    if "WlrLayer.Overlay" not in layer:
        return False
    if "WlrKeyboardFocus.OnDemand" not in keyboard:
        return False
    if "screenState.launcher" not in keyboard or "screenState.session" not in keyboard:
        return False
    if "? null" not in mask or "hasFullscreen ? emptyRegion : regions" not in mask:
        return False
    if "return true;" not in focus_active:
        return False

    for flag in flags:
        if f"screenState.{flag}" not in layer:
            return False
        if f"screenState.{flag}" not in keyboard:
            return False
        if f"screenState.{flag}" not in mask:
            return False
        if f"s.{flag}" not in focus_active:
            return False
        if f"screenState.{flag} = false;" not in fullscreen:
            return False
        if f"root.screenState.{flag} = false;" not in cleared:
            return False

    # The Overview scrim is owned by the base patch. Clipboard may nest its
    # own 0.48 scrim after it; Hardware/Display do not replace this invariant.
    if "opacity: root.screenState.overview ? 0.58" not in text:
        return False
    if "clipboard" in flags and "root.screenState.clipboard ? 0.48" not in text:
        return False

    return True


def check_panels(root: Path, text: str) -> bool:
    del root
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


def check_regions(root: Path, text: str) -> bool:
    del root
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

    root = args.root.resolve()
    path = root / args.rel
    if not path.is_file():
        raise SystemExit(1)

    text = path.read_text(encoding="utf-8")
    raise SystemExit(0 if check(root, text) else 1)


if __name__ == "__main__":
    main()
