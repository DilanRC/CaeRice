pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    property alias enabled: state.enabled
    readonly property alias enabledSince: state.enabledSince

    onEnabledChanged: {
        if (enabled)
            state.enabledSince = new Date();
    }

    PersistentProperties {
        id: state
        property bool enabled: false
        property date enabledSince
        reloadableId: "cortetsu-idle-inhibitor"
    }

    IdleInhibitor {
        enabled: root.enabled
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            mask: Region {}
        }
    }
}
