pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property var power: ({})
    property var batteryPowerHistory: []
    property var cpuPowerHistory: []
    property var amdPowerHistory: []
    property var nvidiaPowerHistory: []
    property string statusText: qsTr("Collecting energy samples…")

    readonly property string helperPath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) +
        "/.local/bin/caerice-hardware-power"

    readonly property var battery: power?.battery ?? ({})
    readonly property var cpu: power?.cpu ?? ({})
    readonly property var ac: power?.ac ?? ({})
    readonly property var gpus: power?.gpus ?? []

    function number(value, digits = 1): string {
        if (value === null || value === undefined || isNaN(Number(value)))
            return "—";
        return Number(value).toFixed(digits);
    }

    function pushHistory(source, value): var {
        const next = Array.from(source ?? []);
        next.push(Math.max(0, Number(value ?? 0)));
        return next.slice(-90);
    }

    function gpuAt(index): var {
        return index >= 0 && index < gpus.length ? gpus[index] : ({});
    }

    function duration(minutes): string {
        if (minutes === null || minutes === undefined || isNaN(Number(minutes)))
            return "—";
        const total = Math.max(0, Math.round(Number(minutes)));
        const h = Math.floor(total / 60);
        const m = total % 60;
        return h > 0 ? `${h}h ${m}m` : `${m}m`;
    }

    function batteryEstimate(): string {
        const status = String(battery?.status ?? "").toLowerCase();
        if (status === "discharging" && battery?.remaining_minutes !== null && battery?.remaining_minutes !== undefined)
            return qsTr("Estimated remaining: %1").arg(duration(battery.remaining_minutes));
        if (status === "charging" && battery?.time_to_full_minutes !== null && battery?.time_to_full_minutes !== undefined)
            return qsTr("Estimated to full: %1").arg(duration(battery.time_to_full_minutes));
        if (status === "full")
            return qsTr("Battery full");
        return qsTr("Runtime estimate unavailable at the current power state");
    }

    function refresh(): void {
        if (!probe.running)
            probe.running = true;
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Process {
        id: probe
        command: [root.helperPath]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim());
                    root.power = parsed;
                    root.batteryPowerHistory = root.pushHistory(root.batteryPowerHistory, parsed?.battery?.power_w);
                    root.cpuPowerHistory = root.pushHistory(root.cpuPowerHistory, parsed?.cpu?.package_power_w);
                    root.amdPowerHistory = root.pushHistory(root.amdPowerHistory, parsed?.gpus?.[0]?.power_w);
                    root.nvidiaPowerHistory = root.pushHistory(root.nvidiaPowerHistory, parsed?.gpus?.[1]?.power_w);
                    root.statusText = qsTr("Live energy telemetry · 2 s cadence");
                } catch (error) {
                    root.statusText = qsTr("Energy telemetry unavailable");
                    console.warn(`Hardware Center Energy: invalid JSON: ${error}`);
                }
            }
        }
    }

    Column {
        anchors.fill: parent
        spacing: 12

        Grid {
            id: summaryGrid
            width: parent.width
            height: 126
            columns: 3
            columnSpacing: 12

            Repeater {
                model: [
                    {
                        icon: root.ac?.online ? "power" : "battery_5_bar",
                        title: qsTr("Power source"),
                        value: root.ac?.online ? qsTr("AC connected") : qsTr("Battery"),
                        detail: root.statusText
                    },
                    {
                        icon: "battery_charging_full",
                        title: qsTr("Battery energy"),
                        value: root.battery?.present
                            ? `${root.number(root.battery?.energy_now_wh, 1)} / ${root.number(root.battery?.energy_full_wh, 1)} Wh`
                            : qsTr("Not detected"),
                        detail: root.batteryEstimate()
                    },
                    {
                        icon: "electric_bolt",
                        title: qsTr("Current power"),
                        value: `${root.number(root.cpu?.package_power_w, 1)} W CPU · ${root.number(root.power?.total_gpu_power_w, 1)} W GPU`,
                        detail: root.battery?.present
                            ? `${root.number(root.battery?.power_w, 1)} W battery · ${root.number(root.battery?.health_percent, 1)}% health`
                            : qsTr("Battery power telemetry unavailable")
                    }
                ]

                delegate: StyledRect {
                    required property var modelData
                    width: (summaryGrid.width - 24) / 3
                    height: summaryGrid.height
                    radius: Tokens.rounding.extraLarge
                    color: Colours.palette.m3surfaceContainer
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant

                    Row {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        StyledRect {
                            width: 44
                            height: 44
                            anchors.verticalCenter: parent.verticalCenter
                            radius: Tokens.rounding.large
                            color: Colours.palette.m3secondaryContainer

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: modelData.icon
                                color: Colours.palette.m3onSecondaryContainer
                                fontStyle: Tokens.font.icon.large
                            }
                        }

                        Column {
                            width: parent.width - 56
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            StyledText {
                                width: parent.width
                                text: modelData.title
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                            StyledText {
                                width: parent.width
                                text: modelData.value
                                color: Colours.palette.m3onSurface
                                font: Tokens.font.title.small
                                elide: Text.ElideRight
                            }
                            StyledText {
                                width: parent.width
                                text: modelData.detail
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        Grid {
            width: parent.width
            height: parent.height - summaryGrid.height - 12
            columns: 2
            columnSpacing: 12
            rowSpacing: 12

            HistoryGraph {
                width: (parent.width - 12) / 2
                height: (parent.height - 12) / 2
                title: qsTr("Battery power")
                icon: "battery_charging_full"
                headline: `${root.number(root.battery?.power_w, 2)} W`
                subtitle: root.batteryEstimate()
                legendA: qsTr("Battery flow")
                seriesA: root.batteryPowerHistory
                unit: "W"
                colourA: Colours.palette.m3primary
            }

            HistoryGraph {
                width: (parent.width - 12) / 2
                height: (parent.height - 12) / 2
                title: qsTr("CPU package power")
                icon: "memory"
                headline: root.cpu?.package_power_w !== null && root.cpu?.package_power_w !== undefined
                    ? `${root.number(root.cpu.package_power_w, 2)} W`
                    : qsTr("Not exposed")
                subtitle: `${root.cpu?.driver ?? "—"} · ${root.cpu?.platform_profile ?? "—"}`
                legendA: qsTr("CPU package")
                seriesA: root.cpuPowerHistory
                unit: "W"
                colourA: Colours.palette.m3secondary
            }

            HistoryGraph {
                width: (parent.width - 12) / 2
                height: (parent.height - 12) / 2
                title: qsTr("AMD GPU power")
                icon: "view_in_ar"
                headline: `${root.number(root.gpuAt(0)?.power_w, 2)} W`
                subtitle: `${root.gpuAt(0)?.runtime_status ?? "—"} · ${root.number(root.gpuAt(0)?.temp_c, 1)} °C`
                legendA: qsTr("AMD GPU")
                seriesA: root.amdPowerHistory
                unit: "W"
                colourA: Colours.palette.m3primary
            }

            HistoryGraph {
                width: (parent.width - 12) / 2
                height: (parent.height - 12) / 2
                title: qsTr("NVIDIA GPU power")
                icon: "sports_esports"
                headline: `${root.number(root.gpuAt(1)?.power_w, 2)} W`
                subtitle: `${root.gpuAt(1)?.pstate ?? "—"} · ${root.number(root.gpuAt(1)?.graphics_clock_mhz, 0)} MHz · ${root.number(root.gpuAt(1)?.temp_c, 1)} °C`
                legendA: qsTr("NVIDIA GPU")
                seriesA: root.nvidiaPowerHistory
                unit: "W"
                colourA: Colours.palette.m3tertiary
            }
        }
    }
}
