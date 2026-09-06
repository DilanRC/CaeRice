pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../CortetsuSurface.qml"
import "../CortetsuText.qml"
import "../notifications" as CortetsuNotifications
import "../../services"

Item {
    id: root
    required property var screenState

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            CortetsuText {
                text: Notifs.notClosed.length > 0
                    ? qsTr("Notifications (%1)").arg(Notifs.notClosed.length)
                    : qsTr("Notifications")
                textSize: 14
                Layout.fillWidth: true
            }
            CortetsuSurface {
                implicitWidth: 72
                implicitHeight: 30
                outlined: false
                baseColor: "transparent"
                visible: Notifs.notClosed.length > 0
                CortetsuText { anchors.centerIn: parent; text: qsTr("Clear"); textSize: 11 }
                MouseArea { anchors.fill: parent; onClicked: Notifs.clear() }
            }
        }

        CortetsuSurface {
            Layout.fillWidth: true
            Layout.fillHeight: true
            outlined: false
            baseColor: "transparent"

            ListView {
                id: list
                anchors.fill: parent
                anchors.margins: 4
                spacing: 8
                clip: true
                model: Notifs.notClosed
                delegate: CortetsuNotifications.Notification {
                    width: list.width
                    props: ({})
                    expanded: false
                    screenState: root.screenState
                }

                CortetsText {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: qsTr("All up to date!")
                    textSize: 13
                }
            }
        }
    }
}
