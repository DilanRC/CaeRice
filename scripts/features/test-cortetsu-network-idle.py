import re
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
modules = repo / "cortetsu/modules"
network = (modules / "CortetsuNetwork.qml").read_text(encoding="utf-8")
idle = (modules / "CortetsuIdleInhibitor.qml").read_text(encoding="utf-8")
hub = (modules / "BottomHub.qml").read_text(encoding="utf-8")

for marker in ("nmcli", "device", "wifi", "interval: 10000", "activeEthernet", "strength"):
    assert marker in network, marker
assert "monitor" not in network
for marker in ("IdleInhibitor", "PersistentProperties", "cortetsu-idle-inhibitor"):
    assert marker in idle, marker
assert "Services.IdleInhibitor" not in hub
assert not re.search(r"(?<!Cortetsu)Nmcli\.", hub)
for marker in ("CortetsuNetwork.active", "CortetsuIdleInhibitor.enabled"):
    assert marker in hub, marker
print("PASS: Bottom Hub network and idle state use Cortetsu contracts")
