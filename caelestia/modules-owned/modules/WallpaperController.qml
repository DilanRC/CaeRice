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
            if (ShellState.forScreen(screen)?.cortetsuState?.wallpaperManager)
                return true;
        }
        return false;
    }

    function closeAll(): void {
        for (const screen of CortetsuScreens.screens) {
            const state = ShellState.forScreen(screen)?.cortetsuState;
            if (state)
                state.setRetained("wallpaperManager", false);
        }
    }

    function closeOtherPanels(): void {
        for (const screen of CortetsuScreens.screens)
            OverlayPolicy.closeForWallpaper(ShellState.forScreen(screen)?.cortetsuState?.legacyState);
    }

    function open(): void {
        const state = ShellState.forActive()?.cortetsuState;
        if (!state)
            return;
        closeAll();
        closeOtherPanels();
        state.setRetained("wallpaperManager", true);
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
