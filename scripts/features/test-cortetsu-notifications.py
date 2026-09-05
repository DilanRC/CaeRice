import re
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
modules = repo / "caelestia/modules-owned/modules"
service = (modules / "CortetsuNotifications.qml").read_text(encoding="utf-8")
hub = (modules / "BottomHub.qml").read_text(encoding="utf-8")
patch = (repo / "caelestia/patches/services__NotificationConfig.qml.patch").read_text(encoding="utf-8")

for marker in ("notifs.json", "notification-status.json", "property int count", "property bool dnd", "watchChanges: true"):
    assert marker in service, marker
assert "import qs.services" not in hub
assert "CortetsuNotifications.count" in hub and "CortetsuNotifications.dnd" in hub
assert not re.search(r"(?<!Cortetsu)Notifs\.", hub)
assert "notification-status.json" in patch and "-    property alias dnd: props.dnd" in patch
print("PASS: Bottom Hub notification state is Cortetsu-owned and XDG-backed")
