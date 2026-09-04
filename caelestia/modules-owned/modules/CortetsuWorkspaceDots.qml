import QtQuick
import "CortetsuDesign.js" as CortetsuDesign

Row {
    id: root

    required property int workspaceCount
    required property int workspaceOffset
    required property int activeWsId
    required property var workspaceOccupancy

    signal workspaceRequested(int workspaceId)

    spacing: 5

    Item {
        width: 3
        height: 1
    }

    Repeater {
        model: root.workspaceCount

        Item {
            id: workspaceDot

            required property int index

            readonly property int wsId: root.workspaceOffset + index + 1
            readonly property bool active: wsId === root.activeWsId
            readonly property bool occupied: root.workspaceOccupancy[wsId] ?? false

            width: active ? 18 : 8
            height: 28

            Behavior on width {
                NumberAnimation {
                    duration: CortetsuDesign.motionStandardMs
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: workspaceDot.active ? 18 : 8
                height: 8
                radius: height / 2
                color: workspaceDot.active
                    ? CortetsuDesign.colorIndigo
                    : workspaceDot.occupied
                        ? CortetsuDesign.colorMuted
                        : Qt.darker(CortetsuDesign.colorMuted, 1.35)

                Behavior on width {
                    NumberAnimation {
                        duration: CortetsuDesign.motionStandardMs
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.workspaceRequested(workspaceDot.wsId)
            }
        }
    }

    Item {
        width: 7
        height: 1
    }
}
