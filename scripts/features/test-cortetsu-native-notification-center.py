#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
content = (ROOT / "cortetsu/modules/sidebar/Content.qml").read_text(encoding="utf-8")
for token in (
    "CortetsuNotifications.history",
    "CortetsuNotifications.dnd",
    "CortetsuNotifications.clear()",
    "Notifs.clear()",
    'title: qsTr(\"Now\")',
    'title: qsTr(\"History\")',
    'text: qsTr(\"All clear\")',
    'text: qsTr(\"No saved notifications\")',
    "CortetsuToggle",
    "CortetsuButton",
    "CortetsuListRow",
):
    assert token in content, token
assert "GlobalConfig" not in content and "Caelestia" not in content
print("PASS: notification center owns live, history, DND, clear and empty states")
