pragma ComponentBehavior: Bound

import QtQuick.Layouts
import qs.modules
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Workspaces")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: CortetsuTokens.spacing.extraSmall / 2

        StepperRow {
            first: true
            label: qsTr("Shown")
            subtext: qsTr("Number of workspaces displayed")
            value: CortetsuConfig.workspacesShown
            from: 1
            to: 20
            stepSize: 1
            onMoved: v => CortetsuConfig.workspacesShown = v
        }

        ToggleRow {
            text: qsTr("Active indicator")
            checked: CortetsuConfig.bar.workspaces.activeIndicator
            onToggled: CortetsuConfig.bar.workspaces.activeIndicator = checked
        }

        ToggleRow {
            text: qsTr("Active trail")
            checked: CortetsuConfig.bar.workspaces.activeTrail
            onToggled: CortetsuConfig.bar.workspaces.activeTrail = checked
        }

        ToggleRow {
            text: qsTr("Occupied background")
            checked: CortetsuConfig.bar.workspaces.occupiedBg
            onToggled: CortetsuConfig.bar.workspaces.occupiedBg = checked
        }

        ToggleRow {
            text: qsTr("Show windows")
            subtext: qsTr("Show icons of open windows on each workspace")
            checked: CortetsuConfig.bar.workspaces.showWindows
            onToggled: CortetsuConfig.bar.workspaces.showWindows = checked
        }

        ToggleRow {
            text: qsTr("Windows on special workspaces")
            checked: CortetsuConfig.bar.workspaces.showWindowsOnSpecialWorkspaces
            onToggled: CortetsuConfig.bar.workspaces.showWindowsOnSpecialWorkspaces = checked
        }

        StepperRow {
            label: qsTr("Max window icons")
            value: CortetsuConfig.bar.workspaces.maxWindowIcons
            from: 0
            to: 20
            stepSize: 1
            onMoved: v => CortetsuConfig.bar.workspaces.maxWindowIcons = v
        }

        ToggleRow {
            last: true
            text: qsTr("Per-monitor workspaces")
            subtext: qsTr("Show each monitor's workspaces independently")
            checked: CortetsuConfig.bar.workspaces.perMonitorWorkspaces
            onToggled: CortetsuConfig.bar.workspaces.perMonitorWorkspaces = checked
        }
    }
}
