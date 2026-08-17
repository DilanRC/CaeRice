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

    required property var contentItem

    property string statusText: qsTr("Save the profile, then copy its Steam Launch Options")
    property string optionsText: ""
    property string actionKind: ""
    readonly property string helperPath: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/caerice-gaming-profile"
    readonly property string appid: String(contentItem?.selectedAppId ?? "")
    readonly property string gameName: String(contentItem?.selectedName ?? "")
    readonly property var profile: contentItem?.profile ?? ({})

    radius: Tokens.rounding.extraLarge
    color: Colours.palette.m3surfaceContainer
    border.width: 1
    border.color: Colours.palette.m3outlineVariant

    function run(kind, args): void {
        if (worker.running || !appid.length)
            return;
        actionKind = kind;
        worker.command = [helperPath, kind, "--appid", appid, "--name", gameName].concat(args ?? []);
        worker.running = true;
    }

    function save(): void {
        statusText = qsTr("Validating and saving profile…");
        run("set", ["--json", JSON.stringify(profile)]);
    }

    function copyOptions(): void {
        statusText = qsTr("Copying Steam Launch Options…");
        run("copy", []);
    }

    function openGame(): void {
        statusText = qsTr("Opening game through Steam normally…");
        run("open", []);
    }

    function refreshPreview(): void {
        run("get", []);
    }

    onAppidChanged: {
        optionsText = "";
        if (appid.length)
            Qt.callLater(refreshPreview);
    }

    Component.onCompleted: {
        if (appid.length)
            refreshPreview();
    }

    Process {
        id: worker
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim());
                    if (parsed?.profile)
                        root.contentItem.profile = parsed.profile;
                    if (parsed?.launch_options !== undefined)
                        root.optionsText = parsed.launch_options ?? "";
                    if (!(parsed?.ok ?? false))
                        root.statusText = parsed?.error ?? qsTr("Gaming profile action failed");
                    else if (parsed?.saved)
                        root.statusText = qsTr("Profile saved · copy these Launch Options into Steam Properties");
                    else if (parsed?.copied)
                        root.statusText = qsTr("Launch Options copied · paste them into this game's Steam Properties");
                    else if (parsed?.opened)
                        root.statusText = qsTr("Game opened normally in Steam · CaeRice does not pretend wrappers propagate through the client");
                    else if (parsed?.ready === false)
                        root.statusText = parsed?.error ?? qsTr("Profile requires a missing tool");
                    else
                        root.statusText = qsTr("Launch Options preview ready");
                } catch (error) {
                    root.statusText = qsTr("Gaming helper returned invalid JSON");
                }
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        StyledText {
            width: parent.width
            text: qsTr("Steam integration")
            color: Colours.palette.m3onSurface
            font: Tokens.font.title.small
        }

        StyledText {
            width: parent.width
            text: root.statusText
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }

        StyledRect {
            width: parent.width
            height: 92
            radius: Tokens.rounding.large
            color: Colours.palette.m3surfaceContainerHigh
            border.width: 1
            border.color: Colours.palette.m3outlineVariant

            StyledText {
                anchors.fill: parent
                anchors.margins: 10
                text: root.optionsText.length ? root.optionsText : qsTr("No generated Launch Options yet")
                color: root.optionsText.length ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3outline
                font: Tokens.font.body.small
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 5
                elide: Text.ElideRight
            }
        }

        StyledRect {
            width: parent.width
            height: 44
            radius: Tokens.rounding.large
            color: Colours.palette.m3primaryContainer
            enabled: root.appid.length > 0 && !worker.running
            opacity: enabled ? 1 : 0.5
            StateLayer { radius: parent.radius; onClicked: root.save() }
            StyledText { anchors.centerIn: parent; text: qsTr("Save profile"); color: Colours.palette.m3onPrimaryContainer; font: Tokens.font.label.medium }
        }

        StyledRect {
            width: parent.width
            height: 44
            radius: Tokens.rounding.large
            color: Colours.palette.m3secondaryContainer
            enabled: root.appid.length > 0 && !worker.running
            opacity: enabled ? 1 : 0.5
            StateLayer { radius: parent.radius; onClicked: root.copyOptions() }
            Row {
                anchors.centerIn: parent
                spacing: 7
                MaterialIcon { text: "content_copy"; color: Colours.palette.m3onSecondaryContainer }
                StyledText { text: qsTr("Copy Steam Launch Options"); color: Colours.palette.m3onSecondaryContainer; font: Tokens.font.label.medium }
            }
        }

        StyledRect {
            width: parent.width
            height: 44
            radius: Tokens.rounding.large
            color: Colours.palette.m3tertiaryContainer
            enabled: root.appid.length > 0 && !worker.running
            opacity: enabled ? 1 : 0.5
            StateLayer { radius: parent.radius; onClicked: root.openGame() }
            StyledText { anchors.centerIn: parent; text: qsTr("Open game in Steam"); color: Colours.palette.m3onTertiaryContainer; font: Tokens.font.label.medium }
        }

        StyledText {
            width: parent.width
            text: qsTr("CaeRice never edits Steam VDF compatibility data. The generated %command% chain follows Steam's Launch Options model.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }
    }
}
