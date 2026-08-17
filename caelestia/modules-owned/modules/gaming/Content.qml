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
    required property bool gamingVisible

    property var snapshot: ({})
    property int page: 0
    property string filterText: ""
    property string selectedAppId: ""
    property string selectedName: ""
    property var profile: ({})
    property string statusText: qsTr("Waiting for gaming inventory…")
    property string actionStatus: ""

    readonly property string probePath: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/caerice-gaming-probe"
    readonly property string profilePath: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/bin/caerice-gaming-profile"
    readonly property var games: filteredGames()

    function filteredGames(): var {
        const source = Array.from(snapshot?.installed_games ?? []);
        const q = filterText.trim().toLowerCase();
        if (!q.length) return source;
        return source.filter(game => `${game?.name ?? ""} ${game?.appid ?? ""}`.toLowerCase().includes(q));
    }

    function closeGamingCenter(): void { screenState.gamingCenter = false; }
    function openGamingCenter(): void { forceActiveFocus(); refresh(); }
    function refresh(): void {
        if (!gamingVisible || probe.running) return;
        statusText = qsTr("Refreshing Steam and runtime inventory…");
        probe.running = true;
    }

    function selectGame(game): void {
        selectedAppId = String(game?.appid ?? "");
        selectedName = String(game?.name ?? "");
        if (!selectedAppId.length) return;
        profileAction.command = [profilePath, "get", "--appid", selectedAppId, "--name", selectedName];
        profileAction.running = true;
    }

    function mutate(field, value): void {
        const next = Object.assign({}, profile);
        next[field] = value;
        profile = next;
        actionStatus = qsTr("Profile changed · Save before launch");
    }

    function cycleGpu(): void {
        const values = ["default", "integrated", "nvidia"];
        let index = values.indexOf(String(profile?.gpu ?? "default"));
        index = (index + 1) % values.length;
        mutate("gpu", values[index]);
    }

    function saveProfile(): void {
        if (!selectedAppId.length || profileAction.running) return;
        profileAction.command = [profilePath, "set", "--appid", selectedAppId, "--name", selectedName, "--json", JSON.stringify(profile)];
        profileAction.running = true;
        actionStatus = qsTr("Saving profile…");
    }

    function launchSelected(): void {
        if (!selectedAppId.length || profileAction.running) return;
        profileAction.command = [profilePath, "launch", "--appid", selectedAppId, "--name", selectedName];
        profileAction.running = true;
        actionStatus = qsTr("Launching saved profile…");
    }

    Keys.onEscapePressed: closeGamingCenter()
    Keys.onPressed: event => {
        if (event.key >= Qt.Key_1 && event.key <= Qt.Key_4) {
            page = event.key - Qt.Key_1;
            event.accepted = true;
        } else if (event.key === Qt.Key_R) {
            refresh(); event.accepted = true;
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
                    root.statusText = qsTr("%1 games · %2 Proton tools · %3 related processes")
                        .arg((parsed?.installed_games ?? []).length)
                        .arg((parsed?.proton_versions ?? []).length)
                        .arg((parsed?.running_related ?? []).length);
                    if (!root.selectedAppId.length && (parsed?.installed_games ?? []).length)
                        root.selectGame(parsed.installed_games[0]);
                } catch (error) {
                    root.statusText = qsTr("Gaming probe returned invalid JSON");
                }
            }
        }
    }

    Process {
        id: profileAction
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim());
                    if (parsed?.profile)
                        root.profile = parsed.profile;
                    if (parsed?.launched)
                        root.actionStatus = qsTr("Launched %1 · PID %2").arg(parsed?.profile?.name ?? root.selectedName).arg(parsed?.pid ?? "—");
                    else if (parsed?.saved)
                        root.actionStatus = qsTr("Profile saved · exact launch command ready");
                    else if (!(parsed?.ok ?? false))
                        root.actionStatus = parsed?.error ?? qsTr("Gaming action failed");
                    else if (parsed?.command)
                        root.actionStatus = parsed.command;
                } catch (error) {
                    root.actionStatus = qsTr("Gaming helper returned invalid JSON");
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
            const outside = mouse.x < panel.x || mouse.x >= panel.x + panel.width || mouse.y < panel.y || mouse.y >= panel.y + panel.height;
            if (outside) root.closeGamingCenter();
        }
    }

    StyledRect {
        id: panel
        width: Math.min(1240, parent.width - 96)
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
                width: parent.width; height: 58; spacing: 12
                StyledRect {
                    width: 52; height: 52; radius: Tokens.rounding.extraLarge; color: Colours.palette.m3primaryContainer
                    MaterialIcon { anchors.centerIn: parent; text: "sports_esports"; fill: 1; color: Colours.palette.m3onPrimaryContainer; fontStyle: Tokens.font.icon.extraLarge }
                }
                Column {
                    width: parent.width - 52 - 108; anchors.verticalCenter: parent.verticalCenter; spacing: 0
                    StyledText { width: parent.width; text: qsTr("Gaming Center"); color: Colours.palette.m3onSurface; font: Tokens.font.title.large }
                    StyledText { width: parent.width; text: root.statusText; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.medium; elide: Text.ElideRight }
                    StyledText { width: parent.width; text: qsTr("Per-game profiles only · no overclock, undervolt, fan or global power changes"); color: Colours.palette.m3outline; font: Tokens.font.label.small; elide: Text.ElideRight }
                }
                StyledRect {
                    width: 44; height: 44; anchors.verticalCenter: parent.verticalCenter; radius: Tokens.rounding.large; color: Colours.palette.m3surfaceContainerHighest
                    StateLayer { radius: parent.radius; onClicked: root.refresh() }
                    MaterialIcon { anchors.centerIn: parent; text: probe.running ? "progress_activity" : "refresh"; color: Colours.palette.m3primary }
                }
                StyledRect {
                    width: 44; height: 44; anchors.verticalCenter: parent.verticalCenter; radius: Tokens.rounding.large; color: Colours.palette.m3surfaceContainerHighest
                    StateLayer { radius: parent.radius; onClicked: root.closeGamingCenter() }
                    MaterialIcon { anchors.centerIn: parent; text: "close"; color: Colours.palette.m3onSurfaceVariant }
                }
            }

            Row {
                width: parent.width; height: 42; spacing: 7
                Repeater {
                    model: [{icon:"dashboard",label:qsTr("1 Dashboard")},{icon:"library_books",label:qsTr("2 Library")},{icon:"tune",label:qsTr("3 Profile")},{icon:"monitoring",label:qsTr("4 Runtime")}]
                    delegate: StyledRect {
                        required property var modelData
                        required property int index
                        width: (parent.width - 21) / 4; height: 42; radius: Tokens.rounding.large
                        color: root.page === index ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainer
                        StateLayer { radius: parent.radius; onClicked: root.page = index }
                        Row { anchors.centerIn: parent; spacing: 7
                            MaterialIcon { text: modelData.icon; color: root.page === index ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant; fontStyle: Tokens.font.icon.small }
                            StyledText { text: modelData.label; color: root.page === index ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.medium }
                        }
                    }
                }
            }

            Item {
                width: parent.width; height: parent.height - 58 - 42 - 36

                // Dashboard
                Column {
                    anchors.fill: parent; spacing: 12; visible: root.page === 0
                    Grid {
                        id: toolGrid; width: parent.width; columns: 4; columnSpacing: 10; rowSpacing: 10
                        Repeater {
                            model: ["steam", "gamescope", "gamemoderun", "mangohud", "wine", "nvidia-smi", "prime-run", "winetricks"]
                            delegate: StyledRect {
                                required property string modelData
                                readonly property bool available: Boolean(root.snapshot?.tools?.[modelData])
                                width: (toolGrid.width - 30) / 4; height: 96; radius: Tokens.rounding.extraLarge
                                color: available ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainer
                                border.width: 1; border.color: Colours.palette.m3outlineVariant
                                Column { anchors.centerIn: parent; spacing: 5
                                    MaterialIcon { anchors.horizontalCenter: parent.horizontalCenter; text: available ? "check_circle" : "cancel"; color: available ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3outline }
                                    StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: modelData; color: available ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.medium }
                                }
                            }
                        }
                    }
                    StyledRect {
                        width: parent.width; height: 150; radius: Tokens.rounding.extraLarge; color: Colours.palette.m3surfaceContainer; border.width: 1; border.color: Colours.palette.m3outlineVariant
                        Column { anchors.fill: parent; anchors.margins: 15; spacing: 7
                            StyledText { text: qsTr("Compatibility tools"); color: Colours.palette.m3onSurface; font: Tokens.font.title.small }
                            StyledText { width: parent.width; text: (root.snapshot?.proton_versions ?? []).map(p => p.name).join(" · ") || qsTr("No Proton directories discovered"); color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.body.small; wrapMode: Text.WordWrap; maximumLineCount: 5; elide: Text.ElideRight }
                        }
                    }
                    StyledRect {
                        width: parent.width; height: Math.max(180, parent.height - toolGrid.height - 174); radius: Tokens.rounding.extraLarge; color: Colours.palette.m3surfaceContainer; border.width: 1; border.color: Colours.palette.m3outlineVariant
                        Column { anchors.fill: parent; anchors.margins: 15; spacing: 7
                            StyledText { text: qsTr("Current runtime"); color: Colours.palette.m3onSurface; font: Tokens.font.title.small }
                            StyledText { text: `${qsTr("GameMode")}: ${root.snapshot?.gamemode?.active === true ? qsTr("active") : qsTr("idle")}`; color: Colours.palette.m3primary; font: Tokens.font.label.medium }
                            StyledText { width: parent.width; text: root.snapshot?.nvidia?.query_ok && (root.snapshot?.nvidia?.gpus ?? []).length ? `${root.snapshot.nvidia.gpus[0].name} · ${root.snapshot.nvidia.gpus[0].usage ?? 0}% · ${root.snapshot.nvidia.gpus[0].vram_used_mib ?? 0}/${root.snapshot.nvidia.gpus[0].vram_mib ?? 0} MiB · ${root.snapshot.nvidia.gpus[0].pstate}` : qsTr("NVIDIA telemetry unavailable or GPU asleep"); color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.body.small; elide: Text.ElideRight }
                        }
                    }
                }

                // Library
                Row {
                    anchors.fill: parent; spacing: 12; visible: root.page === 1
                    StyledRect {
                        width: parent.width * 0.58; height: parent.height; radius: Tokens.rounding.extraLarge; color: Colours.palette.m3surfaceContainer; border.width: 1; border.color: Colours.palette.m3outlineVariant
                        Column { anchors.fill: parent; anchors.margins: 14; spacing: 9
                            StyledRect {
                                width: parent.width; height: 42; radius: Tokens.rounding.large; color: Colours.palette.m3surfaceContainerHigh; border.width: gameSearch.activeFocus ? 1 : 0; border.color: Colours.palette.m3primary
                                MaterialIcon { anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: "search"; color: Colours.palette.m3onSurfaceVariant }
                                StyledText { anchors.left: parent.left; anchors.leftMargin: 42; anchors.verticalCenter: parent.verticalCenter; visible: gameSearch.text.length === 0; text: qsTr("Filter Steam library…"); color: Colours.palette.m3outline; font: Tokens.font.body.medium }
                                TextInput { id: gameSearch; anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: 42; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; height: parent.height; verticalAlignment: TextInput.AlignVCenter; color: Colours.palette.m3onSurface; selectionColor: Colours.palette.m3primary; selectedTextColor: Colours.palette.m3onPrimary; font.pixelSize: 15; text: root.filterText; onTextChanged: root.filterText = text }
                            }
                            Flickable {
                                width: parent.width; height: parent.height - 51; contentHeight: gameColumn.height; clip: true
                                Column {
                                    id: gameColumn; width: parent.width; spacing: 4
                                    Repeater {
                                        model: root.games
                                        delegate: StyledRect {
                                            required property var modelData
                                            width: gameColumn.width; height: 48; radius: Tokens.rounding.medium
                                            color: root.selectedAppId === String(modelData?.appid ?? "") ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh
                                            StateLayer { radius: parent.radius; onClicked: root.selectGame(modelData) }
                                            Row { anchors.fill: parent; anchors.margins: 9
                                                StyledText { width: parent.width * 0.68; anchors.verticalCenter: parent.verticalCenter; text: modelData?.name ?? ""; color: root.selectedAppId === String(modelData?.appid ?? "") ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface; font: Tokens.font.label.medium; elide: Text.ElideRight }
                                                StyledText { width: parent.width * 0.18; anchors.verticalCenter: parent.verticalCenter; text: modelData?.appid ?? ""; color: Colours.palette.m3outline; font: Tokens.font.label.small; horizontalAlignment: Text.AlignRight }
                                                StyledText { width: parent.width * 0.14; anchors.verticalCenter: parent.verticalCenter; text: `${Number(modelData?.size_gb ?? 0).toFixed(1)}G`; color: Colours.palette.m3outline; font: Tokens.font.label.small; horizontalAlignment: Text.AlignRight }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    StyledRect {
                        width: parent.width * 0.42 - 12; height: parent.height; radius: Tokens.rounding.extraLarge; color: Colours.palette.m3surfaceContainer; border.width: 1; border.color: Colours.palette.m3outlineVariant
                        Column { anchors.fill: parent; anchors.margins: 16; spacing: 9
                            StyledText { width: parent.width; text: root.selectedName || qsTr("Select a game"); color: Colours.palette.m3onSurface; font: Tokens.font.title.medium; elide: Text.ElideRight }
                            StyledText { text: root.selectedAppId.length ? `AppID ${root.selectedAppId}` : ""; color: Colours.palette.m3primary; font: Tokens.font.label.medium }
                            StyledText { width: parent.width; text: qsTr("Profiles do not edit Steam VDF files. They launch Steam with reversible per-process wrappers and environment variables."); color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.body.small; wrapMode: Text.WordWrap }
                            StyledRect { width: parent.width; height: 48; radius: Tokens.rounding.large; color: Colours.palette.m3primaryContainer; enabled: root.selectedAppId.length > 0; opacity: enabled ? 1 : 0.5; StateLayer { radius: parent.radius; onClicked: root.page = 2 }; Row { anchors.centerIn: parent; spacing: 7; MaterialIcon { text: "tune"; color: Colours.palette.m3onPrimaryContainer }; StyledText { text: qsTr("Edit launch profile"); color: Colours.palette.m3onPrimaryContainer; font: Tokens.font.label.medium } } }
                        }
                    }
                }

                // Profile editor
                Row {
                    anchors.fill: parent; spacing: 12; visible: root.page === 2
                    StyledRect {
                        width: parent.width * 0.58; height: parent.height; radius: Tokens.rounding.extraLarge; color: Colours.palette.m3surfaceContainer; border.width: 1; border.color: Colours.palette.m3outlineVariant
                        Column { anchors.fill: parent; anchors.margins: 16; spacing: 10
                            StyledText { width: parent.width; text: root.selectedName || qsTr("No game selected"); color: Colours.palette.m3onSurface; font: Tokens.font.title.medium; elide: Text.ElideRight }
                            Repeater {
                                model: [
                                    {label:qsTr("GameMode"), field:"gamemode", icon:"speed"},
                                    {label:qsTr("MangoHud"), field:"mangohud", icon:"monitoring"},
                                    {label:qsTr("Gamescope"), field:"gamescope", icon:"fullscreen"},
                                    {label:qsTr("Fullscreen"), field:"fullscreen", icon:"fit_screen"}
                                ]
                                delegate: StyledRect {
                                    required property var modelData
                                    width: parent.width; height: 50; radius: Tokens.rounding.large
                                    readonly property bool on: Boolean(root.profile?.[modelData.field])
                                    color: on ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh
                                    StateLayer { radius: parent.radius; onClicked: root.mutate(modelData.field, !parent.on) }
                                    Row { anchors.fill: parent; anchors.margins: 11; spacing: 10
                                        MaterialIcon { anchors.verticalCenter: parent.verticalCenter; text: modelData.icon; color: parent.parent.on ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant }
                                        StyledText { anchors.verticalCenter: parent.verticalCenter; text: modelData.label; color: parent.parent.on ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface; font: Tokens.font.label.medium }
                                        Item { width: 1; height: 1 }
                                        StyledText { anchors.verticalCenter: parent.verticalCenter; text: parent.parent.on ? qsTr("On") : qsTr("Off"); color: Colours.palette.m3outline; font: Tokens.font.label.small }
                                    }
                                }
                            }
                            StyledRect {
                                width: parent.width; height: 50; radius: Tokens.rounding.large; color: Colours.palette.m3surfaceContainerHigh
                                StateLayer { radius: parent.radius; onClicked: root.cycleGpu() }
                                Row { anchors.fill: parent; anchors.margins: 11
                                    StyledText { width: parent.width * 0.55; anchors.verticalCenter: parent.verticalCenter; text: qsTr("GPU preference"); color: Colours.palette.m3onSurface; font: Tokens.font.label.medium }
                                    StyledText { width: parent.width * 0.45; anchors.verticalCenter: parent.verticalCenter; text: String(root.profile?.gpu ?? "default"); color: Colours.palette.m3primary; font: Tokens.font.label.medium; horizontalAlignment: Text.AlignRight }
                                }
                            }
                            Row {
                                width: parent.width; height: 50; spacing: 8
                                StyledText { width: parent.width * 0.30; anchors.verticalCenter: parent.verticalCenter; text: qsTr("FPS cap"); color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.medium }
                                StyledRect { width: 42; height: 42; radius: Tokens.rounding.medium; color: Colours.palette.m3surfaceContainerHigh; StateLayer { radius: parent.radius; onClicked: root.mutate("fps_cap", Math.max(0, Number(root.profile?.fps_cap ?? 0) - 15)) }; MaterialIcon { anchors.centerIn: parent; text: "remove"; color: Colours.palette.m3onSurfaceVariant } }
                                StyledText { width: 80; anchors.verticalCenter: parent.verticalCenter; text: Number(root.profile?.fps_cap ?? 0) === 0 ? qsTr("Uncapped") : `${root.profile.fps_cap} FPS`; color: Colours.palette.m3onSurface; font: Tokens.font.label.medium; horizontalAlignment: Text.AlignHCenter }
                                StyledRect { width: 42; height: 42; radius: Tokens.rounding.medium; color: Colours.palette.m3surfaceContainerHigh; StateLayer { radius: parent.radius; onClicked: root.mutate("fps_cap", Math.min(360, Number(root.profile?.fps_cap ?? 0) + 15)) }; MaterialIcon { anchors.centerIn: parent; text: "add"; color: Colours.palette.m3onSurfaceVariant } }
                            }
                        }
                    }
                    StyledRect {
                        width: parent.width * 0.42 - 12; height: parent.height; radius: Tokens.rounding.extraLarge; color: Colours.palette.m3surfaceContainer; border.width: 1; border.color: Colours.palette.m3outlineVariant
                        Column { anchors.fill: parent; anchors.margins: 16; spacing: 10
                            StyledText { text: qsTr("Profile actions"); color: Colours.palette.m3onSurface; font: Tokens.font.title.small }
                            StyledText { width: parent.width; text: root.actionStatus || qsTr("Save stores a small JSON profile under ~/.config/caerice. Launch uses that saved profile."); color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.body.small; wrapMode: Text.WordWrap }
                            StyledRect { width: parent.width; height: 48; radius: Tokens.rounding.large; color: Colours.palette.m3primaryContainer; enabled: root.selectedAppId.length > 0 && !profileAction.running; opacity: enabled ? 1 : 0.5; StateLayer { radius: parent.radius; onClicked: root.saveProfile() }; StyledText { anchors.centerIn: parent; text: qsTr("Save profile"); color: Colours.palette.m3onPrimaryContainer; font: Tokens.font.label.medium } }
                            StyledRect { width: parent.width; height: 48; radius: Tokens.rounding.large; color: Colours.palette.m3tertiaryContainer; enabled: root.selectedAppId.length > 0 && !profileAction.running; opacity: enabled ? 1 : 0.5; StateLayer { radius: parent.radius; onClicked: root.launchSelected() }; StyledText { anchors.centerIn: parent; text: qsTr("Launch saved profile"); color: Colours.palette.m3onTertiaryContainer; font: Tokens.font.label.medium } }
                            StyledText { width: parent.width; text: qsTr("NVIDIA mode uses PRIME render-offload variables only for the launched process. Integrated mode sets DRI_PRIME=0. Default leaves GPU selection untouched."); color: Colours.palette.m3outline; font: Tokens.font.body.small; wrapMode: Text.WordWrap }
                        }
                    }
                }

                // Runtime
                StyledRect {
                    anchors.fill: parent; visible: root.page === 3; radius: Tokens.rounding.extraLarge; color: Colours.palette.m3surfaceContainer; border.width: 1; border.color: Colours.palette.m3outlineVariant
                    Column { anchors.fill: parent; anchors.margins: 15; spacing: 8
                        Row { width: parent.width; height: 28
                            StyledText { width: parent.width * 0.10; text: "PID"; color: Colours.palette.m3outline; font: Tokens.font.label.small }
                            StyledText { width: parent.width * 0.22; text: qsTr("Process"); color: Colours.palette.m3outline; font: Tokens.font.label.small }
                            StyledText { width: parent.width * 0.14; text: "AppID"; color: Colours.palette.m3outline; font: Tokens.font.label.small }
                            StyledText { width: parent.width * 0.54; text: qsTr("Command"); color: Colours.palette.m3outline; font: Tokens.font.label.small }
                        }
                        Flickable { width: parent.width; height: parent.height - 36; contentHeight: runtimeColumn.height; clip: true
                            Column { id: runtimeColumn; width: parent.width; spacing: 3
                                Repeater { model: root.snapshot?.running_related ?? []
                                    delegate: Row { required property var modelData; width: runtimeColumn.width; height: 30
                                        StyledText { width: parent.width * 0.10; text: String(modelData?.pid ?? ""); color: Colours.palette.m3outline; font: Tokens.font.label.small }
                                        StyledText { width: parent.width * 0.22; text: modelData?.name ?? ""; color: Colours.palette.m3onSurface; font: Tokens.font.label.medium; elide: Text.ElideRight }
                                        StyledText { width: parent.width * 0.14; text: modelData?.steam_appid ?? ""; color: Colours.palette.m3primary; font: Tokens.font.label.small }
                                        StyledText { width: parent.width * 0.54; text: modelData?.command ?? ""; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small; elide: Text.ElideRight }
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
