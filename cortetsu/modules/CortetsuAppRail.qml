pragma ComponentBehavior: Bound

import QtQuick
import "CortetsuDesign.js" as CortetsuDesign

Item {
    id: root

    required property var items
    required property real maxWidth

    signal activateRequested(string key)
    signal togglePinnedRequested(string key)
    signal closeRequested(string key)
    signal cycleRequested(string key, int direction)

    implicitWidth: Math.min(appRailContent.implicitWidth + 14, maxWidth)
    implicitHeight: 52
    width: implicitWidth
    height: implicitHeight
    clip: true

    CortetsuSurface {
        anchors.fill: parent
        radiusValue: CortetsuDesign.radiusLarge
        baseColor: CortetsuDesign.colorTetsu
        outlined: true
    }

    Flickable {
        id: appRail
        anchors.fill: parent
        anchors.leftMargin: 7
        anchors.rightMargin: 7
        contentWidth: appRailContent.implicitWidth
        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentWidth > width
        clip: true

        Row {
            id: appRailContent
            height: parent.height
            spacing: CortetsuDesign.spacingUnit

            Repeater {
                model: root.items

                Item {
                    id: appItem
                    required property var modelData

                    implicitWidth: 46
                    implicitHeight: 52
                    width: implicitWidth
                    height: implicitHeight
                    scale: appMouse.containsMouse ? CortetsuDesign.hoverScale : 1

                    Behavior on scale {
                        NumberAnimation {
                            duration: CortetsuDesign.motionFastMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    CortetsuSurface {
                        anchors.fill: parent
                        anchors.topMargin: 2
                        anchors.bottomMargin: 2
                        radiusValue: CortetsuDesign.radiusMedium
                        baseColor: "transparent"
                        hoverColor: Qt.lighter(CortetsuDesign.colorTetsu, 1.16)
                        activeColor: CortetsuDesign.colorIndigo
                        hovered: appMouse.containsMouse
                        pressed: appMouse.pressed
                        active: appItem.modelData.active
                        outlined: appItem.modelData.active
                    }

                    Image {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 6
                        width: 32
                        height: 32
                        source: appItem.modelData.iconSource
                        sourceSize.width: 64
                        sourceSize.height: 64
                        asynchronous: false
                        retainWhileLoading: true
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        opacity: appItem.modelData.running ? 1 : 0.62
                    }

                    Rectangle {
                        visible: appItem.modelData.pinned && !appItem.modelData.running
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 6
                        anchors.rightMargin: 5
                        width: 7
                        height: 7
                        radius: 4
                        color: CortetsuDesign.colorMuted
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        spacing: 3
                        visible: appItem.modelData.running

                        Repeater {
                            model: Math.min(appItem.modelData.windowCount, 4)

                            Rectangle {
                                required property int index
                                width: appItem.modelData.active ? 12 : 5
                                height: 5
                                radius: 3
                                color: appItem.modelData.active
                                    ? CortetsuDesign.colorWashi
                                    : CortetsuDesign.colorMuted
                                opacity: index < 3 ? 1 : 0.55
                            }
                        }
                    }

                    MouseArea {
                        id: appMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor

                        onClicked: event => {
                            if (event.button === Qt.RightButton) {
                                root.togglePinnedRequested(appItem.modelData.key);
                                return;
                            }

                            if (event.button === Qt.MiddleButton) {
                                root.closeRequested(appItem.modelData.key);
                                return;
                            }

                            root.activateRequested(appItem.modelData.key);
                        }

                        onWheel: wheel => {
                            if (wheel.angleDelta.y > 0)
                                root.cycleRequested(appItem.modelData.key, -1);
                            else if (wheel.angleDelta.y < 0)
                                root.cycleRequested(appItem.modelData.key, 1);

                            wheel.accepted = true;
                        }
                    }
                }
            }
        }
    }
}
