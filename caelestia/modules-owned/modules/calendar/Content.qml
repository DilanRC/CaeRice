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
    function eventCount(day: int): int { return (payload.events || []).filter(event => { const d = eventDate(event); return d.getFullYear() === selectedDate.getFullYear() && d.getMonth() === selectedDate.getMonth() && d.getDate() === day; }).length; }
    function isToday(day: int): bool { return sameDay(new Date(), new Date(selectedDate.getFullYear(), selectedDate.getMonth(), day)); }
    function isSelected(day: int): bool { return day === selectedDate.getDate(); }
    function friendlyName(calendar): string { return calendar.calendarName.includes("@") ? qsTr("Personal") : calendar.calendarName; }
    function timeLeft(): string {
        const ms = pomodoro.phase === "PAUSED" ? Number(pomodoro.pausedRemainingMs || 0) : Math.max(0, Number(pomodoro.targetEndTimestamp || 0) * 1000 - nowMs);
        return `${String(Math.floor(ms / 60000)).padStart(2, "0")}:${String(Math.floor(ms / 1000) % 60).padStart(2, "0")}`;
    }
    function changeMonth(delta: int): void { selectedDate = new Date(selectedDate.getFullYear(), selectedDate.getMonth() + delta, 1); }
    function load(): void { try { payload = JSON.parse(cache.text()); } catch (_) { payload = {}; } try { selection = JSON.parse(selectionFile.text()); } catch (_) { selection = {}; } try { pomodoro = JSON.parse(pomodoroFile.text()); } catch (_) { pomodoro = {}; } }

    Component.onCompleted: load()
    FileView { id: cache; path: root.cachePath; watchChanges: true; printErrors: false; onLoaded: root.load(); onFileChanged: root.load() }
    FileView { id: selectionFile; path: `${Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`}/caelestia/calendar-selection.json`; watchChanges: true; printErrors: false; onLoaded: root.load(); onFileChanged: root.load() }
    FileView { id: pomodoroFile; path: `${Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`}/caelestia/pomodoro.json`; watchChanges: true; printErrors: false; onLoaded: root.load(); onFileChanged: root.load() }
    Process { id: selectionProcess }
    Process { id: pomoProcess; onExited: root.load() }
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
                                required property int index
                                Layout.fillWidth: true; Layout.fillHeight: true
                                readonly property int day: { const value = index - root.firstOffset(root.selectedDate) + 1; return value > 0 && value <= root.daysInMonth(root.selectedDate) ? value : 0; }
                                StyledRect { anchors.centerIn: parent; width: 34; height: 34; radius: 17; color: root.isSelected(parent.day) ? Colours.palette.m3primary : (root.isToday(parent.day) ? Colours.palette.m3primaryContainer : "transparent") }
                                StyledText { anchors.centerIn: parent; text: parent.day || ""; color: root.isSelected(parent.day) ? Colours.palette.m3onPrimary : (root.isToday(parent.day) ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface); font: Tokens.font.label.medium }
                                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; width: parent.day && root.eventCount(parent.day) ? Math.min(12, 4 + root.eventCount(parent.day) * 2) : 0; height: 4; radius: 2; color: Colours.palette.m3tertiary }
                                MouseArea { anchors.fill: parent; enabled: parent.day > 0; hoverEnabled: true; onClicked: root.selectedDate = new Date(root.selectedDate.getFullYear(), root.selectedDate.getMonth(), parent.day) }
                            }
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.small
                        Repeater {
                            model: root.payload.calendars || []
                            delegate: CheckBox {
                                required property var modelData
                                text: root.friendlyName(modelData)
                                checked: (root.selection.enabled || []).includes(modelData.calendarId)
                                onToggled: { selectionProcess.command = [Quickshell.env("HOME") + "/.local/bin/caerice-calendar", "set-selection", modelData.calendarId, checked ? "true" : "false"]; selectionProcess.running = true; }
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
                            StyledText { text: root.selectedEvents.length ? qsTr("Selected day") : qsTr("No events for this day"); color: Colours.palette.m3primary; font: Tokens.font.label.medium }
                            ListView {
                                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; model: root.selectedEvents
                                delegate: RowLayout {
                                    required property var modelData; width: parent.width; spacing: Tokens.spacing.small
                                    Rectangle { implicitWidth: 7; implicitHeight: 32; radius: 4; color: modelData.calendarColor || Colours.palette.m3primary }
                                    ColumnLayout { Layout.fillWidth: true; StyledText { Layout.fillWidth: true; text: modelData.title; elide: Text.ElideRight; color: Colours.palette.m3onSurface; font: Tokens.font.body.large } StyledText { text: modelData.allDay ? qsTr("All day") : Qt.formatTime(root.eventDate(modelData), "HH:mm"); color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small } }
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
                            RowLayout { Layout.fillWidth: true; Item { Layout.fillWidth: true } Button { text: pomodoro.phase === "FOCUS" || pomodoro.phase === "BREAK" ? qsTr("Pause") : pomodoro.phase === "PAUSED" ? qsTr("Resume") : qsTr("Start"); onClicked: { pomoProcess.command = [Quickshell.env("HOME") + "/.local/bin/caerice-pomodoro", pomodoro.phase === "FOCUS" || pomodoro.phase === "BREAK" ? "pause" : pomodoro.phase === "PAUSED" ? "resume" : "start"]; pomoProcess.running = true; } } Button { text: qsTr("Reset"); onClicked: { pomoProcess.command = [Quickshell.env("HOME") + "/.local/bin/caerice-pomodoro", "reset"]; pomoProcess.running = true; } } }
                        }
                    }
                }
            }
        }
    }
}
