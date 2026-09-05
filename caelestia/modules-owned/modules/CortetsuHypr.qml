pragma Singleton

import QtQml
import qs.services

// First-party Hyprland contract. Keep backend access in one adapter so
// consumers do not depend on Caelestia service names or implementation.
QtObject {
    readonly property var toplevels: Hypr.toplevels
    readonly property var workspaces: Hypr.workspaces
    readonly property var monitors: Hypr.monitors
    readonly property bool usingLua: Hypr.usingLua
    readonly property var activeToplevel: Hypr.activeToplevel
    readonly property var focusedWorkspace: Hypr.focusedWorkspace
    readonly property var focusedMonitor: Hypr.focusedMonitor
    readonly property int activeWsId: Hypr.activeWsId

    function dispatch(request: string): void {
        Hypr.dispatch(request)
    }

    function monitorFor(screen): var {
        return Hypr.monitorFor(screen)
    }

    function isTaskbarToplevel(client): bool {
        return Hypr.isTaskbarToplevel(client)
    }
}
