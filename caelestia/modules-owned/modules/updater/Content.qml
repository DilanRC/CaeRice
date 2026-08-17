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
    required property bool updaterVisible

    property string refText: "v2.3.0"
    property var result: ({})
    property string phase: "status"
    property string statusText: qsTr("Ready · package updates remain separate")
    readonly property string updaterPath: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/caerice-updater"
    readonly property var report: result?.report ?? (phase === "test" ? result : ({}))

    function closeUpdater(): void { screenState.updaterCenter = false; }
    function openUpdater(): void { forceActiveFocus(); run("status", []); }
    function run(name, args): void {
        if (worker.running) return;
        phase = name; statusText = qsTr("Running %1…").arg(name);
        worker.command = [updaterPath, name].concat(args);
        worker.running = true;
    }
    function openApplyTerminal(): void {
        if (!refText.trim().length) return;
        Quickshell.execDetached(["kitty", "--hold", "--title", "CaeRice Updater apply", updaterPath, "apply", "--ref", refText.trim(), "--confirm", "APPLY"]);
        statusText = qsTr("Apply opened in a terminal so sudo can be reviewed and authenticated");
    }
    function openRollbackTerminal(): void {
        Quickshell.execDetached(["kitty", "--hold", "--title", "CaeRice Updater rollback", updaterPath, "rollback"]);
        statusText = qsTr("Rollback opened in a terminal");
    }

    Keys.onEscapePressed: closeUpdater()
    Keys.onPressed: event => { if (event.key === Qt.Key_R) { run("status", []); event.accepted = true; } }

    Process {
        id: worker
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim());
                    root.result = parsed;
                    if (root.phase === "discover" && parsed?.patch_base?.upstream_tag)
                        root.refText = parsed.patch_base.upstream_tag;
                    if (parsed?.ok === false)
                        root.statusText = parsed?.error ?? qsTr("Updater phase failed");
                    else if (root.phase === "fetch")
                        root.statusText = qsTr("Candidate fetched · %1").arg(parsed?.commit ?? "");
                    else if (root.phase === "test")
                        root.statusText = parsed?.ok ? qsTr("Dry run clean · no blocking patch conflicts") : qsTr("Dry run has blockers");
                    else
                        root.statusText = qsTr("%1 complete").arg(root.phase);
                } catch (error) {
                    root.statusText = qsTr("Updater returned invalid JSON");
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
            const outside = mouse.x < panel.x || mouse.x >= panel.x + panel.width || mouse.y < panel.y || mouse.y >= panel.y + panel.height;
            if (outside) root.closeUpdater();
        }
    }

    StyledRect {
        id: panel
        width: Math.min(1220, parent.width - 96)
        height: Math.min(880, parent.height - 64)
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
                width: parent.width; height: 58; spacing: 12
                StyledRect { width: 52; height: 52; radius: Tokens.rounding.extraLarge; color: Colours.palette.m3primaryContainer; MaterialIcon { anchors.centerIn: parent; text: "system_update_alt"; fill: 1; color: Colours.palette.m3onPrimaryContainer; fontStyle: Tokens.font.icon.extraLarge } }
                Column {
                    width: parent.width - 52 - 108; anchors.verticalCenter: parent.verticalCenter
                    StyledText { width: parent.width; text: qsTr("CaeRice Updater"); color: Colours.palette.m3onSurface; font: Tokens.font.title.large }
                    StyledText { width: parent.width; text: root.statusText; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.medium; elide: Text.ElideRight }
                    StyledText { width: parent.width; text: qsTr("Discover → Fetch → Test → package update separately → Snapshot → Apply → Verify/Rollback"); color: Colours.palette.m3outline; font: Tokens.font.label.small; elide: Text.ElideRight }
                }
                StyledRect { width: 44; height: 44; anchors.verticalCenter: parent.verticalCenter; radius: Tokens.rounding.large; color: Colours.palette.m3surfaceContainerHighest; StateLayer { radius: parent.radius; onClicked: root.run("status", []) }; MaterialIcon { anchors.centerIn: parent; text: "refresh"; color: Colours.palette.m3primary } }
                StyledRect { width: 44; height: 44; anchors.verticalCenter: parent.verticalCenter; radius: Tokens.rounding.large; color: Colours.palette.m3surfaceContainerHighest; StateLayer { radius: parent.radius; onClicked: root.closeUpdater() }; MaterialIcon { anchors.centerIn: parent; text: "close"; color: Colours.palette.m3onSurfaceVariant } }
            }

            Row {
                width: parent.width; height: 54; spacing: 8
                StyledRect {
                    width: parent.width * 0.34; height: 48; radius: Tokens.rounding.large; color: Colours.palette.m3surfaceContainer
                    StyledText { anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; visible: refInput.text.length === 0; text: qsTr("upstream ref/tag"); color: Colours.palette.m3outline; font: Tokens.font.body.medium }
                    TextInput { id: refInput; anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; verticalAlignment: TextInput.AlignVCenter; text: root.refText; color: Colours.palette.m3onSurface; selectionColor: Colours.palette.m3primary; onTextChanged: root.refText = text }
                }
                Repeater {
                    model: [
                        {label:qsTr("Discover"), action:() => root.run("discover", [])},
                        {label:qsTr("Fetch"), action:() => root.run("fetch", ["--ref", root.refText.trim()])},
                        {label:qsTr("Test"), action:() => root.run("test", ["--ref", root.refText.trim()])}
                    ]
                    delegate: StyledRect {
                        required property var modelData
                        width: (parent.width * 0.40 - 16) / 3; height: 48; radius: Tokens.rounding.large; color: Colours.palette.m3secondaryContainer
                        enabled: !worker.running; opacity: enabled ? 1 : 0.55
                        StateLayer { radius: parent.radius; onClicked: modelData.action() }
                        StyledText { anchors.centerIn: parent; text: modelData.label; color: Colours.palette.m3onSecondaryContainer; font: Tokens.font.label.medium }
                    }
                }
                StyledRect { width: parent.width * 0.13 - 4; height: 48; radius: Tokens.rounding.large; color: Colours.palette.m3tertiaryContainer; StateLayer { radius: parent.radius; onClicked: root.openApplyTerminal() }; StyledText { anchors.centerIn: parent; text: qsTr("Apply terminal"); color: Colours.palette.m3onTertiaryContainer; font: Tokens.font.label.small } }
                StyledRect { width: parent.width * 0.13 - 4; height: 48; radius: Tokens.rounding.large; color: Colours.palette.m3errorContainer; StateLayer { radius: parent.radius; onClicked: root.openRollbackTerminal() }; StyledText { anchors.centerIn: parent; text: qsTr("Rollback"); color: Colours.palette.m3onErrorContainer; font: Tokens.font.label.small } }
            }

            Row {
                width: parent.width; height: 142; spacing: 10
                Repeater {
                    model: [
                        {title:qsTr("Patch base"), value: root.result?.patch_base?.upstream_tag ?? root.result?.base?.upstream_tag ?? "—", sub: root.result?.patch_base?.upstream_commit ?? root.result?.base?.upstream_commit ?? ""},
                        {title:qsTr("Candidate"), value: root.result?.candidate_commit ?? root.result?.state?.candidate_commit ?? "—", sub: root.result?.ref ?? root.result?.state?.candidate_ref ?? ""},
                        {title:qsTr("Blockers"), value: String(root.report?.blockers ?? 0), sub: root.report?.ok ? qsTr("dry run clean") : qsTr("review required")},
                        {title:qsTr("Snapshot"), value: root.result?.state?.last_snapshot ? qsTr("available") : qsTr("none"), sub: root.result?.state?.last_snapshot ?? ""}
                    ]
                    delegate: StyledRect {
                        required property var modelData
                        width: (parent.width - 30) / 4; height: 142; radius: Tokens.rounding.extraLarge; color: Colours.palette.m3surfaceContainer; border.width: 1; border.color: Colours.palette.m3outlineVariant
                        Column { anchors.fill: parent; anchors.margins: 14; spacing: 6
                            StyledText { text: modelData.title; color: Colours.palette.m3outline; font: Tokens.font.label.small }
                            StyledText { width: parent.width; text: modelData.value; color: Colours.palette.m3onSurface; font: Tokens.font.title.medium; elide: Text.ElideMiddle }
                            StyledText { width: parent.width; text: modelData.sub; color: Colours.palette.m3primary; font: Tokens.font.label.small; elide: Text.ElideMiddle }
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width; height: parent.height - 58 - 54 - 142 - 48; radius: Tokens.rounding.extraLarge; color: Colours.palette.m3surfaceContainer; border.width: 1; border.color: Colours.palette.m3outlineVariant
                Column { anchors.fill: parent; anchors.margins: 14; spacing: 8
                    Row { width: parent.width; height: 28
                        StyledText { width: parent.width * 0.35; text: qsTr("Patch"); color: Colours.palette.m3outline; font: Tokens.font.label.small }
                        StyledText { width: parent.width * 0.35; text: qsTr("Target"); color: Colours.palette.m3outline; font: Tokens.font.label.small }
                        StyledText { width: parent.width * 0.20; text: qsTr("Status"); color: Colours.palette.m3outline; font: Tokens.font.label.small }
                        StyledText { width: parent.width * 0.10; text: qsTr("Blocking"); color: Colours.palette.m3outline; font: Tokens.font.label.small; horizontalAlignment: Text.AlignRight }
                    }
                    Flickable {
                        width: parent.width; height: parent.height - 42; contentHeight: patchColumn.height; clip: true
                        Column {
                            id: patchColumn; width: parent.width; spacing: 4
                            Repeater {
                                model: root.report?.patches ?? root.result?.patches ?? []
                                delegate: StyledRect {
                                    required property var modelData
                                    width: patchColumn.width; height: 38; radius: Tokens.rounding.medium
                                    color: modelData?.status === "conflict" || modelData?.status === "missing" ? Colours.palette.m3errorContainer : Colours.palette.m3surfaceContainerHigh
                                    Row { anchors.fill: parent; anchors.margins: 8
                                        StyledText { width: parent.width * 0.35; anchors.verticalCenter: parent.verticalCenter; text: modelData?.patch ?? modelData?.name ?? ""; color: Colours.palette.m3onSurface; font: Tokens.font.label.small; elide: Text.ElideRight }
                                        StyledText { width: parent.width * 0.35; anchors.verticalCenter: parent.verticalCenter; text: modelData?.target ?? ""; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small; elide: Text.ElideRight }
                                        StyledText { width: parent.width * 0.20; anchors.verticalCenter: parent.verticalCenter; text: modelData?.status ?? qsTr("inventory"); color: modelData?.status === "conflict" ? Colours.palette.m3onErrorContainer : Colours.palette.m3primary; font: Tokens.font.label.small }
                                        StyledText { width: parent.width * 0.10; anchors.verticalCenter: parent.verticalCenter; text: modelData?.status === "conflict" || modelData?.status === "missing" ? qsTr("YES") : "—"; color: Colours.palette.m3onErrorContainer; font: Tokens.font.label.small; horizontalAlignment: Text.AlignRight }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
