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

        selectedIndex = Math.max(0, Math.min(selectedIndex < 0 ? 0 : selectedIndex, filteredEntries.length - 1));
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
            search.forceActiveFocus();
            search.selectAll();
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
            search.forceActiveFocus();
            search.selectAll();
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

    StyledRect {
        id: panel
        anchors.centerIn: parent
        width: Math.min(780, parent.width - 70)
        height: Math.min(720, parent.height - 90)
        radius: Tokens.rounding.extraLarge
        color: Qt.alpha(Colours.tPalette.m3surfaceContainerHigh, 0.97)
        border.width: 1
        border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.82)

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: false
        }

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Row {
                width: parent.width
                height: 46
                spacing: 10

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "content_paste_search"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.extraLarge
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - toolbar.width - 58
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

                Row {
                    id: toolbar
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    StyledRect {
                        implicitWidth: pinnedText.implicitWidth + 24
                        implicitHeight: 34
                        radius: Tokens.rounding.full
                        color: root.pinnedOnly
                            ? Colours.palette.m3secondaryContainer
                            : Colours.palette.m3surfaceContainer

                        StyledText {
                            id: pinnedText
                            anchors.centerIn: parent
                            text: root.pinnedOnly ? qsTr("Pinned") : qsTr("All")
                            font: Tokens.font.label.medium
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.pinnedOnly = !root.pinnedOnly
                        }
                    }

                    StyledRect {
                        implicitWidth: clearText.implicitWidth + 24
                        implicitHeight: 34
                        radius: Tokens.rounding.full
                        color: Colours.palette.m3surfaceContainer

                        StyledText {
                            id: clearText
                            anchors.centerIn: parent
                            text: qsTr("Clear")
                            font: Tokens.font.label.medium
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.clearNonPinned()
                        }
                    }
                }
            }

            TextField {
                id: search
                width: parent.width
                height: 46
                placeholderText: qsTr("Search clipboard…")
                selectByMouse: true
                color: Colours.palette.m3onSurface
                placeholderTextColor: Colours.palette.m3outline
                font: Tokens.font.body.large
                leftPadding: 16
                rightPadding: 16

                background: StyledRect {
                    radius: Tokens.rounding.large
                    color: Colours.palette.m3surfaceContainer
                    border.width: search.activeFocus ? 2 : 1
                    border.color: search.activeFocus
                        ? Colours.palette.m3primary
                        : Colours.palette.m3outlineVariant
                }

                onTextChanged: root.query = text
                Keys.onUpPressed: root.moveSelection(-1)
                Keys.onDownPressed: root.moveSelection(1)
                Keys.onReturnPressed: root.copyEntry(root.selectedEntry)
                Keys.onEnterPressed: root.copyEntry(root.selectedEntry)
                Keys.onEscapePressed: root.screenState.clipboard = false
                Keys.onDeletePressed: {
                    if (selectionStart === selectionEnd)
                        root.deleteEntry(root.selectedEntry);
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Qt.alpha(Colours.palette.m3outlineVariant, 0.65)
            }

            ListView {
                id: list
                width: parent.width
                height: parent.height - 155
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

                footer: Item { width: 1; height: 4 }
            }

            StyledText {
                width: parent.width
                height: 18
                text: root.statusText.length > 0
                    ? root.statusText
                    : qsTr("↑↓ navigate · Enter copy · Delete remove · P pin · Ctrl+F search · right click pin")
                elide: Text.ElideRight
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
            }
        }

        Item {
            anchors.centerIn: parent
            width: 300
            height: 100
            visible: root.filteredEntries.length === 0

            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.query.length > 0 ? "search_off" : "content_paste_off"
                color: Colours.palette.m3outline
                fontStyle: Tokens.font.icon.extraLarge
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.verticalCenter
                anchors.topMargin: 8
                text: root.query.length > 0 ? qsTr("No matching clipboard entries") : qsTr("Clipboard history is empty")
                color: Colours.palette.m3outline
                font: Tokens.font.body.medium
            }
        }
    }
}
