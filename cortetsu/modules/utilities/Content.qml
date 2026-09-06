import QtQuick
import Quickshell
import ".."
import "../CortetsuDesign.js" as CortetsuDesign
import "../CortetsuTypography.js" as CortetsuTypography
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

        Rectangle {
            width: parent.width
            height: 58
            radius: CortetsuDesign.radiusMedium
            color: CortetsuIdleInhibitor.enabled ? CortetsuDesign.colorPrimaryContainer : CortetsuDesign.colorSurface
            Text {
                anchors.centerIn: parent
                text: CortetsuIdleInhibitor.enabled ? qsTr("Keep-awake enabled") : qsTr("Keep-awake disabled")
                color: CortetsuDesign.colorWashi
                font.family: CortetsuTypography.uiFamily
                font.pixelSize: CortetsuTypography.bodyPx
            }
            MouseArea { anchors.fill: parent; onClicked: CortetsuIdleInhibitor.enabled = !CortetsuIdleInhibitor.enabled }
        }

        Rectangle {
            width: parent.width
            height: 58
            radius: CortetsuDesign.radiusMedium
            color: CortetsuRecorder.running ? CortetsuDesign.colorVermillion : CortetsuDesign.colorSurface
            Text {
                anchors.centerIn: parent
                text: CortetsuRecorder.running ? qsTr("Stop recording") : qsTr("Start recording")
                color: CortetsuDesign.colorWashi
                font.family: CortetsuTypography.uiFamily
                font.pixelSize: CortetsuTypography.bodyPx
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (CortetsuRecorder.running)
                        CortetsuRecorder.stop();
                    else
                        Quickshell.execDetached(["cortetsu-record", "start"]);
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 58
            radius: CortetsuDesign.radiusMedium
            color: CortetsuDesign.colorSurface
            Text {
                anchors.centerIn: parent
                text: qsTr("Open notification controls")
                color: CortetsuDesign.colorWashi
                font.family: CortetsuTypography.uiFamily
                font.pixelSize: CortetsuTypography.bodyPx
            }
            MouseArea { anchors.fill: parent; onClicked: root.screenState.sidebar = true }
        }
    }
}
