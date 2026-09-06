from pathlib import Path

path = Path(__file__).resolve().parents[2] / "cortetsu/modules/utilities/Content.qml"
source = path.read_text(encoding="utf-8")
for legacy in ("Caelestia", "GlobalConfig", "qs.services", "qs.components", "Tokens", "Colours", "IdleInhibit", "RecordingDeleteModal"):
    assert legacy not in source, legacy
assert "CortetsuIdleInhibitor" in source
assert "CortetsuRecorder" in source
assert "required property var deformMatrix" in source
print("PASS: utilities content uses first-party controls")
