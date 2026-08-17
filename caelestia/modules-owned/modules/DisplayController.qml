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
            if (state?.displayManager)
                return true;
        }
        return false;
    }

    function closeAll(): void {
        for (const screen of Screens.screens) {
            const state = ShellState.forScreen(screen);
            if (state)
                state.displayManager = false;
        }
    }

    function closeOtherPanels(state): void {
        if (!state)
            return;
        state.launcher = false;
        state.session = false;
        state.dashboard = false;
        state.utilities = false;
        state.sidebar = false;
        state.overview = false;
        if (state.clipboard !== undefined)
            state.clipboard = false;
        if (state.hardware !== undefined)
            state.hardware = false;
    }

    function open(): void {
        const state = ShellState.forActive();
        if (!state)
            return;
        closeAll();
        closeOtherPanels(state);
        state.displayManager = true;
    }

    function close(): void {
        closeAll();
    }

    function toggle(): void {
        if (anyOpen()) {
            closeAll();
            return;
        }
        open();
    }

    CustomShortcut {
        name: "displaymanager"
        description: "Toggle CaeRice Display Manager"
        onPressed: root.toggle()
    }

    IpcHandler {
        target: "display"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function isOpen(): bool { return root.anyOpen(); }
    }
}
