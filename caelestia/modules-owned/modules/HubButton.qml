import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property string icon: "circle"
    property string imageSource: ""
    property bool active: false
    property string tooltip: ""
    property int buttonSize: 48
    property font iconFontStyle: Tokens.font.icon.extraLarge
    property color activeColor: Colours.palette.m3secondaryContainer
    property color hoverColor: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
    property color iconColor: active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3secondary

    signal clicked()
    signal wheel(real delta)

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
        visible: root.imageSource.length === 0
        text: root.icon
        color: root.iconColor
        fontStyle: root.iconFontStyle
    }

    Image {
        anchors.centerIn: parent
        visible: root.imageSource.length > 0
        width: Math.round(root.buttonSize * 0.58)
        height: width
        source: root.imageSource
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onWheel: event => {
            root.wheel(event.angleDelta.y);
            event.accepted = true;
        }
    }
}
