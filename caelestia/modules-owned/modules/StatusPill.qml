pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property bool recordingActive: false
    property bool dndActive: false
    property bool idleInhibited: false

    readonly property bool hasStatus: recordingActive || dndActive || idleInhibited
    readonly property int visibleItemCount:
        Number(recordingActive) + Number(dndActive) + Number(idleInhibited)

    signal stopRecordingRequested()
    signal toggleDndRequested()
    signal toggleIdleInhibitorRequested()

    width: hasStatus ? pill.implicitWidth : 0
    implicitWidth: width
    implicitHeight: 44
    height: implicitHeight
    visible: hasStatus || width > 0
    opacity: hasStatus ? 1 : 0
    scale: hasStatus ? 1 : 0.96
    transformOrigin: Item.Center
    clip: true

    Behavior on width {
        NumberAnimation {
            duration: Tokens.anim.durations.expressiveFastSpatial
            easing: Tokens.anim.expressiveFastSpatial
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Tokens.anim.durations.expressiveFastEffects
            easing: Tokens.anim.expressiveFastEffects
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Tokens.anim.durations.expressiveFastSpatial
            easing: Tokens.anim.expressiveFastSpatial
        }
    }

    StyledRect {
        id: pill

        anchors.centerIn: parent
        implicitWidth: statusRow.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: 36
        radius: Tokens.rounding.extraLarge
        color: Colours.palette.m3surfaceContainerHighest
        border.width: 1
        border.color: Colours.palette.m3outlineVariant

        Row {
            id: statusRow

            anchors.centerIn: parent
            spacing: Tokens.spacing.extraSmall

            StatusPillItem {
                visible: root.recordingActive
                icon: "fiber_manual_record"
                label: qsTr("REC")
                tooltip: qsTr("Screen recording active")
                iconColor: Colours.palette.m3error
                textColor: Colours.palette.m3error
                pulse: true
                onClicked: root.stopRecordingRequested()
            }

            StatusPillDivider {
                visible: root.recordingActive && (root.dndActive || root.idleInhibited)
            }

            StatusPillItem {
                visible: root.dndActive
                icon: "do_not_disturb_on"
                label: qsTr("DND")
                tooltip: qsTr("Do Not Disturb enabled")
                iconColor: Colours.palette.m3secondary
                textColor: Colours.palette.m3onSurface
                onClicked: root.toggleDndRequested()
            }

            StatusPillDivider {
                visible: root.dndActive && root.idleInhibited
            }

            StatusPillItem {
                visible: root.idleInhibited
                icon: "coffee"
                label: qsTr("Awake")
                tooltip: qsTr("Idle inhibition active")
                iconColor: Colours.palette.m3tertiary
                textColor: Colours.palette.m3onSurface
                onClicked: root.toggleIdleInhibitorRequested()
            }
        }
    }

    component StatusPillDivider: Rectangle {
        width: 1
        height: 18
        anchors.verticalCenter: parent.verticalCenter
        color: Colours.palette.m3outlineVariant
        opacity: 0.7
    }

    component StatusPillItem: Item {
        id: item

        property string icon: ""
        property string label: ""
        property string tooltip: ""
        property color iconColor: Colours.palette.m3onSurface
        property color textColor: Colours.palette.m3onSurface
        property bool pulse: false

        signal clicked()

        implicitWidth: content.implicitWidth
        implicitHeight: 28

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.large
            color: mouse.containsMouse
                ? Colours.palette.m3surfaceContainerHigh
                : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: Tokens.anim.durations.expressiveFastEffects
                    easing: Tokens.anim.expressiveFastEffects
                }
            }
        }

        Row {
            id: content

            anchors.centerIn: parent
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                id: icon

                anchors.verticalCenter: parent.verticalCenter
                text: item.icon
                color: item.iconColor
                fontStyle: Tokens.font.icon.small
                scale: item.pulse && root.recordingActive ? 1 : 0.9

                SequentialAnimation on scale {
                    running: item.pulse && root.recordingActive
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: 1.12
                        duration: Tokens.anim.durations.expressiveSlowEffects
                        easing: Tokens.anim.expressiveSlowEffects
                    }
                    NumberAnimation {
                        to: 0.9
                        duration: Tokens.anim.durations.expressiveSlowEffects
                        easing: Tokens.anim.expressiveSlowEffects
                    }
                }
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: item.label
                color: item.textColor
                font: Tokens.font.label.small
            }
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: item.clicked()

            ToolTip.visible: containsMouse
            ToolTip.text: item.tooltip
        }
    }
}
