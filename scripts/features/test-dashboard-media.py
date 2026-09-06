from pathlib import Path

path = Path(__file__).resolve().parents[2] / "cortetsu/modules/dashboard/dash/Media.qml"
source = path.read_text(encoding="utf-8")
for legacy in ("Caelestia", "GlobalConfig", "ServiceRef", "qs.services", "qs.components"):
    assert legacy not in source, legacy
assert "Players.active" in source
assert "previous()" in source and "togglePlaying()" in source and "next()" in source
print("PASS: dashboard media card uses the Cortetsu player boundary")
