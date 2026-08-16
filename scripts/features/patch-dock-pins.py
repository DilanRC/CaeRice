#!/usr/bin/env python3
from __future__ import annotations

import os
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DOCK = REPO / "caelestia/modules-owned/modules/CustomDock.qml"
LIVE = Path("/etc/xdg/quickshell/caelestia/modules/CustomDock.qml")

MARKER = "id: dockPinButton"
ANCHOR = '''                                Row {
                                    anchors.horizontalCenter:
                                        parent.horizontalCenter

                                    anchors.bottom:
                                        parent.bottom
'''

PIN = '''                                Item {
                                    id: dockPinButton

                                    visible: appItem.modelData.pinned || mouse.containsMouse || pinMouse.containsMouse
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.topMargin: 1
                                    anchors.rightMargin: 1
                                    width: 20
                                    height: 20
                                    z: 4

                                    StyledRect {
                                        anchors.fill: parent
                                        radius: Tokens.rounding.full
                                        color: pinMouse.containsMouse
                                            ? Colours.palette.m3secondaryContainer
                                            : appItem.modelData.pinned
                                                ? Colours.palette.m3surfaceContainerHighest
                                                : Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.78)
                                    }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "push_pin"
                                        fill: appItem.modelData.pinned ? 1 : 0
                                        color: appItem.modelData.pinned || pinMouse.containsMouse
                                            ? Colours.palette.m3primary
                                            : Colours.palette.m3onSurfaceVariant
                                        fontStyle: Tokens.font.icon.small
                                    }

                                    MouseArea {
                                        id: pinMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: event => {
                                            win.togglePinned(appItem.modelData);
                                            event.accepted = true;
                                        }
                                    }
                                }

'''


def main() -> None:
    text = DOCK.read_text(encoding="utf-8")
    if MARKER not in text:
        if ANCHOR not in text:
            raise SystemExit("ERROR: no encontré el punto de inserción del pin en CustomDock.qml")
        text = text.replace(ANCHOR, PIN + ANCHOR, 1)
        DOCK.write_text(text, encoding="utf-8")
        print("CustomDock repo: pin visible añadido")
    else:
        print("CustomDock repo: pin visible ya presente")

    if LIVE.exists():
        subprocess.run(["sudo", "install", "-m", "0644", str(DOCK), str(LIVE)], check=True)
        print("CustomDock live: actualizado")


if __name__ == "__main__":
    main()
