import QtQuick
import "CortetsuDesign.js" as CortetsuDesign

Row {
    id: root

    required property int workspaceCount
    required property int workspaceOffset
    required property int activeWsId
    required property var occupiedWorkspaceIds

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
            readonly property bool occupied: root.occupiedWorkspaceIds.includes(wsId)

            width: active ? 18 : 8
            height: 28
            focus: true
            activeFocusOnTab: true

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
                border.width: workspaceDot.activeFocus ? 1 : 0
                border.color: CortetsuDesign.colorWashi

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

            Keys.onEnterPressed: root.workspaceRequested(workspaceDot.wsId)
            Keys.onReturnPressed: root.workspaceRequested(workspaceDot.wsId)
            Keys.onSpacePressed: root.workspaceRequested(workspaceDot.wsId)
            Keys.onLeftPressed: root.workspaceRequested(Math.max(root.workspaceOffset + 1, workspaceDot.wsId - 1))
            Keys.onRightPressed: root.workspaceRequested(Math.min(root.workspaceOffset + root.workspaceCount, workspaceDot.wsId + 1))
        }
    }

    Item {
        width: 7
        height: 1
    }
}
