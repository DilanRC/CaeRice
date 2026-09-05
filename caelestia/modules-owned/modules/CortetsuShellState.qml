pragma Singleton

import QtQml
import qs.services

// Compatibility boundary while the first-party overlay host is introduced.
// Consumers depend on this contract, never on the upstream ShellState name.
QtObject {
    function forScreen(screen): var {
        return ShellState.forScreen(screen)
    }

    function forActive(): var {
        return ShellState.forActive()
    }

    function componentsFor(screen): var {
        return ShellState.componentsFor(screen)
    }
}
