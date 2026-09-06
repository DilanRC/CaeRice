import QtQuick
import QtQuick.Layouts
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

    CortetsuPopupSurface {
        id: panel
        anchors.fill: parent

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: CortetsuDesign.spacingStandard
            spacing: CortetsuDesign.spacingStandard

            CortetsuSectionHeader {
                Layout.fillWidth: true
                title: qsTr("Quick settings")
                detail: qsTr("Cortetsu controls")
            }

            CortetsuText {
                Layout.fillWidth: true
                text: CortetsuRecorder.running
                    ? qsTr("Recording active · keep-awake %1").arg(CortetsuIdleInhibitor.enabled ? qsTr("on") : qsTr("off"))
                    : qsTr("Ready · keep-awake %1").arg(CortetsuIdleInhibitor.enabled ? qsTr("on") : qsTr("off"))
                textSize: CortetsuTypography.labelSmallPx
                color: CortetsuDesign.colorOnSurfaceVariant
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: CortetsuDesign.spacingCompact

                CortetsuButton {
                    Layout.fillWidth: true
                    label: CortetsuIdleInhibitor.enabled ? qsTr("Keep-awake") : qsTr("Allow idle")
                    icon: CortetsuIdleInhibitor.enabled ? "bedtime_off" : "bedtime"
                    active: CortetsuIdleInhibitor.enabled
                    onClicked: CortetsuIdleInhibitor.enabled = !CortetsuIdleInhibitor.enabled
                }

                CortetsuButton {
                    Layout.fillWidth: true
                    label: CortetsuRecorder.running ? qsTr("Recording") : qsTr("Record screen")
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
            }

            CortetsuButton {
                Layout.fillWidth: true
                label: qsTr("Notification controls")
                icon: "notifications"
                onClicked: root.screenState.sidebar = true
            }
        }
    }
}
