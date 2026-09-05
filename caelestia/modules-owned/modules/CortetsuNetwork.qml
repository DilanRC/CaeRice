pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var active: null
    property var activeEthernet: null

    function refresh(): void {
        deviceStatus.running = true;
        wifiStatus.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: deviceStatus
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const rows = text.split("\n").map(line => line.split(":"));
                root.activeEthernet = rows.some(row => row[0] === "ethernet" && row[1] === "connected")
                    ? { connected: true } : null;
            }
        }
    }

    Process {
        id: wifiStatus
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SSID", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const row = text.split("\n").map(line => line.split(":")).find(parts => parts[0] === "*");
                root.active = row ? { strength: Number(row[1]) || 0, ssid: row.slice(2).join(":") } : null;
            }
        }
    }

    Timer { interval: 10000; repeat: true; running: true; onTriggered: root.refresh() }
}
