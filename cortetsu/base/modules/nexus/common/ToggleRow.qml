import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.controls
import qs.services

StyledSwitch {
    id: root

    property string subtext
    property alias first: bg.first
    property alias last: bg.last
    readonly property alias bg: bg

    Layout.fillWidth: true

    horizontalPadding: CortetsuTokens.padding.largeIncreased
    verticalPadding: CortetsuTokens.padding.medium
    font: CortetsuTokens.font.body.small

    implicitWidth: implicitContentWidth + implicitIndicatorWidth + horizontalPadding * 2
    implicitHeight: Math.max(implicitContentHeight, implicitIndicatorHeight) + verticalPadding * 2
    cLayer: 2

    indicator.anchors.verticalCenter: verticalCenter
    indicator.anchors.right: right
    indicator.anchors.rightMargin: root.horizontalPadding

    onPressed: stateLayer.press(stateLayer.mouseX, stateLayer.mouseY)

    background: ConnectedRect {
        id: bg

        CortetsuStateLayer {
            id: stateLayer

            disabled: root.disabled
            manualPressOverride: root.pressed
        }
    }

    contentItem: Item {
        anchors.left: parent.left
        anchors.right: root.indicator.left
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: CortetsuTokens.spacing.medium

        implicitWidth: column.implicitWidth
        implicitHeight: column.implicitHeight

        Column {
            id: column

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            CortetsuText {
                id: label

                anchors.left: parent.left
                anchors.right: parent.right

                text: root.text
                font: root.font
                elide: Text.ElideRight
            }

            CortetsuText {
                anchors.left: parent.left
                anchors.right: parent.right

                visible: root.subtext
                text: root.subtext
                color: CortetsuColours.palette.m3outline
                font: CortetsuTokens.font.label.small
                elide: Text.ElideRight
            }
        }
    }
}
