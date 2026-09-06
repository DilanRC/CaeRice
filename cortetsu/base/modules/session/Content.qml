import QtQuick
import QtQuick.Layouts
import Quickshell
import "../CortetsuDesign.js" as CortetsuDesign
import "../CortetsuTypography.js" as CortetsuTypography

Column {
    id: root
    required property var screenState
    padding: CortetsuDesign.spacingStandard
    spacing: CortetsuDesign.spacingCompact

    function run(command: list<string>): void {
        Quickshell.execDetached(command);
        root.screenState.session = false;
    }

    Repeater {
        model: [
            { label: qsTr("Log out"), icon: "logout", command: ["hyprctl", "dispatch", "exit"] },
            { label: qsTr("Shutdown"), icon: "power_settings_new", command: ["systemctl", "poweroff"] },
            { label: qsTr("Hibernate"), icon: "bedtime", command: ["systemctl", "hibernate"] },
            { label: qsTr("Reboot"), icon: "restart_alt", command: ["systemctl", "reboot"] }
        ]
        delegate: Rectangle {
            required property var modelData
            implicitWidth: 220
            implicitHeight: 52
            radius: CortetsuDesign.radiusMedium
            color: hovered ? CortetsuDesign.colorSurfaceHigh : CortetsuDesign.colorSurface
            property bool hovered: false

            Row {
                anchors.fill: parent
                anchors.margins: CortetsuDesign.spacingStandard
                spacing: CortetsuDesign.spacingStandard
                Text {
                    text: modelData.icon
                    color: CortetsuDesign.colorPrimary
                    font.family: CortetsuTypography.iconFamily
                    font.pixelSize: CortetsuTypography.iconMediumPx
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.label
                    color: CortetsuDesign.colorWashi
                    font.family: CortetsuTypography.uiFamily
                    font.pixelSize: CortetsuTypography.bodyPx
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: parent.hovered = true
                onExited: parent.hovered = false
                onClicked: root.run(modelData.command)
            }
        }
    }
}
