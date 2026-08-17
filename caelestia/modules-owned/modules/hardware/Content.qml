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
    property int currentPage: 0

    property var cpuHistory: []
    property var cpuCoreHistories: []
    property var memoryUsedHistory: []
    property var memoryCacheHistory: []
    property var swapUsedHistory: []
    property var networkRxHistory: []
    property var networkTxHistory: []
    property var diskReadHistory: []
    property var diskWriteHistory: []
    property var gpu0History: []
    property var gpu1History: []

    readonly property string probePath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) +
        "/.local/bin/caerice-hardware-probe"

    readonly property var processes: snapshot?.processes ?? []

    function number(value, digits = 1): string {
        if (value === null || value === undefined || isNaN(Number(value)))
            return "—";
        return Number(value).toFixed(digits);
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

    function pushHistory(source, value): var {
        const next = Array.from(source ?? []);
        next.push(Number(value ?? 0));
        return next.slice(-72);
    }

    function recordHistory(parsed): void {
        root.cpuHistory = pushHistory(root.cpuHistory, parsed?.cpu?.usage);

        const coreValues = parsed?.cpu?.per_core ?? [];
        const coreHistories = Array.from(root.cpuCoreHistories ?? []);
        while (coreHistories.length < coreValues.length)
            coreHistories.push([]);
        for (let i = 0; i < coreValues.length; ++i)
            coreHistories[i] = pushHistory(coreHistories[i], coreValues[i]);
        root.cpuCoreHistories = coreHistories;

        root.memoryUsedHistory = pushHistory(root.memoryUsedHistory, parsed?.memory?.used_gb);
        root.memoryCacheHistory = pushHistory(root.memoryCacheHistory, parsed?.memory?.cache_gb);
        root.swapUsedHistory = pushHistory(root.swapUsedHistory, parsed?.memory?.swap_used_gb);
        root.networkRxHistory = pushHistory(root.networkRxHistory, parsed?.network?.rx_mbps);
        root.networkTxHistory = pushHistory(root.networkTxHistory, parsed?.network?.tx_mbps);
        root.diskReadHistory = pushHistory(root.diskReadHistory, parsed?.disk_io?.read_mib_s);
        root.diskWriteHistory = pushHistory(root.diskWriteHistory, parsed?.disk_io?.write_mib_s);
        root.gpu0History = pushHistory(root.gpu0History, parsed?.gpus?.[0]?.usage);
        root.gpu1History = pushHistory(root.gpu1History, parsed?.gpus?.[1]?.usage);
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
            return;
        }
        if (event.key >= Qt.Key_1 && event.key <= Qt.Key_7) {
            root.currentPage = event.key - Qt.Key_1;
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
                    root.recordHistory(parsed);
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
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
            const outsidePanel =
                mouse.x < panel.x ||
                mouse.x >= panel.x + panel.width ||
                mouse.y < panel.y ||
                mouse.y >= panel.y + panel.height;

            if (outsidePanel)
                root.screenState.hardware = false;
        }
    }

    StyledRect {
        id: panel

        width: Math.min(1260, parent.width - 96)
        height: Math.min(900, parent.height - 64)
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
            spacing: 12

            Row {
                id: header
                width: parent.width
                height: 58
                spacing: 14

                StyledRect {
                    width: 52
                    height: 52
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
                    width: parent.width - 52 - refreshButton.width - 28
                    spacing: 0

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

            Row {
                id: tabs
                width: parent.width
                height: 42
                spacing: 7

                Repeater {
                    model: [
                        { label: qsTr("Overview"), icon: "dashboard" },
                        { label: qsTr("Performance"), icon: "monitoring" },
                        { label: qsTr("Processes"), icon: "account_tree" },
                        { label: qsTr("Sensors"), icon: "device_thermostat" },
                        { label: qsTr("I/O"), icon: "lan" },
                        { label: qsTr("Power"), icon: "bolt" },
                        { label: qsTr("Auto"), icon: "auto_mode" }
                    ]

                    delegate: StyledRect {
                        required property var modelData
                        required property int index
                        width: Math.min(150, (tabs.width - tabs.spacing * 6) / 7)
                        height: 42
                        radius: Tokens.rounding.large
                        color: root.currentPage === index
                            ? Colours.palette.m3secondaryContainer
                            : Colours.palette.m3surfaceContainer
                        border.width: root.currentPage === index ? 1 : 0
                        border.color: Colours.palette.m3primary

                        StateLayer {
                            radius: parent.radius
                            onClicked: root.currentPage = index
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 7

                            MaterialIcon {
                                text: modelData.icon
                                color: root.currentPage === index
                                    ? Colours.palette.m3onSecondaryContainer
                                    : Colours.palette.m3onSurfaceVariant
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                text: `${index + 1}  ${modelData.label}`
                                color: root.currentPage === index
                                    ? Colours.palette.m3onSecondaryContainer
                                    : Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.medium
                            }
                        }
                    }
                }
            }

            Loader {
                id: pageLoader
                width: parent.width
                height: parent.height - header.height - tabs.height - 24
                sourceComponent: root.currentPage === 0
                    ? overviewComponent
                    : root.currentPage === 1
                        ? performanceComponent
                        : root.currentPage === 2
                            ? processesComponent
                            : root.currentPage === 3
                                ? sensorsComponent
                                : root.currentPage === 4
                                    ? ioComponent
                                    : root.currentPage === 5
                                        ? powerComponent
                                        : automationComponent
            }
        }
    }

    Component {
        id: overviewComponent

        OverviewPage {
            snapshot: root.snapshot
        }
    }

    Component {
        id: performanceComponent

        PerformancePage {
            snapshot: root.snapshot
            cpuHistory: root.cpuHistory
            cpuCoreHistories: root.cpuCoreHistories
            memoryUsedHistory: root.memoryUsedHistory
            memoryCacheHistory: root.memoryCacheHistory
            swapUsedHistory: root.swapUsedHistory
            networkRxHistory: root.networkRxHistory
            networkTxHistory: root.networkTxHistory
            diskReadHistory: root.diskReadHistory
            diskWriteHistory: root.diskWriteHistory
            gpu0History: root.gpu0History
            gpu1History: root.gpu1History
        }
    }

    Component {
        id: processesComponent

        ProcessesPage {
            processes: root.processes
            memoryTotalGb: Number(root.snapshot?.memory?.total_gb ?? 0)
        }
    }

    Component {
        id: sensorsComponent

        SensorsPage {
            snapshot: root.snapshot
        }
    }

    Component {
        id: ioComponent

        IOPage {
            snapshot: root.snapshot
        }
    }

    Component {
        id: powerComponent

        PowerPage {}
    }

    Component {
        id: automationComponent

        PowerAutomationPage {}
    }
}
