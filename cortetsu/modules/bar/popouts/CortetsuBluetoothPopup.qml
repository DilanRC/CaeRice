pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../../../services"
import "../../../components"
import "../../CortetsuDesign.js" as CortetsuDesign
import "../.."

CortetsuPopupSurface {
    id: root
    required property var popouts
    implicitWidth: 324
    implicitHeight: body.implicitHeight + CortetsuDesign.spacingComfortable * 2

    readonly property var devices: [...Bluetooth.devices.values].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))

    ColumnLayout {
        id: body
        anchors.fill: parent
        anchors.margins: CortetsuDesign.spacingComfortable
        spacing: CortetsuDesign.spacingCompact

        RowLayout {
            Layout.fillWidth: true
            CortetsuSectionHeader { title: qsTr("Bluetooth"); detail: Bluetooth.defaultAdapter?.enabled ? qsTr("Ready") : qsTr("Off") }
            Item { Layout.fillWidth: true }
            CortetsuToggle {
                checked: Bluetooth.defaultAdapter?.enabled ?? false
                onToggled: checked => { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = checked; }
            }
        }

        CortetsuStateMessage {
            Layout.fillWidth: true
            visible: root.devices.length === 0
            kind: Bluetooth.defaultAdapter?.enabled ? "empty" : "error"
            title: Bluetooth.defaultAdapter?.enabled ? qsTr("No devices nearby") : qsTr("Bluetooth unavailable")
            detail: Bluetooth.defaultAdapter?.enabled ? "" : qsTr("Enable Bluetooth to scan for devices")
        }

        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 5 * CortetsuDesign.rowHeight)
            visible: root.devices.length > 0
            clip: true
            spacing: CortetsuDesign.spacingUnit
            model: root.devices
            delegate: CortetsuListRow {
                required property BluetoothDevice modelData
                width: ListView.view.width
                icon: modelData.connected ? "bluetooth_connected" : "bluetooth"
                title: modelData.name ?? qsTr("Unknown device")
                subtitle: modelData.connected ? qsTr("Connected") : modelData.paired ? qsTr("Paired") : qsTr("Available")
                selected: modelData.connected
                onClicked: if (modelData.connected) modelData.disconnect(); else modelData.connect()
            }
        }
    }
}
