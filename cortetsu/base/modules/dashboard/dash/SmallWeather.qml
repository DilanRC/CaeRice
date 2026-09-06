import QtQuick
import qs.components
import qs.services

Item {
    id: root

    anchors.centerIn: parent

    implicitWidth: icon.implicitWidth + info.implicitWidth + info.anchors.leftMargin
    implicitHeight: Math.max(icon.implicitHeight, info.implicitHeight) + CortetsuTokens.padding.largeIncreased * 2

    Component.onCompleted: Weather.reload()

    CortetsuIcon {
        id: icon

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        animate: true
        text: Weather.icon
        color: CortetsuColours.palette.m3secondary
        fontStyle: CortetsuTokens.font.icon.builders.extraLarge.scale(1.6).build()
    }

    Column {
        id: info

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: icon.right
        anchors.leftMargin: CortetsuTokens.spacing.largeIncreased

        spacing: CortetsuTokens.spacing.extraSmall

        CortetsuText {
            anchors.horizontalCenter: parent.horizontalCenter

            animate: true
            text: Weather.temp
            color: CortetsuColours.palette.m3primary
            font: CortetsuTokens.font.headline.builders.medium.width(110).weight(Font.DemiBold).build()
        }

        CortetsuText {
            anchors.horizontalCenter: parent.horizontalCenter

            animate: true
            text: Weather.description
            font: CortetsuTokens.font.body.small

            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.parent.width - icon.implicitWidth - info.anchors.leftMargin - CortetsuTokens.padding.extraLargeIncreased)
        }
    }
}
