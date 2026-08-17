pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.launcher.services

Scope {
    id: dockRoot

    property bool shown: false
    property bool appGridOpen: false
    property int appGridMonitorId: -1
    property string appQuery: ""

    /*
     * Native Caelestia has one ScreenState per monitor. Never leave a
     * launcher open on an old monitor when focus moves to the other one.
     * A stale ScreenState was able to leave an empty launcher background
     * ("black rectangle") on the second display.
     */
    function closeAllLaunchers(): void {
        for (const screen of Screens.screens) {
            const state = ShellState.forScreen(screen);
            if (state)
                state.launcher = false;
        }
    }

    function setShown(value): void {
        shown = value;

        if (!shown) {
            closeAllLaunchers();
            appGridOpen = false;
            appGridMonitorId = -1;
            appQuery = "";
        }
    }

    function toggle(): void {
        setShown(!shown);
    }

    /*
     * IMPORTANTE:
     * el launcher visual ya NO vive dentro de este PanelWindow.
     * Reutilizamos el launcher nativo de Caelestia (Drawers/ContentWindow),
     * que tiene la máscara de input y el focus grab que ya sabemos que
     * funcionan correctamente con el touchpad.
     */
    function launcher(): void {
        const state = ShellState.forActive();
        if (!state)
            return;

        const wasOpen = state.launcher;

        // Critical for dual-monitor setups: only one native launcher exists.
        closeAllLaunchers();

        if (wasOpen) {
            setShown(false);
        } else {
            setShown(true);
            state.launcher = true;
        }
    }

    function toggleLauncherFor(screen): void {
        const state = ShellState.forScreen(screen);
        if (!state)
            return;

        const wasOpen = state.launcher;
        closeAllLaunchers();

        if (wasOpen) {
            // Button closes only the launcher panel; dock stays available.
            state.launcher = false;
        } else {
            setShown(true);
            state.launcher = true;
        }
    }

    // Ya no se usa para dibujar el launcher dentro del dock.
    function toggleGrid(monitorId): void {
        appGridOpen = false;
        appGridMonitorId = -1;
        appQuery = "";
    }

    IpcHandler {
        target: "customDock"

        function toggle(): void {
            dockRoot.toggle();
        }

        function show(): void {
            dockRoot.setShown(true);
        }

        function hide(): void {
            dockRoot.setShown(false);
        }

        function launcher(): void {
            dockRoot.launcher();
        }
    }

    Variants {
        model: Screens.screens

        PanelWindow {
            id: win

            required property ShellScreen modelData

            readonly property var monitor: Hypr.monitorFor(modelData)
            readonly property int monitorId: monitor?.id ?? -1
            // El launcher integrado antiguo queda deshabilitado.
            // El launcher real ahora es el panel nativo de Caelestia.
            readonly property bool gridVisible: false

            readonly property string activeAddress:
                Hypr.activeToplevel?.lastIpcObject?.address ?? ""

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

                const pinnedEntries =
                    DesktopEntries.applications.values.filter(entry =>
                        Strings.testRegexList(
                            GlobalConfig.launcher.favouriteApps,
                            entry.id
                        )
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

            function isPinned(entry): bool {
                return entry &&
                    Strings.testRegexList(
                        GlobalConfig.launcher.favouriteApps,
                        entry.id
                    );
            }

            function togglePinnedEntry(entry): void {
                if (!entry)
                    return;

                const id = entry.id;
                const apps = GlobalConfig.launcher.favouriteApps;

                // Las apps fijadas explícitamente desde este dock se guardan
                // como IDs exactos. No eliminamos regex globales por accidente.
                if (apps.includes(id)) {
                    GlobalConfig.launcher.favouriteApps =
                        apps.filter(app => app !== id);
                } else if (!Strings.testRegexList(apps, id)) {
                    GlobalConfig.launcher.favouriteApps =
                        [...apps, id];
                }
            }

            function togglePinned(item): void {
                togglePinnedEntry(item?.entry);
            }

            /*
             * El cambio de foco de Hyprland puede mover el puntero.
             * Antes de enfocar guardamos la posición global con hyprctl
             * y, unos milisegundos después, la restauramos.
             */
            property var pendingFocusClient: null

            Process {
                id: cursorPosProcess

                stdout: StdioCollector {
                    onStreamFinished: {
                        const client = win.pendingFocusClient;
                        win.pendingFocusClient = null;

                        if (!client)
                            return;

                        const raw = this.text.trim();
                        const parts = raw.split(",");

                        let restoreX = NaN;
                        let restoreY = NaN;

                        if (parts.length >= 2) {
                            restoreX = Number(parts[0].trim());
                            restoreY = Number(parts[1].trim());
                        }

                        win.focusWindowNow(client);

                        if (
                            Number.isFinite(restoreX) &&
                            Number.isFinite(restoreY)
                        ) {
                            restoreCursorTimer.restoreX =
                                Math.round(restoreX);
                            restoreCursorTimer.restoreY =
                                Math.round(restoreY);
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
                    if (Hypr.usingLua) {
                        Hypr.dispatch(
                            `hl.dsp.cursor.move({ x = ${restoreX}, y = ${restoreY} })`
                        );
                    } else {
                        Hypr.dispatch(
                            `movecursor ${restoreX} ${restoreY}`
                        );
                    }
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
                        ? `hl.dsp.focus({ window = "${selector}" })`
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
                        ? `hl.dsp.window.close({ window = "${selector}" })`
                        : `closewindow ${selector}`
                );
            }

            function activeWindowFor(item): var {
                for (const client of item.windows) {
                    if (
                        client.lastIpcObject?.address ===
                        win.activeAddress
                    ) {
                        return client;
                    }
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
                const next =
                    item.windows[
                        (index + 1) % item.windows.length
                    ];

                focusWindow(next);
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
                const nextIndex =
                    (index + direction + count) % count;

                focusWindow(item.windows[nextIndex]);
            }

            function launchGridEntry(entry): void {
                if (!entry)
                    return;

                Apps.launch(entry);

                // El dock permanece visible. Solo se repliega la cuadrícula.
                dockRoot.appGridOpen = false;
                dockRoot.appGridMonitorId = -1;
                dockRoot.appQuery = "";
            }

            function closeGrid(): void {
                dockRoot.appGridOpen = false;
                dockRoot.appGridMonitorId = -1;
                dockRoot.appQuery = "";
            }

            onGridVisibleChanged: {
                if (gridVisible)
                    Qt.callLater(() => gridSearch.forceActiveFocus());
            }

            screen: modelData
            visible: dockRoot.shown
            color: "transparent"

            anchors.bottom: true
            margins.bottom: 2

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            implicitWidth: Math.min(
                Math.max(
                    dockBackground.implicitWidth + 8,
                    gridVisible ? appPanel.implicitWidth + 8 : 0
                ),
                modelData.width - 8
            )

            implicitHeight:
                contentColumn.implicitHeight + 4

            Column {
                id: contentColumn

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom

                spacing: 6

                /*
                 * LAUNCHER INTEGRADO
                 *
                 * Se abre encima del dock, solo en el monitor desde el
                 * que pulsaste el botón de aplicaciones.
                 */
                StyledRect {
                    id: appPanel

                    visible: win.gridVisible

                    implicitWidth:
                        Math.min(720, win.modelData.width - 16)

                    implicitHeight:
                        Math.min(470, win.modelData.height * 0.54)

                    radius: Tokens.rounding.extraLarge

                    color:
                        Colours.tPalette.m3surfaceContainerHigh

                    border.width: 1
                    border.color:
                        Colours.palette.m3outlineVariant

                    Column {
                        id: appPanelContent

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.large

                        spacing: Tokens.spacing.medium

                        SearchBar {
                            id: gridSearch

                            width: parent.width

                            placeholderText:
                                qsTr("Buscar aplicaciones")

                            Component.onCompleted:
                                text = dockRoot.appQuery

                            onTextChanged: {
                                if (dockRoot.appQuery !== text)
                                    dockRoot.appQuery = text;
                            }

                            onAccepted: {
                                if (
                                    appGrid.currentItem &&
                                    appGrid.currentItem.modelData
                                ) {
                                    win.launchGridEntry(
                                        appGrid.currentItem.modelData
                                    );
                                }
                            }

                            Keys.onEscapePressed:
                                win.closeGrid()

                            Keys.onDownPressed: {
                                if (appGrid.count > 0) {
                                    appGrid.currentIndex = 0;
                                    appGrid.forceActiveFocus();
                                }
                            }

                            Connections {
                                target: dockRoot

                                function onAppQueryChanged(): void {
                                    if (
                                        gridSearch.text !==
                                        dockRoot.appQuery
                                    ) {
                                        gridSearch.text =
                                            dockRoot.appQuery;
                                    }
                                }
                            }
                        }

                        GridView {
                            id: appGrid

                            width: parent.width
                            height:
                                parent.height -
                                gridSearch.height -
                                appPanelContent.spacing

                            clip: true

                            readonly property int columns:
                                width >= 650 ? 6 :
                                width >= 530 ? 5 : 4

                            cellWidth: width / columns
                            cellHeight: 104

                            boundsBehavior:
                                Flickable.StopAtBounds

                            keyNavigationWraps: true

                            model: ScriptModel {
                                values:
                                    Apps.search(dockRoot.appQuery)
                            }

                            delegate: Item {
                                id: gridItem

                                required property var modelData

                                width: appGrid.cellWidth
                                height: appGrid.cellHeight

                                readonly property bool pinned:
                                    win.isPinned(modelData)

                                readonly property bool selected:
                                    GridView.isCurrentItem

                                scale:
                                    gridMouse.containsMouse
                                        ? 1.04
                                        : 1

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 110
                                        easing.type:
                                            Easing.OutCubic
                                    }
                                }

                                StyledRect {
                                    anchors.fill: parent
                                    anchors.margins: 4

                                    radius:
                                        Tokens.rounding.large

                                    color:
                                        gridItem.selected
                                        ? Colours.palette
                                            .m3secondaryContainer
                                        : gridMouse.containsMouse
                                            ? Colours.palette
                                                .m3surfaceContainerHighest
                                            : "transparent"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 110
                                        }
                                    }
                                }

                                Image {
                                    id: gridIcon

                                    anchors.horizontalCenter:
                                        parent.horizontalCenter

                                    anchors.top:
                                        parent.top

                                    anchors.topMargin: 12

                                    width: 50
                                    height: 50

                                    source:
                                        Quickshell.iconPath(
                                            gridItem.modelData?.icon,
                                            "image-missing"
                                        )

                                    fillMode:
                                        Image.PreserveAspectFit

                                    smooth: true
                                    mipmap: true
                                }

                                StyledText {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom

                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    anchors.bottomMargin: 9

                                    text:
                                        gridItem.modelData?.name ?? ""

                                    font:
                                        Tokens.font.body.small

                                    horizontalAlignment:
                                        Text.AlignHCenter

                                    elide:
                                        Text.ElideRight

                                    maximumLineCount: 1
                                }

                                MaterialIcon {
                                    visible: gridItem.pinned

                                    anchors.top: parent.top
                                    anchors.right: parent.right

                                    anchors.topMargin: 7
                                    anchors.rightMargin: 8

                                    text: "push_pin"
                                    fill: 1

                                    color:
                                        Colours.palette.m3primary

                                    fontStyle:
                                        Tokens.font.icon.small
                                }

                                MouseArea {
                                    id: gridMouse

                                    anchors.fill: parent

                                    hoverEnabled: true

                                    acceptedButtons:
                                        Qt.LeftButton |
                                        Qt.RightButton

                                    cursorShape:
                                        Qt.PointingHandCursor

                                    onClicked: event => {
                                        appGrid.currentIndex = index;

                                        if (
                                            event.button ===
                                            Qt.RightButton
                                        ) {
                                            win.togglePinnedEntry(
                                                gridItem.modelData
                                            );
                                            return;
                                        }

                                        win.launchGridEntry(
                                            gridItem.modelData
                                        );
                                    }
                                }
                            }

                            Keys.onEscapePressed:
                                win.closeGrid()

                            Keys.onReturnPressed: {
                                if (
                                    currentItem &&
                                    currentItem.modelData
                                ) {
                                    win.launchGridEntry(
                                        currentItem.modelData
                                    );
                                }
                            }

                            Keys.onEnterPressed: {
                                if (
                                    currentItem &&
                                    currentItem.modelData
                                ) {
                                    win.launchGridEntry(
                                        currentItem.modelData
                                    );
                                }
                            }

                            Keys.onUpPressed: {
                                if (currentIndex < columns) {
                                    gridSearch.forceActiveFocus();
                                } else {
                                    moveCurrentIndexUp();
                                }
                            }
                        }
                    }
                }

                /*
                 * DOCK
                 */
                StyledRect {
                    id: dockBackground

                    anchors.horizontalCenter:
                        parent.horizontalCenter

                    implicitWidth:
                        appsRow.implicitWidth +
                        Tokens.padding.large * 2

                    implicitHeight: 62

                    radius:
                        Tokens.rounding.extraLarge

                    color:
                        Colours.tPalette.m3surfaceContainerHigh

                    border.width: 1
                    border.color:
                        Colours.palette.m3outlineVariant

                    Row {
                        id: appsRow

                        anchors.centerIn: parent

                        spacing:
                            Tokens.spacing.small

                        /*
                         * BOTÓN DE APLICACIONES
                         */
                        Item {
                            id: allAppsButton

                            implicitWidth: 48
                            implicitHeight: 50

                            scale:
                                allAppsMouse.containsMouse
                                    ? 1.10
                                    : 1

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 110
                                    easing.type:
                                        Easing.OutCubic
                                }
                            }

                            StyledRect {
                                anchors.fill: parent

                                radius:
                                    Tokens.rounding.large

                                color:
                                    win.gridVisible
                                    ? Colours.palette
                                        .m3secondaryContainer
                                    : allAppsMouse.containsMouse
                                        ? Colours.palette
                                            .m3surfaceContainerHighest
                                        : "transparent"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 110
                                    }
                                }
                            }

                            MaterialIcon {
                                anchors.centerIn: parent

                                text: "apps"

                                color:
                                    win.gridVisible
                                    ? Colours.palette.m3primary
                                    : Colours.palette.m3onSurface

                                fontStyle:
                                    Tokens.font.icon.extraLarge
                            }

                            MouseArea {
                                id: allAppsMouse

                                anchors.fill: parent
                                hoverEnabled: true

                                cursorShape:
                                    Qt.PointingHandCursor

                                onClicked:
                                    dockRoot.toggleLauncherFor(
                                        win.modelData
                                    )
                            }
                        }

                        Rectangle {
                            width: 1
                            height: 30

                            anchors.verticalCenter:
                                parent.verticalCenter

                            color:
                                Colours.palette.m3outlineVariant

                            opacity: 0.65
                        }

                        /*
                         * APPS FIJADAS + ABIERTAS
                         */
                        Repeater {
                            model: win.dockItems

                            Item {
                                id: appItem

                                required property var modelData

                                readonly property bool running:
                                    modelData.windows.length > 0

                                readonly property bool active:
                                    modelData.windows.some(
                                        client =>
                                            client.lastIpcObject
                                                ?.address ===
                                            win.activeAddress
                                    )

                                readonly property string iconSource: {
                                    if (modelData.entry?.icon) {
                                        return Quickshell.iconPath(
                                            modelData.entry.icon,
                                            "image-missing"
                                        );
                                    }

                                    return Icons.getAppIcon(
                                        modelData.className,
                                        "image-missing"
                                    );
                                }

                                implicitWidth: 48
                                implicitHeight: 50

                                scale:
                                    mouse.containsMouse
                                        ? 1.10
                                        : 1

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 110
                                        easing.type:
                                            Easing.OutCubic
                                    }
                                }

                                StyledRect {
                                    anchors.fill: parent

                                    radius:
                                        Tokens.rounding.large

                                    color:
                                        appItem.active
                                        ? Colours.palette
                                            .m3secondaryContainer
                                        : mouse.containsMouse
                                            ? Colours.palette
                                                .m3surfaceContainerHighest
                                            : "transparent"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 110
                                        }
                                    }
                                }

                                Image {
                                    anchors.horizontalCenter:
                                        parent.horizontalCenter

                                    anchors.top:
                                        parent.top

                                    anchors.topMargin: 5

                                    width: 34
                                    height: 34

                                    source:
                                        appItem.iconSource

                                    fillMode:
                                        Image.PreserveAspectFit

                                    smooth: true
                                    mipmap: true
                                }

                                Item {
                                    id: dockPinButton

                                    visible: appItem.modelData.pinned || mouse.containsMouse || pinMouse.containsMouse
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.topMargin: 1
                                    anchors.rightMargin: 1
                                    width: 20
                                    height: 20
                                    z: 4

                                    StyledRect {
                                        anchors.fill: parent
                                        radius: Tokens.rounding.full
                                        color: pinMouse.containsMouse
                                            ? Colours.palette.m3secondaryContainer
                                            : appItem.modelData.pinned
                                                ? Colours.palette.m3surfaceContainerHighest
                                                : Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.78)
                                    }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "push_pin"
                                        fill: appItem.modelData.pinned ? 1 : 0
                                        color: appItem.modelData.pinned || pinMouse.containsMouse
                                            ? Colours.palette.m3primary
                                            : Colours.palette.m3onSurfaceVariant
                                        fontStyle: Tokens.font.icon.small
                                    }

                                    MouseArea {
                                        id: pinMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: event => {
                                            win.togglePinned(appItem.modelData);
                                            event.accepted = true;
                                        }
                                    }
                                }

                                Row {
                                    anchors.horizontalCenter:
                                        parent.horizontalCenter

                                    anchors.bottom:
                                        parent.bottom

                                    anchors.bottomMargin: 3

                                    spacing: 3

                                    visible:
                                        appItem.running

                                    Repeater {
                                        model:
                                            Math.min(
                                                appItem
                                                    .modelData
                                                    .windows
                                                    .length,
                                                3
                                            )

                                        Rectangle {
                                            required property int index

                                            width:
                                                appItem.active
                                                    ? 6
                                                    : 5

                                            height: width
                                            radius: width / 2

                                            color:
                                                appItem.active
                                                ? Colours.palette
                                                    .m3primary
                                                : Colours.palette
                                                    .m3onSurfaceVariant
                                        }
                                    }
                                }

                                MouseArea {
                                    id: mouse

                                    anchors.fill: parent

                                    hoverEnabled: true

                                    acceptedButtons:
                                        Qt.LeftButton |
                                        Qt.MiddleButton |
                                        Qt.RightButton

                                    cursorShape:
                                        Qt.PointingHandCursor

                                    onClicked: event => {
                                        if (
                                            event.button ===
                                            Qt.RightButton
                                        ) {
                                            win.togglePinned(
                                                appItem.modelData
                                            );
                                            return;
                                        }

                                        if (
                                            event.button ===
                                            Qt.MiddleButton
                                        ) {
                                            const active =
                                                win.activeWindowFor(
                                                    appItem.modelData
                                                );

                                            win.closeWindow(
                                                active ??
                                                appItem
                                                    .modelData
                                                    .windows[0]
                                            );

                                            return;
                                        }

                                        win.activateItem(
                                            appItem.modelData
                                        );
                                    }

                                    onWheel: wheel => {
                                        if (
                                            wheel.angleDelta.y > 0
                                        ) {
                                            win.cycleItem(
                                                appItem.modelData,
                                                -1
                                            );
                                        } else if (
                                            wheel.angleDelta.y < 0
                                        ) {
                                            win.cycleItem(
                                                appItem.modelData,
                                                1
                                            );
                                        }

                                        wheel.accepted = true;
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
