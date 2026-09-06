from pathlib import Path

path = Path(__file__).resolve().parents[2] / "cortetsu/modules/dashboard/Dash.qml"
source = path.read_text(encoding="utf-8")
for legacy in ("Caelestia", "GlobalConfig", "qs.services", "qs.components", "Tokens", "Colours", "StyledRect"):
    assert legacy not in source, legacy
assert "required property var screenState" in source
assert "Time.hourStr" in source and "Weather.temp" in source and "Players.active" in source
print("PASS: dashboard host is first-party and uses Cortetsu services")
