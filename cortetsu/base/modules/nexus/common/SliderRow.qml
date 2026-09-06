pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

ConnectedRect {
    id: root

    property alias icon: icon.text
    property alias label: label.text
    property alias valueLabel: valueLabel.text
    property real value

    signal moved(value: real)

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins + rowLayout.anchors.topMargin

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        anchors.margins: CortetsuTokens.padding.largeIncreased
        anchors.topMargin: CortetsuTokens.padding.large
        spacing: CortetsuTokens.spacing.medium

        CortetsuIcon {
            id: icon

            color: CortetsuColours.palette.m3onSurfaceVariant
            fontStyle: CortetsuTokens.font.icon.medium
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: CortetsuTokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: CortetsuTokens.spacing.small

                CortetsuText {
                    id: label

                    Layout.fillWidth: true
                    font: CortetsuTokens.font.body.small
                    elide: Text.ElideRight
                }

                CortetsuText {
                    id: valueLabel

                    color: CortetsuColours.palette.m3outline
                    font: CortetsuTokens.font.body.small
                }
            }

            CustomMouseArea {
                function onWheel(event: WheelEvent): void {
                    const step = CortetsuConfig.audioIncrement;
                    if (event.angleDelta.y > 0)
                        root.moved(Math.min(1, root.value + step));
                    else if (event.angleDelta.y < 0)
                        root.moved(Math.max(0, root.value - step));
                }

                Layout.fillWidth: true
                implicitHeight: CortetsuTokens.padding.medium * 2

                StyledSlider {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitHeight: parent.implicitHeight

                    radius: CortetsuTokens.rounding.small
                    value: root.value
                    enabled: root.enabled
                    onInteraction: v => root.moved(v)
                }
            }
        }
    }
}
