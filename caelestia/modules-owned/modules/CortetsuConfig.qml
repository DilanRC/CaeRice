pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io

// Functional preferences owned by Cortetsu. Design tokens remain separate.
QtObject {
    id: root

    readonly property string path: `${Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`}/cortetsu/preferences.json`
    property list<string> favouriteApps: []
    property list<string> hiddenApps: []
    property list<string> hiddenTrayIcons: []
    property list<string> terminalCommand: ["kitty"]
    property string actionPrefix: ">"
    property string specialPrefix: "@"
    property var actions: []
    property bool enableDangerousActions: true
    property bool useFuzzyApps: true
    property bool useFuzzyWallpapers: true
    property bool smartScheme: true
    property string wallpaperDirectory: "~/Pictures/Wallpapers"
    property bool useTwelveHourClock: false
    property real audioIncrement: 0.1
    property real brightnessIncrement: 0.1
    property real maxVolume: 1.0
    property int visualiserBars: 60
    property string defaultPlayer: "Spotify"
    property var playerAliases: [{ from: "com.github.th_ch.youtube_music", to: "YT Music" }]
    property bool toastAudioOutputChanged: true
    property bool toastAudioInputChanged: true
    property bool toastNowPlaying: false
    property bool vimKeybinds: true
    property int workspacesShown: 5
    property bool loaded: false

    function load(raw: string): void {
        try {
            const data = JSON.parse(raw);
            if (Array.isArray(data.favouriteApps))
                favouriteApps = data.favouriteApps.filter(value => typeof value === "string");
            if (Array.isArray(data.hiddenApps))
                hiddenApps = data.hiddenApps.filter(value => typeof value === "string");
            if (Array.isArray(data.hiddenTrayIcons))
                hiddenTrayIcons = data.hiddenTrayIcons.filter(value => typeof value === "string");
            if (Array.isArray(data.terminalCommand))
                terminalCommand = data.terminalCommand.filter(value => typeof value === "string");
            if (Array.isArray(data.actions))
                actions = data.actions.filter(value => value && typeof value === "object");
            if (typeof data.actionPrefix === "string" && data.actionPrefix.length > 0)
                actionPrefix = data.actionPrefix;
            if (typeof data.specialPrefix === "string" && data.specialPrefix.length > 0)
                specialPrefix = data.specialPrefix;
            if (typeof data.enableDangerousActions === "boolean")
                enableDangerousActions = data.enableDangerousActions;
            if (typeof data.useFuzzyApps === "boolean")
                useFuzzyApps = data.useFuzzyApps;
            if (typeof data.useFuzzyWallpapers === "boolean")
                useFuzzyWallpapers = data.useFuzzyWallpapers;
            if (typeof data.smartScheme === "boolean")
                smartScheme = data.smartScheme;
            if (typeof data.wallpaperDirectory === "string" && data.wallpaperDirectory.length > 0)
                wallpaperDirectory = data.wallpaperDirectory;
            if (typeof data.useTwelveHourClock === "boolean")
                useTwelveHourClock = data.useTwelveHourClock;
            if (typeof data.audioIncrement === "number")
                audioIncrement = Math.max(0.01, Math.min(1, data.audioIncrement));
            if (typeof data.brightnessIncrement === "number")
                brightnessIncrement = Math.max(0.01, Math.min(1, data.brightnessIncrement));
            if (typeof data.maxVolume === "number")
                maxVolume = Math.max(0, Math.min(2, data.maxVolume));
            if (Number.isInteger(data.visualiserBars))
                visualiserBars = Math.max(1, Math.min(256, data.visualiserBars));
            if (typeof data.defaultPlayer === "string")
                defaultPlayer = data.defaultPlayer;
            if (Array.isArray(data.playerAliases))
                playerAliases = data.playerAliases.filter(value => value && typeof value === "object");
            if (typeof data.toastAudioOutputChanged === "boolean")
                toastAudioOutputChanged = data.toastAudioOutputChanged;
            if (typeof data.toastAudioInputChanged === "boolean")
                toastAudioInputChanged = data.toastAudioInputChanged;
            if (typeof data.toastNowPlaying === "boolean")
                toastNowPlaying = data.toastNowPlaying;
            if (typeof data.vimKeybinds === "boolean")
                vimKeybinds = data.vimKeybinds;
            if (Number.isInteger(data.workspacesShown))
                workspacesShown = Math.max(1, Math.min(20, data.workspacesShown));
        } catch (_) {}
        loaded = true;
    }

    function save(): void {
        if (!loaded)
            return;
        storage.setText(JSON.stringify({ schema: 1, favouriteApps, hiddenApps, hiddenTrayIcons, terminalCommand, actions, actionPrefix, specialPrefix, enableDangerousActions, useFuzzyApps, useFuzzyWallpapers, smartScheme, wallpaperDirectory, useTwelveHourClock, audioIncrement, brightnessIncrement, maxVolume, visualiserBars, defaultPlayer, playerAliases, toastAudioOutputChanged, toastAudioInputChanged, toastNowPlaying, vimKeybinds, workspacesShown }, null, 2) + "\n");
    }

    function setFavouriteApps(values: list<string>): void {
        favouriteApps = values.filter(value => typeof value === "string");
        save();
    }

    function setHiddenTrayIcons(values: list<string>): void {
        hiddenTrayIcons = values.filter(value => typeof value === "string");
        save();
    }

    function setHiddenApps(values: list<string>): void {
        hiddenApps = values.filter(value => typeof value === "string");
        save();
    }

    function setWorkspacesShown(value: int): void {
        workspacesShown = Math.max(1, Math.min(20, value));
        save();
    }

    property var storage: FileView {
        path: root.path
        watchChanges: true
        printErrors: false
        onLoaded: root.load(text())
        onFileChanged: root.load(text())
    }
}
