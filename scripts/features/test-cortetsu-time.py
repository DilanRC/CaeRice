from pathlib import Path
source = Path(__file__).resolve().parents[2] / "cortetsu/services/Time.qml"
text = source.read_text(encoding="utf-8")
assert "Caelestia" not in text
assert "CortetsuConfig.useTwelveHourClock" in text
assert "SystemClock" in text
print("PASS: Cortetsu owns the Time service")
