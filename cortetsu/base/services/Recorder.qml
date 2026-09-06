pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property alias running: props.running
    readonly property alias paused: props.paused
    readonly property alias elapsed: props.elapsed
    property bool needsStart: false
    property list<string> startArgs: []
    property bool needsStop: false
    property bool needsPause: false

    function start(extraArgs = []): void {
        needsStart = true; startArgs = extraArgs; checkProc.running = true;
    }
    function stop(): void { needsStop = true; checkProc.running = true; }
    function togglePause(): void { needsPause = true; checkProc.running = true; }

    PersistentProperties {
        id: props
        property bool running: false
        property bool paused: false
        property real elapsed: 0
        reloadableId: "recorder"
    }

    Process {
        id: checkProc
        running: true
        command: ["cortetsu-record", "status"]
        onExited: code => { // qmllint disable signal-handler-parameters
            props.running = code === 0;
            if (code === 0) {
                if (root.needsStop) {
                    Quickshell.execDetached(["cortetsu-record", "stop"]);
                    props.running = false; props.paused = false;
                } else if (root.needsPause) {
                    Quickshell.execDetached(["cortetsu-record", "pause"]);
                    props.paused = !props.paused;
                }
            } else if (root.needsStart) {
                Quickshell.execDetached(["cortetsu-record", "start", ...root.startArgs]);
                props.running = true; props.paused = false; props.elapsed = 0;
            }
            root.needsStart = false; root.needsStop = false; root.needsPause = false;
        }
    }

    Connections {
        target: Time // qmllint disable incompatible-type
        function onSecondsChanged(): void { props.elapsed++; }
    }
}
