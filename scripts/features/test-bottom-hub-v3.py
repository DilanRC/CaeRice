#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
BOTTOM_HUB = REPO / "caelestia/modules-owned/modules/BottomHub.qml"
HUB_BUTTON = REPO / "caelestia/modules-owned/modules/HubButton.qml"


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        raise SystemExit(f"FAIL: missing {label}")


def require_order(text: str, labels: list[tuple[str, str]]) -> None:
    cursor = -1
    for needle, label in labels:
        pos = text.find(needle)
        if pos < 0:
            raise SystemExit(f"FAIL: missing {label}")
        if pos <= cursor:
            raise SystemExit(f"FAIL: {label} is out of order")
        cursor = pos


def require_balanced_qml(text: str, path: Path) -> None:
    stack = []
    pairs = {"{": "}", "(": ")", "[": "]"}
    closing = set(pairs.values())
    quote: str | None = None
    escaped = False

    for line_no, line in enumerate(text.splitlines(), start=1):
        for char in line:
            if quote:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == quote:
                    quote = None
                continue

            if char in ("'", '"', "`"):
                quote = char
            elif char in pairs:
                stack.append((char, line_no))
            elif char in closing:
                if not stack or pairs[stack[-1][0]] != char:
                    raise SystemExit(f"FAIL: unbalanced {char} in {path}:{line_no}")
                stack.pop()

    if stack:
        char, line_no = stack[-1]
        raise SystemExit(f"FAIL: unclosed {char} in {path}:{line_no}")


def main() -> None:
    bottom = BOTTOM_HUB.read_text(encoding="utf-8")
    button = HUB_BUTTON.read_text(encoding="utf-8")

    require_balanced_qml(bottom, BOTTOM_HUB)
    require_balanced_qml(button, HUB_BUTTON)

    require(bottom, "readonly property bool panelActive:", "panel activity state")
    require(bottom, "readonly property int hubMargin: 8", "full-width hub margin")
    require(bottom, "readonly property int appRailMaxWidth:", "bounded app rail width")
    require(bottom, "implicitWidth: modelData.width - hubMargin * 2", "monitor-width bar")
    require(bottom, 'color: "transparent"\n                border.width: 0', "transparent outer surface")
    require(bottom, "id: leftSegment", "anchored left segment")
    require(bottom, "anchors.horizontalCenter: parent.horizontalCenter", "centered app segment")
    require(bottom, "implicitWidth: Math.min(appRailContent.implicitWidth + 14, win.appRailMaxWidth)", "content-sized app rail")
    if "Layout.fillWidth: true" in bottom:
        raise SystemExit("FAIL: app rail must size to content instead of filling the bar")
    require(bottom, "Flickable {", "scrollable app rail")
    require(bottom, "interactive: contentWidth > width", "rail overflow interaction")
    require(bottom, "visible: appItem.modelData.pinned && !appItem.running", "pinned dormant badge")
    require(bottom, "model: Math.min(appItem.modelData.windows.length, 4)", "capped window indicators")
    require(bottom, 'imageSource: "file:///usr/share/icons/cachyos.svg"', "CachyOS launcher logo")
    require(bottom, "id: workspaceDots", "workspace indicator spheres")
    require(bottom, "Icons.getVolumeIcon(Audio.volume, Audio.muted)", "Caelestia volume icon")
    if 'icon: "speaker_group"' in bottom:
        raise SystemExit("FAIL: duplicate audio output control remains")
    require(bottom, "id: volumeButton", "single audio control")
    require(bottom, "Icons.getNetworkIcon(Nmcli.active.strength ?? 0)", "Caelestia network icon")
    require(bottom, '"bluetooth_connected"', "Caelestia bluetooth state icon")
    require(bottom, "Icons.getBatteryIcon(", "Caelestia battery icon")
    require(bottom, "trayItems: SystemTray.items.values.filter(", "system tray items")
    require(bottom, "layer.enabled: Config.bar.tray.recolour", "native tray recolouring")
    require(bottom, "`traymenu${trayItem.sourceIndex}`", "native tray hover menu")
    require(bottom, "Colours.tPalette.m3surfaceContainer", "scheme-aware translucent surfaces")
    require(bottom, "activeColor: Colours.palette.m3errorContainer", "session danger active state")
    require(bottom, "onClicked: hubRoot.toggleLauncherFor(win.modelData)", "launcher action")
    if "toggleOverviewFor" in bottom or 'icon: "view_quilt"' in bottom:
        raise SystemExit("FAIL: overview control must not be present in BottomHub")
    require(bottom, "onClicked: hubRoot.toggleSidebarFor(win.modelData)", "sidebar action")
    require(bottom, '"audio",\n                                            win.popoutAnchorCenter(volumeButton)', "anchored audio hover")
    require(bottom, '"network",\n                                            win.popoutAnchorCenter(networkButton)', "anchored network hover")
    require(bottom, '"bluetooth",\n                                            win.popoutAnchorCenter(bluetoothButton)', "anchored bluetooth hover")
    require(bottom, '"battery",\n                                            win.popoutAnchorCenter(batteryButton)', "anchored battery hover")
    require(bottom, "onClicked: hubRoot.openCalendarFor(win.modelData)", "clock-click calendar")
    require(bottom, "win.togglePinned(appItem.modelData);", "right-click pin action")
    require(bottom, "win.closeWindow(activeWindow ?? appItem.modelData.windows[0]);", "middle-click close action")
    require(bottom, "win.cycleItem(appItem.modelData, -1);", "wheel previous action")
    require(bottom, "win.cycleItem(appItem.modelData, 1);", "wheel next action")

    require_order(
        bottom,
        [
            ("id: leftSegment", "left mode segment"),
            ("id: appSegment", "center app segment"),
            ("id: traySegment", "tray segment"),
            ("id: statusSegment", "right status segment"),
        ],
    )

    require(button, "property int buttonSize: 48", "button size parameter")
    require(button, "property font iconFontStyle:", "button icon scale parameter")
    require(button, 'property string imageSource: ""', "image button support")
    require(button, "signal wheel(real delta)", "wheel interaction support")
    require(button, "property color activeColor:", "button active color parameter")
    require(button, "property color iconColor:", "button icon color parameter")
    require(button, "readonly property bool hovered: mouse.containsMouse", "hover state exposure")
    require(button, "implicitWidth: buttonSize", "button width binding")
    require(button, "implicitHeight: buttonSize", "button height binding")

    print("BottomHub v3 semantic tests: OK")


if __name__ == "__main__":
    main()
