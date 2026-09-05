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
            const state = ShellState.forScreen(screen)?.cortetsuState;
            if (state?.hardware)
                return true;
        }
        return false;
    }

    function closeAll(): void {
        for (const screen of CortetsuScreens.screens) {
            const state = ShellState.forScreen(screen)?.cortetsuState;
            if (state)
                state.setRetained("hardware", false);
        }
    }

    function closeOtherPanels(): void {
        for (const screen of CortetsuScreens.screens)
            OverlayPolicy.closeOtherPanels(ShellState.forScreen(screen)?.cortetsuState?.legacyState);
    }

    function open(): void {
        const state = ShellState.forActive()?.cortetsuState;
        if (!state)
            return;

        closeAll();
        closeOtherPanels();
        state.setRetained("hardware", true);
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
        description: "Toggle Cortetsu Hardware Center"
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
