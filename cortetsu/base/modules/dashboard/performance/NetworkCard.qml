import QtQuick
import QtQuick.Layouts
import qs.components
import qs.modules
import qs.services

CortetsuSurface {
    id: root

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.extraLarge

    implicitWidth: Tokens.sizes.dashboard.perfNetworkCardWidth
    implicitHeight: Tokens.sizes.dashboard.perfNetworkCardHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        anchors.bottomMargin: Tokens.padding.medium
        spacing: 0

        RowLayout {
            spacing: Tokens.spacing.small

            CortetsuIcon {
                text: "swap_vert"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.medium
            }

            CortetsuText {
                text: qsTr("Network")
                font: Tokens.font.title.medium
            }
        }

        // Sparkline graph
        Item {
            Layout.topMargin: Tokens.spacing.medium
            Layout.bottomMargin: Tokens.spacing.small
            Layout.fillWidth: true
            Layout.fillHeight: true

            Row {
                anchors.fill: parent
                spacing: 2
                anchors.margins: Tokens.padding.small

                Repeater {
                    model: NetworkUsage.historyLength

                    Rectangle {
                        required property int index
                        width: Math.max(1, (parent.width - (NetworkUsage.historyLength - 1) * 2) / NetworkUsage.historyLength)
                        height: parent.height * Math.max(NetworkUsage.downloadHistory[index] ?? 0, NetworkUsage.uploadHistory[index] ?? 0) / Math.max(1024, Math.max(...NetworkUsage.downloadHistory, ...NetworkUsage.uploadHistory, 1))
                        anchors.bottom: parent.bottom
                        radius: 2
                        color: index % 2 ? Colours.palette.m3tertiary : Colours.palette.m3secondary
                        opacity: 0.75
                    }
                }
            }

            // "Collecting data" placeholder
            CortetsuText {
                anchors.centerIn: parent
                text: qsTr("Collecting data...")
                font: Tokens.font.body.small
                color: Colours.palette.m3outline
                visible: NetworkUsage.downloadHistory.length < 2
            }
        }

        // Download row
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            CortetsuIcon {
                text: "download"
                color: Colours.palette.m3tertiary
                fontStyle: Tokens.font.icon.medium
            }

            CortetsuText {
                text: qsTr("Download")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            Item {
                Layout.fillWidth: true
            }

            CortetsuText {
                text: {
                    const fmt = NetworkUsage.formatBytesRate(NetworkUsage.downloadSpeed ?? 0);
                    return fmt ? `${fmt.value.toFixed(1)} ${fmt.unit}` : "0.0 B/s";
                }
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                color: Colours.palette.m3tertiary
            }
        }

        // Upload row
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            CortetsuIcon {
                text: "upload"
                color: Colours.palette.m3secondary
                fontStyle: Tokens.font.icon.medium
            }

            CortetsuText {
                text: qsTr("Upload")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            Item {
                Layout.fillWidth: true
            }

            CortetsuText {
                text: {
                    const fmt = NetworkUsage.formatBytesRate(NetworkUsage.uploadSpeed ?? 0);
                    return fmt ? `${fmt.value.toFixed(1)} ${fmt.unit}` : "0.0 B/s";
                }
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                color: Colours.palette.m3secondary
            }
        }

        // Session totals
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            CortetsuIcon {
                text: "history"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            }

            CortetsuText {
                text: qsTr("Total")
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            Item {
                Layout.fillWidth: true
            }

            CortetsuText {
                text: {
                    const down = NetworkUsage.formatBytes(NetworkUsage.downloadTotal ?? 0);
                    const up = NetworkUsage.formatBytes(NetworkUsage.uploadTotal ?? 0);
                    return (down && up) ? `↓${down.value.toFixed(1)}${down.unit} ↑${up.value.toFixed(1)}${up.unit}` : "↓0.0B ↑0.0B";
                }
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
