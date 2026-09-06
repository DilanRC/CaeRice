#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
content = (ROOT / "cortetsu/modules/sidebar/Content.qml").read_text(encoding="utf-8")
notification = (ROOT / "cortetsu/modules/notifications/Notification.qml").read_text(encoding="utf-8")
for token in (
    "CortetsuNotifications.history",
    "CortetsuNotifications.dnd",
    "CortetsuNotifications.clear()",
    "Notifs.clear()",
    'title: qsTr(\"Now\")',
    'title: qsTr(\"History\")',
    'title: qsTr(\"All clear\")',
    'title: qsTr(\"No saved notifications\")',
    "CortetsuStateMessage",
    "CortetsuToggle",
    "CortetsuButton",
    "CortetsuListRow",
):
    assert token in content, token
assert "GlobalConfig" not in content and "Caelestia" not in content
assert "id: contentLayout" in notification
assert "contentLayout.implicitHeight" in notification
assert 'import "../CortetsuDesign.js" as CortetsuDesign' in notification
wrapper = (ROOT / "cortetsu/modules/notifications/Wrapper.qml").read_text(encoding="utf-8")
assert "modelData: root.visibleNotifications[index]" in wrapper
assert "modelData: root.active[index]" in content
assert "required property var modelData" in notification
print("PASS: notification center owns live, history, DND, clear and empty states")
