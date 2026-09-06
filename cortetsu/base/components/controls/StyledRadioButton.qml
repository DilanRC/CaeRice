import QtQuick
import QtQuick.Templates
import qs.components
import qs.services

RadioButton {
    id: root

    font: CortetsuTokens.font.body.small

    implicitWidth: implicitIndicatorWidth + implicitContentWidth + contentItem.anchors.leftMargin
    implicitHeight: Math.max(implicitIndicatorHeight, implicitContentHeight)

    indicator: Rectangle {
        id: outerCircle

        implicitWidth: 20
        implicitHeight: 20
        radius: CortetsuTokens.rounding.full
        color: "transparent"
        border.color: root.checked ? CortetsuColours.palette.m3primary : CortetsuColours.palette.m3onSurfaceVariant
        border.width: 2
        anchors.verticalCenter: parent.verticalCenter

        CortetsuStateLayer {
            anchors.margins: -CortetsuTokens.padding.small
            color: root.checked ? CortetsuColours.palette.m3onSurface : CortetsuColours.palette.m3primary
            z: -1
            onClicked: root.click()
        }

        CortetsuSurface {
            anchors.centerIn: parent
            implicitWidth: 8
            implicitHeight: 8

            radius: CortetsuTokens.rounding.full
            color: Qt.alpha(CortetsuColours.palette.m3primary, root.checked ? 1 : 0)
        }

        Behavior on border.color {
            CAnim {}
        }
    }

    contentItem: CortetsuText {
        text: root.text
        font: root.font
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: outerCircle.right
        anchors.leftMargin: CortetsuTokens.spacing.medium
    }
}
