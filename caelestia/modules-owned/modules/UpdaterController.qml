pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.components.misc
import qs.services

Scope {
    id: root

    function anyOpen(): bool {
        for (const screen of Screens.screens) {
            const state = ShellState.forScreen(screen);
            if (state?.updaterCenter) return true;
        }
        return false;
    }
    function closeAll(): void {
        for (const screen of Screens.screens) {
            const state = ShellState.forScreen(screen);
            if (state) state.updaterCenter = false;
        }
    }
    function closeOtherPanels(state): void {
        if (!state) return;
        state.launcher = false; state.session = false; state.dashboard = false; state.utilities = false; state.sidebar = false; state.overview = false;
        if (state.clipboard !== undefined) state.clipboard = false;
        if (state.hardware !== undefined) state.hardware = false;
        if (state.displayManager !== undefined) state.displayManager = false;
        if (state.gamingCenter !== undefined) state.gamingCenter = false;
    }
    function open(): void {
        const state = ShellState.forActive(); if (!state) return;
        closeAll(); closeOtherPanels(state); state.updaterCenter = true;
    }
    function close(): void { closeAll(); }
    function toggle(): void { anyOpen() ? closeAll() : open(); }

    CustomShortcut { name: "updatercenter"; description: "Toggle CaeRice Updater"; onPressed: root.toggle() }
    IpcHandler {
        target: "updater"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function isOpen(): bool { return root.anyOpen(); }
    }
}
