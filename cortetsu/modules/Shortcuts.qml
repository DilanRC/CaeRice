import QtQuick
import Quickshell
import "../components/misc"
import "../services"
import "nexus"

Scope {
    id: root
    property bool launcherInterrupted: false
    readonly property bool hasFullscreen: CortetsuHypr.focusedWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false

    CustomShortcut { name: "nexus"; description: "Open nexus"; onPressed: WindowFactory.create() }
    CustomShortcut {
        name: "showall"; description: "Toggle launcher, dashboard and osd"
        onPressed: {
            if (root.hasFullscreen) return;
            const state = ShellState.forActive();
            state.launcher = state.dashboard = state.osd = state.utilities = !(state.launcher || state.dashboard || state.osd || state.utilities);
        }
    }
    CustomShortcut { name: "dashboard"; description: "Toggle dashboard"; onPressed: if (!root.hasFullscreen) ShellState.forActive().dashboard = !ShellState.forActive().dashboard }
    CustomShortcut { name: "session"; description: "Toggle session menu"; onPressed: if (!root.hasFullscreen) ShellState.forActive().session = !ShellState.forActive().session }
    CustomShortcut {
        name: "launcher"; description: "Toggle launcher"
        onPressed: root.launcherInterrupted = false
        onReleased: {
            if (!root.launcherInterrupted && !root.hasFullscreen)
                Quickshell.execDetached(["qs", "-p", `${Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`}/quickshell/cortetsu/current`, "ipc", "call", "customDock", "launcher"]);
            root.launcherInterrupted = false;
        }
    }
    CustomShortcut { name: "launcherInterrupt"; description: "Interrupt launcher keybind"; onPressed: root.launcherInterrupted = true }
    CustomShortcut {
        name: "sidebar"; description: "Toggle sidebar"
        onPressed: {
            if (root.hasFullscreen) return;
            const state = ShellState.forActive(), open = !(state.sidebar || state.utilities);
            state.sidebar = open; state.utilities = open; state.cortetsuState?.setRetained("wallpaperManager", false);
        }
    }
    CustomShortcut { name: "utilities"; description: "Toggle utilities"; onPressed: if (!root.hasFullscreen) ShellState.forActive().utilities = !ShellState.forActive().utilities }

    IpcHandler {
        target: "drawers"
        function toggle(drawer: string): void {
            const state = ShellState.forActive();
            if (!state || typeof state[drawer] !== "boolean") return;
            if (root.hasFullscreen && ["launcher", "session", "dashboard"].includes(drawer)) return;
            state[drawer] = !state[drawer];
        }
        function list(): string { const state = ShellState.forActive(); return state ? Object.keys(state).filter(k => typeof state[k] === "boolean").join("\n") : ""; }
        function isOpen(drawer: string): string { const state = ShellState.forActive(); return !state || typeof state[drawer] !== "boolean" ? "unknown" : state[drawer] ? "1" : "0"; }
    }
    IpcHandler { target: "nexus"; function open(): void { WindowFactory.create(); } }
}
