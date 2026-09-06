import QtQuick
import Quickshell
import ".."
import "../../components"
import "../CortetsuDesign.js" as CortetsuDesign
import "../../services"

Item {
    id: root
    required property var props
    required property var screenState
    required property var popouts
    readonly property real nonAnimHeight: column.implicitHeight
    implicitWidth: 480
    implicitHeight: column.implicitHeight

    Column {
        id: column
        anchors.fill: parent
        spacing: CortetsuDesign.spacingStandard

        CortetsuSectionHeader {
            title: qsTr("Quick settings")
            detail: qsTr("Cortetsu controls")
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
