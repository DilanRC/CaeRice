pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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

    function setShown(value): void {
        shown = value;

        if (!shown) {
            closeAllLaunchers();
            closeAllSidebars();
        }
    }

    function toggle(): void {
        setShown(!shown);
    }

    function toggleLauncherFor(screen): void {
        const state = ShellState.forScreen(screen);
        if (!state)
            return;

        const wasOpen = state.launcher;
        closeAllLaunchers();
        closeAllSidebars();
        state.launcher = !wasOpen;
        shown = true;
    }

    function toggleOverviewFor(screen): void {
        const state = ShellState.forScreen(screen);
        if (!state)
            return;

        closeAllLaunchers();
        closeAllSidebars();
        state.overview = !state.overview;
        shown = true;
    }

    function toggleSidebarFor(screen): void {
        const state = ShellState.forScreen(screen);
        if (!state)
            return;

        const wasOpen = state.sidebar;
        closeAllLaunchers();
        closeAllSidebars();
        state.sidebar = !wasOpen;
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
            hubRoot.closeAllLaunchers();
            hubRoot.closeAllSidebars();
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
            hubRoot.closeAllLaunchers();
            hubRoot.closeAllSidebars();
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
            readonly property bool panelActive:
                (screenState?.launcher ?? false)
                || (screenState?.overview ?? false)
                || (screenState?.sidebar ?? false)
                || (screenState?.session ?? false)
            readonly property int hubMargin: 8
            readonly property int appRailMaxWidth: Math.max(320, modelData.width - 360)

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

            implicitWidth: modelData.width - hubMargin * 2
            implicitHeight: hubSurface.implicitHeight + 6

            StyledRect {
                id: hubSurface

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                implicitHeight: 68
                radius: Tokens.rounding.extraLarge
                color: win.panelActive
                    ? Colours.palette.m3surfaceContainerHighest
                    : Colours.tPalette.m3surfaceContainerHigh
                border.width: 1
                border.color: win.panelActive
                    ? Colours.palette.m3primary
                    : Colours.palette.m3outlineVariant

                Behavior on color {
                    ColorAnimation { duration: 140 }
                }

                Behavior on border.color {
                    ColorAnimation { duration: 140 }
                }

                StyledRect {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    height: 2
                    radius: 1
                    color: Colours.palette.m3primary
                    opacity: win.panelActive ? 0.72 : 0.22

                    Behavior on opacity {
                        NumberAnimation { duration: 140 }
                    }
                }

                RowLayout {
                    id: hubRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 9
                    anchors.rightMargin: 9
                    spacing: 8

                    StyledRect {
                        Layout.preferredWidth: modeRow.implicitWidth + 8
                        Layout.preferredHeight: 52
                        implicitWidth: modeRow.implicitWidth + 8
                        implicitHeight: 52
                        radius: Tokens.rounding.extraLarge
                        color: Colours.palette.m3surfaceContainer
                        border.width: 1
                        border.color: Colours.palette.m3outlineVariant

                        Row {
                            id: modeRow
                            anchors.centerIn: parent
                            spacing: 2

                            HubButton {
                                buttonSize: 44
                                icon: "apps"
                                active: win.screenState?.launcher ?? false
                                tooltip: qsTr("Applications")
                                onClicked: hubRoot.toggleLauncherFor(win.modelData)
                            }

                            HubButton {
                                buttonSize: 44
                                icon: "view_quilt"
                                active: win.screenState?.overview ?? false
                                tooltip: qsTr("Overview")
                                onClicked: hubRoot.toggleOverviewFor(win.modelData)
                            }
                        }
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 180
                        Layout.maximumWidth: win.appRailMaxWidth
                        Layout.preferredHeight: 52
                        implicitWidth: Math.min(appRailContent.implicitWidth + 14, win.appRailMaxWidth)
                        implicitHeight: 52
                        radius: Tokens.rounding.extraLarge
                        color: Colours.palette.m3surfaceContainerLowest
                        border.width: 1
                        border.color: Colours.palette.m3outlineVariant
                        clip: true

                        Flickable {
                            id: appRail
                            anchors.fill: parent
                            anchors.leftMargin: 7
                            anchors.rightMargin: 7
                            contentWidth: appRailContent.implicitWidth
                            contentHeight: height
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: contentWidth > width
                            clip: true

                            Row {
                                id: appRailContent
                                height: parent.height
                                spacing: 4

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

                                        implicitWidth: 46
                                        implicitHeight: 52
                                        scale: appMouse.containsMouse ? 1.10 : 1

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: 110
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        StyledRect {
                                            anchors.fill: parent
                                            anchors.topMargin: 2
                                            anchors.bottomMargin: 2
                                            radius: Tokens.rounding.large
                                            color: appItem.active
                                                ? Colours.palette.m3secondaryContainer
                                                : appMouse.containsMouse
                                                    ? Colours.palette.m3surfaceContainerHighest
                                                    : "transparent"
                                            border.width: appItem.active ? 1 : 0
                                            border.color: Colours.palette.m3primary

                                            Behavior on color {
                                                ColorAnimation { duration: 110 }
                                            }
                                        }

                                        Image {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.top: parent.top
                                            anchors.topMargin: 6
                                            width: 32
                                            height: 32
                                            source: appItem.iconSource
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                            mipmap: true
                                            opacity: appItem.running ? 1 : 0.62
                                        }

                                        StyledRect {
                                            visible: appItem.modelData.pinned && !appItem.running
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.topMargin: 6
                                            anchors.rightMargin: 5
                                            width: 7
                                            height: 7
                                            radius: 4
                                            color: Colours.palette.m3tertiary
                                        }

                                        Row {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 4
                                            spacing: 3
                                            visible: appItem.running

                                            Repeater {
                                                model: Math.min(appItem.modelData.windows.length, 4)

                                                Rectangle {
                                                    required property int index
                                                    width: appItem.active ? 12 : 5
                                                    height: 5
                                                    radius: 3
                                                    color: appItem.active
                                                        ? Colours.palette.m3primary
                                                        : Colours.palette.m3onSurfaceVariant
                                                    opacity: index < 3 ? 1 : 0.55
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
                            }
                        }
                    }

                    StyledRect {
                        Layout.preferredWidth: statusRow.implicitWidth + 8
                        Layout.preferredHeight: 52
                        implicitWidth: statusRow.implicitWidth + 8
                        implicitHeight: 52
                        radius: Tokens.rounding.extraLarge
                        color: Colours.palette.m3surfaceContainer
                        border.width: 1
                        border.color: Colours.palette.m3outlineVariant

                        Row {
                            id: statusRow
                            anchors.centerIn: parent
                            spacing: 2

                            Item {
                                implicitWidth: 44
                                implicitHeight: 44

                                HubButton {
                                    anchors.fill: parent
                                    buttonSize: 44
                                    icon: "notifications"
                                    active: win.screenState?.sidebar ?? false
                                    tooltip: qsTr("Notifications")
                                    onClicked: hubRoot.toggleSidebarFor(win.modelData)
                                }

                                Rectangle {
                                    visible: Notifs.notClosed.length > 0
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.topMargin: 0
                                    anchors.rightMargin: 0
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: Colours.palette.m3primary

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: Math.min(Notifs.notClosed.length, 9)
                                        color: Colours.palette.m3onPrimary
                                        font: Tokens.font.label.small
                                    }
                                }
                            }

                            Item {
                                implicitWidth: 74
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
                                buttonSize: 44
                                icon: "power_settings_new"
                                active: win.screenState?.session ?? false
                                tooltip: qsTr("Session")
                                activeColor: Colours.palette.m3errorContainer
                                iconColor: active ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurface
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
    }
}
