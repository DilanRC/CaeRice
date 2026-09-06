import QtQuick
import "../modules/CortetsuDesign.js" as CortetsuDesign

Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property bool disabled: false
    signal moved(real value)

    implicitHeight: 28

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: 3
        color: CortetsuDesign.colorSurfaceGlassStrong

        Rectangle {
            width: track.width * root.progress
            height: parent.height
            radius: parent.radius
            color: CortetsuDesign.colorPrimary
        }
    }

    Rectangle {
        id: handle
        width: 18
        height: width
        radius: width / 2
        x: Math.max(0, Math.min(root.width - width, root.progress * (root.width - width)))
        anchors.verticalCenter: parent.verticalCenter
        color: mouse.containsMouse || mouse.pressed ? CortetsuDesign.colorWashi : CortetsuDesign.colorPrimary
        border.width: 1
        border.color: CortetsuDesign.colorOutline
        Behavior on x { NumberAnimation { duration: CortetsuDesign.motionFastMs; easing.type: Easing.OutCubic } }
    }

    readonly property real progress: root.to === root.from ? 0 : Math.max(0, Math.min(1, (root.value - root.from) / (root.to - root.from)))

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: !root.disabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: event => root.setFromPosition(event.x)
        onPositionChanged: event => { if (pressed) root.setFromPosition(event.x); }
    }

    function setFromPosition(position: real): void {
        const next = root.from + Math.max(0, Math.min(1, position / root.width)) * (root.to - root.from);
        root.value = next;
        root.moved(next);
    }
}
