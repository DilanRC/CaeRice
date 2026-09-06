import QtQuick
import qs.components
import qs.services

Item {
    id: root

    required property ScreenState screenState

    implicitWidth: icon.implicitHeight + CortetsuTokens.padding.small
    implicitHeight: icon.implicitHeight

    CortetsuStateLayer {
        // Cursed workaround to make the height larger than the parent
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + CortetsuTokens.padding.small
        radius: CortetsuTokens.rounding.full
        onClicked: root.screenState.session = !root.screenState.session
    }

    CortetsuIcon {
        id: icon

        anchors.centerIn: parent

        text: "power_settings_new"
        color: CortetsuColours.palette.m3error
        fontStyle: CortetsuTokens.font.icon.builders.small.weight(Font.Bold).build()
    }
}
