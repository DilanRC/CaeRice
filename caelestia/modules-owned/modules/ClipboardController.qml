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

    function anyOpen(): bool {
        for (const screen of Screens.screens) {
            const state = ShellState.forScreen(screen);
            if (state?.clipboard)
                return true;
        }

        return false;
    }

    function closeAll(): void {
        for (const screen of Screens.screens) {
            const state = ShellState.forScreen(screen);
            if (state)
                state.clipboard = false;
        }
    }

    function closeOtherPanels(): void {
        for (const screen of Screens.screens)
            OverlayPolicy.closeOtherPanels(ShellState.forScreen(screen));
    }

    function open(): void {
        const state = ShellState.forActive();
        if (!state)
            return;

        closeAll();
        closeOtherPanels();
        state.clipboard = true;
    }

    function close(): void {
        closeAll();
    }

    function toggle(): void {
        // The focused surface can move to another monitor once the drawer opens.
        // Do not rely on forActive() to decide whether Clipboard is already open.
        if (anyOpen()) {
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
            return root.anyOpen();
        }
    }
}
