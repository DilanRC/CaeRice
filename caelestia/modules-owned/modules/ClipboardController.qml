pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.components.misc
import qs.services

Scope {
    id: root

    function closeAll(): void {
        for (const screen of Screens.screens) {
            const state = ShellState.forScreen(screen);
            if (state)
                state.clipboard = false;
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
    }

    function open(): void {
        const state = ShellState.forActive();
        if (!state)
            return;

        closeAll();
        closeOtherPanels(state);
        state.clipboard = true;
    }

    function close(): void {
        closeAll();
    }

    function toggle(): void {
        const state = ShellState.forActive();
        if (!state)
            return;

        if (state.clipboard) {
            closeAll();
            return;
        }

        open();
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "clipboard"
        description: "Toggle native clipboard manager"
        onPressed: root.toggle()
    }

    IpcHandler {
        target: "clipboard"

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
            const state = ShellState.forActive();
            return state?.clipboard ?? false;
        }
    }
}
