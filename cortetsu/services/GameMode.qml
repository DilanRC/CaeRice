pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import "../modules"

Singleton {
    id: root

    property alias enabled: state.enabled

    function notify(title: string, message: string): void {
        if (CortetsuConfig.toastGameModeChanged)
            Quickshell.execDetached(["notify-send", "--app-name=Cortetsu", title, message]);
    }

    function apply(): void {
        for (const setting of [
            ["animations:enabled", "0"], ["decoration:shadow:enabled", "0"],
            ["decoration:blur:enabled", "0"], ["general:gaps_in", "0"],
            ["general:gaps_out", "0"], ["general:border_size", "1"],
            ["decoration:rounding", "0"], ["general:allow_tearing", "1"]
        ])
            CortetsuHypr.dispatch(`keyword ${setting[0]} ${setting[1]}`);
    }

    function toggle(): void { enabled = !enabled; }

    onEnabledChanged: {
        if (enabled) {
            apply();
            notify(qsTr("Game mode enabled"), qsTr("Reduced compositor effects for games"));
        } else {
            CortetsuHypr.dispatch("reload");
            notify(qsTr("Game mode disabled"), qsTr("Hyprland settings restored"));
        }
    }

    PersistentProperties {
        id: state
        property bool enabled: false
        reloadableId: "gameMode"
    }

    IpcHandler {
        target: "gameMode"
        function isEnabled(): bool { return root.enabled; }
        function toggle(): void { root.toggle(); }
        function enable(): void { root.enabled = true; }
        function disable(): void { root.enabled = false; }
    }
}
