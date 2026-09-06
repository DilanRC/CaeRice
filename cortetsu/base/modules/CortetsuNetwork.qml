pragma Singleton

import Quickshell
import Quickshell.Networking
import QtQuick

/**
 * First-party network status service.
 *
 * Backed by Quickshell's native Quickshell.Networking module, which talks to
 * NetworkManager over DBus and exposes properties as Qt bindable properties
 * (org.freedesktop.NetworkManager PropertiesChanged signals drive updates).
 * No polling, no CLI subprocess, no upstream shell dependency.
 *
 * Contract (unchanged for consumers, e.g. BottomHub.qml):
 *   - active: { strength, ssid } for the connected Wi-Fi network, else null.
 *   - activeEthernet: { connected: true } when a wired device is connected, else null.
 *   - connecting: true while NetworkManager reports an in-flight (re)connection.
 */
Singleton {
    id: root

    function deviceOfType(type): var {
        return (Networking.devices?.values ?? []).find(device => device.type === type) ?? null;
    }

    readonly property var wifiDevice: deviceOfType(DeviceType.Wifi)
    readonly property var wiredDevice: deviceOfType(DeviceType.Wired)

    readonly property var activeWifiNetwork: wifiDevice
        ? (wifiDevice.networks?.values ?? []).find(network => network.connected) ?? null
        : null

    readonly property var active: activeWifiNetwork
        ? { strength: Math.round(activeWifiNetwork.signalStrength ?? 0), ssid: activeWifiNetwork.name }
        : null

    readonly property var activeEthernet: (wiredDevice?.connected ?? false)
        ? { connected: true } : null

    readonly property bool connecting:
        (wifiDevice?.state === ConnectionState.Connecting)
        || (activeWifiNetwork?.stateChanging ?? false)
}
