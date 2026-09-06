import QtQuick
import QtQuick.Layouts
import qs.components
import qs.modules
import qs.services

CortetsuSurface {
    id: root

    color: CortetsuColours.tPalette.m3surfaceContainer
    radius: CortetsuTokens.rounding.extraLarge

    implicitWidth: CortetsuTokens.sizes.dashboard.perfNetworkCardWidth
    implicitHeight: CortetsuTokens.sizes.dashboard.perfNetworkCardHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: CortetsuTokens.padding.large
        anchors.bottomMargin: CortetsuTokens.padding.medium
        spacing: 0

        RowLayout {
            spacing: CortetsuTokens.spacing.small

            CortetsuIcon {
                text: "swap_vert"
                color: CortetsuColours.palette.m3primary
                fontStyle: CortetsuTokens.font.icon.medium
            }

            CortetsuText {
                text: qsTr("Network")
                font: CortetsuTokens.font.title.medium
            }
        }

        // Sparkline graph
        Item {
            Layout.topMargin: CortetsuTokens.spacing.medium
            Layout.bottomMargin: CortetsuTokens.spacing.small
            Layout.fillWidth: true
            Layout.fillHeight: true

            Row {
                anchors.fill: parent
                spacing: 2
                anchors.margins: CortetsuTokens.padding.small

                Repeater {
                    model: NetworkUsage.historyLength

                    Rectangle {
                        required property int index
                        width: Math.max(1, (parent.width - (NetworkUsage.historyLength - 1) * 2) / NetworkUsage.historyLength)
                        height: parent.height * Math.max(NetworkUsage.downloadHistory[index] ?? 0, NetworkUsage.uploadHistory[index] ?? 0) / Math.max(1024, Math.max(...NetworkUsage.downloadHistory, ...NetworkUsage.uploadHistory, 1))
                        anchors.bottom: parent.bottom
                        radius: 2
                        color: index % 2 ? CortetsuColours.palette.m3tertiary : CortetsuColours.palette.m3secondary
                        opacity: 0.75
                    }
                }
            }

            // "Collecting data" placeholder
            CortetsuText {
                anchors.centerIn: parent
                text: qsTr("Collecting data...")
                font: CortetsuTokens.font.body.small
                color: CortetsuColours.palette.m3outline
                visible: NetworkUsage.downloadHistory.length < 2
            }
        }

        // Download row
        RowLayout {
            Layout.fillWidth: true
            spacing: CortetsuTokens.spacing.small

            CortetsuIcon {
                text: "download"
                color: CortetsuColours.palette.m3tertiary
                fontStyle: CortetsuTokens.font.icon.medium
            }

            CortetsuText {
                text: qsTr("Download")
                font: CortetsuTokens.font.body.small
                color: CortetsuColours.palette.m3onSurfaceVariant
            }

            Item {
                Layout.fillWidth: true
            }

            CortetsuText {
                text: {
                    const fmt = NetworkUsage.formatBytesRate(NetworkUsage.downloadSpeed ?? 0);
                    return fmt ? `${fmt.value.toFixed(1)} ${fmt.unit}` : "0.0 B/s";
                }
                font: CortetsuTokens.font.body.builders.medium.weight(Font.Medium).build()
                color: CortetsuColours.palette.m3tertiary
            }
        }

        // Upload row
        RowLayout {
            Layout.fillWidth: true
            spacing: CortetsuTokens.spacing.small

            CortetsuIcon {
                text: "upload"
                color: CortetsuColours.palette.m3secondary
                fontStyle: CortetsuTokens.font.icon.medium
            }

            CortetsuText {
                text: qsTr("Upload")
                font: CortetsuTokens.font.body.small
                color: CortetsuColours.palette.m3onSurfaceVariant
            }

            Item {
                Layout.fillWidth: true
            }

            CortetsuText {
                text: {
                    const fmt = NetworkUsage.formatBytesRate(NetworkUsage.uploadSpeed ?? 0);
                    return fmt ? `${fmt.value.toFixed(1)} ${fmt.unit}` : "0.0 B/s";
                }
                font: CortetsuTokens.font.body.builders.medium.weight(Font.Medium).build()
                color: CortetsuColours.palette.m3secondary
            }
        }

        // Session totals
        RowLayout {
            Layout.fillWidth: true
            spacing: CortetsuTokens.spacing.small

            CortetsuIcon {
                text: "history"
                color: CortetsuColours.palette.m3onSurfaceVariant
                fontStyle: CortetsuTokens.font.icon.medium
            }

            CortetsuText {
                text: qsTr("Total")
                font: CortetsuTokens.font.body.small
                color: CortetsuColours.palette.m3onSurfaceVariant
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
                font: CortetsuTokens.font.body.small
                color: CortetsuColours.palette.m3onSurfaceVariant
            }
        }
    }
}
