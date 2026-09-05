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
        for (const screen of CortetsuScreens.screens) {
            if (ShellState.forScreen(screen)?.cortetsuState?.calendar)
                return true;
        }
        return false;
    }

    function close(): void {
        for (const screen of CortetsuScreens.screens) {
            const state = ShellState.forScreen(screen)?.cortetsuState;
            if (state)
                state.setRetained("calendar", false);
        }
    }

    function open(): void {
        const state = ShellState.forActive()?.cortetsuState;
        if (!state)
            return;
        close();
        OverlayPolicy.closeOtherPanels(state.legacyState);
        state.setRetained("calendar", true);
    }

    function toggle(): void { anyOpen() ? close() : open(); }

    CustomShortcut {
        name: "calendar"
        description: "Toggle Cortetsu calendar"
        onPressed: root.toggle()
    }

    IpcHandler {
        target: "calendar"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function isOpen(): bool { return root.anyOpen(); }
    }
}
