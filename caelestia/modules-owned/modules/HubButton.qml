import QtQuick
import Caelestia.Config
import qs.components

Item {
    id: root

    property string icon: "circle"
    property bool active: false
    property string tooltip: ""
    property int buttonSize: 48
    property color activeColor: Colours.palette.m3secondaryContainer
    property color hoverColor: Colours.palette.m3surfaceContainerHighest
    property color iconColor: active ? Colours.palette.m3primary : Colours.palette.m3onSurface

    signal clicked()

    implicitWidth: buttonSize
    implicitHeight: buttonSize
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
            ? root.activeColor
            : mouse.containsMouse
                ? root.hoverColor
                : "transparent"

        Behavior on color {
            ColorAnimation { duration: 110 }
        }
    }

    MaterialIcon {
        anchors.centerIn: parent
        text: root.icon
        color: root.iconColor
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
