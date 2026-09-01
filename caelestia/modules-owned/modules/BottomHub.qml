pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.services as Services
import qs.utils
import qs.modules.launcher.services
import "OverlayPolicy.js" as OverlayPolicy

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

    function closeAllPanels(): void {
        for (const screen of Screens.screens) {
            const state = ShellState.forScreen(screen);
            OverlayPolicy.closeOtherPanels(state);
        }
    }

    function setShown(value): void {
        shown = value;

        if (!shown) {
            closeAllLaunchers();
            closeAllPanels();
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
        closeAllPanels();
        OverlayPolicy.closeOtherPanels(state);
        state.launcher = !wasOpen;
        shown = true;
    }

    function toggleSidebarFor(screen): void {
        const state = ShellState.forScreen(screen);
        if (!state)
            return;

        const wasOpen = state.sidebar || state.utilities;
        closeAllLaunchers();
        closeAllPanels();
        OverlayPolicy.closeOtherPanels(state);
        state.sidebar = !wasOpen;
        state.utilities = !wasOpen;
        shown = true;
    }

    function toggleUtilitiesFor(screen): void {
        const state = ShellState.forScreen(screen);
        if (!state)
            return;

        const wasOpen = state.utilities;
        closeAllLaunchers();
        closeAllPanels();
        OverlayPolicy.closeOtherPanels(state);
        state.utilities = !wasOpen;
        shown = true;
    }

    function openWallpaperFor(screen): void {
        for (const candidate of Screens.screens) {
            const state = ShellState.forScreen(candidate);
            if (!state)
                continue;
            OverlayPolicy.closeOtherPanels(state);
            state.wallpaperManager = candidate === screen;
        }
        shown = true;
    }

    function toggleDetachedControlFor(screen, mode): void {
        const popouts = ShellState.componentsFor(screen)?.panels?.popouts;
        if (!popouts)
            return;

        closeAllLaunchers();
        closeAllPanels();

        if (popouts.isDetached && popouts.queuedMode === mode) {
            popouts.close();
            return;
        }

        popouts.detach(mode);
        shown = true;
    }

    function showAttachedControlFor(screen, mode, anchorCenter = -1): void {
        const popouts = ShellState.componentsFor(screen)?.panels?.popouts;
        if (!popouts)
            return;

        closeAllLaunchers();
        closeAllPanels();
        popouts.bottomAnchorCenter = anchorCenter;
        popouts.bottomAttached = true;
        popouts.currentName = mode;
        popouts.hasCurrent = true;
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
            hubRoot.toggleLauncherFor(state.modelData);
        }
        function notifications(): void {
            hubRoot.toggleSidebarFor(ShellState.forActive()?.modelData);
        }
        function quickSettings(): void {
            hubRoot.toggleUtilitiesFor(ShellState.forActive()?.modelData);
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
            hubRoot.toggleLauncherFor(state.modelData);
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
            readonly property int appRailMaxWidth: Math.max(
                180,
                modelData.width - Math.max(leftSegment.width, rightOccupiedWidth) * 2 - 48
            )
            readonly property int rightOccupiedWidth:
                statusSegment.width + (traySegment.visible ? traySegment.width + 8 : 0)
            readonly property int activeWsId: monitor?.activeWorkspace?.id ?? Hypr.activeWsId
            readonly property int workspaceCount: Math.max(1, GlobalConfig.bar.workspaces.shown)
            readonly property int workspaceOffset: Math.floor((activeWsId - 1) / workspaceCount) * workspaceCount

            property date now: new Date()
            property var pendingFocusClient: null

            function popoutAnchorCenter(item): real {
                return hubMargin + item.mapToItem(hubRow, item.width / 2, 0).x;
            }

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
                implicitHeight: 60
                radius: 0
                color: "transparent"
                border.width: 0

                Item {
                    id: hubRow
                    anchors.fill: parent

                    StyledRect {
                        id: leftSegment

                        anchors.left: parent.left
                        anchors.leftMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: modeRow.implicitWidth + 12
                        implicitHeight: 52
                        radius: Tokens.rounding.full
                        color: Colours.tPalette.m3surfaceContainer

                        Row {
                            id: modeRow
                            anchors.centerIn: parent
                            spacing: 2

                            HubButton {
                                buttonSize: 44
                                imageSource: "file:///usr/share/icons/cachyos.svg"
                                active: win.screenState?.launcher ?? false
                                tooltip: qsTr("Applications")
                                onClicked: hubRoot.toggleLauncherFor(win.modelData)
                            }

                            HubButton {
                                buttonSize: 40
                                cropImage: true
                                imageSource: Wallpapers.actualCurrent
                                active: win.screenState?.wallpaperManager ?? false
                                tooltip: qsTr("Wallpaper manager")
                                onClicked: hubRoot.openWallpaperFor(win.modelData)
                            }

                            Row {
                                id: workspaceDots
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                Item {
                                    width: 3
                                    height: 1
                                }

                                Repeater {
                                    model: win.workspaceCount

                                    Item {
                                        id: workspaceDot
                                        required property int index
                                        readonly property int wsId: win.workspaceOffset + index + 1
                                        readonly property bool active: wsId === win.activeWsId
                                        readonly property bool occupied: Hypr.workspaces.values.some(
                                            ws => ws.id === wsId && ws.lastIpcObject?.windows > 0
                                        )

                                        width: active ? 18 : 8
                                        height: 28

                                        Behavior on width {
                                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                        }

                                        StyledRect {
                                            anchors.centerIn: parent
                                            width: workspaceDot.active ? 18 : 8
                                            height: 8
                                            radius: Tokens.rounding.full
                                            color: workspaceDot.active
                                                ? Colours.palette.m3primary
                                                : workspaceDot.occupied
                                                    ? Colours.palette.m3secondary
                                                    : Colours.palette.m3outlineVariant

                                            Behavior on width {
                                                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Hypr.dispatch(
                                                Hypr.usingLua
                                                    ? `hl.dsp.focus({ workspace = "${workspaceDot.wsId}" })`
                                                    : `workspace ${workspaceDot.wsId}`
                                            )
                                        }
                                    }
                                }

                                Item {
                                    width: 7
                                    height: 1
                                }
                            }
                        }
                    }

                    StyledRect {
                        id: appSegment

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: Math.min(appRailContent.implicitWidth + 14, win.appRailMaxWidth)
                        implicitHeight: 52
                        radius: Tokens.rounding.full
                        color: Colours.tPalette.m3surfaceContainer
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
                                            border.width: 0

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
                        id: traySegment

                        readonly property var trayItems: SystemTray.items.values.filter(
                            item => !GlobalConfig.bar.tray.hiddenIcons.includes(item.id)
                        )

                        visible: trayItems.length > 0
                        anchors.right: statusSegment.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: trayRow.implicitWidth + 12
                        implicitHeight: 52
                        radius: Tokens.rounding.full
                        color: Colours.tPalette.m3surfaceContainer

                        Row {
                            id: trayRow
                            anchors.centerIn: parent
                            spacing: 2

                            Repeater {
                                model: traySegment.trayItems

                                Item {
                                    id: trayItem
                                    required property SystemTrayItem modelData
                                    readonly property int sourceIndex: SystemTray.items.values.indexOf(modelData)
                                    readonly property string iconSource: modelData.icon
                                        || Icons.getTrayIcon(modelData.id, modelData.icon)

                                    implicitWidth: 34
                                    implicitHeight: 40

                                    ColouredIcon {
                                        anchors.centerIn: parent
                                        implicitWidth: 22
                                        implicitHeight: 22
                                        source: trayItem.iconSource
                                        colour: Colours.palette.m3secondary
                                        layer.enabled: Config.bar.tray.recolour
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: hubRoot.showAttachedControlFor(
                                            win.modelData,
                                            `traymenu${trayItem.sourceIndex}`,
                                            win.popoutAnchorCenter(trayItem)
                                        )
                                        onClicked: event => {
                                            if (event.button === Qt.LeftButton)
                                                trayItem.modelData.activate();
                                            else
                                                trayItem.modelData.secondaryActivate();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    StyledRect {
                        id: statusSegment

                        anchors.right: parent.right
                        anchors.rightMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: statusRow.implicitWidth + 8
                        implicitHeight: 52
                        radius: Tokens.rounding.full
                        color: Colours.tPalette.m3surfaceContainer

                        Row {
                            id: statusRow
                            anchors.centerIn: parent
                            spacing: 2

                            HubButton {
                                id: volumeButton
                                buttonSize: 40
                                iconFontStyle: Tokens.font.icon.medium
                                icon: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                                tooltip: Audio.muted ? qsTr("Unmute") : qsTr("Mute")
                                onHoveredChanged: {
                                    if (hovered)
                                        hubRoot.showAttachedControlFor(
                                            win.modelData,
                                            "audio",
                                            win.popoutAnchorCenter(volumeButton)
                                        );
                                }
                                onClicked: {
                                    if (Audio.sink?.audio)
                                        Audio.sink.audio.muted = !Audio.sink.audio.muted;
                                }
                                onWheel: delta => {
                                    if (delta > 0)
                                        Audio.incrementVolume();
                                    else if (delta < 0)
                                        Audio.decrementVolume();
                                }
                            }

                            HubButton {
                                id: networkButton
                                buttonSize: 40
                                iconFontStyle: Tokens.font.icon.medium
                                icon: Nmcli.activeEthernet
                                    ? "cable"
                                    : Nmcli.active
                                        ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0)
                                        : "wifi_off"
                                active: Nmcli.activeEthernet || !!Nmcli.active
                                tooltip: qsTr("Network")
                                onHoveredChanged: {
                                    if (hovered)
                                        hubRoot.showAttachedControlFor(
                                            win.modelData,
                                            "network",
                                            win.popoutAnchorCenter(networkButton)
                                        );
                                }
                                onClicked: hubRoot.toggleDetachedControlFor(win.modelData, "network")
                            }

                            HubButton {
                                id: bluetoothButton
                                buttonSize: 40
                                iconFontStyle: Tokens.font.icon.medium
                                icon: !Bluetooth.defaultAdapter?.enabled
                                    ? "bluetooth_disabled"
                                    : Bluetooth.devices.values.some(device => device.connected)
                                        ? "bluetooth_connected"
                                        : "bluetooth"
                                active: Bluetooth.devices.values.some(device => device.connected)
                                tooltip: qsTr("Bluetooth")
                                onHoveredChanged: {
                                    if (hovered)
                                        hubRoot.showAttachedControlFor(
                                            win.modelData,
                                            "bluetooth",
                                            win.popoutAnchorCenter(bluetoothButton)
                                        );
                                }
                                onClicked: hubRoot.toggleDetachedControlFor(win.modelData, "bluetooth")
                            }

                            HubButton {
                                id: batteryButton
                                buttonSize: 40
                                iconFontStyle: Tokens.font.icon.medium
                                icon: UPower.displayDevice.isLaptopBattery
                                    ? Icons.getBatteryIcon(
                                        UPower.displayDevice.percentage,
                                        [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state)
                                    )
                                    : "balance"
                                iconColor: UPower.onBattery && UPower.displayDevice.percentage <= 0.2
                                    ? Colours.palette.m3error
                                    : Colours.palette.m3secondary
                                tooltip: UPower.displayDevice.isLaptopBattery
                                    ? qsTr("Battery %1%").arg(Math.round(UPower.displayDevice.percentage * 100))
                                    : qsTr("Power profile")
                                onHoveredChanged: {
                                    if (hovered)
                                        hubRoot.showAttachedControlFor(
                                            win.modelData,
                                            "battery",
                                            win.popoutAnchorCenter(batteryButton)
                                        );
                                }
                                onClicked: hubRoot.showAttachedControlFor(
                                    win.modelData,
                                    "battery",
                                    win.popoutAnchorCenter(batteryButton)
                                )
                            }

                            Item {
                                implicitWidth: 44
                                implicitHeight: 44

                                HubButton {
                                    anchors.fill: parent
                                    buttonSize: 44
                                    iconFontStyle: Tokens.font.icon.medium
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

                            StatusPill {
                                recordingActive: Recorder.running
                                dndActive: Notifs.dnd
                                idleInhibited: Services.IdleInhibitor.enabled
                                onStopRecordingRequested: Recorder.stop()
                                onToggleDndRequested: Notifs.dnd = !Notifs.dnd
                                onToggleIdleInhibitorRequested: Services.IdleInhibitor.enabled = !Services.IdleInhibitor.enabled
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

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: hubRoot.toggleUtilitiesFor(win.modelData)
                                }
                            }

                            HubButton {
                                buttonSize: 44
                                iconFontStyle: Tokens.font.icon.medium
                                icon: "power_settings_new"
                                active: win.screenState?.session ?? false
                                tooltip: qsTr("Session")
                                activeColor: Colours.palette.m3errorContainer
                                iconColor: active ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurface
                                onClicked: {
                                    if (win.screenState) {
                                        const wasOpen = win.screenState.session;
                                        hubRoot.closeAllLaunchers();
                                        hubRoot.closeAllPanels();
                                        OverlayPolicy.closeOtherPanels(win.screenState);
                                        win.screenState.session = !wasOpen;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
