from pathlib import Path

repo = Path(__file__).resolve().parents[2]
patch = (repo / "caelestia/patches/utils__Paths__Config.qml.patch").read_text(encoding="utf-8")
paths = (repo / "cortetsu/utils/Paths.qml").read_text(encoding="utf-8")

for root in ("data", "state", "cache", "config"):
    assert f"readonly property string {root}" in patch
assert patch.count("}/cortetsu`") == 4
assert patch.count("+/cortetsu`") == 0
assert patch.count("}/cortetsu`") == 4
assert "import Caelestia" not in paths
assert "Caelestia.Config" not in paths
assert "/cortetsu" in paths
assert "CORTETSU_RECORDINGS_DIR" in paths
assert "function toLocalFile" in paths and "function absolutePath" in paths
print("PASS: compatibility Paths routes all XDG runtime roots to Cortetsu")
