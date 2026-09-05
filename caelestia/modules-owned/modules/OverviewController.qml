pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.components.misc
import qs.services
import "OverlayPolicy.js" as OverlayPolicy

Scope {
    id: root

    function closeAll(): void {
        for (const screen of Screens.screens) {
            const state = ShellState.forScreen(screen)?.cortetsuState;
            if (state)
                state.setRetained("overview", false);
        }
    }

    function closeOtherPanels(): void {
        for (const screen of Screens.screens)
            OverlayPolicy.closeOtherPanels(ShellState.forScreen(screen)?.cortetsuState?.legacyState);
    }

    function open(): void {
        const state = ShellState.forActive()?.cortetsuState;
        if (!state)
            return;

        closeAll();
        closeOtherPanels();
        state.setRetained("overview", true);
    }

    function close(): void {
        closeAll();
    }

    function toggle(): void {
        const state = ShellState.forActive()?.cortetsuState;
        if (!state)
            return;

        if (state.overview) {
            closeAll();
            return;
        }

        open();
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "overview"
        description: "Toggle window overview"
        onPressed: root.toggle()
    }

    IpcHandler {
        target: "overview"

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
            return state?.overview ?? false;
        }
    }
}
