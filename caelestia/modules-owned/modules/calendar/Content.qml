pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root
    focus: true
    required property ScreenState screenState
    property var payload: ({})
    property var selection: ({})
    property var pomodoro: ({})
    property date selectedDate: new Date()
    property double nowMs: Date.now()
    property string syncStatus: ""
    readonly property string cachePath: `${Quickshell.env("XDG_CACHE_HOME") || `${Quickshell.env("HOME")}/.cache`}/caelestia/calendar-events.json`
    readonly property string selectionPath: `${Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`}/caelestia/calendar-selection.json`
    readonly property string pomodoroPath: `${Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`}/caelestia/pomodoro.json`
    readonly property string calendarHelperPath: `${Quickshell.env("HOME")}/.local/bin/caerice-calendar`
    readonly property string pomodoroHelperPath: `${Quickshell.env("HOME")}/.local/bin/caerice-pomodoro`
    readonly property var selectedEvents: (payload.events || []).filter(event => eventOccursOnDate(event, selectedDate))

    function eventDate(event): date {
        if (event.allDay) {
            const parts = event.start.split("-");
            return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
        }
        return new Date(event.start);
    }
    function sameDay(a: date, b: date): bool {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate();
    }
    function daysInMonth(d: date): int { return new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate(); }
    function firstOffset(d: date): int { return (new Date(d.getFullYear(), d.getMonth(), 1).getDay() + 6) % 7; }
    function dayStart(value: date): date { return new Date(value.getFullYear(), value.getMonth(), value.getDate()); }
    function eventEndDate(event): date {
        if (event.allDay) {
            const parts = event.end.split("-");
            return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]), 0, 0, 0, -1);
        }
        return new Date(new Date(event.end).getTime() - 1);
    }
    function eventOccursOnDate(event, value: date): bool {
        const target = dayStart(value).getTime();
        return target >= dayStart(eventDate(event)).getTime()
            && target <= dayStart(eventEndDate(event)).getTime();
    }
    function eventsForDay(day: int): var {
        const target = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), day);
        return (payload.events || []).filter(event => eventOccursOnDate(event, target));
    }
    function isToday(day: int): bool { return day > 0 && sameDay(new Date(), new Date(selectedDate.getFullYear(), selectedDate.getMonth(), day)); }
    function isSelected(day: int): bool { return day > 0 && day === selectedDate.getDate(); }
    function friendlyName(calendar): string { return calendar.primary ? qsTr("Personal") : calendar.calendarName; }
    function eventTime(event): string {
        if (event.allDay) return qsTr("All day");
        return `${Qt.formatTime(eventDate(event), "HH:mm")}–${Qt.formatTime(new Date(event.end), "HH:mm")}`;
    }
    function isBreakPhase(phase): bool { return phase === "BREAK" || phase === "LONG_BREAK"; }
    function isActivePhase(phase): bool { return phase === "FOCUS" || isBreakPhase(phase); }
    function phaseDurationMs(phase): double {
        if (phase === "LONG_BREAK") return Number(pomodoro.longBreakMinutes || 15) * 60000;
        if (phase === "BREAK") return Number(pomodoro.shortBreakMinutes || 5) * 60000;
        return Number(pomodoro.focusMinutes || 25) * 60000;
    }
    function remainingMs(): double {
        if (pomodoro.phase === "PAUSED") return Math.max(0, Number(pomodoro.pausedRemainingMs || 0));
        if (isActivePhase(pomodoro.phase)) return Math.max(0, Number(pomodoro.targetEndTimestamp || 0) * 1000 - nowMs);
        return phaseDurationMs("FOCUS");
    }
    function timeLeft(): string {
        const ms = remainingMs();
        return `${String(Math.floor(ms / 60000)).padStart(2, "0")}:${String(Math.floor(ms / 1000) % 60).padStart(2, "0")}`;
    }
    function progress(): double {
        const phase = pomodoro.phase === "PAUSED" ? (pomodoro.pausedPhase || "FOCUS") : pomodoro.phase;
        if (!isActivePhase(phase)) return 0;
        return Math.max(0, Math.min(1, 1 - remainingMs() / Math.max(1, phaseDurationMs(phase))));
    }
    function phaseLabel(): string {
        if (pomodoro.phase === "FOCUS") return qsTr("Focus");
        if (pomodoro.phase === "BREAK") return qsTr("Short break");
        if (pomodoro.phase === "LONG_BREAK") return qsTr("Long break");
        if (pomodoro.phase === "PAUSED") return qsTr("Paused");
        return qsTr("Ready to focus");
    }
    function runPomodoro(command: string): void {
        if (pomoProcess.running) return;
        const next = Object.assign({}, pomodoro);
        const now = Date.now();
        root.nowMs = now;
        if (command === "start") {
            next.phase = "FOCUS"; next.targetEndTimestamp = now / 1000 + Number(next.focusMinutes || 25) * 60;
            next.pausedRemainingMs = 0; next.pausedPhase = "FOCUS";
        } else if (command === "pause" && isActivePhase(next.phase)) {
            next.pausedRemainingMs = Math.max(0, Number(next.targetEndTimestamp || 0) * 1000 - now);
            next.pausedPhase = next.phase; next.targetEndTimestamp = 0; next.phase = "PAUSED";
        } else if (command === "resume" && next.phase === "PAUSED") {
            next.phase = next.pausedPhase || "FOCUS";
            next.targetEndTimestamp = now / 1000 + Number(next.pausedRemainingMs || 0) / 1000;
            next.pausedRemainingMs = 0;
        } else if (command === "skip" && isBreakPhase(next.phase)) {
            next.phase = "FOCUS"; next.targetEndTimestamp = now / 1000 + Number(next.focusMinutes || 25) * 60;
            next.pausedRemainingMs = 0; next.pausedPhase = "FOCUS";
        } else if (command === "reset") {
            next.phase = "IDLE"; next.targetEndTimestamp = 0; next.pausedRemainingMs = 0;
            next.pausedPhase = "FOCUS"; next.completedSessions = 0;
        }
        root.pomodoro = next;
        pomoProcess.command = [root.pomodoroHelperPath, command];
        pomoProcess.running = true;
    }
    function changeMonth(delta: int): void { selectedDate = new Date(selectedDate.getFullYear(), selectedDate.getMonth() + delta, 1); }
    function loadCalendar(): void { try { payload = JSON.parse(cache.text()); } catch (_) { payload = {}; } }
    function loadSelection(): void { try { selection = JSON.parse(selectionFile.text()); } catch (_) { selection = {}; } }
    function loadPomodoro(): void { try { pomodoro = JSON.parse(pomodoroFile.text()); } catch (_) { pomodoro = {}; } }
    function load(): void { loadCalendar(); loadSelection(); loadPomodoro(); }
    function requestCalendarSync(force = false): void {
        if (calendarSync.running) return;
        syncStatus = qsTr("Syncing…");
        calendarSync.command = force ? [calendarHelperPath, "sync", "--force"] : [calendarHelperPath, "sync"];
        calendarSync.running = true;
    }

    component FocusButton: StyledRect {
        required property string label
        signal clicked()
        implicitWidth: buttonLabel.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: 30
        radius: Tokens.rounding.small
        color: buttonMouse.containsMouse ? Colours.palette.m3secondary : Colours.palette.m3surfaceContainerHigh
        StyledText { id: buttonLabel; anchors.centerIn: parent; text: parent.label; color: Colours.palette.m3onSurface; font: Tokens.font.label.medium }
        MouseArea { id: buttonMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }

    Component.onCompleted: {
        load();
        if (screenState.calendar) requestCalendarSync();
    }
    Connections {
        target: root.screenState
        function onCalendarChanged(): void {
            if (root.screenState.calendar) root.requestCalendarSync();
        }
    }
    FileView { id: cache; path: root.cachePath; watchChanges: true; printErrors: false; onLoaded: root.loadCalendar(); onFileChanged: root.loadCalendar() }
    FileView { id: selectionFile; path: root.selectionPath; watchChanges: true; printErrors: false; onLoaded: root.loadSelection(); onFileChanged: root.loadSelection() }
    FileView { id: pomodoroFile; path: root.pomodoroPath; watchChanges: true; printErrors: false; onLoaded: root.loadPomodoro(); onFileChanged: pomodoroReload.restart() }
    Process {
        id: calendarSync
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text.trim());
                    syncStatus = result.status === "ok" ? qsTr("Up to date")
                        : result.status === "cached" ? qsTr("Recently synced")
                        : result.status === "partial" ? qsTr("Partial sync")
                        : result.status === "auth_required" ? qsTr("Sign-in required")
                        : result.status === "sync_in_progress" ? qsTr("Sync already running")
                        : qsTr("Sync failed");
                } catch (_) { syncStatus = qsTr("Sync failed"); }
                root.loadCalendar();
            }
        }
    }
    Process { id: selectionProcess; onExited: { root.loadSelection(); root.requestCalendarSync(true); } }
    Process {
        id: pomoProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.pomodoro = JSON.parse(text.trim()); }
                catch (_) { pomodoroReload.restart(); }
            }
        }
        onExited: pomodoroReload.restart()
    }
    Timer { id: pomodoroReload; interval: 60; repeat: false; onTriggered: root.loadPomodoro() }
    Timer { interval: 1000; repeat: true; running: root.isActivePhase(pomodoro.phase); onTriggered: root.nowMs = Date.now() }
    Keys.onEscapePressed: root.screenState.calendar = false

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainer

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                StyledText { Layout.fillWidth: true; text: qsTr("Calendar"); font: Tokens.font.title.large; color: Colours.palette.m3onSurface }
                StyledText { visible: root.syncStatus.length > 0; text: root.syncStatus; font: Tokens.font.label.small; color: Colours.palette.m3onSurfaceVariant }
                Item { implicitWidth: 32; implicitHeight: 32; MaterialIcon { anchors.centerIn: parent; text: calendarSync.running ? "sync" : "refresh"; color: Colours.palette.m3onSurfaceVariant } MouseArea { anchors.fill: parent; enabled: !calendarSync.running; cursorShape: Qt.PointingHandCursor; onClicked: root.requestCalendarSync(true) } }
                Item { implicitWidth: 32; implicitHeight: 32; MaterialIcon { anchors.centerIn: parent; text: "close"; color: Colours.palette.m3onSurfaceVariant } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.screenState.calendar = false } }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Tokens.spacing.large

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 430
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        Item { implicitWidth: 32; implicitHeight: 32; MaterialIcon { anchors.centerIn: parent; text: "chevron_left"; color: Colours.palette.m3onSurface } MouseArea { anchors.fill: parent; onClicked: root.changeMonth(-1) } }
                        StyledText { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(root.selectedDate, "MMMM yyyy"); font: Tokens.font.title.medium; color: Colours.palette.m3onSurface }
                        Button { text: qsTr("Today"); flat: true; onClicked: root.selectedDate = new Date() }
                        Item { implicitWidth: 32; implicitHeight: 32; MaterialIcon { anchors.centerIn: parent; text: "chevron_right"; color: Colours.palette.m3onSurface } MouseArea { anchors.fill: parent; onClicked: root.changeMonth(1) } }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 290
                        columns: 7
                        Repeater { model: [qsTr("Mo"), qsTr("Tu"), qsTr("We"), qsTr("Th"), qsTr("Fr"), qsTr("Sa"), qsTr("Su")]; delegate: StyledText { required property var modelData; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: modelData; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small } }
                        Repeater {
                            model: 42
                            delegate: Item {
                                id: dayCell
                                required property int index
                                Layout.fillWidth: true; Layout.fillHeight: true
                                readonly property int day: { const value = index - root.firstOffset(root.selectedDate) + 1; return value > 0 && value <= root.daysInMonth(root.selectedDate) ? value : 0; }
                                StyledRect { anchors.centerIn: parent; width: 34; height: 34; radius: 17; color: root.isSelected(parent.day) ? Colours.palette.m3primary : (root.isToday(parent.day) ? Colours.palette.m3primaryContainer : "transparent") }
                                StyledText { anchors.centerIn: parent; text: parent.day || ""; color: root.isSelected(parent.day) ? Colours.palette.m3onPrimary : (root.isToday(parent.day) ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface); font: Tokens.font.label.medium }
                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; spacing: 2
                                    Repeater {
                                        model: dayCell.day ? root.eventsForDay(dayCell.day).slice(0, 3) : []
                                        delegate: Rectangle { required property var modelData; width: 4; height: 4; radius: 2; color: modelData.calendarColor || Colours.palette.m3tertiary }
                                    }
                                    StyledText { visible: dayCell.day && root.eventsForDay(dayCell.day).length > 3; text: "+"; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small }
                                }
                                MouseArea { anchors.fill: parent; enabled: parent.day > 0; hoverEnabled: true; onClicked: root.selectedDate = new Date(root.selectedDate.getFullYear(), root.selectedDate.getMonth(), parent.day) }
                            }
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small
                        Repeater {
                            model: root.payload.calendars || []
                            delegate: StyledRect {
                                required property var modelData
                                readonly property bool enabled: (root.selection.enabled || []).includes(modelData.calendarId)
                                implicitWidth: chipRow.implicitWidth + Tokens.padding.medium * 2; implicitHeight: 30; radius: Tokens.rounding.full
                                color: enabled ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh
                                RowLayout {
                                    id: chipRow; anchors.centerIn: parent; spacing: Tokens.spacing.small
                                    Rectangle { implicitWidth: 8; implicitHeight: 8; radius: 4; color: modelData.calendarColor || Colours.palette.m3secondary }
                                    StyledText { text: root.friendlyName(modelData); color: parent.parent.enabled ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.medium }
                                    StyledText { text: parent.parent.enabled ? "✓" : "+"; color: parent.parent.enabled ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.medium }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { selectionProcess.command = [Quickshell.env("HOME") + "/.local/bin/caerice-calendar", "set-selection", modelData.calendarId, parent.enabled ? "false" : "true"]; selectionProcess.running = true; } }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 350
                    spacing: Tokens.spacing.medium

                    StyledRect {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Tokens.rounding.medium
                        color: Colours.palette.m3surfaceContainerHigh
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: Tokens.padding.medium; spacing: Tokens.spacing.small
                            StyledText { Layout.fillWidth: true; text: Qt.formatDate(root.selectedDate, "dddd, MMMM d"); font: Tokens.font.title.medium; color: Colours.palette.m3onSurface }
                            StyledText { text: root.selectedEvents.length ? `${root.selectedEvents.length} ${root.selectedEvents.length === 1 ? qsTr("event") : qsTr("events")}` : qsTr("Your day is clear"); color: Colours.palette.m3primary; font: Tokens.font.label.medium }
                            ColumnLayout {
                                visible: !root.selectedEvents.length; Layout.fillWidth: true; Layout.fillHeight: true; spacing: Tokens.spacing.small
                                Item { Layout.fillHeight: true }
                                MaterialIcon { Layout.alignment: Qt.AlignHCenter; text: "event_available"; color: Colours.palette.m3onSurfaceVariant; fontStyle: Tokens.font.icon.large }
                                StyledText { Layout.alignment: Qt.AlignHCenter; text: qsTr("No events"); color: Colours.palette.m3onSurface; font: Tokens.font.title.small }
                                StyledText { Layout.alignment: Qt.AlignHCenter; text: qsTr("Take the time for yourself."); color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.body.small }
                                Item { Layout.fillHeight: true }
                            }
                            ListView {
                                visible: root.selectedEvents.length > 0; Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: Tokens.spacing.small; model: root.selectedEvents
                                delegate: RowLayout {
                                    required property var modelData; width: parent.width; spacing: Tokens.spacing.small
                                    Rectangle { implicitWidth: 5; implicitHeight: eventDetails.implicitHeight; radius: 3; color: modelData.calendarColor || Colours.palette.m3primary }
                                    ColumnLayout {
                                        id: eventDetails; Layout.fillWidth: true; spacing: 1
                                        StyledText { Layout.fillWidth: true; text: modelData.title; elide: Text.ElideRight; color: Colours.palette.m3onSurface; font: Tokens.font.body.large }
                                        StyledText { Layout.fillWidth: true; text: `${root.eventTime(modelData)}  ·  ${root.friendlyName(modelData)}`; elide: Text.ElideRight; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small }
                                        StyledText { visible: !!modelData.location; Layout.fillWidth: true; text: modelData.location; elide: Text.ElideRight; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small }
                                    }
                                }
                            }
                        }
                    }

                    StyledRect {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 154
                        radius: Tokens.rounding.medium
                        color: Colours.palette.m3secondaryContainer
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: Tokens.padding.medium; spacing: Tokens.spacing.small
                            RowLayout { Layout.fillWidth: true; StyledText { Layout.fillWidth: true; text: root.phaseLabel(); color: Colours.palette.m3onSecondaryContainer; font: Tokens.font.label.large } StyledText { text: qsTr("%1 sessions").arg(Number(pomodoro.completedSessions || 0)); color: Colours.palette.m3onSecondaryContainer; font: Tokens.font.label.small } }
                            StyledText { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: root.timeLeft(); color: Colours.palette.m3onSecondaryContainer; font: Tokens.font.display.small }
                            Rectangle { Layout.fillWidth: true; implicitHeight: 5; radius: 3; color: Colours.palette.m3secondary; Rectangle { height: parent.height; width: parent.width * root.progress(); radius: 3; color: Colours.palette.m3onSecondaryContainer; Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } } } }
                            RowLayout { Layout.fillWidth: true; Item { Layout.fillWidth: true } FocusButton { visible: root.isBreakPhase(pomodoro.phase); label: qsTr("Skip break"); onClicked: root.runPomodoro("skip") } FocusButton { label: root.isActivePhase(pomodoro.phase) ? qsTr("Pause") : pomodoro.phase === "PAUSED" ? qsTr("Resume") : qsTr("Start"); onClicked: root.runPomodoro(root.isActivePhase(pomodoro.phase) ? "pause" : pomodoro.phase === "PAUSED" ? "resume" : "start") } FocusButton { label: qsTr("Reset"); onClicked: root.runPomodoro("reset") } }
                        }
                    }
                }
            }
        }
    }
}
