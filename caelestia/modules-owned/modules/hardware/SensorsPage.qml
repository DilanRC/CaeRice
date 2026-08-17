pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var snapshot

    readonly property var cpu: snapshot?.cpu ?? ({})
    readonly property var gpus: snapshot?.gpus ?? []
    readonly property var fans: snapshot?.fans ?? []
    readonly property var battery: snapshot?.battery ?? ({})

    function number(value, digits = 1): string {
        if (value === null || value === undefined || isNaN(Number(value)))
            return "—";
        return Number(value).toFixed(digits);
    }

    function gpuAt(index): var {
        return index >= 0 && index < gpus.length ? gpus[index] : ({});
    }

    Row {
        anchors.fill: parent
        spacing: 12

        StyledRect {
            id: coresCard
            width: parent.width * 0.56
            height: parent.height
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

                    Column {
                        width: parent.width * 0.68
                        spacing: 2

                        StyledText {
                            text: qsTr("CPU cores")
                            color: Colours.palette.m3onSurface
                            font: Tokens.font.title.medium
                        }

                        StyledText {
                            width: parent.width
                            text: root.cpu?.model ?? "CPU"
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    Column {
                        width: parent.width * 0.32
                        spacing: 2

                        StyledText {
                            width: parent.width
                            text: `${root.number(root.cpu?.temp_c, 1)} °C`
                            color: Colours.palette.m3primary
                            font: Tokens.font.title.medium
                            horizontalAlignment: Text.AlignRight
                        }

                        StyledText {
                            width: parent.width
                            text: `${root.number(root.cpu?.freq_mhz, 0)} MHz`
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                Grid {
                    id: coreGrid
                    width: parent.width
                    columns: 3
                    columnSpacing: 10
                    rowSpacing: 10

                    Repeater {
                        model: root.cpu?.per_core ?? []

                        delegate: StyledRect {
                            required property var modelData
                            required property int index
                            width: (coreGrid.width - coreGrid.columnSpacing * 2) / 3
                            height: 74
                            radius: Tokens.rounding.large
                            color: Colours.palette.m3surfaceContainerHigh

                            Column {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 7

                                Row {
                                    width: parent.width

                                    StyledText {
                                        width: parent.width * 0.55
                                        text: `CPU ${index}`
                                        color: Colours.palette.m3onSurfaceVariant
                                        font: Tokens.font.label.small
                                    }

                                    StyledText {
                                        width: parent.width * 0.45
                                        text: `${Number(modelData ?? 0).toFixed(0)}%`
                                        color: Colours.palette.m3onSurface
                                        font: Tokens.font.label.medium
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                StyledRect {
                                    width: parent.width
                                    height: 8
                                    radius: Tokens.rounding.full
                                    color: Colours.palette.m3surfaceContainerHighest

                                    StyledRect {
                                        width: parent.width * Math.max(0, Math.min(1, Number(modelData ?? 0) / 100))
                                        height: parent.height
                                        radius: parent.radius
                                        color: Colours.palette.m3primary
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Column {
            width: parent.width - coresCard.width - 12
            height: parent.height
            spacing: 12

            StyledRect {
                width: parent.width
                height: (parent.height - 24) / 3
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 9

                    StyledText {
                        text: qsTr("Cooling")
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.title.small
                    }

                    Repeater {
                        model: root.fans

                        delegate: Row {
                            required property var modelData
                            width: parent.width
                            height: 23

                            StyledText {
                                width: parent.width * 0.66
                                text: modelData?.name ?? qsTr("Fan")
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                width: parent.width * 0.34
                                text: `${modelData?.rpm ?? "—"} RPM`
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.medium
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    StyledText {
                        visible: root.fans.length === 0
                        text: qsTr("No fan telemetry exposed by hwmon")
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.small
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: (parent.height - 24) / 3
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 7

                    StyledText {
                        text: qsTr("Thermals & power")
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.title.small
                    }

                    Repeater {
                        model: [
                            { label: qsTr("CPU"), value: `${root.number(root.cpu?.temp_c, 1)} °C` },
                            { label: root.gpuAt(0)?.vendor ?? qsTr("GPU 1"), value: `${root.number(root.gpuAt(0)?.temp_c, 1)} °C · ${root.number(root.gpuAt(0)?.power_w, 1)} W` },
                            { label: root.gpuAt(1)?.vendor ?? qsTr("GPU 2"), value: `${root.number(root.gpuAt(1)?.temp_c, 1)} °C · ${root.number(root.gpuAt(1)?.power_w, 1)} W` }
                        ]

                        delegate: Row {
                            required property var modelData
                            width: parent.width
                            height: 24

                            StyledText {
                                width: parent.width * 0.38
                                text: modelData.label
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                            }

                            StyledText {
                                width: parent.width * 0.62
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

            StyledRect {
                width: parent.width
                height: (parent.height - 24) / 3
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    StyledText {
                        text: qsTr("Battery")
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.title.small
                    }

                    StyledText {
                        text: root.battery?.present
                            ? `${root.number(root.battery?.percent, 0)}% · ${root.battery?.status ?? "—"}`
                            : qsTr("No battery detected")
                        color: Colours.palette.m3primary
                        font: Tokens.font.title.medium
                    }

                    StyledText {
                        text: root.battery?.present
                            ? `${qsTr("Current draw")}: ${root.number(root.battery?.power_w, 1)} W`
                            : ""
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.medium
                    }

                    StyledText {
                        text: root.battery?.present
                            ? qsTr("Battery and fan values come directly from kernel power_supply/hwmon interfaces.")
                            : qsTr("Sensor data is read only while Hardware Center is open.")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }
        }
    }
}
