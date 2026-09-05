pragma Singleton

import QtQml
import Quickshell

// First-party screen contract. The upstream Screens singleton remains the
// compatibility backend until its consumers are independently replaced.
QtObject {
    readonly property var screens: Quickshell.screens

    function monitorFor(screen): var {
        return CortetsuHypr.monitorFor(screen)
    }
}
