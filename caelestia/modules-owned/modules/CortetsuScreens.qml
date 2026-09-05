pragma Singleton

import QtQml
import qs.services

// First-party screen contract. The upstream Screens singleton remains the
// compatibility backend until its consumers are independently replaced.
QtObject {
    readonly property var screens: Screens.screens

    function monitorFor(screen): var {
        return Hypr.monitorFor(screen)
    }
}
