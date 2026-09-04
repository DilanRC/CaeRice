import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property string icon: "circle"
    property string imageSource: ""
    property bool cropImage: false
    property bool active: false
    property string tooltip: ""
    property int buttonSize: 48
    property font iconFontStyle: Tokens.font.icon.extraLarge
    property color activeColor: Colours.palette.m3secondaryContainer
    property color hoverColor: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
    property color iconColor: active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3secondary
    readonly property bool hovered: mouse.containsMouse

    signal clicked()
    signal wheel(real delta)

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    scale: mouse.containsMouse ? 1.06 : 1

    Behavior on scale {
        NumberAnimation {
            duration: Tokens.anim.durations.expressiveFastSpatial
            easing: Tokens.anim.expressiveFastSpatial
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
            ColorAnimation {
                duration: Tokens.anim.durations.expressiveFastEffects
                easing: Tokens.anim.expressiveFastEffects
            }
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
        sourceSize.width: 64
        sourceSize.height: 64
        asynchronous: true
        retainWhileLoading: true
        fillMode: root.cropImage ? Image.PreserveAspectCrop : Image.PreserveAspectFit
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
