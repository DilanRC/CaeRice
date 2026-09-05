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
    required property bool displayVisible

    property var snapshot: ({})
    property var candidateOutputs: []
    property int selectedIndex: 0
    property var planResult: ({})
    property string statusText: qsTr("Waiting for display inventory…")
    property string planStatus: qsTr("No dry run yet")

    readonly property string probePath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/cortetsu-display-probe"
    readonly property string plannerPath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/cortetsu-display-plan"
    readonly property var monitors: snapshot?.hyprland ?? []
    readonly property var selectedCandidate:
        selectedIndex >= 0 && selectedIndex < candidateOutputs.length ? candidateOutputs[selectedIndex] : ({})
    readonly property var selectedLive: liveByName(selectedCandidate?.name ?? "")
    readonly property int enabledCount: candidateOutputs.filter(item => item?.enabled ?? true).length

    function liveByName(name): var {
        for (const monitor of monitors) {
            if (monitor?.name === name)
                return monitor;
        }
        return ({});
    }

    function currentMode(monitor): string {
        const modes = monitor?.available_modes ?? [];
        const width = Number(monitor?.width ?? 0);
        const height = Number(monitor?.height ?? 0);
        const refresh = Number(monitor?.refresh_hz ?? 0);
        let nearest = "";
        let nearestDelta = 9999;
        for (const mode of modes) {
            const match = String(mode).match(/^(\d+)x(\d+)@([0-9.]+)/);
            if (!match)
                continue;
            if (Number(match[1]) !== width || Number(match[2]) !== height)
                continue;
            const delta = Math.abs(Number(match[3]) - refresh);
            if (delta < nearestDelta) {
                nearestDelta = delta;
                nearest = String(mode);
            }
        }
        if (nearest.length)
            return nearest;
        return modes.length ? String(modes[0]) : "preferred";
    }

    function resetCandidate(): void {
        const next = [];
        for (const monitor of monitors) {
            next.push({
                name: monitor?.name ?? "",
                enabled: !(monitor?.disabled ?? false),
                mode: currentMode(monitor),
                x: Number(monitor?.x ?? 0),
                y: Number(monitor?.y ?? 0),
                scale: Number(monitor?.scale ?? 1),
                transform: Number(monitor?.transform ?? 0)
            });
        }
        candidateOutputs = next;
        selectedIndex = Math.max(0, Math.min(selectedIndex, next.length - 1));
        planResult = ({});
        planStatus = qsTr("Candidate reset to the current live layout");
    }

    function updateSelected(field, value): void {
        if (selectedIndex < 0 || selectedIndex >= candidateOutputs.length)
            return;
        const next = candidateOutputs.map(item => Object.assign({}, item));
        next[selectedIndex][field] = value;
        candidateOutputs = next;
        planResult = ({});
        planStatus = qsTr("Candidate changed · run Dry run again");
    }

    function toggleSelectedEnabled(): void {
        if (selectedIndex < 0 || selectedIndex >= candidateOutputs.length)
            return;
        const current = candidateOutputs[selectedIndex];
        if ((current?.enabled ?? true) && enabledCount <= 1) {
            planStatus = qsTr("Blocked: at least one output must stay enabled");
            return;
        }
        updateSelected("enabled", !(current?.enabled ?? true));
    }

    function cycleMode(delta): void {
        const modes = selectedLive?.available_modes ?? [];
        if (!modes.length)
            return;
        const current = String(selectedCandidate?.mode ?? "");
        let index = modes.indexOf(current);
        if (index < 0)
            index = 0;
        index = (index + delta + modes.length) % modes.length;
        updateSelected("mode", String(modes[index]));
    }

    function cycleTransform(delta): void {
        const current = Number(selectedCandidate?.transform ?? 0);
        updateSelected("transform", (current + delta + 8) % 8);
    }

    function parseMode(mode): var {
        const match = String(mode ?? "").match(/^(\d+)x(\d+)@?([0-9.]*)/);
        if (!match)
            return ({ width: 1920, height: 1080 });
        return ({ width: Number(match[1]), height: Number(match[2]) });
    }

    function logicalWidth(output): real {
        const size = parseMode(output?.mode);
        return size.width / Math.max(0.5, Number(output?.scale ?? 1));
    }

    function applyLaptopPreset(): void {
        const next = candidateOutputs.map(item => Object.assign({}, item));
        let found = false;
        for (const item of next) {
            const internal = String(item?.name ?? "").startsWith("eDP-");
            item.enabled = internal;
            if (internal) {
                item.x = 0;
                item.y = 0;
                found = true;
            }
        }
        if (!found) {
            planStatus = qsTr("Laptop preset unavailable: no eDP output is active");
            return;
        }
        candidateOutputs = next;
        selectedIndex = Math.max(0, next.findIndex(item => String(item?.name ?? "").startsWith("eDP-")));
        planResult = ({});
        planStatus = qsTr("Preset: Laptop only · run Dry run");
    }

    function applyDualPreset(): void {
        const next = candidateOutputs.map(item => Object.assign({}, item));
        const internalIndex = next.findIndex(item => String(item?.name ?? "").startsWith("eDP-"));
        const externalIndex = next.findIndex(item => !String(item?.name ?? "").startsWith("eDP-"));
        if (internalIndex < 0 || externalIndex < 0) {
            planStatus = qsTr("Dual preset unavailable: connect an external output first");
            return;
        }
        for (let i = 0; i < next.length; ++i)
            next[i].enabled = i === internalIndex || i === externalIndex;
        next[externalIndex].x = 0;
        next[externalIndex].y = 0;
        next[internalIndex].x = Math.round(logicalWidth(next[externalIndex]));
        next[internalIndex].y = 0;
        candidateOutputs = next;
        selectedIndex = externalIndex;
        planResult = ({});
        planStatus = qsTr("Preset: Dual · external left, laptop right · run Dry run");
    }

    function applyExternalPreset(): void {
        const next = candidateOutputs.map(item => Object.assign({}, item));
        const externalIndex = next.findIndex(item => !String(item?.name ?? "").startsWith("eDP-"));
        if (externalIndex < 0) {
            planStatus = qsTr("External-only preset unavailable: no external output connected");
            return;
        }
        for (let i = 0; i < next.length; ++i)
            next[i].enabled = i === externalIndex;
        next[externalIndex].x = 0;
        next[externalIndex].y = 0;
        candidateOutputs = next;
        selectedIndex = externalIndex;
        planResult = ({});
        planStatus = qsTr("Preset: External only · run Dry run");
    }

    function layoutBounds(): var {
        if (!candidateOutputs.length)
            return ({ minX: 0, minY: 0, width: 1920, height: 1080 });
        let minX = 1e9;
        let minY = 1e9;
        let maxX = -1e9;
        let maxY = -1e9;
        let found = false;
        for (const output of candidateOutputs) {
            if (!output?.enabled)
                continue;
            const size = parseMode(output?.mode);
            const scale = Math.max(0.5, Number(output?.scale ?? 1));
            const width = size.width / scale;
            const height = size.height / scale;
            minX = Math.min(minX, Number(output?.x ?? 0));
            minY = Math.min(minY, Number(output?.y ?? 0));
            maxX = Math.max(maxX, Number(output?.x ?? 0) + width);
            maxY = Math.max(maxY, Number(output?.y ?? 0) + height);
            found = true;
        }
        if (!found)
            return ({ minX: 0, minY: 0, width: 1920, height: 1080 });
        return ({ minX, minY, width: Math.max(1, maxX - minX), height: Math.max(1, maxY - minY) });
    }

    function topologyScale(width, height): real {
        const bounds = layoutBounds();
        return Math.min((width - 36) / bounds.width, (height - 36) / bounds.height);
    }

    function refresh(): void {
        if (!displayVisible || probe.running)
            return;
        statusText = qsTr("Refreshing outputs…");
        probe.running = true;
    }

    function runPlan(): void {
        if (planner.running || !candidateOutputs.length)
            return;
        planStatus = qsTr("Validating candidate…");
        planner.command = [plannerPath, "--candidate", JSON.stringify({ outputs: candidateOutputs })];
        planner.running = true;
    }

    function openDisplayManager(): void {
        forceActiveFocus();
        refresh();
    }

    function closeDisplayManager(): void {
        screenState.cortetsuState?.setRetained("displayManager", false);
    }

    Keys.onEscapePressed: closeDisplayManager()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_R) {
            refresh();
            event.accepted = true;
        } else if (event.key === Qt.Key_P) {
            runPlan();
            event.accepted = true;
        }
    }

    Process {
        id: probe
        command: [root.probePath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim());
                    root.snapshot = parsed;
                    root.statusText = qsTr("%1 output(s) · %2 focused")
                        .arg(parsed?.summary?.connected ?? 0)
                        .arg(parsed?.summary?.focused ?? qsTr("none"));
                    if (!root.candidateOutputs.length)
                        root.resetCandidate();
                } catch (error) {
                    root.statusText = qsTr("Display probe returned invalid JSON");
                    console.warn(`Display Manager probe JSON: ${error}`);
                }
            }
        }
    }

    Process {
        id: planner
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim());
                    root.planResult = parsed;
                    root.planStatus = parsed?.ok
                        ? qsTr("Dry run valid · %1 monitor command(s)").arg(parsed?.commands?.length ?? 0)
                        : qsTr("Dry run blocked · %1 error(s)").arg(parsed?.errors?.length ?? 0);
                } catch (error) {
                    root.planResult = ({ ok: false, errors: [String(error)] });
                    root.planStatus = qsTr("Planner returned invalid JSON");
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
            const outsidePanel = mouse.x < panel.x || mouse.x >= panel.x + panel.width ||
                mouse.y < panel.y || mouse.y >= panel.y + panel.height;
            if (outsidePanel)
                root.closeDisplayManager();
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

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 12

            Row {
                width: parent.width
                height: 58
                spacing: 12

                StyledRect {
                    width: 52
                    height: 52
                    radius: Tokens.rounding.extraLarge
                    color: Colours.palette.m3primaryContainer
                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "desktop_windows"
                        fill: 1
                        color: Colours.palette.m3onPrimaryContainer
                        fontStyle: Tokens.font.icon.extraLarge
                    }
                }

                Column {
                    width: parent.width - 52 - refreshButton.width - resetButton.width - closeButton.width - 48
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    StyledText {
                        width: parent.width
                        text: qsTr("Display Manager")
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.title.large
                    }
                    StyledText {
                        width: parent.width
                        text: root.statusText
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.medium
                        elide: Text.ElideRight
                    }
                    StyledText {
                        width: parent.width
                        text: qsTr("Edit safely · P validates · Preview is temporary · Keep confirms · Save persists")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                StyledRect {
                    id: refreshButton
                    width: 44; height: 44
                    anchors.verticalCenter: parent.verticalCenter
                    radius: Tokens.rounding.large
                    color: Colours.palette.m3surfaceContainerHighest
                    StateLayer { radius: parent.radius; onClicked: root.refresh() }
                    MaterialIcon { anchors.centerIn: parent; text: probe.running ? "progress_activity" : "refresh"; color: Colours.palette.m3primary }
                }
                StyledRect {
                    id: resetButton
                    width: 44; height: 44
                    anchors.verticalCenter: parent.verticalCenter
                    radius: Tokens.rounding.large
                    color: Colours.palette.m3surfaceContainerHighest
                    StateLayer { radius: parent.radius; onClicked: root.resetCandidate() }
                    MaterialIcon { anchors.centerIn: parent; text: "restart_alt"; color: Colours.palette.m3onSurfaceVariant }
                }
                StyledRect {
                    id: closeButton
                    width: 44; height: 44
                    anchors.verticalCenter: parent.verticalCenter
                    radius: Tokens.rounding.large
                    color: Colours.palette.m3surfaceContainerHighest
                    StateLayer { radius: parent.radius; onClicked: root.closeDisplayManager() }
                    MaterialIcon { anchors.centerIn: parent; text: "close"; color: Colours.palette.m3onSurfaceVariant }
                }
            }

            Row {
                width: parent.width
                height: 320
                spacing: 12

                StyledRect {
                    id: topologyCard
                    width: parent.width * 0.60
                    height: parent.height
                    radius: Tokens.rounding.extraLarge
                    color: Colours.palette.m3surfaceContainer
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant

                    StyledText {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: 14
                        text: qsTr("Topology candidate")
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.title.small
                    }

                    Item {
                        id: topologyCanvas
                        anchors.fill: parent
                        anchors.margins: 18
                        anchors.topMargin: 48
                        readonly property var bounds: root.layoutBounds()
                        readonly property real factor: root.topologyScale(width, height)

                        Repeater {
                            model: root.candidateOutputs
                            delegate: StyledRect {
                                id: outputRect
                                required property var modelData
                                required property int index
                                readonly property var modeSize: root.parseMode(modelData?.mode)
                                readonly property real logicalWidth: modeSize.width / Math.max(0.5, Number(modelData?.scale ?? 1))
                                readonly property real logicalHeight: modeSize.height / Math.max(0.5, Number(modelData?.scale ?? 1))
                                x: 18 + (Number(modelData?.x ?? 0) - topologyCanvas.bounds.minX) * topologyCanvas.factor
                                y: 18 + (Number(modelData?.y ?? 0) - topologyCanvas.bounds.minY) * topologyCanvas.factor
                                width: Math.max(90, logicalWidth * topologyCanvas.factor)
                                height: Math.max(54, logicalHeight * topologyCanvas.factor)
                                visible: modelData?.enabled ?? true
                                radius: Tokens.rounding.large
                                color: root.selectedIndex === index ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHighest
                                border.width: root.selectedIndex === index ? 2 : 1
                                border.color: root.selectedIndex === index ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
                                StateLayer { radius: parent.radius; onClicked: root.selectedIndex = outputRect.index }
                                Column {
                                    anchors.centerIn: parent
                                    width: parent.width - 16
                                    spacing: 2
                                    StyledText {
                                        width: parent.width
                                        text: outputRect.modelData?.name ?? ""
                                        color: root.selectedIndex === outputRect.index ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                        font: Tokens.font.label.medium
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }
                                    StyledText {
                                        width: parent.width
                                        text: String(outputRect.modelData?.mode ?? "")
                                        color: Colours.palette.m3onSurfaceVariant
                                        font: Tokens.font.label.small
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }

                StyledRect {
                    width: parent.width - topologyCard.width - 12
                    height: parent.height
                    radius: Tokens.rounding.extraLarge
                    color: Colours.palette.m3surfaceContainer
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant

                    Column {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 7

                        Row {
                            width: parent.width
                            StyledText {
                                width: parent.width * 0.70
                                text: root.selectedCandidate?.name ?? qsTr("No output")
                                color: Colours.palette.m3onSurface
                                font: Tokens.font.title.medium
                            }
                            StyledText {
                                width: parent.width * 0.30
                                text: root.selectedLive?.gpu_vendor ?? "—"
                                color: Colours.palette.m3primary
                                font: Tokens.font.label.medium
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                        StyledText {
                            width: parent.width
                            text: root.selectedLive?.description ?? ""
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }

                        Row {
                            width: parent.width
                            height: 34
                            spacing: 7
                            Repeater {
                                model: [
                                    { label: qsTr("Laptop"), action: () => root.applyLaptopPreset() },
                                    { label: qsTr("Dual"), action: () => root.applyDualPreset() },
                                    { label: qsTr("External"), action: () => root.applyExternalPreset() }
                                ]
                                delegate: StyledRect {
                                    required property var modelData
                                    width: (parent.width - 14) / 3
                                    height: 34
                                    radius: Tokens.rounding.medium
                                    color: Colours.palette.m3surfaceContainerHigh
                                    StateLayer { radius: parent.radius; onClicked: modelData.action() }
                                    StyledText { anchors.centerIn: parent; text: modelData.label; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small }
                                }
                            }
                        }

                        Row {
                            width: parent.width; height: 42; spacing: 8
                            StyledRect {
                                width: 42; height: 42; radius: Tokens.rounding.large; color: Colours.palette.m3surfaceContainerHigh
                                StateLayer { radius: parent.radius; onClicked: root.cycleMode(-1) }
                                MaterialIcon { anchors.centerIn: parent; text: "chevron_left"; color: Colours.palette.m3onSurfaceVariant }
                            }
                            StyledRect {
                                width: parent.width - 92; height: 42; radius: Tokens.rounding.large; color: Colours.palette.m3surfaceContainerHigh
                                StyledText { anchors.centerIn: parent; width: parent.width - 12; text: root.selectedCandidate?.mode ?? "—"; color: Colours.palette.m3onSurface; font: Tokens.font.label.medium; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideMiddle }
                            }
                            StyledRect {
                                width: 42; height: 42; radius: Tokens.rounding.large; color: Colours.palette.m3surfaceContainerHigh
                                StateLayer { radius: parent.radius; onClicked: root.cycleMode(1) }
                                MaterialIcon { anchors.centerIn: parent; text: "chevron_right"; color: Colours.palette.m3onSurfaceVariant }
                            }
                        }

                        Repeater {
                            model: [
                                { label: qsTr("Scale"), value: Number(root.selectedCandidate?.scale ?? 1).toFixed(2), minus: () => root.updateSelected("scale", Math.max(0.5, Number(root.selectedCandidate?.scale ?? 1) - 0.25)), plus: () => root.updateSelected("scale", Math.min(3, Number(root.selectedCandidate?.scale ?? 1) + 0.25)) },
                                { label: qsTr("X position"), value: String(root.selectedCandidate?.x ?? 0), minus: () => root.updateSelected("x", Number(root.selectedCandidate?.x ?? 0) - 100), plus: () => root.updateSelected("x", Number(root.selectedCandidate?.x ?? 0) + 100) },
                                { label: qsTr("Y position"), value: String(root.selectedCandidate?.y ?? 0), minus: () => root.updateSelected("y", Number(root.selectedCandidate?.y ?? 0) - 100), plus: () => root.updateSelected("y", Number(root.selectedCandidate?.y ?? 0) + 100) },
                                { label: qsTr("Transform"), value: String(root.selectedCandidate?.transform ?? 0), minus: () => root.cycleTransform(-1), plus: () => root.cycleTransform(1) }
                            ]
                            delegate: Row {
                                required property var modelData
                                width: parent.width; height: 31; spacing: 7
                                StyledText { width: parent.width * 0.36; anchors.verticalCenter: parent.verticalCenter; text: modelData.label; color: Colours.palette.m3outline; font: Tokens.font.label.small }
                                StyledRect {
                                    width: 30; height: 30; radius: Tokens.rounding.medium; color: Colours.palette.m3surfaceContainerHigh
                                    StateLayer { radius: parent.radius; onClicked: modelData.minus() }
                                    MaterialIcon { anchors.centerIn: parent; text: "remove"; color: Colours.palette.m3onSurfaceVariant; fontStyle: Tokens.font.icon.small }
                                }
                                StyledText { width: parent.width * 0.28; anchors.verticalCenter: parent.verticalCenter; text: modelData.value; color: Colours.palette.m3onSurface; font: Tokens.font.label.medium; horizontalAlignment: Text.AlignHCenter }
                                StyledRect {
                                    width: 30; height: 30; radius: Tokens.rounding.medium; color: Colours.palette.m3surfaceContainerHigh
                                    StateLayer { radius: parent.radius; onClicked: modelData.plus() }
                                    MaterialIcon { anchors.centerIn: parent; text: "add"; color: Colours.palette.m3onSurfaceVariant; fontStyle: Tokens.font.icon.small }
                                }
                            }
                        }

                        StyledRect {
                            width: parent.width
                            height: 32
                            radius: Tokens.rounding.medium
                            color: (root.selectedCandidate?.enabled ?? true) ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHighest
                            StateLayer { radius: parent.radius; onClicked: root.toggleSelectedEnabled() }
                            Row {
                                anchors.centerIn: parent
                                spacing: 7
                                MaterialIcon { text: (root.selectedCandidate?.enabled ?? true) ? "toggle_on" : "toggle_off"; color: (root.selectedCandidate?.enabled ?? true) ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3outline }
                                StyledText { text: (root.selectedCandidate?.enabled ?? true) ? qsTr("Output enabled") : qsTr("Output disabled"); color: (root.selectedCandidate?.enabled ?? true) ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3outline; font: Tokens.font.label.small }
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: 168
                spacing: 10

                Repeater {
                    model: root.candidateOutputs
                    delegate: StyledRect {
                        id: outputCard
                        required property var modelData
                        required property int index
                        width: Math.max(220, (parent.width - 10 * Math.max(0, root.candidateOutputs.length - 1)) / Math.max(1, root.candidateOutputs.length))
                        height: parent.height
                        radius: Tokens.rounding.extraLarge
                        color: root.selectedIndex === index ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainer
                        border.width: root.selectedIndex === index ? 1 : 0
                        border.color: Colours.palette.m3primary
                        opacity: outputCard.modelData?.enabled ?? true ? 1 : 0.58
                        StateLayer { radius: parent.radius; onClicked: root.selectedIndex = outputCard.index }
                        Column {
                            anchors.fill: parent; anchors.margins: 13; spacing: 5
                            StyledText { text: outputCard.modelData?.name ?? ""; color: root.selectedIndex === outputCard.index ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface; font: Tokens.font.title.small }
                            StyledText { width: parent.width; text: String(outputCard.modelData?.mode ?? ""); color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small; elide: Text.ElideRight }
                            StyledText { text: `${outputCard.modelData?.x ?? 0} × ${outputCard.modelData?.y ?? 0} · scale ${Number(outputCard.modelData?.scale ?? 1).toFixed(2)} · transform ${outputCard.modelData?.transform ?? 0}`; color: Colours.palette.m3outline; font: Tokens.font.label.small }
                            StyledText { text: `${root.liveByName(outputCard.modelData?.name)?.gpu_vendor ?? "—"} · ${root.liveByName(outputCard.modelData?.name)?.drm_card ?? "—"}`; color: Colours.palette.m3primary; font: Tokens.font.label.small }
                            StyledText { text: `${root.liveByName(outputCard.modelData?.name)?.workspace?.name ?? qsTr("no workspace")} · ${(outputCard.modelData?.enabled ?? true) ? qsTr("enabled") : qsTr("disabled")}`; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: parent.height - 58 - 320 - 168 - 36
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                Row {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    Column {
                        width: parent.width * 0.66
                        height: parent.height
                        spacing: 5
                        StyledText { text: qsTr("Dry-run plan"); color: Colours.palette.m3onSurface; font: Tokens.font.title.small }
                        StyledText { width: parent.width; text: root.planStatus; color: root.planResult?.ok ? Colours.palette.m3primary : Colours.palette.m3outline; font: Tokens.font.label.medium; elide: Text.ElideRight }
                        StyledText {
                            width: parent.width
                            height: parent.height - 46
                            text: root.planResult?.ok
                                ? (root.planResult?.hypr_lines ?? []).join("\n")
                                : ((root.planResult?.errors ?? []).concat(root.planResult?.warnings ?? [])).join("\n")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                            wrapMode: Text.WrapAnywhere
                            elide: Text.ElideRight
                        }
                    }

                    Column {
                        width: parent.width * 0.34 - 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 9
                        StyledRect {
                            width: parent.width; height: 46; radius: Tokens.rounding.large
                            color: Colours.palette.m3primaryContainer
                            StateLayer { radius: parent.radius; onClicked: root.runPlan() }
                            Row { anchors.centerIn: parent; spacing: 7
                                MaterialIcon { text: "fact_check"; color: Colours.palette.m3onPrimaryContainer }
                                StyledText { text: planner.running ? qsTr("Validating…") : qsTr("Dry run candidate"); color: Colours.palette.m3onPrimaryContainer; font: Tokens.font.label.medium }
                            }
                        }
                        StyledText {
                            width: parent.width
                            text: qsTr("Dry run never changes outputs. Use Preview for a timed live test, Keep to confirm it, then Save to persist with backup/rollback.")
                            color: Colours.palette.m3outline
                            font: Tokens.font.body.small
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}
