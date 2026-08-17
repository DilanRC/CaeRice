pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property var candidateOutputs

    property var previewState: ({ active: false })
    property var lastResult: ({})
    property string statusText: qsTr("No active preview")
    property string actionPath: ""
    property string previewCandidateJson: ""
    property string confirmedCandidateJson: ""

    readonly property string transactionPath: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/caerice-display-transaction"
    readonly property string persistPath: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/caerice-display-persist"
    readonly property bool active: previewState?.active ?? false
    readonly property real remaining: Number(previewState?.remaining_seconds ?? 0)
    readonly property string currentCandidateJson: JSON.stringify({ outputs: candidateOutputs })
    readonly property bool canPersist: !root.active && (root.lastResult?.confirmed ?? false) && root.confirmedCandidateJson.length > 0 && root.confirmedCandidateJson === root.currentCandidateJson

    radius: Tokens.rounding.extraLarge
    color: Colours.palette.m3surfaceContainerHigh
    border.width: 1
    border.color: root.active ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

    function refresh(): void { if (!statusProbe.running) statusProbe.running = true; }
    function runTool(path, args): void {
        if (action.running) return;
        actionPath = path; action.command = [path].concat(args); action.running = true;
    }
    function startPreview(): void {
        if (!candidateOutputs.length) return;
        lastResult = ({}); confirmedCandidateJson = ""; previewCandidateJson = currentCandidateJson;
        statusText = qsTr("Starting 15 second preview…");
        runTool(transactionPath, ["preview", "--timeout", "15", "--candidate", previewCandidateJson]);
    }
    function confirm(): void { statusText = qsTr("Keeping preview for this session…"); runTool(transactionPath, ["confirm"]); }
    function persist(): void {
        if (!canPersist) return;
        statusText = qsTr("Saving layout, color policy and workspace ranges atomically…");
        runTool(persistPath, ["persist", "--candidate", confirmedCandidateJson]);
    }
    function revert(): void { statusText = qsTr("Restoring previous layout…"); confirmedCandidateJson = ""; runTool(transactionPath, ["revert"]); }

    onCurrentCandidateJsonChanged: {
        if (confirmedCandidateJson.length > 0 && confirmedCandidateJson !== currentCandidateJson && !root.active)
            statusText = qsTr("Candidate changed after Keep · preview it again before Save");
    }
    Component.onCompleted: refresh()

    Timer { interval: 500; repeat: true; running: root.active; onTriggered: root.refresh() }

    Process {
        id: statusProbe
        command: [root.transactionPath, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim()); root.previewState = parsed;
                    if (parsed?.active) root.statusText = qsTr("Preview active · auto-revert in %1 s").arg(Number(parsed?.remaining_seconds ?? 0).toFixed(1));
                    else if (!action.running && !(root.lastResult?.confirmed ?? false) && !(root.lastResult?.persisted ?? false)) root.statusText = qsTr("No active preview");
                } catch (error) { root.statusText = qsTr("Preview status unavailable"); }
            }
        }
    }

    Process {
        id: action
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim()); root.lastResult = parsed;
                    if (root.actionPath === root.persistPath) {
                        if (parsed?.ok && parsed?.persisted) {
                            root.statusText = qsTr("Saved atomically · monitors, color policy and 1–10 / 11–20 workspace ranges verified");
                        } else {
                            root.confirmedCandidateJson = "";
                            root.statusText = parsed?.error ?? qsTr("Persistence failed and the pre-Save state was restored");
                        }
                    } else if (parsed?.ok && parsed?.preview) {
                        root.statusText = qsTr("Preview applied · Keep before the countdown expires");
                    } else if (parsed?.ok && parsed?.confirmed) {
                        root.confirmedCandidateJson = root.previewCandidateJson;
                        root.statusText = root.confirmedCandidateJson === root.currentCandidateJson
                            ? qsTr("Session layout kept · Save makes this exact candidate persistent")
                            : qsTr("Session layout kept · candidate changed, preview again before Save");
                    } else if (parsed?.ok && parsed?.reverted) {
                        root.confirmedCandidateJson = "";
                        root.statusText = qsTr("Previous layout, color policy and VRR restored");
                    } else if (!(parsed?.ok ?? false)) {
                        root.confirmedCandidateJson = "";
                        root.statusText = parsed?.error ?? qsTr("Display action failed");
                    }
                } catch (error) {
                    root.confirmedCandidateJson = "";
                    root.statusText = qsTr("Display action returned invalid JSON");
                }
                root.refresh();
            }
        }
    }

    Column {
        anchors.fill: parent; anchors.margins: 12; spacing: 7
        Row {
            width: parent.width; height: 24
            StyledText { width: parent.width * 0.58; text: qsTr("Preview & save"); color: Colours.palette.m3onSurface; font: Tokens.font.title.small }
            StyledText { width: parent.width * 0.42; text: root.active ? qsTr("%1 s").arg(root.remaining.toFixed(1)) : qsTr("rollback protected"); color: root.active ? Colours.palette.m3primary : Colours.palette.m3outline; font: Tokens.font.label.small; horizontalAlignment: Text.AlignRight }
        }
        StyledText { width: parent.width; height: 34; text: root.statusText; color: root.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small; wrapMode: Text.WordWrap; elide: Text.ElideRight }
        Row {
            width: parent.width; height: 42; spacing: 7
            StyledRect { width:(parent.width-21)/4; height:42; radius:Tokens.rounding.large; color:root.active?Colours.palette.m3surfaceContainerHighest:Colours.palette.m3primaryContainer; enabled:!root.active&&!action.running; opacity:enabled?1:0.55; StateLayer{radius:parent.radius;onClicked:root.startPreview()}; StyledText{anchors.centerIn:parent;text:qsTr("Preview");color:root.active?Colours.palette.m3onSurfaceVariant:Colours.palette.m3onPrimaryContainer;font:Tokens.font.label.medium} }
            StyledRect { width:(parent.width-21)/4; height:42; radius:Tokens.rounding.large; color:root.active?Colours.palette.m3secondaryContainer:Colours.palette.m3surfaceContainerHighest; enabled:root.active&&!action.running; opacity:enabled?1:0.55; StateLayer{radius:parent.radius;onClicked:root.confirm()}; StyledText{anchors.centerIn:parent;text:qsTr("Keep");color:root.active?Colours.palette.m3onSecondaryContainer:Colours.palette.m3outline;font:Tokens.font.label.medium} }
            StyledRect { width:(parent.width-21)/4; height:42; radius:Tokens.rounding.large; color:root.canPersist?Colours.palette.m3tertiaryContainer:Colours.palette.m3surfaceContainerHighest; enabled:root.canPersist&&!action.running; opacity:enabled?1:0.55; StateLayer{radius:parent.radius;onClicked:root.persist()}; StyledText{anchors.centerIn:parent;text:qsTr("Save");color:root.canPersist?Colours.palette.m3onTertiaryContainer:Colours.palette.m3outline;font:Tokens.font.label.medium} }
            StyledRect { width:(parent.width-21)/4; height:42; radius:Tokens.rounding.large; color:root.active?Colours.palette.m3errorContainer:Colours.palette.m3surfaceContainerHighest; enabled:root.active&&!action.running; opacity:enabled?1:0.55; StateLayer{radius:parent.radius;onClicked:root.revert()}; StyledText{anchors.centerIn:parent;text:qsTr("Revert");color:root.active?Colours.palette.m3onErrorContainer:Colours.palette.m3outline;font:Tokens.font.label.medium} }
        }
    }
}
