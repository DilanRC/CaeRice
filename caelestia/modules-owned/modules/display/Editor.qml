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
        StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/caerice-display-probe"
    readonly property string plannerPath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/caerice-display-plan"
    readonly property var monitors: snapshot?.hyprland ?? []
    readonly property var selectedCandidate:
        selectedIndex >= 0 && selectedIndex < candidateOutputs.length ? candidateOutputs[selectedIndex] : ({})
    readonly property var selectedLive: liveByName(selectedCandidate?.name ?? "")

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

    function parseMode(mode): var {
        const match = String(mode ?? "").match(/^(\d+)x(\d+)@?([0-9.]*)/);
        if (!match)
            return ({ width: 1920, height: 1080 });
        return ({ width: Number(match[1]), height: Number(match[2]) });
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
        screenState.displayManager = false;
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
                        text: qsTr("Candidate editor is dry-run only · P validates · no display changes are applied")
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
                        spacing: 9

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
                            width: parent.width; height: 46; spacing: 8
                            StyledRect {
                                width: 46; height: 46; radius: Tokens.rounding.large; color: Colours.palette.m3surfaceContainerHigh
                                StateLayer { radius: parent.radius; onClicked: root.cycleMode(-1) }
                                MaterialIcon { anchors.centerIn: parent; text: "chevron_left"; color: Colours.palette.m3onSurfaceVariant }
                            }
                            StyledRect {
                                width: parent.width - 100; height: 46; radius: Tokens.rounding.large; color: Colours.palette.m3surfaceContainerHigh
                                StyledText { anchors.centerIn: parent; width: parent.width - 12; text: root.selectedCandidate?.mode ?? "—"; color: Colours.palette.m3onSurface; font: Tokens.font.label.medium; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideMiddle }
                            }
                            StyledRect {
                                width: 46; height: 46; radius: Tokens.rounding.large; color: Colours.palette.m3surfaceContainerHigh
                                StateLayer { radius: parent.radius; onClicked: root.cycleMode(1) }
                                MaterialIcon { anchors.centerIn: parent; text: "chevron_right"; color: Colours.palette.m3onSurfaceVariant }
                            }
                        }

                        Repeater {
                            model: [
                                { label: qsTr("Scale"), value: Number(root.selectedCandidate?.scale ?? 1).toFixed(2), minus: () => root.updateSelected("scale", Math.max(0.5, Number(root.selectedCandidate?.scale ?? 1) - 0.25)), plus: () => root.updateSelected("scale", Math.min(3, Number(root.selectedCandidate?.scale ?? 1) + 0.25)) },
                                { label: qsTr("X position"), value: String(root.selectedCandidate?.x ?? 0), minus: () => root.updateSelected("x", Number(root.selectedCandidate?.x ?? 0) - 100), plus: () => root.updateSelected("x", Number(root.selectedCandidate?.x ?? 0) + 100) },
                                { label: qsTr("Y position"), value: String(root.selectedCandidate?.y ?? 0), minus: () => root.updateSelected("y", Number(root.selectedCandidate?.y ?? 0) - 100), plus: () => root.updateSelected("y", Number(root.selectedCandidate?.y ?? 0) + 100) }
                            ]
                            delegate: Row {
                                required property var modelData
                                width: parent.width; height: 36; spacing: 7
                                StyledText { width: parent.width * 0.36; anchors.verticalCenter: parent.verticalCenter; text: modelData.label; color: Colours.palette.m3outline; font: Tokens.font.label.small }
                                StyledRect {
                                    width: 34; height: 34; radius: Tokens.rounding.medium; color: Colours.palette.m3surfaceContainerHigh
                                    StateLayer { radius: parent.radius; onClicked: modelData.minus() }
                                    MaterialIcon { anchors.centerIn: parent; text: "remove"; color: Colours.palette.m3onSurfaceVariant; fontStyle: Tokens.font.icon.small }
                                }
                                StyledText { width: parent.width * 0.28; anchors.verticalCenter: parent.verticalCenter; text: modelData.value; color: Colours.palette.m3onSurface; font: Tokens.font.label.medium; horizontalAlignment: Text.AlignHCenter }
                                StyledRect {
                                    width: 34; height: 34; radius: Tokens.rounding.medium; color: Colours.palette.m3surfaceContainerHigh
                                    StateLayer { radius: parent.radius; onClicked: modelData.plus() }
                                    MaterialIcon { anchors.centerIn: parent; text: "add"; color: Colours.palette.m3onSurfaceVariant; fontStyle: Tokens.font.icon.small }
                                }
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
                        StateLayer { radius: parent.radius; onClicked: root.selectedIndex = outputCard.index }
                        Column {
                            anchors.fill: parent; anchors.margins: 13; spacing: 5
                            StyledText { text: outputCard.modelData?.name ?? ""; color: root.selectedIndex === outputCard.index ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface; font: Tokens.font.title.small }
                            StyledText { width: parent.width; text: String(outputCard.modelData?.mode ?? ""); color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small; elide: Text.ElideRight }
                            StyledText { text: `${outputCard.modelData?.x ?? 0} × ${outputCard.modelData?.y ?? 0} · scale ${Number(outputCard.modelData?.scale ?? 1).toFixed(2)}`; color: Colours.palette.m3outline; font: Tokens.font.label.small }
                            StyledText { text: `${root.liveByName(outputCard.modelData?.name)?.gpu_vendor ?? "—"} · ${root.liveByName(outputCard.modelData?.name)?.drm_card ?? "—"}`; color: Colours.palette.m3primary; font: Tokens.font.label.small }
                            StyledText { text: `${root.liveByName(outputCard.modelData?.name)?.workspace?.name ?? qsTr("no workspace")} · DPMS ${root.liveByName(outputCard.modelData?.name)?.dpms ? qsTr("on") : qsTr("off")}`; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small }
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
                            text: qsTr("No monitor command is executed in this phase. The next phase will add timed Preview → Confirm/Revert.")
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
