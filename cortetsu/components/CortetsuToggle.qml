import QtQuick
import "../modules/CortetsuDesign.js" as CortetsuDesign

Item {
    id: root

    focus: !disabled
    activeFocusOnTab: !disabled

    property bool checked: false
    property bool disabled: false
    signal toggled(bool checked)

    implicitWidth: 46
    implicitHeight: 26

    CortetsuSurface {
        anchors.fill: parent
        radiusValue: CortetsuDesign.radiusPill
        active: root.checked
        baseColor: root.checked ? CortetsuDesign.colorPrimary : CortetsuDesign.colorSurfaceGlass
        hoverColor: CortetsuDesign.colorSurfaceGlassStrong
        outlined: true
        focused: root.activeFocus
        hovered: mouse.containsMouse
        pressed: mouse.pressed
    }

    Rectangle {
        id: thumb
        width: 18
        height: width
        radius: width / 2
        x: root.checked ? parent.width - width - 4 : 4
        anchors.verticalCenter: parent.verticalCenter
        color: root.checked ? CortetsuDesign.colorOnPrimary : CortetsuDesign.colorOnSurfaceMuted
        Behavior on x { NumberAnimation { duration: CortetsuDesign.motionFastMs; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: !root.disabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }

    Keys.onEnterPressed: root.toggled(!root.checked)
    Keys.onReturnPressed: root.toggled(!root.checked)
    Keys.onSpacePressed: root.toggled(!root.checked)
}
