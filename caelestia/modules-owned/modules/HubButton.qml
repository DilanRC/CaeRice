import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import "CortetsuDesign.js" as CortetsuDesign

Item {
    id: root

    property string icon: "circle"
    property string imageSource: ""
    property bool cropImage: false
    property bool active: false
    property string tooltip: ""
    property int buttonSize: 48
    property font iconFontStyle: Tokens.font.icon.extraLarge
    property color activeColor: CortetsuDesign.colorIndigo
    property color hoverColor: Qt.lighter(CortetsuDesign.colorTetsu, 1.18)
    property color iconColor: active || hovered
        ? CortetsuDesign.colorWashi
        : CortetsuDesign.colorMuted
    readonly property bool hovered: mouse.containsMouse
    readonly property bool pressed: mouse.pressed

    signal clicked()
    signal wheel(real delta)

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    scale: root.pressed
        ? 0.97
        : root.hovered
            ? CortetsuDesign.hoverScale
            : 1

    Behavior on scale {
        NumberAnimation {
            duration: CortetsuDesign.motionInstantMs
            easing.type: Easing.OutCubic
        }
    }

    CortetsuSurface {
        anchors.fill: parent
        anchors.margins: 2
        radiusValue: CortetsuDesign.radiusMedium
        baseColor: "transparent"
        hoverColor: root.hoverColor
        activeColor: root.activeColor
        hovered: root.hovered
        pressed: root.pressed
        active: root.active
        outlined: root.active
    }

    MaterialIcon {
        anchors.centerIn: parent
        visible: root.imageSource.length === 0
        text: root.icon
        color: root.iconColor
        fontStyle: root.iconFontStyle

        Behavior on color {
            ColorAnimation {
                duration: CortetsuDesign.motionFastMs
                easing.type: Easing.OutCubic
            }
        }
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
        opacity: root.hovered || root.active ? 1 : 0.88

        Behavior on opacity {
            NumberAnimation {
                duration: CortetsuDesign.motionFastMs
                easing.type: Easing.OutCubic
            }
        }
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
