from pathlib import Path

repo = Path(__file__).resolve().parents[2]
patch = (repo / "caelestia/patches/utils__Paths__Config.qml.patch").read_text(encoding="utf-8")

for root in ("data", "state", "cache", "config"):
    assert f"readonly property string {root}" in patch
assert patch.count("}/cortetsu`") == 4
assert patch.count("+/cortetsu`") == 0
assert patch.count("}/cortetsu`") == 4
print("PASS: compatibility Paths routes all XDG runtime roots to Cortetsu")
