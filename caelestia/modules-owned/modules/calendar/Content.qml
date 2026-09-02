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
    readonly property string cachePath: `${Quickshell.env("XDG_CACHE_HOME") || `${Quickshell.env("HOME")}/.cache`}/caelestia/calendar-events.json`
    readonly property var selectedEvents: (payload.events || []).filter(event => sameDay(eventDate(event), selectedDate))

    function eventDate(event): date {
        if (event.allDay) {
            const parts = event.start.split("-");
            return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
        }
        return new Date(event.start);
    }
    function sameDay(a: date, b: date): bool { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate(); }
    function daysInMonth(d: date): int { return new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate(); }
    function firstOffset(d: date): int { return (new Date(d.getFullYear(), d.getMonth(), 1).getDay() + 6) % 7; }
    function eventsForDay(day: int): var { return (payload.events || []).filter(event => { const d = eventDate(event); return d.getFullYear() === selectedDate.getFullYear() && d.getMonth() === selectedDate.getMonth() && d.getDate() === day; }); }
    function isToday(day: int): bool { return sameDay(new Date(), new Date(selectedDate.getFullYear(), selectedDate.getMonth(), day)); }
    function isSelected(day: int): bool { return day === selectedDate.getDate(); }
    function friendlyName(calendar): string { return calendar.primary ? qsTr("Personal") : calendar.calendarName; }
    function eventTime(event): string {
        if (event.allDay) return qsTr("All day");
        return `${Qt.formatTime(eventDate(event), "HH:mm")}–${Qt.formatTime(new Date(event.end), "HH:mm")}`;
    }
    function timeLeft(): string {
        const ms = pomodoro.phase === "PAUSED" ? Number(pomodoro.pausedRemainingMs || 0) : Math.max(0, Number(pomodoro.targetEndTimestamp || 0) * 1000 - nowMs);
        return `${String(Math.floor(ms / 60000)).padStart(2, "0")}:${String(Math.floor(ms / 1000) % 60).padStart(2, "0")}`;
    }
    function runPomodoro(command: string): void {
        const next = Object.assign({}, pomodoro);
        const now = Date.now();
        if (command === "start") { next.phase = "FOCUS"; next.targetEndTimestamp = now / 1000 + Number(next.focusMinutes || 25) * 60; }
        else if (command === "pause") { next.pausedRemainingMs = Math.max(0, Number(next.targetEndTimestamp || 0) * 1000 - now); next.pausedPhase = next.phase; next.targetEndTimestamp = 0; next.phase = "PAUSED"; }
        else if (command === "resume") { next.phase = next.pausedPhase || "FOCUS"; next.targetEndTimestamp = now / 1000 + Number(next.pausedRemainingMs || 0) / 1000; }
        else if (command === "skip") { next.phase = "FOCUS"; next.targetEndTimestamp = now / 1000 + Number(next.focusMinutes || 25) * 60; }
        else if (command === "reset") { next.phase = "IDLE"; next.targetEndTimestamp = 0; next.pausedRemainingMs = 0; }
        root.pomodoro = next;
        pomoProcess.command = [Quickshell.env("HOME") + "/.local/bin/caerice-pomodoro", command];
        pomoProcess.running = true;
    }
    function changeMonth(delta: int): void { selectedDate = new Date(selectedDate.getFullYear(), selectedDate.getMonth() + delta, 1); }
    function load(): void { try { payload = JSON.parse(cache.text()); } catch (_) { payload = {}; } try { selection = JSON.parse(selectionFile.text()); } catch (_) { selection = {}; } try { pomodoro = JSON.parse(pomodoroFile.text()); } catch (_) { pomodoro = {}; } }

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

    Component.onCompleted: load()
    FileView { id: cache; path: root.cachePath; watchChanges: true; printErrors: false; onLoaded: root.load(); onFileChanged: root.load() }
    FileView { id: selectionFile; path: `${Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`}/caelestia/calendar-selection.json`; watchChanges: true; printErrors: false; onLoaded: root.load(); onFileChanged: root.load() }
    FileView { id: pomodoroFile; path: `${Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`}/caelestia/pomodoro.json`; watchChanges: true; printErrors: false; onLoaded: root.load() }
    Process { id: selectionProcess }
    Process {
        id: pomoProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.pomodoro = JSON.parse(text.trim()); }
                catch (_) { root.load(); }
            }
        }
    }
    Timer { interval: 1000; repeat: true; running: pomodoro.phase === "FOCUS" || pomodoro.phase === "BREAK"; onTriggered: root.nowMs = Date.now() }
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
                Item { implicitWidth: 32; implicitHeight: 32; MaterialIcon { anchors.centerIn: parent; text: "close"; color: Colours.palette.m3onSurfaceVariant } MouseArea { anchors.fill: parent; onClicked: root.screenState.calendar = false } }
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
                            StyledText { text: pomodoro.phase || qsTr("FOCUS"); color: Colours.palette.m3onSecondaryContainer; font: Tokens.font.label.large }
                            StyledText { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: root.timeLeft(); color: Colours.palette.m3onSecondaryContainer; font: Tokens.font.display.small }
                            Rectangle { Layout.fillWidth: true; implicitHeight: 5; radius: 3; color: Colours.palette.m3secondary; Rectangle { height: parent.height; width: pomodoro.phase === "FOCUS" || pomodoro.phase === "BREAK" ? parent.width * Math.max(0, Math.min(1, 1 - ((Number(pomodoro.targetEndTimestamp || 0) * 1000 - root.nowMs) / ((pomodoro.phase === "BREAK" ? Number(pomodoro.shortBreakMinutes || 5) : Number(pomodoro.focusMinutes || 25)) * 60000)))) : 0; radius: 3; color: Colours.palette.m3onSecondaryContainer } }
                            RowLayout { Layout.fillWidth: true; Item { Layout.fillWidth: true } FocusButton { visible: pomodoro.phase === "BREAK"; label: qsTr("Skip break"); onClicked: root.runPomodoro("skip") } FocusButton { label: pomodoro.phase === "FOCUS" || pomodoro.phase === "BREAK" ? qsTr("Pause") : pomodoro.phase === "PAUSED" ? qsTr("Resume") : qsTr("Start"); onClicked: root.runPomodoro(pomodoro.phase === "FOCUS" || pomodoro.phase === "BREAK" ? "pause" : pomodoro.phase === "PAUSED" ? "resume" : "start") } FocusButton { label: qsTr("Reset"); onClicked: root.runPomodoro("reset") } }
                        }
                    }
                }
            }
        }
    }
}
