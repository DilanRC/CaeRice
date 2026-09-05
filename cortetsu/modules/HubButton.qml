import QtQuick
import QtQuick.Controls
import "CortetsuDesign.js" as CortetsuDesign
import "CortetsuTypography.js" as CortetsuTypography

Item {
    id: root

    property string icon: "circle"
    property string imageSource: ""
    property bool cropImage: false
    property bool active: false
    property string tooltip: ""
    property int buttonSize: 48
    property int iconSize: CortetsuTypography.iconMediumPx
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
    width: implicitWidth
    height: implicitHeight
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

    CortetsuIcon {
        anchors.centerIn: parent
        visible: root.imageSource.length === 0
        text: root.icon
        color: root.iconColor
        iconSize: root.iconSize

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

    ToolTip {
        id: tooltipPopup

        parent: root
        visible: root.tooltip.length > 0 && root.hovered
        delay: CortetsuDesign.motionDeliberateMs
        text: root.tooltip

        background: CortetsuSurface {
            radiusValue: CortetsuDesign.radiusSmall
            baseColor: CortetsuDesign.colorTetsu
            outlined: true
        }

        contentItem: CortetsuText {
            text: tooltipPopup.text
            textSize: CortetsuTypography.labelSmallPx
            color: CortetsuDesign.colorWashi
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
