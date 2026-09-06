pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool running: false

    function refresh(): void {
        status.running = true;
    }

    function stop(): void {
        Quickshell.execDetached(["cortetsu-record", "stop"]);
        Qt.callLater(refresh);
    }

    Component.onCompleted: refresh()

    Process {
        id: status
        command: ["cortetsu-record", "status"]
        onExited: code => root.running = code === 0
    }

    Timer { interval: 2000; repeat: true; running: true; onTriggered: root.refresh() }
}
