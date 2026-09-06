from pathlib import Path

path = Path(__file__).resolve().parents[2] / "cortetsu/modules/utilities/Content.qml"
source = path.read_text(encoding="utf-8")
for legacy in ("Caelestia", "GlobalConfig", "qs.services", "qs.components", "Tokens", "Colours"):
    assert legacy not in source, legacy
assert "CortetsuIdleInhibitor" in source
assert "CortetsuRecorder" in source
assert "deformMatrix" not in source
wrapper = (path.parent / "Wrapper.qml").read_text(encoding="utf-8")
assert "deformMatrix" not in wrapper
assert 'import "../bar/popouts"' not in wrapper
assert "required property var popouts" in wrapper
print("PASS: utilities content uses first-party controls")
