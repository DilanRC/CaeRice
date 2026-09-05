pragma Singleton

import QtQml

QtObject {
    property var states: []
    property var components: []

    function registerState(screen, state): void {
        states = states.filter(entry => entry.screen !== screen).concat([{ screen, state }]);
    }

    function unregisterState(screen, state): void {
        states = states.filter(entry => entry.screen !== screen || entry.state !== state);
    }

    function registerComponents(screen, component): void {
        components = components.filter(entry => entry.screen !== screen).concat([{ screen, component }]);
    }

    function unregisterComponents(screen, component): void {
        components = components.filter(entry => entry.screen !== screen || entry.component !== component);
    }

    function forScreen(screen): var {
        return states.find(entry => entry.screen === screen)?.state ?? null;
    }

    function anySidebarOpen(): bool {
        return states.some(entry => !!entry.state?.sidebar);
    }

    function forActive(): var {
        const monitor = CortetsuHypr.focusedMonitor;
        return states.find(entry => CortetsuHypr.monitorFor(entry.screen) === monitor)?.state ?? null;
    }

    function componentsFor(screen): var {
        return components.find(entry => entry.screen === screen)?.component ?? null;
    }
}
