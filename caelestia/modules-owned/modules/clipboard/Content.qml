pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtCore
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components

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
            const haystack = `${value} ${recorded} ${isImage ? "image" : "text"}`.toLowerCase();

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
                if (!item || typeof item !== "object" || item.value === undefined || item.recorded === undefined)
                    continue;

                valid.push({
                    value: item.value,
                    recorded: item.recorded,
                    pinned: Boolean(item.pinned),
                    filePath: typeof item.filePath === "string" ? item.filePath : null
                });
            }

            valid.sort((a, b) => String(b.recorded).localeCompare(String(a.recorded)));
            history = valid;

            if (filteredEntries.length === 0)
                selectedIndex = -1;
            else if (selectedIndex < 0 || selectedIndex >= filteredEntries.length)
                selectedIndex = 0;
        } catch (error) {
            statusText = qsTr("Could not read Clipse history");
            console.warn(`Clipboard QML: failed to parse history: ${error}`);
        }
    }

    function saveHistory(): void {
        try {
            historyFile.setText(JSON.stringify({ clipboardHistory: history }, null, 2));
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

        Qt.callLater(() => list.positionViewAtIndex(selectedIndex, ListView.Contain));
    }

    function moveSelection(delta): void {
        if (filteredEntries.length === 0)
            return;

        let idx = selectedIndex;

        if (idx < 0)
            idx = 0;
        else
            idx = (idx + delta + filteredEntries.length) % filteredEntries.length;

        selectedIndex = idx;
        Qt.callLater(() => list.positionViewAtIndex(selectedIndex, ListView.Contain));
    }

    function copyEntry(entry): void {
        if (!entry)
            return;

        const item = entry.item;
        const path = String(item.filePath ?? "");

        if (path.length > 0 && path !== "null") {
            Quickshell.execDetached([
                "sh", "-c",
                'mime="$(file --brief --mime-type -- "$1")"; wl-copy --type "$mime" < "$1"',
                "sh", path
            ]);
        } else {
            Quickshell.clipboardText = String(item.value ?? "");
        }

        statusText = qsTr("Copied");
        screenState.clipboard = false;
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

    Keys.onEscapePressed: screenState.clipboard = false
    Keys.onUpPressed: moveSelection(-1)
    Keys.onDownPressed: moveSelection(1)
    Keys.onReturnPressed: copyEntry(selectedEntry)
    Keys.onEnterPressed: copyEntry(selectedEntry)
    Keys.onDeletePressed: deleteEntry(selectedEntry)

    Keys.onPressed: event => {
        if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            searchInput.forceActiveFocus();
            searchInput.selectAll();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_P && !(event.modifiers & Qt.ControlModifier)) {
            togglePin(selectedEntry);
            event.accepted = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.screenState.clipboard = false
    }

    /*
     * Premium CaeRice panel. Every colour comes from the active Material
     * scheme so wallpaper/theme changes propagate exactly like Dock/Launcher.
     */
    StyledRect {
        id: panelHalo

        x: panel.x - 7
        y: panel.y - 7
        width: panel.width + 14
        height: panel.height + 14
        radius: panel.radius + 7
        color: "transparent"
        border.width: 2
        border.color: Qt.alpha(Colours.palette.m3primary, 0.08)
    }

    StyledRect {
        id: panel

        width: Math.min(860, parent.width - 84)
        height: Math.min(758, parent.height - 92)

        x: Math.max(
            30,
            Math.round(
                (parent.width - width) / 2 -
                Math.min(110, parent.width * 0.055)
            )
        )
        y: Math.max(28, Math.round((parent.height - height) / 2))

        radius: Tokens.rounding.extraLarge
        color: Colours.palette.m3surfaceContainerHigh
        border.width: 1
        border.color: Qt.alpha(Colours.palette.m3primary, 0.38)
        clip: true

        // Subtle tonal wash gives the panel the same layered glass feel as the
        // rest of CaeRice without forcing a fixed dark colour.
        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: Qt.alpha(Colours.tPalette.m3surfaceContainerHigh, 0.46)
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: Qt.alpha(Colours.palette.m3primary, 0.50)
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: false
        }

        Column {
            id: panelContent

            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            Row {
                id: header

                width: parent.width
                height: 58
                spacing: 12

                StyledRect {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 52
                    height: 52
                    radius: Tokens.rounding.extraLarge
                    color: Qt.alpha(Colours.palette.m3primary, 0.13)
                    border.width: 1
                    border.color: Qt.alpha(Colours.palette.m3primary, 0.27)

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "content_paste_search"
                        color: Colours.palette.m3primary
                        fill: 1
                        fontStyle: Tokens.font.icon.extraLarge
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(180, parent.width - headerActions.width - 78)
                    spacing: -1

                    StyledText {
                        text: qsTr("Clipboard")
                        font: Tokens.font.title.large
                    }

                    StyledText {
                        text: qsTr("%1 items · Clipse backend").arg(root.filteredEntries.length)
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.medium
                    }
                }

                StyledRect {
                    id: headerActions

                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: actionRow.implicitWidth + 12
                    implicitHeight: 40
                    radius: Tokens.rounding.full
                    color: Qt.alpha(Colours.palette.m3surfaceContainer, 0.76)
                    border.width: 1
                    border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.58)

                    Row {
                        id: actionRow
                        anchors.centerIn: parent
                        spacing: 4

                        StyledRect {
                            implicitWidth: allLabel.implicitWidth + 30
                            implicitHeight: 32
                            radius: Tokens.rounding.full
                            color: !root.pinnedOnly
                                ? Qt.alpha(Colours.palette.m3primary, 0.16)
                                : "transparent"
                            border.width: !root.pinnedOnly ? 1 : 0
                            border.color: Qt.alpha(Colours.palette.m3primary, 0.68)

                            StyledText {
                                id: allLabel
                                anchors.centerIn: parent
                                text: qsTr("All")
                                font: Tokens.font.label.medium
                                color: !root.pinnedOnly
                                    ? Colours.palette.m3primary
                                    : Colours.palette.m3outline
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pinnedOnly = false
                            }
                        }

                        StyledRect {
                            implicitWidth: pinnedRow.implicitWidth + 24
                            implicitHeight: 32
                            radius: Tokens.rounding.full
                            color: root.pinnedOnly
                                ? Qt.alpha(Colours.palette.m3primary, 0.16)
                                : "transparent"
                            border.width: root.pinnedOnly ? 1 : 0
                            border.color: Qt.alpha(Colours.palette.m3primary, 0.68)

                            Row {
                                id: pinnedRow
                                anchors.centerIn: parent
                                spacing: 6

                                MaterialIcon {
                                    text: "keep"
                                    fill: root.pinnedOnly ? 1 : 0
                                    color: root.pinnedOnly
                                        ? Colours.palette.m3primary
                                        : Colours.palette.m3outline
                                    fontStyle: Tokens.font.icon.small
                                }

                                StyledText {
                                    text: qsTr("Pinned")
                                    font: Tokens.font.label.medium
                                    color: root.pinnedOnly
                                        ? Colours.palette.m3primary
                                        : Colours.palette.m3outline
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pinnedOnly = true
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: 20
                            color: Qt.alpha(Colours.palette.m3outlineVariant, 0.62)
                        }

                        StyledRect {
                            implicitWidth: clearRow.implicitWidth + 22
                            implicitHeight: 32
                            radius: Tokens.rounding.full
                            color: clearMouse.containsMouse
                                ? Qt.alpha(Colours.palette.m3primary, 0.13)
                                : "transparent"

                            Row {
                                id: clearRow
                                anchors.centerIn: parent
                                spacing: 6

                                MaterialIcon {
                                    text: "delete_sweep"
                                    color: clearMouse.containsMouse
                                        ? Colours.palette.m3primary
                                        : Colours.palette.m3outline
                                    fontStyle: Tokens.font.icon.small
                                }

                                StyledText {
                                    text: qsTr("Clear")
                                    font: Tokens.font.label.medium
                                    color: clearMouse.containsMouse
                                        ? Colours.palette.m3primary
                                        : Colours.palette.m3outline
                                }
                            }

                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.clearNonPinned()
                            }
                        }
                    }
                }
            }

            StyledRect {
                id: searchHost

                width: parent.width
                height: 50
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer
                border.width: searchInput.activeFocus ? 2 : 1
                border.color: searchInput.activeFocus
                    ? Qt.alpha(Colours.palette.m3primary, 0.86)
                    : Qt.alpha(Colours.palette.m3outlineVariant, 0.68)

                Behavior on border.color {
                    ColorAnimation { duration: 110 }
                }

                MaterialIcon {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    text: "search"
                    color: searchInput.activeFocus
                        ? Colours.palette.m3primary
                        : Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.medium
                }

                TextInput {
                    id: searchInput

                    anchors.left: searchIcon.right
                    anchors.leftMargin: 10
                    anchors.right: searchShortcut.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    height: 28

                    text: root.query
                    selectByMouse: true
                    clip: true
                    color: Colours.palette.m3onSurface
                    selectionColor: Qt.alpha(Colours.palette.m3primary, 0.38)
                    selectedTextColor: Colours.palette.m3onSurface
                    font: Tokens.font.body.large

                    onTextChanged: {
                        if (root.query !== text)
                            root.query = text;
                    }

                    Keys.onUpPressed: root.moveSelection(-1)
                    Keys.onDownPressed: root.moveSelection(1)
                    Keys.onReturnPressed: root.copyEntry(root.selectedEntry)
                    Keys.onEnterPressed: root.copyEntry(root.selectedEntry)
                    Keys.onEscapePressed: root.screenState.clipboard = false
                    Keys.onDeletePressed: {
                        if (selectionStart === selectionEnd && text.length === 0)
                            root.deleteEntry(root.selectedEntry);
                    }
                }

                StyledText {
                    visible: searchInput.text.length === 0
                    anchors.left: searchInput.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Search clipboard…")
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.large
                }

                StyledRect {
                    id: searchShortcut

                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: shortcutLabel.implicitWidth + 16
                    implicitHeight: 26
                    radius: Tokens.rounding.large
                    color: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.78)
                    border.width: 1
                    border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.55)

                    StyledText {
                        id: shortcutLabel
                        anchors.centerIn: parent
                        text: "Ctrl+F"
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }
                }
            }

            Rectangle {
                id: separator
                width: parent.width
                height: 1
                color: Qt.alpha(Colours.palette.m3outlineVariant, 0.58)
            }

            ListView {
                id: list

                width: parent.width
                height: Math.max(
                    150,
                    panelContent.height -
                    header.height -
                    searchHost.height -
                    separator.height -
                    footer.height -
                    panelContent.spacing * 4
                )

                model: root.filteredEntries
                clip: true
                spacing: 8
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: root.selectedIndex

                ScrollBar.vertical: ScrollBar {
                    policy: list.contentHeight > list.height
                        ? ScrollBar.AsNeeded
                        : ScrollBar.AlwaysOff
                }

                delegate: ClipboardItem {
                    required property var modelData
                    required property int index

                    width: list.width - (list.ScrollBar.vertical.visible ? 10 : 0)
                    entry: modelData.item
                    selected: index === root.selectedIndex

                    onSelectRequested: root.selectedIndex = index
                    onActivateRequested: root.copyEntry(modelData)
                    onDeleteRequested: root.deleteEntry(modelData)
                    onPinRequested: root.togglePin(modelData)
                }

                footer: Item {
                    width: 1
                    height: 5
                }

                Item {
                    anchors.centerIn: parent
                    width: 320
                    height: 132
                    visible: root.filteredEntries.length === 0

                    StyledRect {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 56
                        height: 56
                        radius: Tokens.rounding.extraLarge
                        color: Qt.alpha(Colours.palette.m3primary, 0.10)

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: root.query.length > 0
                                ? "search_off"
                                : "content_paste_off"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.large
                        }
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 70
                        text: root.query.length > 0
                            ? qsTr("No matching clipboard entries")
                            : qsTr("Clipboard history is empty")
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.medium
                    }
                }
            }

            StyledRect {
                id: footer

                width: parent.width
                height: 40
                radius: Tokens.rounding.large
                color: Qt.alpha(Colours.palette.m3surfaceContainer, 0.64)
                border.width: 1
                border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.42)

                Row {
                    id: hints

                    visible: root.statusText.length === 0
                    anchors.centerIn: parent
                    spacing: 15

                    Repeater {
                        model: [
                            { key: "↑ ↓", label: "Navigate" },
                            { key: "Enter", label: "Copy" },
                            { key: "Delete", label: "Remove" },
                            { key: "P", label: "Pin" },
                            { key: "Ctrl+F", label: "Search" }
                        ]

                        Row {
                            required property var modelData
                            spacing: 6

                            StyledRect {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: keyLabel.implicitWidth + 14
                                implicitHeight: 24
                                radius: Tokens.rounding.medium
                                color: Qt.alpha(Colours.palette.m3primary, 0.11)
                                border.width: 1
                                border.color: Qt.alpha(Colours.palette.m3primary, 0.28)

                                StyledText {
                                    id: keyLabel
                                    anchors.centerIn: parent
                                    text: modelData.key
                                    color: Colours.palette.m3primary
                                    font: Tokens.font.label.small
                                }
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.label
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                            }
                        }
                    }
                }

                Row {
                    visible: root.statusText.length > 0
                    anchors.centerIn: parent
                    spacing: 7

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "check_circle"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.statusText
                        color: Colours.palette.m3primary
                        font: Tokens.font.label.medium
                    }
                }
            }
        }
    }
}
