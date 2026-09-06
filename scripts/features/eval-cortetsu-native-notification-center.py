#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
source = (ROOT / "cortetsu/modules/sidebar/Content.qml").read_text(encoding="utf-8")
notification = (ROOT / "cortetsu/modules/notifications/Notification.qml").read_text(encoding="utf-8")
sections = sum(source.count(f'title: qsTr(\"{name}\")') for name in ("Now", "History"))
states = sum(source.count(token) for token in ("All clear", "No saved notifications", "Do not disturb"))
assert sections == 2
assert states >= 2
assert source.count("CortetsuDesign.") >= 6
assert "contentLayout.implicitHeight" in notification
assert 'import "../CortetsuDesign.js" as CortetsuDesign' in notification
assert 'import "../CortetsuTypography.js" as CortetsuTypography' in notification
assert "modelData.appName" in notification and "modelData.image" in notification
assert "modelData.urgency >= 2" in notification
print("PASS: notification center eval covers hierarchy, empty states and visual token use")
