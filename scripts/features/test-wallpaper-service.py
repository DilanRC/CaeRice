from pathlib import Path

repo = Path(__file__).resolve().parents[2]
service = (repo / "cortetsu/modules/CortetsuWallpapers.qml").read_text()

for legacy in ("Caelestia", "qs.services", "Searcher", "FileSystemModel", "Colours.", "Paths."):
    assert legacy not in service, legacy
for contract in ("cortetsu/wallpaper/path.txt", 'target: "cortetsu-wallpaper"', "function query", "function preview", "previewGeneration", "cortetsu-wallpaper-select", "cortetsu-wallpaper-colours"):
    assert contract in service, contract

print("PASS: Wallpaper service is first-party, XDG-owned and cancellation-aware")
