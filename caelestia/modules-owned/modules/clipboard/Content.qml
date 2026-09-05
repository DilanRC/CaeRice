pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtCore
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services

FocusScope {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property bool clipboardVisible

    property var history: []
    property string query: ""
    property bool pinnedOnly: false
    property int selectedIndex: -1
    property string statusText: ""

    readonly property url historyPath:
        StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/clipse/clipboard_history.json"

    /*
     * Clipboard is deliberately dark even when the global Caelestia scheme is
     * light. We still inherit the scheme hue/accent, but use inverse Material
     * surfaces in light mode so wallpaper readability is deterministic.
     *
     * Do NOT use Colours.tPalette for primary surfaces here: tPalette follows
     * Caelestia's user transparency setting and made the fullscreen overlay
     * behave like a wireframe over bright wallpapers.
     */
    readonly property color panelSurface:
        Colours.light
            ? Colours.palette.m3inverseSurface
            : Colours.palette.m3surfaceContainerHigh

    readonly property color elevatedSurface:
        Colours.light
            ? Qt.lighter(panelSurface, 1.08)
            : Colours.palette.m3surfaceContainerHighest

    readonly property color cardSurface:
        Colours.light
            ? Qt.lighter(panelSurface, 1.12)
            : Colours.palette.m3surfaceContainer

    readonly property color hoverSurface:
        Colours.light
            ? Qt.lighter(panelSurface, 1.20)
            : Colours.palette.m3surfaceContainerHighest

    readonly property color textPrimary:
        Colours.light
            ? Colours.palette.m3inverseOnSurface
            : Colours.palette.m3onSurface

    readonly property color textMuted:
        Colours.light
            ? Qt.alpha(Colours.palette.m3inverseOnSurface, 0.68)
            : Colours.palette.m3onSurfaceVariant

    readonly property color accent:
        Colours.palette.m3primaryFixedDim

    readonly property color accentSoft:
        Qt.alpha(accent, 0.14)

    readonly property color accentOutline:
        Qt.alpha(accent, 0.34)

    readonly property var filteredEntries: {
        const needle = query.trim().toLowerCase();
        const output = [];

        for (let i = 0; i < history.length; ++i) {
            const item = history[i];
            if (!item)
                continue;

            if (pinnedOnly && !item.pinned)
                continue;

            const value = String(item.value ?? "");
            const recorded = String(item.recorded ?? "");
            const isImage = item.filePath && item.filePath !== "null";
            const haystack =
                `${value} ${recorded} ${isImage ? "image" : "text"}`.toLowerCase();

            if (needle.length === 0 || haystack.includes(needle))
                output.push({ item: item, originalIndex: i });
        }

        return output;
    }

    readonly property var selectedEntry:
        selectedIndex >= 0 && selectedIndex < filteredEntries.length
            ? filteredEntries[selectedIndex]
            : null

    function reloadHistory(): void {
        if (!historyFile.loaded)
            return;

        try {
            const raw = historyFile.text();

            if (!raw || raw.trim().length === 0) {
                history = [];
                selectedIndex = -1;
                return;
            }

            const parsed = JSON.parse(raw);
            const input = Array.isArray(parsed.clipboardHistory)
                ? parsed.clipboardHistory
                : [];
            const valid = [];

            for (const item of input) {
                if (
                    !item ||
                    typeof item !== "object" ||
                    item.value === undefined ||
                    item.recorded === undefined
                ) {
                    continue;
                }

                valid.push({
                    value: item.value,
                    recorded: item.recorded,
                    pinned: Boolean(item.pinned),
                    filePath:
                        typeof item.filePath === "string"
                            ? item.filePath
                            : null
                });
            }

            valid.sort(
                (a, b) =>
                    String(b.recorded).localeCompare(String(a.recorded))
            );

            history = valid;

            if (filteredEntries.length === 0)
                selectedIndex = -1;
            else if (
                selectedIndex < 0 ||
                selectedIndex >= filteredEntries.length
            )
                selectedIndex = 0;
        } catch (error) {
            statusText = qsTr("Could not read Clipse history");
            console.warn(`Clipboard QML: failed to parse history: ${error}`);
        }
    }

    function saveHistory(): void {
        try {
            historyFile.setText(
                JSON.stringify({ clipboardHistory: history }, null, 2)
            );
        } catch (error) {
            statusText = qsTr("Could not save clipboard history");
            console.warn(`Clipboard QML: failed to save history: ${error}`);
        }
    }

    function normalizeSelection(): void {
        if (filteredEntries.length === 0) {
            selectedIndex = -1;
            return;
        }

        selectedIndex = Math.max(
            0,
            Math.min(
                selectedIndex < 0 ? 0 : selectedIndex,
                filteredEntries.length - 1
            )
        );

        Qt.callLater(
            () => list.positionViewAtIndex(selectedIndex, ListView.Contain)
        );
    }

    function moveSelection(delta): void {
        if (filteredEntries.length === 0)
            return;

        let idx = selectedIndex;

        if (idx < 0)
            idx = 0;
        else
            idx =
                (idx + delta + filteredEntries.length) %
                filteredEntries.length;

        selectedIndex = idx;

        Qt.callLater(
            () => list.positionViewAtIndex(selectedIndex, ListView.Contain)
        );
    }

    function copyEntry(entry): void {
        if (!entry)
            return;

        const item = entry.item;
        const path = String(item.filePath ?? "");

        if (path.length > 0 && path !== "null") {
            Quickshell.execDetached([
                "sh",
                "-c",
                'mime="$(file --brief --mime-type -- "$1")"; wl-copy --type "$mime" < "$1"',
                "sh",
                path
            ]);
        } else {
            Quickshell.clipboardText = String(item.value ?? "");
        }

        statusText = qsTr("Copied");
        screenState.cortetsuState?.setRetained("clipboard", false);
    }

    function deleteEntry(entry): void {
        if (!entry)
            return;

        const idx = entry.originalIndex;

        if (idx < 0 || idx >= history.length)
            return;

        const next = history.slice();
        next.splice(idx, 1);
        history = next;
        saveHistory();
        normalizeSelection();
        statusText = qsTr("Removed");
    }

    function togglePin(entry): void {
        if (!entry)
            return;

        const idx = entry.originalIndex;

        if (idx < 0 || idx >= history.length)
            return;

        const next = history.slice();
        const copy = Object.assign({}, next[idx]);
        copy.pinned = !Boolean(copy.pinned);
        next[idx] = copy;
        history = next;
        saveHistory();
        normalizeSelection();
        statusText = copy.pinned ? qsTr("Pinned") : qsTr("Unpinned");
    }

    function clearNonPinned(): void {
        history = history.filter(item => Boolean(item.pinned));
        saveHistory();
        selectedIndex = filteredEntries.length > 0 ? 0 : -1;
        statusText = qsTr("History cleared; pinned items kept");
    }

    function openClipboard(): void {
        historyFile.reload();
        normalizeSelection();

        Qt.callLater(() => {
            searchInput.forceActiveFocus();
            searchInput.selectAll();
        });
    }

    onClipboardVisibleChanged: {
        if (clipboardVisible)
            Qt.callLater(openClipboard);
    }

    onQueryChanged: {
        selectedIndex = filteredEntries.length > 0 ? 0 : -1;
        normalizeSelection();
    }

    onPinnedOnlyChanged: {
        selectedIndex = filteredEntries.length > 0 ? 0 : -1;
        normalizeSelection();
    }

    FileView {
        id: historyFile

        path: root.historyPath
        watchChanges: true
        atomicWrites: true
        printErrors: true

        onFileChanged: reload()
        onTextChanged: root.reloadHistory()
        onLoaded: root.reloadHistory()

        onSaveFailed: error => {
            root.statusText = qsTr("Failed to save history");
            console.warn(`Clipboard QML save error: ${error}`);
        }
    }

    Keys.onEscapePressed:
        screenState.cortetsuState?.setRetained("clipboard", false)

    Keys.onUpPressed:
        moveSelection(-1)

    Keys.onDownPressed:
        moveSelection(1)

    Keys.onReturnPressed:
        copyEntry(selectedEntry)

    Keys.onEnterPressed:
        copyEntry(selectedEntry)

    Keys.onDeletePressed:
        deleteEntry(selectedEntry)

    Keys.onPressed: event => {
        if (
            event.key === Qt.Key_F &&
            (event.modifiers & Qt.ControlModifier)
        ) {
            searchInput.forceActiveFocus();
            searchInput.selectAll();
            event.accepted = true;
            return;
        }

        if (
            event.key === Qt.Key_P &&
            !(event.modifiers & Qt.ControlModifier)
        ) {
            togglePin(selectedEntry);
            event.accepted = true;
        }
    }

    /*
     * Clicking the dimmed desktop closes Clipboard. This stays below the real
     * panel so touchpad/mouse interaction inside the panel remains native.
     */
    MouseArea {
        anchors.fill: parent
        onClicked:
            root.screenState.cortetsuState?.setRetained("clipboard", false)
    }

    /*
     * One soft shadow + one accent halo. The actual panel surface below is
     * fully opaque; only these decorative layers use alpha.
     */
    StyledRect {
        x: panel.x + 2
        y: panel.y + 12
        width: panel.width
        height: panel.height
        radius: panel.radius
        color: Qt.alpha(Colours.palette.m3shadow, 0.44)
    }

    StyledRect {
        x: panel.x - 3
        y: panel.y - 3
        width: panel.width + 6
        height: panel.height + 6
        radius: panel.radius + 3
        color: Qt.alpha(root.accent, 0.08)
        border.width: 1
        border.color: Qt.alpha(root.accent, 0.22)
    }

    StyledRect {
        id: panel

        width: Math.min(910, parent.width - 88)
        height: Math.min(770, parent.height - 96)

        // True monitor center. Do not compensate for the Caelestia side bar:
        // ContentWindow already spans the monitor and the previous -105px bias
        // is exactly what pushed Clipboard to the left.
        x: Math.round((parent.width - width) / 2)

        y: Math.max(
            32,
            Math.round((parent.height - height) / 2)
        )

        radius: 30
        color: root.panelSurface
        border.width: 1
        border.color: root.accentOutline
        clip: true

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: false
        }

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 13

            Row {
                id: header

                width: parent.width
                height: 62
                spacing: 14

                StyledRect {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 54
                    height: 54
                    radius: Tokens.rounding.extraLarge
                    color: root.accentSoft
                    border.width: 1
                    border.color: Qt.alpha(root.accent, 0.26)

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "content_paste_search"
                        color: root.accent
                        fill: 1
                        fontStyle: Tokens.font.icon.extraLarge
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(
                        180,
                        parent.width -
                        filterBar.width -
                        82
                    )
                    spacing: 0

                    StyledText {
                        text: qsTr("Clipboard")
                        color: root.textPrimary
                        font: Tokens.font.title.large
                    }

                    StyledText {
                        text:
                            qsTr("%1 items · Clipse backend")
                                .arg(root.filteredEntries.length)
                        color: root.textMuted
                        font: Tokens.font.label.medium
                    }
                }

                StyledRect {
                    id: filterBar

                    anchors.verticalCenter: parent.verticalCenter
                    width: filterRow.implicitWidth + 12
                    height: 42
                    radius: Tokens.rounding.full
                    color: root.cardSurface
                    border.width: 1
                    border.color: Qt.alpha(root.textMuted, 0.18)

                    Row {
                        id: filterRow

                        anchors.centerIn: parent
                        spacing: 4

                        StyledRect {
                            width: 66
                            height: 32
                            radius: Tokens.rounding.full
                            color:
                                !root.pinnedOnly
                                    ? root.accentSoft
                                    : "transparent"
                            border.width:
                                !root.pinnedOnly ? 1 : 0
                            border.color:
                                Qt.alpha(root.accent, 0.62)

                            StyledText {
                                anchors.centerIn: parent
                                text: qsTr("All")
                                color:
                                    !root.pinnedOnly
                                        ? root.accent
                                        : root.textMuted
                                font: Tokens.font.label.medium
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked:
                                    root.pinnedOnly = false
                            }
                        }

                        StyledRect {
                            width: 100
                            height: 32
                            radius: Tokens.rounding.full
                            color:
                                root.pinnedOnly
                                    ? root.accentSoft
                                    : "transparent"
                            border.width:
                                root.pinnedOnly ? 1 : 0
                            border.color:
                                Qt.alpha(root.accent, 0.62)

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                MaterialIcon {
                                    text: "keep"
                                    fill: root.pinnedOnly ? 1 : 0
                                    color:
                                        root.pinnedOnly
                                            ? root.accent
                                            : root.textMuted
                                    fontStyle:
                                        Tokens.font.icon.small
                                }

                                StyledText {
                                    text: qsTr("Pinned")
                                    color:
                                        root.pinnedOnly
                                            ? root.accent
                                            : root.textMuted
                                    font: Tokens.font.label.medium
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked:
                                    root.pinnedOnly = true
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: 20
                            color: Qt.alpha(root.textMuted, 0.20)
                        }

                        StyledRect {
                            width: 86
                            height: 32
                            radius: Tokens.rounding.full
                            color:
                                clearMouse.containsMouse
                                    ? Qt.alpha(
                                        Colours.palette.m3error,
                                        0.12
                                    )
                                    : "transparent"

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                MaterialIcon {
                                    text: "delete_sweep"
                                    color:
                                        clearMouse.containsMouse
                                            ? Colours.palette.m3error
                                            : root.textMuted
                                    fontStyle:
                                        Tokens.font.icon.small
                                }

                                StyledText {
                                    text: qsTr("Clear")
                                    color:
                                        clearMouse.containsMouse
                                            ? Colours.palette.m3error
                                            : root.textMuted
                                    font: Tokens.font.label.medium
                                }
                            }

                            MouseArea {
                                id: clearMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked:
                                    root.clearNonPinned()
                            }
                        }
                    }
                }
            }

            StyledRect {
                id: searchHost

                width: parent.width
                height: 52
                radius: Tokens.rounding.extraLarge
                color: root.cardSurface
                border.width: searchInput.activeFocus ? 2 : 1
                border.color:
                    searchInput.activeFocus
                        ? Qt.alpha(root.accent, 0.78)
                        : Qt.alpha(root.textMuted, 0.18)

                Behavior on border.color {
                    ColorAnimation {
                        duration: 110
                    }
                }

                MaterialIcon {
                    id: searchIcon

                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "search"
                    color:
                        searchInput.activeFocus
                            ? root.accent
                            : root.textMuted
                    fontStyle: Tokens.font.icon.medium
                }

                TextInput {
                    id: searchInput

                    anchors.left: searchIcon.right
                    anchors.leftMargin: 11
                    anchors.right: searchShortcut.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter

                    height: 30
                    text: root.query
                    selectByMouse: true
                    clip: true
                    color: root.textPrimary
                    selectionColor: Qt.alpha(root.accent, 0.34)
                    selectedTextColor: root.textPrimary
                    font: Tokens.font.body.large

                    onTextChanged: {
                        if (root.query !== text)
                            root.query = text;
                    }

                    Keys.onUpPressed:
                        root.moveSelection(-1)

                    Keys.onDownPressed:
                        root.moveSelection(1)

                    Keys.onReturnPressed:
                        root.copyEntry(root.selectedEntry)

                    Keys.onEnterPressed:
                        root.copyEntry(root.selectedEntry)

                    Keys.onEscapePressed:
                        root.screenState.cortetsuState?.setRetained("clipboard", false)

                    Keys.onDeletePressed: {
                        if (
                            selectionStart === selectionEnd &&
                            text.length === 0
                        ) {
                            root.deleteEntry(root.selectedEntry);
                        }
                    }
                }

                StyledText {
                    visible: searchInput.text.length === 0
                    anchors.left: searchInput.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Search clipboard…")
                    color: root.textMuted
                    font: Tokens.font.body.large
                }

                StyledRect {
                    id: searchShortcut

                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: shortcutLabel.implicitWidth + 18
                    height: 28
                    radius: Tokens.rounding.large
                    color: root.elevatedSurface
                    border.width: 1
                    border.color: Qt.alpha(root.textMuted, 0.18)

                    StyledText {
                        id: shortcutLabel

                        anchors.centerIn: parent
                        text: "Ctrl+F"
                        color: root.textMuted
                        font: Tokens.font.label.small
                    }
                }
            }

            ListView {
                id: list

                width: parent.width
                height:
                    Math.max(
                        180,
                        parent.height -
                        header.height -
                        searchHost.height -
                        footer.height -
                        52
                    )

                model: root.filteredEntries
                clip: true
                spacing: 10
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: root.selectedIndex

                ScrollBar.vertical: ScrollBar {
                    policy:
                        list.contentHeight > list.height
                            ? ScrollBar.AsNeeded
                            : ScrollBar.AlwaysOff
                }

                delegate: ClipboardItem {
                    required property var modelData
                    required property int index

                    width:
                        list.width -
                        (list.ScrollBar.vertical.visible ? 10 : 0)

                    entry: modelData.item
                    selected: index === root.selectedIndex

                    onSelectRequested:
                        root.selectedIndex = index

                    onActivateRequested:
                        root.copyEntry(modelData)

                    onDeleteRequested:
                        root.deleteEntry(modelData)

                    onPinRequested:
                        root.togglePin(modelData)
                }

                footer:
                    Item {
                        width: 1
                        height: 4
                    }
            }

            Row {
                id: footer

                width: parent.width
                height: 36
                spacing: 14

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.statusText.length > 0
                    width: visible ? Math.min(180, implicitWidth) : 0
                    text: root.statusText
                    color: root.accent
                    font: Tokens.font.label.medium
                    elide: Text.ElideRight
                }

                Repeater {
                    model: [
                        { key: "↑ ↓", label: qsTr("Navigate") },
                        { key: "Enter", label: qsTr("Copy") },
                        { key: "Delete", label: qsTr("Remove") },
                        { key: "P", label: qsTr("Pin") },
                        { key: "Ctrl+F", label: qsTr("Search") }
                    ]

                    Row {
                        required property var modelData

                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 7

                        StyledRect {
                            width: keyLabel.implicitWidth + 16
                            height: 28
                            radius: Tokens.rounding.large
                            color: root.elevatedSurface
                            border.width: 1
                            border.color:
                                Qt.alpha(root.accent, 0.26)

                            StyledText {
                                id: keyLabel

                                anchors.centerIn: parent
                                text: modelData.key
                                color: root.accent
                                font: Tokens.font.label.small
                            }
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            color: root.textMuted
                            font: Tokens.font.label.small
                        }
                    }
                }
            }
        }

        Item {
            anchors.centerIn: parent
            width: 320
            height: 110
            visible: root.filteredEntries.length === 0

            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text:
                    root.query.length > 0
                        ? "search_off"
                        : "content_paste_off"
                color: root.accent
                fontStyle: Tokens.font.icon.extraLarge
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.verticalCenter
                anchors.topMargin: 12
                text:
                    root.query.length > 0
                        ? qsTr("No matching clipboard entries")
                        : qsTr("Clipboard history is empty")
                color: root.textMuted
                font: Tokens.font.body.medium
            }
        }
    }
}
