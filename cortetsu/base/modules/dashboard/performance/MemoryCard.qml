import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.controls
import qs.services

CortetsuSurface {
    id: root

    readonly property color accent: CortetsuColours.palette.m3tertiary

    color: CortetsuColours.tPalette.m3surfaceContainer
    radius: CortetsuTokens.rounding.medium

    implicitWidth: layout.implicitWidth + CortetsuTokens.padding.extraLargeIncreased * 2
    implicitHeight: layout.implicitHeight + CortetsuTokens.padding.large * 2

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: CortetsuTokens.spacing.extraSmall

        RowLayout {
            Layout.leftMargin: -CortetsuTokens.padding.extraSmall
            spacing: CortetsuTokens.spacing.small

            CortetsuIcon {
                text: "memory_alt"
                fill: 1
                color: root.accent
                fontStyle: CortetsuTokens.font.icon.builders.medium.weight(Font.DemiBold).build() // DemiBold to fix fill issues
            }

            CortetsuText {
                text: qsTr("Memory")
                font: CortetsuTokens.font.title.medium
            }
        }

        CircularProgress {
            Layout.topMargin: CortetsuTokens.spacing.large
            Layout.alignment: Qt.AlignHCenter
            implicitSize: usageColumn.implicitHeight + thickness + CortetsuTokens.padding.largeIncreased * 2
            startAngle: -225
            sweepAngle: 270

            fgColour: root.accent
            value: Memory.percentage

            Behavior on clampedVal {
                Anim {}
            }

            ColumnLayout {
                id: usageColumn

                anchors.centerIn: parent
                anchors.verticalCenterOffset: CortetsuTokens.padding.extraSmall
                spacing: 0

                CortetsuText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Math.round(Memory.percentage * 100) + "%"
                    font: CortetsuTokens.font.title.builders.large.width(90).build()
                    color: root.accent
                }

                CortetsuText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Used")
                    font: CortetsuTokens.font.body.small
                    color: CortetsuColours.palette.m3onSurfaceVariant
                }
            }
        }

        CortetsuText {
            Layout.alignment: Qt.AlignHCenter
            text: {
                const fmt = UsageFmt.formatKib(Memory.used, Memory.total);
                return `${+fmt.value.toFixed(1)} / ${+fmt.total.toFixed(1)} ${fmt.unit}`;
            }
            font: CortetsuTokens.font.body.medium
        }
    }
}
