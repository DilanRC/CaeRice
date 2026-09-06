pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../components"
import ".."
import "../../services"
import qs.modules.notifications as NotificationComponents
import "../CortetsuDesign.js" as CortetsuDesign

Item {
    id: root
    required property var screenState

    readonly property var active: Notifs.notClosed
    readonly property var history: CortetsuNotifications.history

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: CortetsuDesign.spacingComfortable
        spacing: CortetsuDesign.spacingStandard

        RowLayout {
            Layout.fillWidth: true
            CortetsuSectionHeader {
                title: qsTr("Notifications")
                detail: root.active.length > 0 ? qsTr("%1 active").arg(root.active.length) : qsTr("Quiet")
            }
            Item { Layout.fillWidth: true }
            CortetsuToggle {
                checked: CortetsuNotifications.dnd
                onToggled: checked => CortetsuNotifications.dnd = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            CortetsuText {
                text: CortetsuNotifications.dnd ? qsTr("Do not disturb") : qsTr("Notifications on")
                textSize: CortetsuDesign.labelSmallPx
                color: CortetsuNotifications.dnd ? CortetsuDesign.colorWarning : CortetsuDesign.colorOnSurfaceVariant
            }
            Item { Layout.fillWidth: true }
            CortetsuButton {
                visible: root.active.length > 0 || root.history.length > 0
                compact: true
                label: qsTr("Clear")
                icon: "delete_sweep"
                onClicked: { CortetsuNotifications.clear(); Notifs.clear(); }
            }
        }

        CortetsuSectionHeader {
            Layout.fillWidth: true
            title: qsTr("Now")
            detail: root.active.length === 0 ? qsTr("Nothing new") : ""
        }

        CortetsuSurface {
            Layout.fillWidth: true
            Layout.fillHeight: true
            baseColor: "transparent"
            outlined: false

            ListView {
                id: activeList
                anchors.fill: parent
                clip: true
                spacing: CortetsuDesign.spacingCompact
                model: root.active
                delegate: NotificationComponents.Notification {
                    width: activeList.width
                    props: ({})
                    expanded: false
                    screenState: root.screenState
                }

                CortetsuStateMessage {
                    anchors.centerIn: parent
                    visible: activeList.count === 0
                    title: qsTr("All clear")
                    detail: qsTr("New notifications will appear here")
                }
            }
        }

        CortetsuSectionHeader {
            Layout.fillWidth: true
            title: qsTr("History")
            detail: root.history.length > 0 ? qsTr("%1 saved").arg(root.history.length) : qsTr("Empty")
        }

        CortetsuSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(historyList.contentHeight, 3 * CortetsuDesign.rowHeight)
            baseColor: "transparent"
            outlined: false

            ListView {
                id: historyList
                anchors.fill: parent
                clip: true
                spacing: CortetsuDesign.spacingUnit
                model: root.history
                delegate: CortetsuListRow {
                    required property var modelData
                    width: historyList.width
                    icon: "history"
                    title: modelData.summary ?? qsTr("Notification")
                    subtitle: modelData.appName ?? modelData.body ?? qsTr("Saved notification")
                    onClicked: {}
                }

                CortetsuStateMessage {
                    anchors.centerIn: parent
                    visible: historyList.count === 0
                    title: qsTr("No saved notifications")
                }
            }
        }
    }
}
