pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

FocusScope {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property bool hardwareVisible

    property var snapshot: ({})
    property string statusText: qsTr("Waiting for first sample…")
    property int sampleCount: 0

    readonly property string probePath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) +
        "/.local/bin/caerice-hardware-probe"

    readonly property var cpu: snapshot?.cpu ?? ({})
    readonly property var memory: snapshot?.memory ?? ({})
    readonly property var disk: snapshot?.disk ?? ({})
    readonly property var battery: snapshot?.battery ?? ({})
    readonly property var network: snapshot?.network ?? ({})
    readonly property var gpus: snapshot?.gpus ?? []
    readonly property var fans: snapshot?.fans ?? []
    readonly property var processes: snapshot?.processes ?? []

    function number(value, digits = 1): string {
        if (value === null || value === undefined || isNaN(Number(value)))
            return "—";
        return Number(value).toFixed(digits);
    }

    function pct(value): string {
        return `${number(value, 1)}%`;
    }

    function temp(value): string {
        return value === null || value === undefined ? "—" : `${number(value, 1)} °C`;
    }

    function gb(value): string {
        return value === null || value === undefined ? "—" : `${number(value, 2)} GiB`;
    }

    function watt(value): string {
        return value === null || value === undefined ? "—" : `${number(value, 1)} W`;
    }

    function speed(value): string {
        return value === null || value === undefined ? "—" : `${number(value, 2)} Mb/s`;
    }

    function uptimeText(seconds): string {
        const total = Math.max(0, Number(seconds ?? 0));
        const days = Math.floor(total / 86400);
        const hours = Math.floor((total % 86400) / 3600);
        const mins = Math.floor((total % 3600) / 60);
        if (days > 0)
            return `${days}d ${hours}h ${mins}m`;
        if (hours > 0)
            return `${hours}h ${mins}m`;
        return `${mins}m`;
    }

    function gpuAt(index): var {
        return index >= 0 && index < gpus.length ? gpus[index] : ({});
    }

    function refresh(): void {
        if (!root.hardwareVisible || probe.running)
            return;
        root.statusText = qsTr("Refreshing…");
        probe.running = true;
    }

    function openHardware(): void {
        forceActiveFocus();
        refresh();
    }

    Keys.onEscapePressed: root.screenState.hardware = false

    Keys.onPressed: event => {
        if (event.key === Qt.Key_R) {
            root.refresh();
            event.accepted = true;
        }
    }

    Timer {
        interval: 1500
        repeat: true
        running: root.hardwareVisible
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: probe
        command: [root.probePath]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim());
                    root.snapshot = parsed;
                    root.sampleCount += 1;
                    root.statusText = qsTr("Live · %1 ms cadence").arg(1500);
                } catch (error) {
                    root.statusText = qsTr("Probe returned invalid JSON");
                    console.warn(`Hardware Center: invalid probe JSON: ${error}`);
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.screenState.hardware = false
    }

    StyledRect {
        id: panel

        width: Math.min(1180, parent.width - 96)
        height: Math.min(840, parent.height - 80)
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        radius: 30
        color: Colours.palette.m3surfaceContainerHigh
        border.width: 1
        border.color: Colours.palette.m3outlineVariant
        clip: true

        StyledRect {
            anchors.fill: parent
            anchors.margins: 1
            radius: panel.radius - 1
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(Colours.palette.m3primary, 0.18)
        }

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14

            Row {
                id: header
                width: parent.width
                height: 62
                spacing: 14

                StyledRect {
                    width: 54
                    height: 54
                    radius: Tokens.rounding.extraLarge
                    color: Colours.palette.m3primaryContainer

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "monitor_heart"
                        fill: 1
                        color: Colours.palette.m3onPrimaryContainer
                        fontStyle: Tokens.font.icon.extraLarge
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 54 - refreshButton.width - 28
                    spacing: 1

                    StyledText {
                        width: parent.width
                        text: qsTr("Hardware Center")
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.title.large
                        elide: Text.ElideRight
                    }

                    StyledText {
                        width: parent.width
                        text:
                            `${root.snapshot?.host ?? "CaeRice"} · ` +
                            `${root.snapshot?.kernel ?? ""} · ` +
                            `${root.uptimeText(root.snapshot?.uptime_sec)}`
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.medium
                        elide: Text.ElideRight
                    }

                    StyledText {
                        width: parent.width
                        text: root.statusText
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                StyledRect {
                    id: refreshButton
                    anchors.verticalCenter: parent.verticalCenter
                    width: 46
                    height: 46
                    radius: Tokens.rounding.large
                    color: Colours.palette.m3surfaceContainerHighest

                    StateLayer {
                        radius: parent.radius
                        onClicked: root.refresh()
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: probe.running ? "progress_activity" : "refresh"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.large
                    }
                }
            }

            Grid {
                id: cards
                width: parent.width
                columns: 3
                columnSpacing: 12
                rowSpacing: 12

                MetricCard {
                    width: (cards.width - cards.columnSpacing * 2) / 3
                    title: qsTr("CPU")
                    icon: "memory"
                    headline: root.pct(root.cpu?.usage)
                    subtitle: root.cpu?.model ?? "CPU"
                    progress: Number(root.cpu?.usage ?? 0) / 100
                    rows: [
                        { label: qsTr("Temperature"), value: root.temp(root.cpu?.temp_c) },
                        { label: qsTr("Frequency"), value: root.cpu?.freq_mhz ? `${root.number(root.cpu.freq_mhz, 0)} MHz` : "—" },
                        { label: qsTr("Governor"), value: root.cpu?.governor ?? "—" }
                    ]
                }

                MetricCard {
                    width: (cards.width - cards.columnSpacing * 2) / 3
                    title: qsTr("Memory")
                    icon: "developer_board"
                    headline: root.pct(root.memory?.usage)
                    subtitle:
                        `${root.gb(root.memory?.used_gb)} / ${root.gb(root.memory?.total_gb)}`
                    progress: Number(root.memory?.usage ?? 0) / 100
                    rows: [
                        { label: qsTr("Used"), value: root.gb(root.memory?.used_gb) },
                        { label: qsTr("Available"), value: root.gb(Math.max(0, Number(root.memory?.total_gb ?? 0) - Number(root.memory?.used_gb ?? 0))) },
                        { label: qsTr("Swap"), value: `${root.gb(root.memory?.swap_used_gb)} / ${root.gb(root.memory?.swap_total_gb)}` }
                    ]
                }

                MetricCard {
                    width: (cards.width - cards.columnSpacing * 2) / 3
                    title: qsTr("Storage /")
                    icon: "hard_drive"
                    headline: root.pct(root.disk?.usage)
                    subtitle:
                        `${root.gb(root.disk?.used_gb)} / ${root.gb(root.disk?.total_gb)}`
                    progress: Number(root.disk?.usage ?? 0) / 100
                    rows: [
                        { label: qsTr("Used"), value: root.gb(root.disk?.used_gb) },
                        { label: qsTr("Free"), value: root.gb(root.disk?.free_gb) },
                        { label: qsTr("Filesystem"), value: "/" }
                    ]
                }

                MetricCard {
                    width: (cards.width - cards.columnSpacing * 2) / 3
                    title: root.gpuAt(0)?.vendor ? `${root.gpuAt(0).vendor} GPU` : qsTr("GPU 1")
                    icon: "view_in_ar"
                    headline: root.gpus.length > 0 ? root.pct(root.gpuAt(0)?.usage) : qsTr("Not detected")
                    subtitle: root.gpuAt(0)?.name ?? qsTr("No GPU telemetry")
                    progress: root.gpus.length > 0 ? Number(root.gpuAt(0)?.usage ?? 0) / 100 : -1
                    rows: [
                        { label: qsTr("Temperature"), value: root.temp(root.gpuAt(0)?.temp_c) },
                        { label: qsTr("VRAM"), value: `${root.gb(root.gpuAt(0)?.vram_used_gb)} / ${root.gb(root.gpuAt(0)?.vram_total_gb)}` },
                        { label: qsTr("Power"), value: root.watt(root.gpuAt(0)?.power_w) }
                    ]
                }

                MetricCard {
                    width: (cards.width - cards.columnSpacing * 2) / 3
                    title: root.gpuAt(1)?.vendor ? `${root.gpuAt(1).vendor} GPU` : qsTr("GPU 2")
                    icon: "sports_esports"
                    headline: root.gpus.length > 1 ? root.pct(root.gpuAt(1)?.usage) : qsTr("Not detected")
                    subtitle: root.gpuAt(1)?.name ?? qsTr("No second GPU telemetry")
                    progress: root.gpus.length > 1 ? Number(root.gpuAt(1)?.usage ?? 0) / 100 : -1
                    rows: [
                        { label: qsTr("Temperature"), value: root.temp(root.gpuAt(1)?.temp_c) },
                        { label: qsTr("VRAM"), value: `${root.gb(root.gpuAt(1)?.vram_used_gb)} / ${root.gb(root.gpuAt(1)?.vram_total_gb)}` },
                        { label: qsTr("Power"), value: root.watt(root.gpuAt(1)?.power_w) }
                    ]
                }

                MetricCard {
                    width: (cards.width - cards.columnSpacing * 2) / 3
                    title: root.battery?.present ? qsTr("Battery") : qsTr("Network")
                    icon: root.battery?.present ? "battery_charging_full" : "wifi"
                    headline:
                        root.battery?.present
                            ? root.pct(root.battery?.percent)
                            : (root.network?.interface ?? "—")
                    subtitle:
                        root.battery?.present
                            ? (root.battery?.status ?? "—")
                            : `${qsTr("Down")} ${root.speed(root.network?.rx_mbps)}`
                    progress:
                        root.battery?.present
                            ? Number(root.battery?.percent ?? 0) / 100
                            : -1
                    rows:
                        root.battery?.present
                            ? [
                                { label: qsTr("Power"), value: root.watt(root.battery?.power_w) },
                                { label: qsTr("Network"), value: root.network?.interface ?? "—" },
                                { label: qsTr("Down / Up"), value: `${root.speed(root.network?.rx_mbps)} / ${root.speed(root.network?.tx_mbps)}` }
                            ]
                            : [
                                { label: qsTr("Down"), value: root.speed(root.network?.rx_mbps) },
                                { label: qsTr("Up"), value: root.speed(root.network?.tx_mbps) },
                                { label: qsTr("Load 1m"), value: root.snapshot?.load?.length ? root.number(root.snapshot.load[0], 2) : "—" }
                            ]
                }
            }

            StyledRect {
                id: processCard
                width: parent.width
                height: Math.max(136, panel.height - header.height - cards.height - 22 * 2 - 14 * 3)
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                Row {
                    id: processHeader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 15

                    StyledText {
                        width: parent.width * 0.58
                        text: qsTr("Top processes")
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.title.small
                    }

                    StyledText {
                        width: parent.width * 0.14
                        text: qsTr("PID")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        horizontalAlignment: Text.AlignRight
                    }

                    StyledText {
                        width: parent.width * 0.14
                        text: qsTr("CPU")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        horizontalAlignment: Text.AlignRight
                    }

                    StyledText {
                        width: parent.width * 0.14
                        text: qsTr("RAM")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: processHeader.bottom
                    anchors.bottom: footer.top
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    anchors.topMargin: 8
                    spacing: 4
                    clip: true

                    Repeater {
                        model: root.processes.slice(0, 5)

                        delegate: Row {
                            required property var modelData
                            width: parent.width
                            height: 20

                            StyledText {
                                width: parent.width * 0.58
                                text: modelData?.name ?? "—"
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                width: parent.width * 0.14
                                text: String(modelData?.pid ?? "—")
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                horizontalAlignment: Text.AlignRight
                            }

                            StyledText {
                                width: parent.width * 0.14
                                text: root.pct(modelData?.cpu)
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                                horizontalAlignment: Text.AlignRight
                            }

                            StyledText {
                                width: parent.width * 0.14
                                text: root.pct(modelData?.mem)
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }

                Row {
                    id: footer
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 14
                    spacing: 18

                    StyledText {
                        text: qsTr("Esc  Close")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }

                    StyledText {
                        text: qsTr("R  Refresh")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }

                    StyledText {
                        visible: root.fans.length > 0
                        text:
                            root.fans.length > 0
                                ? `${root.fans[0].name}: ${root.fans[0].rpm} RPM`
                                : ""
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }
                }
            }
        }
    }
}
