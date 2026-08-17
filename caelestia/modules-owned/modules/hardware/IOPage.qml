pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var snapshot

    readonly property var disk: snapshot?.disk ?? ({})
    readonly property var diskIo: snapshot?.disk_io ?? ({})
    readonly property var network: snapshot?.network ?? ({})
    readonly property var disks: snapshot?.disks_io ?? []

    function number(value, digits = 1): string {
        if (value === null || value === undefined || isNaN(Number(value)))
            return "—";
        return Number(value).toFixed(digits);
    }

    function gib(value): string {
        return value === null || value === undefined ? "—" : `${number(value, 2)} GiB`;
    }

    function row(label, value): var {
        return { label: label, value: value };
    }

    Row {
        anchors.fill: parent
        spacing: 12

        Column {
            width: parent.width * 0.55
            height: parent.height
            spacing: 12

            StyledRect {
                width: parent.width
                height: (parent.height - 12) * 0.54
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    Row {
                        width: parent.width
                        spacing: 12

                        StyledRect {
                            width: 46
                            height: 46
                            radius: Tokens.rounding.large
                            color: Colours.palette.m3secondaryContainer

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "hard_drive"
                                color: Colours.palette.m3onSecondaryContainer
                                fontStyle: Tokens.font.icon.large
                            }
                        }

                        Column {
                            width: parent.width - 58
                            spacing: 2

                            Row {
                                width: parent.width

                                StyledText {
                                    width: parent.width * 0.58
                                    text: qsTr("Storage / root")
                                    color: Colours.palette.m3onSurface
                                    font: Tokens.font.title.medium
                                }

                                StyledText {
                                    width: parent.width * 0.42
                                    text: `${root.number(root.disk?.usage, 1)}%`
                                    color: Colours.palette.m3primary
                                    font: Tokens.font.title.medium
                                    horizontalAlignment: Text.AlignRight
                                }
                            }

                            StyledText {
                                width: parent.width
                                text: `${root.diskIo?.model ?? root.diskIo?.device ?? "root"}`
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }
                    }

                    StyledRect {
                        width: parent.width
                        height: 10
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3surfaceContainerHighest

                        StyledRect {
                            width: parent.width * Math.max(0, Math.min(1, Number(root.disk?.usage ?? 0) / 100))
                            height: parent.height
                            radius: parent.radius
                            color: Colours.palette.m3primary
                        }
                    }

                    Grid {
                        width: parent.width
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 11

                        Repeater {
                            model: [
                                root.row(qsTr("Used"), root.gib(root.disk?.used_gb)),
                                root.row(qsTr("Free"), root.gib(root.disk?.free_gb)),
                                root.row(qsTr("Read"), `${root.number(root.diskIo?.read_mib_s, 2)} MiB/s`),
                                root.row(qsTr("Write"), `${root.number(root.diskIo?.write_mib_s, 2)} MiB/s`),
                                root.row(qsTr("Read IOPS"), root.number(root.diskIo?.read_iops, 0)),
                                root.row(qsTr("Write IOPS"), root.number(root.diskIo?.write_iops, 0)),
                                root.row(qsTr("Read total"), root.gib(root.diskIo?.read_total_gb)),
                                root.row(qsTr("Write total"), root.gib(root.diskIo?.write_total_gb))
                            ]

                            delegate: Row {
                                required property var modelData
                                width: (parent.width - 20) / 2
                                height: 22

                                StyledText {
                                    width: parent.width * 0.5
                                    text: modelData.label
                                    color: Colours.palette.m3outline
                                    font: Tokens.font.label.small
                                }
                                StyledText {
                                    width: parent.width * 0.5
                                    text: modelData.value
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.label.medium
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideLeft
                                }
                            }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: parent.height - parent.children[0].height - 12
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    Row {
                        width: parent.width

                        StyledText {
                            width: parent.width * 0.6
                            text: qsTr("Detected block devices")
                            color: Colours.palette.m3onSurface
                            font: Tokens.font.title.small
                        }

                        StyledText {
                            width: parent.width * 0.4
                            text: `${root.disks.length} ${qsTr("devices")}`
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    Repeater {
                        model: root.disks.length ? root.disks : [root.diskIo]

                        delegate: StyledRect {
                            required property var modelData
                            width: parent.width
                            height: 52
                            radius: Tokens.rounding.large
                            color: Colours.palette.m3surfaceContainerHigh

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width * 0.54
                                    spacing: 1

                                    StyledText {
                                        text: modelData?.device ?? qsTr("root")
                                        color: Colours.palette.m3onSurface
                                        font: Tokens.font.label.medium
                                    }
                                    StyledText {
                                        width: parent.width
                                        text: modelData?.model ?? modelData?.serial ?? ""
                                        color: Colours.palette.m3outline
                                        font: Tokens.font.label.small
                                        elide: Text.ElideRight
                                    }
                                }

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width * 0.23
                                    text: `${root.number(modelData?.read_mib_s, 2)} R`
                                    color: Colours.palette.m3primary
                                    font: Tokens.font.label.medium
                                    horizontalAlignment: Text.AlignRight
                                }

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width * 0.23
                                    text: `${root.number(modelData?.write_mib_s, 2)} W`
                                    color: Colours.palette.m3tertiary
                                    font: Tokens.font.label.medium
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }
                }
            }
        }

        Column {
            width: parent.width - parent.children[0].width - 12
            height: parent.height
            spacing: 12

            StyledRect {
                width: parent.width
                height: (parent.height - 12) * 0.58
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 13

                    Row {
                        width: parent.width
                        spacing: 12

                        StyledRect {
                            width: 46
                            height: 46
                            radius: Tokens.rounding.large
                            color: Colours.palette.m3secondaryContainer

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: "wifi"
                                color: Colours.palette.m3onSecondaryContainer
                                fontStyle: Tokens.font.icon.large
                            }
                        }

                        Column {
                            width: parent.width - 58
                            spacing: 2

                            StyledText {
                                text: root.network?.interface ?? qsTr("No active interface")
                                color: Colours.palette.m3onSurface
                                font: Tokens.font.title.medium
                            }

                            StyledText {
                                width: parent.width
                                text: root.network?.ssid
                                    ? `${root.network.ssid} · ${root.network?.ipv4 ?? ""}`
                                    : (root.network?.ipv4 ?? qsTr("Active network path"))
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Grid {
                        width: parent.width
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 12

                        Repeater {
                            model: [
                                root.row(qsTr("Download"), `${root.number(root.network?.rx_mbps, 2)} Mb/s`),
                                root.row(qsTr("Upload"), `${root.number(root.network?.tx_mbps, 2)} Mb/s`),
                                root.row(qsTr("RX total"), `${root.number(root.network?.rx_total_gb, 2)} GiB`),
                                root.row(qsTr("TX total"), `${root.number(root.network?.tx_total_gb, 2)} GiB`),
                                root.row(qsTr("Signal"), root.network?.signal_dbm !== undefined ? `${root.network.signal_dbm} dBm` : "—"),
                                root.row(qsTr("Link"), root.network?.bitrate_mbps !== undefined ? `${root.number(root.network.bitrate_mbps, 0)} Mb/s` : "—"),
                                root.row(qsTr("IPv4"), root.network?.ipv4 ?? "—"),
                                root.row(qsTr("MAC"), root.network?.mac ?? "—")
                            ]

                            delegate: Row {
                                required property var modelData
                                width: (parent.width - 20) / 2
                                height: 24

                                StyledText {
                                    width: parent.width * 0.46
                                    text: modelData.label
                                    color: Colours.palette.m3outline
                                    font: Tokens.font.label.small
                                }
                                StyledText {
                                    width: parent.width * 0.54
                                    text: modelData.value
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.label.medium
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideLeft
                                }
                            }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: parent.height - parent.children[0].height - 12
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 10

                    StyledText {
                        text: qsTr("Throughput summary")
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.title.small
                    }

                    StyledText {
                        width: parent.width
                        text: qsTr("The I/O page uses kernel counters and only samples while Hardware Center is open.")
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.small
                        wrapMode: Text.WordWrap
                    }

                    StyledText {
                        width: parent.width
                        text: `${qsTr("Disk")}: ${root.number(root.diskIo?.read_mib_s, 2)} R / ${root.number(root.diskIo?.write_mib_s, 2)} W MiB/s`
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.medium
                    }

                    StyledText {
                        width: parent.width
                        text: `${qsTr("Network")}: ${root.number(root.network?.rx_mbps, 2)} ↓ / ${root.number(root.network?.tx_mbps, 2)} ↑ Mb/s`
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.medium
                    }
                }
            }
        }
    }
}
