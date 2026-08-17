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
            if (state?.gamingCenter)
                return true;
        }
        return false;
    }

    function closeAll(): void {
        for (const screen of Screens.screens) {
            const state = ShellState.forScreen(screen);
            if (state)
                state.gamingCenter = false;
        }
    }

    function closeOtherPanels(state): void {
        if (!state) return;
        state.launcher = false;
        state.session = false;
        state.dashboard = false;
        state.utilities = false;
        state.sidebar = false;
        state.overview = false;
        if (state.clipboard !== undefined) state.clipboard = false;
        if (state.hardware !== undefined) state.hardware = false;
        if (state.displayManager !== undefined) state.displayManager = false;
        if (state.updaterCenter !== undefined) state.updaterCenter = false;
    }

    function open(): void {
        const state = ShellState.forActive();
        if (!state) return;
        closeAll();
        closeOtherPanels(state);
        state.gamingCenter = true;
    }

    function close(): void { closeAll(); }
    function toggle(): void { anyOpen() ? closeAll() : open(); }

    CustomShortcut {
        name: "gamingcenter"
        description: "Toggle CaeRice Gaming Center"
        onPressed: root.toggle()
    }

    IpcHandler {
        target: "gaming"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function isOpen(): bool { return root.anyOpen(); }
    }
}
