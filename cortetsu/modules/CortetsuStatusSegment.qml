import QtQuick
import "CortetsuDesign.js" as CortetsuDesign
import "CortetsuTypography.js" as CortetsuTypography

Item {
    id: root

    required property string volumeIcon
    required property bool volumeMuted
    required property string networkIcon
    required property bool networkActive
    required property string bluetoothIcon
    required property bool bluetoothActive
    required property string batteryIcon
    required property bool batteryCritical
    required property string batteryTooltip
    required property int notificationCount
    required property bool sidebarActive
    required property bool recordingActive
    required property bool dndActive
    required property bool idleInhibited
    required property date now
    required property bool sessionActive

    signal attachedControlRequested(string mode, real centerX)
    signal detachedControlRequested(string mode)
    signal volumeMuteRequested()
    signal volumeWheel(real delta)
    signal notificationsRequested()
    signal stopRecordingRequested()
    signal toggleDndRequested()
    signal toggleIdleInhibitorRequested()
    signal calendarRequested()
    signal sessionRequested()

    function centerFor(item): real {
        return item.x + item.width / 2;
    }

    implicitWidth: statusRow.implicitWidth + CortetsuDesign.spacingCompact
    implicitHeight: 52
    width: implicitWidth
    height: implicitHeight

    CortetsuSurface {
        anchors.fill: parent
        radiusValue: CortetsuDesign.radiusLarge
        baseColor: CortetsuDesign.colorTetsu
        outlined: true
    }

    Row {
        id: statusRow
        anchors.centerIn: parent
        spacing: 2

        HubButton {
            id: volumeButton
            buttonSize: 40
            iconSize: CortetsuTypography.iconMediumPx
            icon: root.volumeIcon
            tooltip: root.volumeMuted ? qsTr("Unmute") : qsTr("Mute")
            onHoveredChanged: {
                if (hovered)
                    root.attachedControlRequested("audio", root.centerFor(volumeButton));
            }
            onClicked: root.volumeMuteRequested()
            onWheel: delta => root.volumeWheel(delta)
        }

        HubButton {
            id: networkButton
            buttonSize: 40
            iconSize: CortetsuTypography.iconMediumPx
            icon: root.networkIcon
            active: root.networkActive
            tooltip: qsTr("Network")
            onHoveredChanged: {
                if (hovered)
                    root.attachedControlRequested("network", root.centerFor(networkButton));
            }
            onClicked: root.detachedControlRequested("network")
        }

        HubButton {
            id: bluetoothButton
            buttonSize: 40
            iconSize: CortetsuTypography.iconMediumPx
            icon: root.bluetoothIcon
            active: root.bluetoothActive
            tooltip: qsTr("Bluetooth")
            onHoveredChanged: {
                if (hovered)
                    root.attachedControlRequested("bluetooth", root.centerFor(bluetoothButton));
            }
            onClicked: root.detachedControlRequested("bluetooth")
        }

        HubButton {
            id: batteryButton
            buttonSize: 40
            iconSize: CortetsuTypography.iconMediumPx
            icon: root.batteryIcon
            iconColor: root.batteryCritical
                ? CortetsuDesign.colorVermillion
                : CortetsuDesign.colorMuted
            tooltip: root.batteryTooltip
            onHoveredChanged: {
                if (hovered)
                    root.attachedControlRequested("battery", root.centerFor(batteryButton));
            }
            onClicked: root.attachedControlRequested("battery", root.centerFor(batteryButton))
        }

        Item {
            implicitWidth: 44
            implicitHeight: 44
            width: implicitWidth
            height: implicitHeight

            HubButton {
                anchors.fill: parent
                buttonSize: 44
                iconSize: CortetsuTypography.iconMediumPx
                icon: "notifications"
                active: root.sidebarActive
                tooltip: qsTr("Notifications")
                onClicked: root.notificationsRequested()
            }

            Rectangle {
                visible: root.notificationCount > 0
                anchors.top: parent.top
                anchors.right: parent.right
                width: 18
                height: 18
                radius: 9
                color: CortetsuDesign.colorIndigo

                CortetsuText {
                    anchors.centerIn: parent
                    text: Math.min(root.notificationCount, 9)
                    color: CortetsuDesign.colorWashi
                    textSize: CortetsuTypography.labelSmallPx
                }
            }
        }

        StatusPill {
            recordingActive: root.recordingActive
            dndActive: root.dndActive
            idleInhibited: root.idleInhibited
            onStopRecordingRequested: root.stopRecordingRequested()
            onToggleDndRequested: root.toggleDndRequested()
            onToggleIdleInhibitorRequested: root.toggleIdleInhibitorRequested()
        }

        Item {
            implicitWidth: 74
            implicitHeight: 44
            width: implicitWidth
            height: implicitHeight

            Column {
                anchors.centerIn: parent
                spacing: -2

                CortetsuText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(root.now, "HH:mm")
                    color: CortetsuDesign.colorWashi
                    textSize: CortetsuTypography.labelLargePx
                }

                CortetsuText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(root.now, "ddd d")
                    color: CortetsuDesign.colorMuted
                    textSize: CortetsuTypography.labelSmallPx
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.calendarRequested()
            }
        }

        HubButton {
            buttonSize: 44
            iconSize: CortetsuTypography.iconMediumPx
            icon: "power_settings_new"
            active: root.sessionActive
            tooltip: qsTr("Session")
            activeColor: CortetsuDesign.colorVermillion
            iconColor: active ? CortetsuDesign.colorWashi : CortetsuDesign.colorMuted
            onClicked: root.sessionRequested()
        }
    }
}
