pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.components.controls
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property PopoutState popouts

    property string connectingToSsid: ""
    property string view: "wireless" // "wireless" or "ethernet"
    property var passwordNetwork: null
    property bool showPasswordDialog: false

    spacing: CortetsuTokens.spacing.small
    width: CortetsuTokens.sizes.bar.networkWidth

    // Wireless section
    CortetsuText {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? CortetsuTokens.padding.medium : 0
        Layout.rightMargin: CortetsuTokens.padding.extraSmall
        text: qsTr("Wireless")
        font: CortetsuTokens.font.body.builders.medium.weight(Font.Medium).build()
    }

    Toggle {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        label: qsTr("Enabled")
        checked: Nmcli.wifiEnabled
        toggle.onToggled: Nmcli.enableWifi(checked)
    }

    CortetsuText {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? CortetsuTokens.spacing.small : 0
        Layout.rightMargin: CortetsuTokens.padding.extraSmall
        text: qsTr("%1 networks available").arg(Nmcli.networks.length) // qmllint disable missing-property
        color: CortetsuColours.palette.m3onSurfaceVariant
        font: CortetsuTokens.font.body.small
    }

    Repeater {
        visible: root.view === "wireless"
        model: ScriptModel {
            values: [...Nmcli.networks].sort((a, b) => {
                if (a.active !== b.active)
                    return b.active - a.active;
                return b.strength - a.strength;
            }).slice(0, 8)
        }

        RowLayout {
            id: networkItem

            required property Nmcli.AccessPoint modelData
            readonly property bool isConnecting: root.connectingToSsid === modelData.ssid
            readonly property bool loading: networkItem.isConnecting

            visible: root.view === "wireless"
            Layout.preferredHeight: visible ? implicitHeight : 0
            Layout.fillWidth: true
            Layout.rightMargin: CortetsuTokens.padding.extraSmall
            spacing: CortetsuTokens.spacing.small

            opacity: 0
            scale: 0.7

            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }

            CortetsuIcon {
                text: Icons.getNetworkIcon(networkItem.modelData.strength)
                color: networkItem.modelData.active ? CortetsuColours.palette.m3primary : CortetsuColours.palette.m3onSurfaceVariant
            }

            CortetsuIcon {
                visible: networkItem.modelData.isSecure
                text: "lock"
                fontStyle: CortetsuTokens.font.icon.small
            }

            CortetsuText {
                Layout.leftMargin: CortetsuTokens.spacing.extraSmall
                Layout.rightMargin: CortetsuTokens.spacing.extraSmall
                Layout.fillWidth: true
                text: networkItem.modelData.ssid
                elide: Text.ElideRight
                font: CortetsuTokens.font.body.builders.medium.weight(networkItem.modelData.active ? Font.Medium : Font.Normal).build()
                color: networkItem.modelData.active ? CortetsuColours.palette.m3primary : CortetsuColours.palette.m3onSurface
            }

            CortetsuSurface {
                implicitWidth: implicitHeight
                implicitHeight: wirelessConnectIcon.implicitHeight + CortetsuTokens.padding.extraSmall

                radius: CortetsuTokens.rounding.full
                color: Qt.alpha(CortetsuColours.palette.m3primary, networkItem.modelData.active ? 1 : 0)

                CircularIndicator {
                    anchors.fill: parent
                    running: networkItem.loading
                }

                CortetsuStateLayer {
                    color: networkItem.modelData.active ? CortetsuColours.palette.m3onPrimary : CortetsuColours.palette.m3onSurface
                    disabled: networkItem.loading || !Nmcli.wifiEnabled

                    onClicked: {
                        if (networkItem.modelData.active) {
                            Nmcli.disconnectFromNetwork();
                        } else {
                            root.connectingToSsid = networkItem.modelData.ssid;
                            NetworkConnection.handleConnect(networkItem.modelData, null, network => {
                                // Password is required - show password dialog
                                root.passwordNetwork = network;
                                root.showPasswordDialog = true;
                                root.popouts.currentName = "wirelesspassword";
                            });

                            // Clear connecting state if connection succeeds immediately (saved profile)
                            // This is handled by the onActiveChanged connection below
                        }
                    }
                }

                CortetsuIcon {
                    id: wirelessConnectIcon

                    anchors.centerIn: parent
                    animate: true
                    text: networkItem.modelData.active ? "link_off" : "link"
                    color: networkItem.modelData.active ? CortetsuColours.palette.m3onPrimary : CortetsuColours.palette.m3onSurface

                    opacity: networkItem.loading ? 0 : 1

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }
        }
    }

    CortetsuSurface {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? CortetsuTokens.spacing.small : 0
        Layout.fillWidth: true
        implicitHeight: rescanBtn.implicitHeight + CortetsuTokens.padding.small

        radius: CortetsuTokens.rounding.full
        color: CortetsuColours.palette.m3primaryContainer

        CortetsuStateLayer {
            color: CortetsuColours.palette.m3onPrimaryContainer
            disabled: Nmcli.scanning || !Nmcli.wifiEnabled
            onClicked: Nmcli.rescanWifi()
        }

        RowLayout {
            id: rescanBtn

            anchors.centerIn: parent
            spacing: CortetsuTokens.spacing.small
            opacity: Nmcli.scanning ? 0 : 1

            CortetsuIcon {
                id: scanIcon

                Layout.topMargin: Math.round(fontInfo.pointSize * 0.0575)
                animate: true
                text: "wifi_find"
                color: CortetsuColours.palette.m3onPrimaryContainer
            }

            CortetsuText {
                Layout.topMargin: -Math.round(scanIcon.fontInfo.pointSize * 0.0575)
                text: qsTr("Rescan networks")
                color: CortetsuColours.palette.m3onPrimaryContainer
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        CircularIndicator {
            anchors.centerIn: parent
            strokeWidth: CortetsuTokens.padding.extraSmall / 2
            bgColour: "transparent"
            implicitSize: parent.implicitHeight - CortetsuTokens.padding.large
            running: Nmcli.scanning
        }
    }

    // Ethernet section
    CortetsuText {
        visible: root.view === "ethernet"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? CortetsuTokens.padding.medium : 0
        Layout.rightMargin: CortetsuTokens.padding.extraSmall
        text: qsTr("Ethernet")
        font: CortetsuTokens.font.body.builders.medium.weight(Font.Medium).build()
    }

    CortetsuText {
        visible: root.view === "ethernet"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? CortetsuTokens.spacing.small : 0
        Layout.rightMargin: CortetsuTokens.padding.extraSmall
        text: qsTr("%1 devices available").arg(Nmcli.ethernetDevices.length)
        color: CortetsuColours.palette.m3onSurfaceVariant
        font: CortetsuTokens.font.body.small
    }

    Repeater {
        visible: root.view === "ethernet"
        model: ScriptModel {
            values: [...Nmcli.ethernetDevices].sort((a, b) => {
                if (a.connected !== b.connected)
                    return b.connected - a.connected;
                return (a.iface || "").localeCompare(b.iface || "");
            }).slice(0, 8)
        }

        RowLayout {
            id: ethernetItem

            required property var modelData
            readonly property bool loading: false

            visible: root.view === "ethernet"
            Layout.preferredHeight: visible ? implicitHeight : 0
            Layout.fillWidth: true
            Layout.rightMargin: CortetsuTokens.padding.extraSmall
            spacing: CortetsuTokens.spacing.small

            opacity: 0
            scale: 0.7

            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }

            CortetsuIcon {
                text: "cable"
                color: ethernetItem.modelData.connected ? CortetsuColours.palette.m3primary : CortetsuColours.palette.m3onSurfaceVariant
            }

            CortetsuText {
                Layout.leftMargin: CortetsuTokens.spacing.extraSmall
                Layout.rightMargin: CortetsuTokens.spacing.extraSmall
                Layout.fillWidth: true
                text: ethernetItem.modelData.iface || qsTr("Unknown")
                elide: Text.ElideRight
                font: CortetsuTokens.font.body.builders.medium.weight(ethernetItem.modelData.connected ? Font.Medium : Font.Normal).build()
                color: ethernetItem.modelData.connected ? CortetsuColours.palette.m3primary : CortetsuColours.palette.m3onSurface
            }

            CortetsuSurface {
                implicitWidth: implicitHeight
                implicitHeight: connectIcon.implicitHeight + CortetsuTokens.padding.extraSmall

                radius: CortetsuTokens.rounding.full
                color: Qt.alpha(CortetsuColours.palette.m3primary, ethernetItem.modelData.connected ? 1 : 0)

                CircularIndicator {
                    anchors.fill: parent
                    running: ethernetItem.loading
                }

                CortetsuStateLayer {
                    color: ethernetItem.modelData.connected ? CortetsuColours.palette.m3onPrimary : CortetsuColours.palette.m3onSurface
                    disabled: ethernetItem.loading

                    onClicked: {
                        if (ethernetItem.modelData.connected && ethernetItem.modelData.connection) {
                            Nmcli.disconnectEthernet(ethernetItem.modelData.connection, () => {});
                        } else {
                            Nmcli.connectEthernet(ethernetItem.modelData.connection || "", ethernetItem.modelData.iface || "", () => {});
                        }
                    }
                }

                CortetsuIcon {
                    id: connectIcon

                    anchors.centerIn: parent
                    animate: true
                    text: ethernetItem.modelData.connected ? "link_off" : "link"
                    color: ethernetItem.modelData.connected ? CortetsuColours.palette.m3onPrimary : CortetsuColours.palette.m3onSurface

                    opacity: ethernetItem.loading ? 0 : 1

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }
        }
    }

    Connections {
        function onActiveChanged(): void {
            if (Nmcli.active && root.connectingToSsid === Nmcli.active.ssid) {
                root.connectingToSsid = "";
                // Close password dialog if we successfully connected
                if (root.showPasswordDialog && root.passwordNetwork && Nmcli.active.ssid === root.passwordNetwork.ssid) {
                    root.showPasswordDialog = false;
                    root.passwordNetwork = null;
                    if (root.popouts.currentName === "wirelesspassword") {
                        root.popouts.currentName = "network";
                    }
                }
            }
        }

        function onScanningChanged(): void {
            if (!Nmcli.scanning)
                scanIcon.rotation = 0;
        }

        target: Nmcli
    }

    Connections {
        function onCurrentNameChanged(): void {
            // Clear password network when leaving password dialog
            if (root.popouts.currentName !== "wirelesspassword" && root.showPasswordDialog) {
                root.showPasswordDialog = false;
                root.passwordNetwork = null;
            }
        }

        target: root.popouts
    }

    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        Layout.rightMargin: CortetsuTokens.padding.extraSmall
        spacing: CortetsuTokens.spacing.medium

        CortetsuText {
            Layout.fillWidth: true
            text: parent.label
        }

        StyledSwitch {
            id: toggle
        }
    }
}
