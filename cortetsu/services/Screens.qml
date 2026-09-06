pragma Singleton

import QtQml
import Quickshell
import "../modules"

// Compatibility name for remaining surfaces. Monitor ownership belongs to
// CortetsuScreens; this service deliberately does not expose design/config
// state from the former upstream shell.
QtObject {
    readonly property var screens: CortetsuScreens.screens

    function isExcluded(screen): bool {
        return !CortetsuScreens.screens.includes(screen);
    }
}
