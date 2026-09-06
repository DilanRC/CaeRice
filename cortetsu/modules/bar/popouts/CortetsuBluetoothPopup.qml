pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../../../services"
import "../../../components"
import "../../CortetsuDesign.js" as CortetsuDesign
import "../.."

CortetsuSurface {
    id: root
    required property var popouts
    implicitWidth: 324
    implicitHeight: body.implicitHeight + CortetsuDesign.spacingComfortable * 2
    radiusValue: CortetsuDesign.radiusLarge
    baseColor: CortetsuDesign.colorSurfaceGlass
    outlined: true

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

        CortetsuText {
            Layout.fillWidth: true
            visible: root.devices.length === 0
            text: qsTr("No devices nearby")
            textSize: CortetsuDesign.bodySmallPx
            color: CortetsuDesign.colorOnSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
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
