import QtQuick
import Caelestia.Config
import qs.components

Item {
    id: root

    property string icon: "circle"
    property bool active: false
    property string tooltip: ""

    signal clicked()

    implicitWidth: 40
    implicitHeight: 44
    scale: mouse.containsMouse ? 1.10 : 1

    Behavior on scale {
        NumberAnimation {
            duration: 110
            easing.type: Easing.OutCubic
        }
    }

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.large
        color: root.active
            ? Colours.palette.m3secondaryContainer
            : mouse.containsMouse
                ? Colours.palette.m3surfaceContainerHighest
                : "transparent"

        Behavior on color {
            ColorAnimation { duration: 110 }
        }
    }

    MaterialIcon {
        anchors.centerIn: parent
        text: root.icon
        color: root.active
            ? Colours.palette.m3primary
            : Colours.palette.m3onSurface
        fontStyle: Tokens.font.icon.extraLarge
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
