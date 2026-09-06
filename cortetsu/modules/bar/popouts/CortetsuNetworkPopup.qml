pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.utils
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

    readonly property var device: CortetsuNetwork.wifiDevice
    readonly property var networks: (device?.networks?.values ?? []).slice().sort((a, b) => {
        if (a.connected !== b.connected) return b.connected - a.connected;
        return (b.signalStrength ?? 0) - (a.signalStrength ?? 0);
    })

    ColumnLayout {
        id: body
        anchors.fill: parent
        anchors.margins: CortetsuDesign.spacingComfortable
        spacing: CortetsuDesign.spacingCompact

        CortetsuSectionHeader {
            title: qsTr("Wi‑Fi")
            detail: CortetsuNetwork.connecting ? qsTr("Connecting") : root.device ? qsTr("%1 networks").arg(root.networks.length) : qsTr("Unavailable")
        }

        CortetsuListRow {
            Layout.fillWidth: true
            visible: CortetsuNetwork.active !== null
            icon: Icons.getNetworkIcon(CortetsuNetwork.active?.strength ?? 0)
            title: CortetsuNetwork.active?.ssid ?? qsTr("Not connected")
            subtitle: qsTr("Connected")
            selected: true
            onClicked: root.popouts.hasCurrent = false
        }

        CortetsuText {
            Layout.fillWidth: true
            visible: root.networks.length === 0
            text: CortetsuNetwork.connecting ? qsTr("Looking for a connection…") : qsTr("No networks available")
            textSize: CortetsuDesign.bodySmallPx
            color: CortetsuDesign.colorOnSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
        }

        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 5 * CortetsuDesign.rowHeight)
            visible: root.networks.length > 0
            clip: true
            spacing: CortetsuDesign.spacingUnit
            model: root.networks
            delegate: CortetsuListRow {
                required property var modelData
                width: ListView.view.width
                icon: Icons.getNetworkIcon(modelData.signalStrength ?? 0)
                title: modelData.name ?? qsTr("Hidden network")
                subtitle: modelData.security === WifiSecurityType.None ? qsTr("Open network") : qsTr("Secured network")
                selected: modelData.connected
                onClicked: {
                    if (modelData.connected) {
                        root.popouts.hasCurrent = false;
                    } else if (modelData.known || modelData.security === WifiSecurityType.None) {
                        modelData.connect();
                    } else {
                        CortetsuToaster.toast(qsTr("Wi‑Fi"), qsTr("Password required for %1").arg(modelData.name), "network");
                    }
                }
            }
        }
    }
}
