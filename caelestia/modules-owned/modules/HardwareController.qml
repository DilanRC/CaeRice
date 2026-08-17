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
            if (state?.hardware)
                return true;
        }
        return false;
    }

    function closeAll(): void {
        for (const screen of Screens.screens) {
            const state = ShellState.forScreen(screen);
            if (state)
                state.hardware = false;
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
    }

    function open(): void {
        const state = ShellState.forActive();
        if (!state)
            return;

        closeAll();
        closeOtherPanels(state);
        state.hardware = true;
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
        name: "hardware"
        description: "Toggle CaeRice Hardware Center"
        onPressed: root.toggle()
    }

    IpcHandler {
        target: "hardware"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }

        function isOpen(): bool {
            return root.anyOpen();
        }
    }
}
