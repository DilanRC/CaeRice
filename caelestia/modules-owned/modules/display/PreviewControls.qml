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

    readonly property string transactionPath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/caerice-display-transaction"
    readonly property bool active: previewState?.active ?? false
    readonly property real remaining: Number(previewState?.remaining_seconds ?? 0)

    radius: Tokens.rounding.extraLarge
    color: Colours.palette.m3surfaceContainerHigh
    border.width: 1
    border.color: root.active ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

    function refresh(): void {
        if (!statusProbe.running)
            statusProbe.running = true;
    }

    function run(args): void {
        if (action.running)
            return;
        action.command = [transactionPath].concat(args);
        action.running = true;
    }

    function startPreview(): void {
        if (!candidateOutputs.length)
            return;
        statusText = qsTr("Starting 15 second preview…");
        run(["preview", "--timeout", "15", "--candidate", JSON.stringify({ outputs: candidateOutputs })]);
    }

    function confirm(): void {
        statusText = qsTr("Keeping preview for this session…");
        run(["confirm"]);
    }

    function revert(): void {
        statusText = qsTr("Restoring previous layout…");
        run(["revert"]);
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 500
        repeat: true
        running: root.active
        onTriggered: root.refresh()
    }

    Process {
        id: statusProbe
        command: [root.transactionPath, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim());
                    root.previewState = parsed;
                    if (parsed?.active)
                        root.statusText = qsTr("Preview active · auto-revert in %1 s").arg(Number(parsed?.remaining_seconds ?? 0).toFixed(1));
                    else if (!action.running && !(root.lastResult?.confirmed ?? false))
                        root.statusText = qsTr("No active preview");
                } catch (error) {
                    root.statusText = qsTr("Preview status unavailable");
                }
            }
        }
    }

    Process {
        id: action
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim());
                    root.lastResult = parsed;
                    if (parsed?.ok && parsed?.preview)
                        root.statusText = qsTr("Preview applied · confirm or it will revert automatically");
                    else if (parsed?.ok && parsed?.confirmed)
                        root.statusText = qsTr("Layout kept for this Hyprland session · not persisted yet");
                    else if (parsed?.ok && parsed?.reverted)
                        root.statusText = qsTr("Previous layout restored");
                    else if (!(parsed?.ok ?? false))
                        root.statusText = parsed?.error ?? qsTr("Display action failed");
                } catch (error) {
                    root.statusText = qsTr("Display transaction returned invalid JSON");
                }
                root.refresh();
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 7

        Row {
            width: parent.width
            height: 24

            StyledText {
                width: parent.width * 0.58
                text: qsTr("Timed preview")
                color: Colours.palette.m3onSurface
                font: Tokens.font.title.small
            }

            StyledText {
                width: parent.width * 0.42
                text: root.active ? qsTr("%1 s").arg(root.remaining.toFixed(1)) : qsTr("safe rollback")
                color: root.active ? Colours.palette.m3primary : Colours.palette.m3outline
                font: Tokens.font.label.small
                horizontalAlignment: Text.AlignRight
            }
        }

        StyledText {
            width: parent.width
            height: 34
            text: root.statusText
            color: root.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
        }

        Row {
            width: parent.width
            height: 42
            spacing: 7

            StyledRect {
                width: (parent.width - 14) / 3
                height: 42
                radius: Tokens.rounding.large
                color: root.active ? Colours.palette.m3surfaceContainerHighest : Colours.palette.m3primaryContainer
                enabled: !root.active && !action.running
                opacity: enabled ? 1 : 0.55
                StateLayer { radius: parent.radius; onClicked: root.startPreview() }
                StyledText {
                    anchors.centerIn: parent
                    text: qsTr("Preview 15s")
                    color: root.active ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onPrimaryContainer
                    font: Tokens.font.label.medium
                }
            }

            StyledRect {
                width: (parent.width - 14) / 3
                height: 42
                radius: Tokens.rounding.large
                color: root.active ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHighest
                enabled: root.active && !action.running
                opacity: enabled ? 1 : 0.55
                StateLayer { radius: parent.radius; onClicked: root.confirm() }
                StyledText {
                    anchors.centerIn: parent
                    text: qsTr("Keep")
                    color: root.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3outline
                    font: Tokens.font.label.medium
                }
            }

            StyledRect {
                width: (parent.width - 14) / 3
                height: 42
                radius: Tokens.rounding.large
                color: root.active ? Colours.palette.m3errorContainer : Colours.palette.m3surfaceContainerHighest
                enabled: root.active && !action.running
                opacity: enabled ? 1 : 0.55
                StateLayer { radius: parent.radius; onClicked: root.revert() }
                StyledText {
                    anchors.centerIn: parent
                    text: qsTr("Revert")
                    color: root.active ? Colours.palette.m3onErrorContainer : Colours.palette.m3outline
                    font: Tokens.font.label.medium
                }
            }
        }
    }
}
