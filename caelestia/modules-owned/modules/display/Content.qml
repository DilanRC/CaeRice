pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property var snapshot: ({})
    property string statusText: qsTr("Display Manager skeleton · read only")

    readonly property string probePath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) +
        "/.local/bin/caerice-display-probe"

    function refresh(): void {
        if (!probe.running)
            probe.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: probe
        command: [root.probePath]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.snapshot = JSON.parse(text.trim());
                    root.statusText = qsTr("Connected outputs discovered · no write capability")
                } catch (error) {
                    root.statusText = qsTr("Display probe returned invalid JSON")
                }
            }
        }
    }

    Column {
        anchors.fill: parent
        spacing: 12

        Row {
            width: parent.width
            height: 54

            Column {
                width: parent.width
                StyledText {
                    text: qsTr("Display Manager")
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.large
                }
                StyledText {
                    text: root.statusText
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                }
            }
        }

        Grid {
            id: monitorGrid
            width: parent.width
            columns: 2
            columnSpacing: 12
            rowSpacing: 12

            Repeater {
                model: root.snapshot?.hyprland ?? []

                delegate: StyledRect {
                    required property var modelData
                    width: (monitorGrid.width - 12) / 2
                    height: 190
                    radius: Tokens.rounding.extraLarge
                    color: Colours.palette.m3surfaceContainer
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant

                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 7

                        StyledText {
                            text: modelData?.name ?? qsTr("Output")
                            color: Colours.palette.m3onSurface
                            font: Tokens.font.title.medium
                        }
                        StyledText {
                            width: parent.width
                            text: modelData?.description ?? ""
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                        StyledText {
                            text: `${modelData?.width ?? "—"}×${modelData?.height ?? "—"} @ ${Number(modelData?.refresh_hz ?? 0).toFixed(2)} Hz`
                            color: Colours.palette.m3primary
                            font: Tokens.font.label.medium
                        }
                        StyledText {
                            text: `x ${modelData?.x ?? "—"} · y ${modelData?.y ?? "—"} · scale ${modelData?.scale ?? "—"}`
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                        }
                        StyledText {
                            text: qsTr("Write controls intentionally disabled in the skeleton.")
                            color: Colours.palette.m3outline
                            font: Tokens.font.body.small
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}
