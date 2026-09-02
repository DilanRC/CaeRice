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
    property date selectedDate: new Date()
    property var selection: ({})
    property var pomodoro: ({})
    property double nowMs: Date.now()
    readonly property string cachePath: `${Quickshell.env("XDG_CACHE_HOME") || `${Quickshell.env("HOME")}/.cache`}/caelestia/calendar-events.json`

    function load(): void {
        try { payload = JSON.parse(cache.text()); } catch (_) { payload = {}; }
        try { selection = JSON.parse(selectionFile.text()); } catch (_) { selection = {}; }
        try { pomodoro = JSON.parse(pomodoroFile.text()); } catch (_) { pomodoro = {}; }
    }
    function daysInMonth(d: date): int { return new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate(); }
    function firstOffset(d: date): int { return (new Date(d.getFullYear(), d.getMonth(), 1).getDay() + 6) % 7; }
    function eventCount(day: int): int {
        let count = 0;
        for (const event of (payload.events || [])) {
            const start = new Date(event.start);
            if (start.getFullYear() === selectedDate.getFullYear() && start.getMonth() === selectedDate.getMonth() && start.getDate() === day)
                count += 1;
        }
        return count;
    }
    function isToday(day: int): bool {
        const today = new Date();
        return today.getFullYear() === selectedDate.getFullYear() && today.getMonth() === selectedDate.getMonth() && today.getDate() === day;
    }

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
            spacing: Tokens.spacing.small

            RowLayout {
                Layout.fillWidth: true
                Item {
                    implicitWidth: 32; implicitHeight: 32
                    MaterialIcon { anchors.centerIn: parent; text: "chevron_left"; color: Colours.palette.m3onSurface }
                    MouseArea { anchors.fill: parent; onClicked: root.selectedDate = new Date(root.selectedDate.getFullYear(), root.selectedDate.getMonth() - 1, 1) }
                }
                StyledText { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(root.selectedDate, "MMMM yyyy"); font: Tokens.font.title.large; color: Colours.palette.m3onSurface }
                Item {
                    implicitWidth: 32; implicitHeight: 32
                    MaterialIcon { anchors.centerIn: parent; text: "chevron_right"; color: Colours.palette.m3onSurface }
                    MouseArea { anchors.fill: parent; onClicked: root.selectedDate = new Date(root.selectedDate.getFullYear(), root.selectedDate.getMonth() + 1, 1) }
                }
                Item {
                    implicitWidth: 32
                    implicitHeight: 32
                    MaterialIcon { anchors.centerIn: parent; text: "close"; color: Colours.palette.m3onSurface }
                    MouseArea { anchors.fill: parent; onClicked: root.screenState.calendar = false }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 250
                columns: 7
                Repeater {
                    model: [qsTr("Mo"), qsTr("Tu"), qsTr("We"), qsTr("Th"), qsTr("Fr"), qsTr("Sa"), qsTr("Su")]
                    delegate: StyledText { required property var modelData; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: modelData; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small }
                }
                Repeater {
                    model: 42
                    delegate: Item {
                        required property int index
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        readonly property int day: {
                            const day = index - root.firstOffset(root.selectedDate) + 1;
                            return day > 0 && day <= root.daysInMonth(root.selectedDate) ? day : 0;
                        }
                        StyledRect { anchors.centerIn: parent; width: 30; height: 30; radius: 15; color: root.isToday(parent.day) ? Colours.palette.m3primaryContainer : "transparent" }
                        StyledText { anchors.centerIn: parent; text: parent.day || ""; color: root.isToday(parent.day) ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface; font: Tokens.font.label.medium }
                        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; width: parent.day && root.eventCount(parent.day) ? 5 : 0; height: width; radius: width / 2; color: Colours.palette.m3primary }
                        MouseArea { anchors.fill: parent; enabled: parent.day > 0; onClicked: root.selectedDate = new Date(root.selectedDate.getFullYear(), root.selectedDate.getMonth(), parent.day) }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.payload.status === "auth_required" ? qsTr("Connect Google Calendar") : (root.payload.events?.length ? qsTr("Upcoming") : qsTr("No upcoming events"))
                color: Colours.palette.m3primary
                font: Tokens.font.title.medium
            }

            RowLayout {
                Layout.fillWidth: true
                StyledText { Layout.fillWidth: true; text: qsTr("Calendars"); color: Colours.palette.m3onSurface; font: Tokens.font.title.small }
                Repeater {
                    model: root.payload.calendars || []
                    delegate: CheckBox {
                        required property var modelData
                        text: modelData.calendarName
                        checked: (root.selection.enabled || []).includes(modelData.calendarId)
                        onToggled: {
                            selectionProcess.command = [Quickshell.env("HOME") + "/.local/bin/caerice-calendar", "set-selection", modelData.calendarId, checked ? "true" : "false"];
                            selectionProcess.running = true;
                        }
                    }
                }
            }

            ListView {
                id: agenda
                Layout.fillWidth: true
                Layout.preferredHeight: 116
                clip: true
                model: root.payload.events || []
                delegate: RowLayout {
                    required property var modelData
                    width: agenda.width
                    spacing: Tokens.spacing.small
                    StyledText { Layout.preferredWidth: 62; text: modelData.allDay ? qsTr("All day") : Qt.formatTime(new Date(modelData.start), "HH:mm"); color: Colours.palette.m3secondary; font: Tokens.font.label.medium }
                    Rectangle { implicitWidth: 8; implicitHeight: 8; radius: 4; color: modelData.calendarColor || Colours.palette.m3primary }
                    ColumnLayout {
                        Layout.fillWidth: true
                        StyledText { Layout.fillWidth: true; text: modelData.title; elide: Text.ElideRight; color: Colours.palette.m3onSurface; font: Tokens.font.body.large }
                        StyledText { text: modelData.calendarName; color: Colours.palette.m3onSurfaceVariant; font: Tokens.font.label.small }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Colours.palette.m3outlineVariant }
            RowLayout {
                Layout.fillWidth: true
                StyledText { Layout.fillWidth: true; text: qsTr("FOCUS"); color: Colours.palette.m3primary; font: Tokens.font.title.small }
                StyledText { text: {
                    const ms = pomodoro.phase === "PAUSED" ? Number(pomodoro.pausedRemainingMs || 0) : Math.max(0, (Number(pomodoro.targetEndTimestamp || 0) * 1000) - root.nowMs);
                    return `${String(Math.floor(ms / 60000)).padStart(2, "0")}:${String(Math.floor(ms / 1000) % 60).padStart(2, "0")}`;
                } color: Colours.palette.m3onSurface; font: Tokens.font.title.large }
                Button { text: pomodoro.phase === "FOCUS" || pomodoro.phase === "BREAK" ? qsTr("Pause") : pomodoro.phase === "PAUSED" ? qsTr("Resume") : qsTr("Start"); onClicked: { pomoProcess.command = [Quickshell.env("HOME") + "/.local/bin/caerice-pomodoro", pomodoro.phase === "FOCUS" || pomodoro.phase === "BREAK" ? "pause" : pomodoro.phase === "PAUSED" ? "resume" : "start"]; pomoProcess.running = true; } }
                Button { text: qsTr("Reset"); onClicked: { pomoProcess.command = [Quickshell.env("HOME") + "/.local/bin/caerice-pomodoro", "reset"]; pomoProcess.running = true; } }
                Button { visible: pomodoro.phase === "BREAK"; text: qsTr("Skip break"); onClicked: { pomoProcess.command = [Quickshell.env("HOME") + "/.local/bin/caerice-pomodoro", "skip"]; pomoProcess.running = true; } }
            }
        }
    }
}
