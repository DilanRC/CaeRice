pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// First-party Hyprland contract. Keep backend access in one adapter so
// consumers do not depend on Caelestia service names or implementation.
Singleton {
    id: root
    readonly property var toplevels: Hyprland.toplevels
    readonly property var workspaces: Hyprland.workspaces
    readonly property var monitors: Hyprland.monitors
    readonly property bool usingLua: Hyprland.usingLua
    readonly property var activeToplevel: isTaskbarToplevel(Hyprland.activeToplevel) ? Hyprland.activeToplevel : null
    readonly property var focusedWorkspace: Hyprland.focusedWorkspace
    readonly property var focusedMonitor: Hyprland.focusedMonitor
    readonly property int activeWsId: focusedWorkspace?.id ?? 1

    function dispatch(request: string): void {
        Hyprland.dispatch(request)
    }

    function monitorFor(screen): var {
        return Hyprland.monitorFor(screen)
    }

    function isTaskbarToplevel(client): bool {
        if (!client)
            return false;
        const window = client.lastIpcObject ?? {};
        const windowClass = window.class ?? "";
        const initialClass = window.initialClass ?? "";
        const title = window.title ?? "";
        const initialTitle = window.initialTitle ?? "";
        if ((window.xwayland ?? false) && !windowClass && !title)
            return false;
        if (/^(QtWebEngineProcess\.exe|QtWebEngineProcess)$/.test(windowClass) || /^(QtWebEngineProcess\.exe|QtWebEngineProcess)$/.test(initialClass))
            return false;
        return !/^(Wine System Tray|System Tray|Qt Tray Icon Window|TrayWindow|win[0-9]+)$/i.test(title)
            && !/^(Wine System Tray|System Tray|Qt Tray Icon Window|TrayWindow|win[0-9]+)$/i.test(initialTitle);
    }

    Connections {
        target: Hyprland
        function onRawEvent(event): void {
            const name = event.name;
            if (name.endsWith("v2"))
                return;
            if (["workspace", "moveworkspace", "activespecial", "focusedmon"].includes(name)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            } else if (["openwindow", "closewindow", "movewindow"].includes(name)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            } else if (name.includes("mon")) {
                Hyprland.refreshMonitors();
            } else if (name.includes("workspace")) {
                Hyprland.refreshWorkspaces();
            } else if (name.includes("window") || name.includes("group") || ["pin", "fullscreen", "changefloatingmode", "minimize"].includes(name)) {
                Hyprland.refreshToplevels();
            }
        }
    }
}
