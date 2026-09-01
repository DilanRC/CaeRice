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
            if (ShellState.forScreen(screen)?.wallpaperManager)
                return true;
        }
        return false;
    }

    function closeAll(): void {
        for (const screen of Screens.screens) {
            const state = ShellState.forScreen(screen);
            if (state)
                state.wallpaperManager = false;
        }
    }

    function closeOtherPanels(): void {
        for (const screen of Screens.screens)
            OverlayPolicy.closeForWallpaper(ShellState.forScreen(screen));
    }

    function open(): void {
        const state = ShellState.forActive();
        if (!state)
            return;
        closeAll();
        closeOtherPanels();
        state.wallpaperManager = true;
    }

    function close(): void { closeAll(); }
    function toggle(): void { anyOpen() ? closeAll() : open(); }

    CustomShortcut {
        name: "wallpapermanager"
        description: "Toggle native wallpaper manager"
        onPressed: root.toggle()
    }

    IpcHandler {
        target: "wallpapermanager"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function isOpen(): bool { return root.anyOpen(); }
    }
}
