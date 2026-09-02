#!/usr/bin/env python3
"""Regression gate for the Calendar V1.1 interaction and information design."""
from pathlib import Path

content = (Path(__file__).resolve().parents[1] / "modules-owned/modules/calendar/Content.qml").read_text()
for expected in (
    'calendar.primary ? qsTr("Personal")',
    'eventsForDay(dayCell.day).slice(0, 3)',
    'modelData.calendarColor || Colours.palette.m3tertiary',
    'label: qsTr("Skip break")',
    'root.runPomodoro("skip")',
    'text: qsTr("No events")',
    'text: qsTr("Take the time for yourself.")',
    'root.eventTime(modelData)',
    'modelData.location',
    'implicitWidth: chipRow.implicitWidth',
    'component FocusButton: StyledRect',
    'onClicked: parent.clicked()',
    'root.pomodoro = JSON.parse(text.trim())',
    'function runPomodoro(command: string)',
    'onClicked: root.runPomodoro(',
):
    assert expected in content, expected
assert "delegate: CheckBox" not in content
print("PASS: calendar polish preserves chips, colored indicators, event details, empty state, and skip break")
