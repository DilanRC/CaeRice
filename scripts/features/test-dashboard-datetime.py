from pathlib import Path

path = Path(__file__).resolve().parents[2] / "cortetsu/modules/dashboard/dash/DateTime.qml"
source = path.read_text(encoding="utf-8")
for legacy in ("Caelestia", "GlobalConfig", "qs.services", "qs.components", "Tokens", "Colours"):
    assert legacy not in source, legacy
assert "Time.hourStr" in source and "Time.minuteStr" in source
assert "CortetsuConfig.useTwelveHourClock" in source
print("PASS: dashboard clock uses Cortetsu time and config")
