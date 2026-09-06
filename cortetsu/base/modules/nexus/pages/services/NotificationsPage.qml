import QtQuick
import QtQuick.Layouts
import qs.components.controls
import qs.modules
import qs.modules.nexus.common

PageBase {
    id: root

    // Notification fullscreen visibility, ordered to match config::NotifsFullscreen (On, Off)
    readonly property list<MenuItem> notifFullscreenItems: [
        MenuItem {
            text: qsTr("On")
            icon: "notifications"
        },
        MenuItem {
            text: qsTr("Off")
            icon: "notifications_off"
        }
    ]

    // Toast fullscreen visibility, mapped to CortetsuConfig.toastFullscreen
    readonly property list<MenuItem> toastFullscreenItems: [
        MenuItem {
            text: qsTr("Off")
            icon: "notifications_off"
        },
        MenuItem {
            text: qsTr("Important")
            icon: "priority_high"
        },
        MenuItem {
            text: qsTr("On")
            icon: "notifications"
        }
    ]
    readonly property list<string> toastFullscreenValues: ["off", "important", "all"]

    title: qsTr("Notifications")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Notifications
        SectionHeader {
            first: true
            text: qsTr("Notifications")
        }

        SelectRow {
            first: true
            label: qsTr("Show in fullscreen")
            subtext: qsTr("Whether notifications appear over fullscreen apps")
            menuItems: root.notifFullscreenItems
            active: root.notifFullscreenItems[CortetsuConfig.notificationFullscreenMode]
            onSelected: item => CortetsuConfig.notificationFullscreenMode = root.notifFullscreenItems.indexOf(item)
        }

        ToggleRow {
            text: qsTr("Expire automatically")
            subtext: qsTr("Dismiss notifications after their timeout")
            checked: CortetsuConfig.notificationExpire
            onToggled: CortetsuConfig.notificationExpire = checked
        }

        ToggleRow {
            text: qsTr("Open expanded")
            subtext: qsTr("Show notifications expanded by default")
            checked: CortetsuConfig.notificationOpenExpanded
            onToggled: CortetsuConfig.notificationOpenExpanded = checked
        }

        StepperRow {
            label: qsTr("Default timeout")
            subtext: qsTr("Time before a notification dismisses (ms)")
            value: CortetsuConfig.notificationDefaultExpireTimeout
            from: 1000
            to: 60000
            stepSize: 500
            onMoved: v => CortetsuConfig.notificationDefaultExpireTimeout = Math.round(v)
        }

        StepperRow {
            last: true
            label: qsTr("Group preview count")
            subtext: qsTr("Notifications shown per group before collapsing")
            value: CortetsuConfig.notificationGroupPreviewNum
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => CortetsuConfig.notificationGroupPreviewNum = Math.round(v)
        }

        // Toasts
        SectionHeader {
            text: qsTr("Toasts")
        }

        SelectRow {
            first: true
            label: qsTr("Show in fullscreen")
            subtext: qsTr("Whether toasts appear over fullscreen apps")
            menuItems: root.toastFullscreenItems
            active: root.toastFullscreenItems[Math.max(0, root.toastFullscreenValues.indexOf(CortetsuConfig.toastFullscreen))]
            onSelected: item => CortetsuConfig.toastFullscreen = root.toastFullscreenValues[root.toastFullscreenItems.indexOf(item)]
        }

        StepperRow {
            last: true
            label: qsTr("Visible toasts")
            subtext: qsTr("Maximum number of toasts shown at once")
            value: CortetsuConfig.maxToasts
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => CortetsuConfig.maxToasts = Math.round(v)
        }

        // Toast events
        SectionHeader {
            text: qsTr("Toast events")
        }

        ToggleRow {
            first: true
            text: qsTr("Charging changes")
            checked: CortetsuConfig.toastChargingChanged
            onToggled: CortetsuConfig.toastChargingChanged = checked
        }

        ToggleRow {
            text: qsTr("Game mode changes")
            checked: CortetsuConfig.toastGameModeChanged
            onToggled: CortetsuConfig.toastGameModeChanged = checked
        }

        ToggleRow {
            text: qsTr("Do not disturb changes")
            checked: CortetsuConfig.toastDndChanged
            onToggled: CortetsuConfig.toastDndChanged = checked
        }

        ToggleRow {
            text: qsTr("Audio output changes")
            checked: CortetsuConfig.toastAudioOutputChanged
            onToggled: CortetsuConfig.toastAudioOutputChanged = checked
        }

        ToggleRow {
            text: qsTr("Audio input changes")
            checked: CortetsuConfig.toastAudioInputChanged
            onToggled: CortetsuConfig.toastAudioInputChanged = checked
        }

        ToggleRow {
            text: qsTr("Caps lock changes")
            checked: CortetsuConfig.toastCapsLockChanged
            onToggled: CortetsuConfig.toastCapsLockChanged = checked
        }

        ToggleRow {
            text: qsTr("Num lock changes")
            checked: CortetsuConfig.toastNumLockChanged
            onToggled: CortetsuConfig.toastNumLockChanged = checked
        }

        ToggleRow {
            text: qsTr("Keyboard layout changes")
            checked: CortetsuConfig.toastKbLayoutChanged
            onToggled: CortetsuConfig.toastKbLayoutChanged = checked
        }

        ToggleRow {
            text: qsTr("VPN changes")
            checked: CortetsuConfig.toastVpnChanged
            onToggled: CortetsuConfig.toastVpnChanged = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Now playing")
            checked: CortetsuConfig.toastNowPlaying
            onToggled: CortetsuConfig.toastNowPlaying = checked
        }
    }
}
