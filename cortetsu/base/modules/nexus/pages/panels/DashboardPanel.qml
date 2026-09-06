pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Dashboard")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // General
        SectionHeader {
            first: true
            text: qsTr("General")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            checked: CortetsuConfig.dashboard.enabled
            onToggled: CortetsuConfig.dashboard.enabled = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Show on hover")
            subtext: qsTr("Reveal when the cursor reaches the screen edge")
            checked: CortetsuConfig.dashboard.showOnHover
            onToggled: CortetsuConfig.dashboard.showOnHover = checked
        }

        // Tabs
        SectionHeader {
            text: qsTr("Tabs")
        }

        ToggleRow {
            first: true
            text: qsTr("Dashboard")
            checked: CortetsuConfig.dashboard.showDashboard
            onToggled: CortetsuConfig.dashboard.showDashboard = checked
        }

        ToggleRow {
            text: qsTr("Media")
            checked: CortetsuConfig.dashboard.showMedia
            onToggled: CortetsuConfig.dashboard.showMedia = checked
        }

        ToggleRow {
            text: qsTr("Performance")
            checked: CortetsuConfig.dashboard.showPerformance
            onToggled: CortetsuConfig.dashboard.showPerformance = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Weather")
            checked: CortetsuConfig.dashboard.showWeather
            onToggled: CortetsuConfig.dashboard.showWeather = checked
        }

        // Performance widgets
        SectionHeader {
            text: qsTr("Performance widgets")
        }

        ToggleRow {
            first: true
            text: qsTr("Battery")
            checked: CortetsuConfig.dashboard.performance.showBattery
            onToggled: CortetsuConfig.dashboard.performance.showBattery = checked
        }

        ToggleRow {
            text: qsTr("GPU")
            checked: CortetsuConfig.dashboard.performance.showGpu
            onToggled: CortetsuConfig.dashboard.performance.showGpu = checked
        }

        ToggleRow {
            text: qsTr("CPU")
            checked: CortetsuConfig.dashboard.performance.showCpu
            onToggled: CortetsuConfig.dashboard.performance.showCpu = checked
        }

        ToggleRow {
            text: qsTr("Memory")
            checked: CortetsuConfig.dashboard.performance.showMemory
            onToggled: CortetsuConfig.dashboard.performance.showMemory = checked
        }

        ToggleRow {
            text: qsTr("Storage")
            checked: CortetsuConfig.dashboard.performance.showStorage
            onToggled: CortetsuConfig.dashboard.performance.showStorage = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Network")
            checked: CortetsuConfig.dashboard.performance.showNetwork
            onToggled: CortetsuConfig.dashboard.performance.showNetwork = checked
        }

        // Behaviour
        SectionHeader {
            text: qsTr("Behaviour")
        }

        StepperRow {
            first: true
            last: true
            label: qsTr("Drag threshold")
            subtext: qsTr("Pixels dragged before the dashboard opens")
            value: CortetsuConfig.dashboard.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => CortetsuConfig.dashboard.dragThreshold = v
        }
    }
}
