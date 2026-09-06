pragma Singleton

import QtQml
import Quickshell
import "../modules"

// Compatibility name for upstream callers while the remaining surfaces move
// to CortetsuShellState. The state registry and component slots are owned by
// Cortetsu; this service contains no upstream service or design dependency.
Singleton {
    id: root

    property var shellRoot

    function anySidebarOpen(): bool {
        return CortetsuShellState.anySidebarOpen();
    }

    function forScreen(screen): var {
        return CortetsuShellState.forScreen(screen);
    }

    function forActive(): var {
        return CortetsuShellState.forActive();
    }

    function componentsFor(screen): var {
        return CortetsuShellState.componentsFor(screen);
    }

    function componentsForActive(): var {
        const active = CortetsuShellState.forActive();
        return active ? CortetsuShellState.componentsFor(active.modelData) : null;
    }

    component ComponentRef: QtObject {
        required property var screen
        required property string slot
        required property var component
        readonly property var target: root.componentsFor(screen)

        onTargetChanged: {
            if (target)
                target[slot] = component;
        }
        Component.onDestruction: {
            if (target && target[slot] === component)
                target[slot] = null;
        }
    }
}
