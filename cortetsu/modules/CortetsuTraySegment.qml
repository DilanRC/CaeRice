pragma ComponentBehavior: Bound

import QtQuick
import "CortetsuDesign.js" as CortetsuDesign

Item {
    id: root

    required property var items

    signal hoverRequested(string itemId, real centerX)
    signal activateRequested(string itemId)
    signal secondaryRequested(string itemId)

    implicitWidth: trayRow.implicitWidth + CortetsuDesign.spacingStandard
    implicitHeight: 52
    width: visible ? implicitWidth : 0
    height: implicitHeight
    visible: items.length > 0

    CortetsuSurface {
        anchors.fill: parent
        radiusValue: CortetsuDesign.radiusLarge
        baseColor: CortetsuDesign.colorTetsu
        outlined: true
    }

    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.items

            Item {
                id: trayItem
                required property var modelData

                implicitWidth: 34
                implicitHeight: 40
                width: implicitWidth
                height: implicitHeight

                CortetsuSurface {
                    anchors.fill: parent
                    anchors.margins: 2
                    radiusValue: CortetsuDesign.radiusSmall
                    baseColor: "transparent"
                    hoverColor: Qt.lighter(CortetsuDesign.colorTetsu, 1.18)
                    hovered: trayMouse.containsMouse
                    pressed: trayMouse.pressed
                    outlined: false
                }

                Image {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    source: trayItem.modelData.iconSource
                    sourceSize.width: 48
                    sourceSize.height: 48
                    asynchronous: false
                    retainWhileLoading: true
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.hoverRequested(
                        trayItem.modelData.id,
                        trayItem.x + trayItem.width / 2
                    )
                    onClicked: event => {
                        if (event.button === Qt.LeftButton)
                            root.activateRequested(trayItem.modelData.id);
                        else
                            root.secondaryRequested(trayItem.modelData.id);
                    }
                }
            }
        }
    }
}
