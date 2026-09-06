pragma Singleton

import Quickshell
import Quickshell.Io

// First-party notification history/DND facade. Owns two XDG-state files
// (cortetsu/notifs.json, cortetsu/notification-status.json) reactively via
// FileView, and routes mutations through the cortetsu-notifications binary
// (deterministic, unit-tested in cortetsu/tests/test-notifications.py)
// rather than embedding JSON-editing logic in QML. No coupling to the
// upstream shared-config singletons. See docs/NOTIFICATIONS.md for the
// DBus ownership boundary this facade respects.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string stateRoot: Quickshell.env("XDG_STATE_HOME") || `${home}/.local/state`
    property int count: 0
    property var history: []
    property bool dnd: false
    property bool loaded: false

    function readNotifications(): void {
        try {
            const entries = JSON.parse(notifications.text());
            history = Array.isArray(entries) ? entries : [];
        } catch (_) {
            history = [];
        }
        count = history.length;
    }

    function dismiss(id: var): void {
        Quickshell.execDetached(["cortetsu-notifications", "dismiss", String(id)]);
    }

    function clear(): void {
        Quickshell.execDetached(["cortetsu-notifications", "clear"]);
    }

    function toggleDnd(): void {
        Quickshell.execDetached(["cortetsu-notifications", "dnd", "toggle"]);
    }

    FileView {
        id: notifications
        path: `${root.stateRoot}/cortetsu/notifs.json`
        watchChanges: true
        printErrors: false
        onLoaded: root.readNotifications()
        onFileChanged: root.readNotifications()
        onLoadFailed: {
            root.history = [];
            root.count = 0;
        }
    }

    FileView {
        id: status

        path: `${root.stateRoot}/cortetsu/notification-status.json`
        watchChanges: true
        printErrors: false
        onLoaded: {
            try { root.dnd = JSON.parse(text()).dnd === true; } catch (_) { root.dnd = false; }
            root.loaded = true;
        }
        onFileChanged: {
            try { root.dnd = JSON.parse(text()).dnd === true; } catch (_) { root.dnd = false; }
        }
        onLoadFailed: {
            root.loaded = true;
            setText(JSON.stringify({ dnd: false }));
        }
    }

    onDndChanged: {
        if (loaded)
            status.setText(JSON.stringify({ dnd }));
    }

    IpcHandler {
        target: "cortetsu-notifications"
        function clear(): void { root.clear(); }
        function dismiss(id: string): void { root.dismiss(id); }
        function toggleDnd(): void { root.toggleDnd(); }
        function isDndEnabled(): bool { return root.dnd; }
        function count(): int { return root.count; }
    }
}
