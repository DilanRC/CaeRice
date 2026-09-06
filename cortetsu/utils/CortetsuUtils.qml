pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property string version: "2.4.0-1"
    readonly property string qtVersion: Qt.version

    function clamp(value: real, low: real, high: real): real {
        return Math.max(low, Math.min(high, value));
    }

    function deleteFile(path: url): void {
        Quickshell.execDetached(["rm", "-f", "--", String(path).replace(/^file:\/\//, "")]);
    }
}
