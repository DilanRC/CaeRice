pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../modules"

Singleton {
    id: root

    readonly property list<Monitor> monitors: variants.instances

    function getMonitorForScreen(screen: ShellScreen): var {
        return monitors.find(m => m.modelData === screen) ?? null;
    }

    function getMonitor(query: string): var {
        if (query === "active")
            return monitors.find(m => CortetsuHypr.monitorFor(m.modelData)?.focused) ?? monitors[0] ?? null;
        if (query.startsWith("model:"))
            return monitors.find(m => m.modelData.model === query.slice(6)) ?? null;
        if (query.startsWith("serial:"))
            return monitors.find(m => m.modelData.serialNumber === query.slice(7)) ?? null;
        if (query.startsWith("id:"))
            return monitors.find(m => CortetsuHypr.monitorFor(m.modelData)?.id === Number(query.slice(3))) ?? null;
        return monitors.find(m => m.modelData.name === query) ?? null;
    }

    function increaseBrightness(): void {
        const monitor = getMonitor("active");
        if (monitor) monitor.setBrightness(monitor.brightness + CortetsuConfig.brightnessIncrement);
    }
    function decreaseBrightness(): void {
        const monitor = getMonitor("active");
        if (monitor) monitor.setBrightness(monitor.brightness - CortetsuConfig.brightnessIncrement);
    }

    Variants {
        id: variants
        model: Quickshell.screens
        Monitor {}
    }

    IpcHandler {
        target: "brightness"
        function get(): real { return root.getMonitor("active")?.brightness ?? -1; }
        function getFor(query: string): real { return root.getMonitor(query)?.brightness ?? -1; }
        function set(value: string): string { return setFor("active", value); }
        function setFor(query: string, value: string): string {
            const monitor = root.getMonitor(query);
            if (!monitor) return "Invalid monitor: " + query;
            let amount = Number(value);
            if (value.endsWith("%")) amount = Number(value.slice(0, -1)) / 100;
            else if (value.startsWith("+")) amount = monitor.brightness + Number(value.slice(1));
            else if (value.endsWith("-")) amount = monitor.brightness - Number(value.slice(0, -1));
            else if (value.includes("%") || value.includes("+") || value.includes("-")) return "Invalid brightness format: " + value;
            if (!Number.isFinite(amount)) return "Failed to parse value: " + value;
            monitor.setBrightness(amount);
            return `Set monitor ${monitor.modelData.name} brightness to ${monitor.brightness.toFixed(2)}`;
        }
    }

    component Monitor: QtObject {
        id: monitor
        required property ShellScreen modelData
        property real brightness: 0
        readonly property string monitorName: modelData?.name ?? ""
        readonly property Process readProcess: Process {
            command: monitor.monitorName.length > 0
                ? ["brightnessctl", "-d", "*" + monitor.monitorName + "*", "g"]
                : ["true"]
            stdout: StdioCollector { onStreamFinished: monitor.brightness = Math.max(0, Math.min(1, Number(text.trim()) / 100)) }
        }
        function setBrightness(value: real): void {
            brightness = Math.max(0, Math.min(1, value));
            Quickshell.execDetached(["brightnessctl", "-d", "*" + modelData.name + "*", "s", Math.round(brightness * 100) + "%"]);
        }
        Component.onCompleted: readProcess.running = true
    }
}
