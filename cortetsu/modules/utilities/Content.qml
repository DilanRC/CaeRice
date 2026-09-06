import QtQuick
import Quickshell
import ".."
import "../../components"
import "../CortetsuDesign.js" as CortetsuDesign
import "../CortetsuTypography.js" as CortetsuTypography
import "../../services"

Item {
    id: root
    required property var props
    required property var screenState
    required property var popouts
    readonly property real nonAnimHeight: column.implicitHeight + CortetsuDesign.spacingStandard * 2
    implicitWidth: 480
    implicitHeight: column.implicitHeight + CortetsuDesign.spacingStandard * 2

    CortetsuSurface {
        id: panel
        anchors.fill: parent
        radiusValue: CortetsuDesign.radiusLarge
        baseColor: CortetsuDesign.colorSurfaceGlass
        outlined: true

        Column {
            id: column
            anchors.fill: parent
            anchors.margins: CortetsuDesign.spacingStandard
            spacing: CortetsuDesign.spacingStandard

            CortetsuSectionHeader {
                title: qsTr("Quick settings")
                detail: qsTr("Cortetsu controls")
            }

            CortetsuText {
                width: parent.width
                text: CortetsuRecorder.running
                    ? qsTr("Recording active · keep-awake %1").arg(CortetsuIdleInhibitor.enabled ? qsTr("on") : qsTr("off"))
                    : qsTr("Ready · keep-awake %1").arg(CortetsuIdleInhibitor.enabled ? qsTr("on") : qsTr("off"))
                textSize: CortetsuTypography.labelSmallPx
                color: CortetsuDesign.colorOnSurfaceVariant
                elide: Text.ElideRight
            }

            CortetsuButton {
                width: parent.width
                label: CortetsuIdleInhibitor.enabled ? qsTr("Keep-awake enabled") : qsTr("Keep-awake disabled")
                icon: CortetsuIdleInhibitor.enabled ? "bedtime_off" : "bedtime"
                active: CortetsuIdleInhibitor.enabled
                onClicked: CortetsuIdleInhibitor.enabled = !CortetsuIdleInhibitor.enabled
            }

            CortetsuButton {
                width: parent.width
                label: CortetsuRecorder.running ? qsTr("Stop recording") : qsTr("Start recording")
                icon: CortetsuRecorder.running ? "stop_circle" : "radio_button_checked"
                active: CortetsuRecorder.running
                danger: CortetsuRecorder.running
                onClicked: {
                    if (CortetsuRecorder.running)
                        CortetsuRecorder.stop();
                    else
                        Quickshell.execDetached(["cortetsu-record", "start"]);
                }
            }

            CortetsuButton {
                width: parent.width
                label: qsTr("Open notification controls")
                icon: "notifications"
                onClicked: root.screenState.sidebar = true
            }
        }
    }
}
