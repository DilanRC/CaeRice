pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string stateRoot: Quickshell.env("XDG_STATE_HOME") || `${home}/.local/state`
    property int count: 0
    property bool dnd: false
    property bool loaded: false

    function readNotifications(): void {
        try {
            const entries = JSON.parse(notifications.text());
            count = Array.isArray(entries) ? entries.length : 0;
        } catch (_) {
            count = 0;
        }
    }

    FileView {
        id: notifications
        path: `${root.stateRoot}/cortetsu/notifs.json`
        watchChanges: true
        printErrors: false
        onLoaded: root.readNotifications()
        onFileChanged: root.readNotifications()
        onLoadFailed: root.count = 0
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
}
