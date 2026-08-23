pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.launcher.services

Scope {
    id: hubRoot

    property bool shown: true

    function closeAllLaunchers(): void {
        for (const screen of Screens.screens) {
            const state = ShellState.forScreen(screen);
            if (state)
                state.launcher = false;
        }
    }

    function closeAllSidebars(): void {
        for (const screen of Screens.screens) {
            const state = ShellState.forScreen(screen);
            if (state)
                state.sidebar = false;
        }
    }

    function closeAllUtilities(): void {
        for (const screen of Screens.screens) {
            const state = ShellState.forScreen(screen);
            if (state)
                state.utilities = false;
        }
    }

    function closeAllPopovers(): void {
        closeAllLaunchers();
        closeAllSidebars();
        closeAllUtilities();
    }

    function setShown(value): void {
        shown = value;

        if (!shown)
            closeAllPopovers();
    }

    function toggle(): void {
        setShown(!shown);
    }

    function toggleLauncherFor(screen): void {
        const state = ShellState.forScreen(screen);
        if (!state)
            return;

        const wasOpen = state.launcher;
        closeAllPopovers();
        state.launcher = !wasOpen;
        shown = true;
    }

    function toggleOverviewFor(screen): void {
        const state = ShellState.forScreen(screen);
        if (!state)
            return;

        closeAllPopovers();
        state.overview = !state.overview;
        shown = true;
    }

    function toggleSidebarFor(screen): void {
        const state = ShellState.forScreen(screen);
        if (!state)
            return;

        const wasOpen = state.sidebar;
        closeAllPopovers();
        state.sidebar = !wasOpen;
        shown = true;
    }

    function toggleUtilitiesFor(screen): void {
        const state = ShellState.forScreen(screen);
        if (!state)
            return;

        const wasOpen = state.utilities;
        closeAllPopovers();
        state.utilities = !wasOpen;
        shown = true;
    }

    IpcHandler {
        target: "bottomHub"

        function toggle(): void { hubRoot.toggle(); }
        function show(): void { hubRoot.setShown(true); }
        function hide(): void { hubRoot.setShown(false); }
        function launcher(): void {
            const state = ShellState.forActive();
            if (!state)
                return;
            hubRoot.closeAllPopovers();
            state.launcher = true;
            hubRoot.shown = true;
        }
    }

    // Compatibility with the existing SUPER+D binding and helper scripts.
    IpcHandler {
        target: "customDock"

        function toggle(): void { hubRoot.toggle(); }
        function show(): void { hubRoot.setShown(true); }
        function hide(): void { hubRoot.setShown(false); }
        function launcher(): void {
            const state = ShellState.forActive();
            if (!state)
                return;
            hubRoot.closeAllPopovers();
            state.launcher = true;
            hubRoot.shown = true;
        }
    }

    Variants {
        model: Screens.screens

        PanelWindow {
            id: win

            required property ShellScreen modelData

            readonly property var monitor: Hypr.monitorFor(modelData)
            readonly property var screenState: ShellState.forScreen(modelData)
            readonly property string activeAddress:
                Hypr.activeToplevel?.lastIpcObject?.address ?? ""

            property date now: new Date()
            property var pendingFocusClient: null

            readonly property var dockItems: {
                const clients = Hypr.toplevels.values.filter(client => {
                    if (!Hypr.isTaskbarToplevel(client))
                        return false;

                    const clientMonitor = client.lastIpcObject?.monitor;
                    return win.monitor && clientMonitor === win.monitor.id;
                });

                const groups = new Map();

                for (const client of clients) {
                    const cls = client.lastIpcObject?.class ?? "";
                    const entry = DesktopEntries.heuristicLookup(cls);
                    const key = entry?.id ?? cls.toLowerCase();

                    if (!groups.has(key)) {
                        groups.set(key, {
                            key: key,
                            entry: entry,
                            className: cls,
                            pinned: false,
                            windows: []
                        });
                    }

                    groups.get(key).windows.push(client);
                }

                const result = [];
                const pinnedEntries = DesktopEntries.applications.values.filter(entry =>
                    Strings.testRegexList(GlobalConfig.launcher.favouriteApps, entry.id)
                );

                for (const entry of pinnedEntries) {
                    const existing = groups.get(entry.id);

                    if (existing) {
                        existing.pinned = true;
                        result.push(existing);
                        groups.delete(entry.id);
                    } else {
                        result.push({
                            key: entry.id,
                            entry: entry,
                            className: entry.startupClass ?? entry.id,
                            pinned: true,
                            windows: []
                        });
                    }
                }

                for (const group of groups.values())
                    result.push(group);

                return result;
            }

            function togglePinned(item): void {
                const entry = item?.entry;
                if (!entry)
                    return;

                const id = entry.id;
                const apps = GlobalConfig.launcher.favouriteApps;

                if (apps.includes(id)) {
                    GlobalConfig.launcher.favouriteApps = apps.filter(app => app !== id);
                } else if (!Strings.testRegexList(apps, id)) {
                    GlobalConfig.launcher.favouriteApps = [...apps, id];
                }
            }

            function focusWindowNow(client): void {
                if (!client)
                    return;

                const address = client.lastIpcObject?.address;
                if (!address)
                    return;

                const selector = `address:${address}`;
                Hypr.dispatch(
                    Hypr.usingLua
                        ? `hl.dsp.focus({ window = \"${selector}\" })`
                        : `focuswindow ${selector}`
                );
            }

            function focusWindow(client): void {
                if (!client)
                    return;

                pendingFocusClient = client;
                cursorPosProcess.exec(["hyprctl", "cursorpos"]);
            }

            function closeWindow(client): void {
                if (!client)
                    return;

                const address = client.lastIpcObject?.address;
                if (!address)
                    return;

                const selector = `address:${address}`;
                Hypr.dispatch(
                    Hypr.usingLua
                        ? `hl.dsp.window.close({ window = \"${selector}\" })`
                        : `closewindow ${selector}`
                );
            }

            function activeWindowFor(item): var {
                for (const client of item.windows) {
                    if (client.lastIpcObject?.address === activeAddress)
                        return client;
                }
                return null;
            }

            function activateItem(item): void {
                if (!item.windows.length) {
                    if (item.entry)
                        Apps.launch(item.entry);
                    return;
                }

                const active = activeWindowFor(item);

                if (!active) {
                    focusWindow(item.windows[0]);
                    return;
                }

                if (item.windows.length === 1) {
                    focusWindow(active);
                    return;
                }

                const index = item.windows.indexOf(active);
                focusWindow(item.windows[(index + 1) % item.windows.length]);
            }

            function cycleItem(item, direction): void {
                if (!item.windows.length)
                    return;

                const active = activeWindowFor(item);

                if (!active) {
                    focusWindow(item.windows[0]);
                    return;
                }

                const index = item.windows.indexOf(active);
                const count = item.windows.length;
                focusWindow(item.windows[(index + direction + count) % count]);
            }

            Process {
                id: cursorPosProcess

                stdout: StdioCollector {
                    onStreamFinished: {
                        const client = win.pendingFocusClient;
                        win.pendingFocusClient = null;

                        if (!client)
                            return;

                        const parts = this.text.trim().split(",");
                        let restoreX = NaN;
                        let restoreY = NaN;

                        if (parts.length >= 2) {
                            restoreX = Number(parts[0].trim());
                            restoreY = Number(parts[1].trim());
                        }

                        win.focusWindowNow(client);

                        if (Number.isFinite(restoreX) && Number.isFinite(restoreY)) {
                            restoreCursorTimer.restoreX = Math.round(restoreX);
                            restoreCursorTimer.restoreY = Math.round(restoreY);
                            restoreCursorTimer.restart();
                        }
                    }
                }
            }

            Timer {
                id: restoreCursorTimer
                interval: 12
                repeat: false
                property int restoreX: 0
                property int restoreY: 0

                onTriggered: {
                    if (Hypr.usingLua)
                        Hypr.dispatch(`hl.dsp.cursor.move({ x = ${restoreX}, y = ${restoreY} })`);
                    else
                        Hypr.dispatch(`movecursor ${restoreX} ${restoreY}`);
                }
            }

            Timer {
                interval: 1000
                repeat: true
                running: true
                onTriggered: win.now = new Date()
            }

            screen: modelData
            visible: hubRoot.shown
            color: "transparent"

            anchors.bottom: true
            margins.bottom: 2

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            implicitWidth: Math.min(hubSurface.implicitWidth + 8, modelData.width - 8)
            implicitHeight: hubSurface.implicitHeight + 4

            // Compact pill: 52px tall (was 64), tighter padding, smaller
            // controls. The dock only grows sideways with app count -- it
            // never grows taller, so keeping this shallow keeps the whole
            // bar reading as one clean strip instead of a slab.
            StyledRect {
                id: hubSurface

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                implicitWidth: hubRow.implicitWidth + Tokens.padding.medium * 2
                implicitHeight: 52
                radius: Tokens.rounding.extraLarge
                color: Colours.tPalette.m3surfaceContainerHigh
                border.width: 1
                border.color: Colours.palette.m3outlineVariant

                Row {
                    id: hubRow
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.extraSmall

                    HubButton {
                        icon: "apps"
                        active: win.screenState?.launcher ?? false
                        tooltip: qsTr("Applications")
                        onClicked: hubRoot.toggleLauncherFor(win.modelData)
                    }

                    HubButton {
                        icon: "view_quilt"
                        active: win.screenState?.overview ?? false
                        tooltip: qsTr("Overview")
                        onClicked: hubRoot.toggleOverviewFor(win.modelData)
                    }

                    Rectangle {
                        width: 1
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colours.palette.m3outlineVariant
                        opacity: 0.65
                    }

                    Repeater {
                        model: win.dockItems

                        Item {
                            id: appItem
                            required property var modelData

                            readonly property bool running: modelData.windows.length > 0
                            readonly property bool active: modelData.windows.some(
                                client => client.lastIpcObject?.address === win.activeAddress
                            )
                            readonly property string iconSource: {
                                if (modelData.entry?.icon)
                                    return Quickshell.iconPath(modelData.entry.icon, "image-missing");
                                return Icons.getAppIcon(modelData.className, "image-missing");
                            }

                            implicitWidth: 42
                            implicitHeight: 44
                            scale: appMouse.containsMouse ? 1.10 : 1

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 110
                                    easing.type: Easing.OutCubic
                                }
                            }

                            StyledRect {
                                anchors.fill: parent
                                radius: Tokens.rounding.large
                                color: appItem.active
                                    ? Colours.palette.m3secondaryContainer
                                    : appMouse.containsMouse
                                        ? Colours.palette.m3surfaceContainerHighest
                                        : "transparent"

                                Behavior on color {
                                    ColorAnimation { duration: 110 }
                                }
                            }

                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.topMargin: 4
                                width: 28
                                height: 28
                                source: appItem.iconSource
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                spacing: 3
                                visible: appItem.running

                                Repeater {
                                    model: Math.min(appItem.modelData.windows.length, 3)

                                    Rectangle {
                                        required property int index
                                        width: appItem.active ? 5 : 4
                                        height: width
                                        radius: width / 2
                                        color: appItem.active
                                            ? Colours.palette.m3primary
                                            : Colours.palette.m3onSurfaceVariant
                                    }
                                }
                            }

                            MouseArea {
                                id: appMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor

                                onClicked: event => {
                                    if (event.button === Qt.RightButton) {
                                        win.togglePinned(appItem.modelData);
                                        return;
                                    }

                                    if (event.button === Qt.MiddleButton) {
                                        const activeWindow = win.activeWindowFor(appItem.modelData);
                                        win.closeWindow(activeWindow ?? appItem.modelData.windows[0]);
                                        return;
                                    }

                                    win.activateItem(appItem.modelData);
                                }

                                onWheel: wheel => {
                                    if (wheel.angleDelta.y > 0)
                                        win.cycleItem(appItem.modelData, -1);
                                    else if (wheel.angleDelta.y < 0)
                                        win.cycleItem(appItem.modelData, 1);

                                    wheel.accepted = true;
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 1
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colours.palette.m3outlineVariant
                        opacity: 0.65
                    }

                    HubButton {
                        icon: "tune"
                        active: win.screenState?.utilities ?? false
                        tooltip: qsTr("Quick Toggles")
                        onClicked: hubRoot.toggleUtilitiesFor(win.modelData)
                    }

                    Item {
                        implicitWidth: 40
                        implicitHeight: 44

                        HubButton {
                            anchors.fill: parent
                            icon: "notifications"
                            active: win.screenState?.sidebar ?? false
                            tooltip: qsTr("Notifications")
                            onClicked: hubRoot.toggleSidebarFor(win.modelData)
                        }

                        Rectangle {
                            visible: Notifs.notClosed.length > 0
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: 1
                            anchors.rightMargin: 0
                            width: 16
                            height: 16
                            radius: 8
                            color: Colours.palette.m3primary

                            StyledText {
                                anchors.centerIn: parent
                                text: Math.min(Notifs.notClosed.length, 9)
                                color: Colours.palette.m3onPrimary
                                font: Tokens.font.label.small
                            }
                        }
                    }

                    Rectangle {
                        width: 1
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colours.palette.m3outlineVariant
                        opacity: 0.65
                    }

                    Item {
                        implicitWidth: 64
                        implicitHeight: 44

                        Column {
                            anchors.centerIn: parent
                            spacing: -2

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatDateTime(win.now, "HH:mm")
                                color: Colours.palette.m3onSurface
                                font: Tokens.font.label.large
                            }

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatDateTime(win.now, "ddd d")
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                            }
                        }
                    }

                    HubButton {
                        icon: "power_settings_new"
                        active: win.screenState?.session ?? false
                        tooltip: qsTr("Session")
                        onClicked: {
                            if (win.screenState)
                                win.screenState.session = !win.screenState.session;
                        }
                    }
                }
            }
        }
    }
}
