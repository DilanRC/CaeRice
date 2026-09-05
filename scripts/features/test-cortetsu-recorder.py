from pathlib import Path

repo = Path(__file__).resolve().parents[2]
helper = (repo / "cortetsu/bin/cortetsu-record").read_text(encoding="utf-8")
service = (repo / "caelestia/modules-owned/modules/CortetsuRecorder.qml").read_text(encoding="utf-8")
hub = (repo / "caelestia/modules-owned/modules/BottomHub.qml").read_text(encoding="utf-8")
cli = (repo / "scripts/cortetsu").read_text(encoding="utf-8")

assert "pidof gpu-screen-recorder" in helper
assert "kill -INT" in helper and "pkill" not in helper
assert '"cortetsu-record", "stop"' in service
assert "CortetsuRecorder.running" in hub and "CortetsuRecorder.stop()" in hub
assert "record) record_cmd" in cli
print("PASS: recorder status and stop use the owned exact-process contract")
