from pathlib import Path

repo = Path(__file__).resolve().parents[2]
service = (repo / "cortetsu/modules/CortetsuWallpapers.qml").read_text()
renderer = (repo / "cortetsu/modules/background/Wallpaper.qml").read_text()
background = (repo / "cortetsu/modules/background/Background.qml").read_text()

for legacy in ("Caelestia", "qs.services", "Searcher", "FileSystemModel", "Colours.", "Paths."):
    assert legacy not in service, legacy
for contract in ("cortetsu/wallpaper/path.txt", 'target: "cortetsu-wallpaper"', "function query", "function preview", "previewGeneration", "cortetsu-wallpaper-select", "cortetsu-wallpaper-colours"):
    assert contract in service, contract

print("PASS: Wallpaper service is first-party, XDG-owned and cancellation-aware")

for legacy in ("Caelestia", "qs.services", "qs.components", "Colours.", "Tokens.", "StyledRect", "StyledText", "MaterialIcon"):
    assert legacy not in renderer, legacy
for contract in ("CortetsuWallpapers.current", "asynchronous: true", "fillMode: Image.PreserveAspectCrop", "CortetsuWallpapers.fallback"):
    assert contract in renderer, contract

print("PASS: Wallpaper renderer is first-party and has a local fallback")

for legacy in ("Caelestia.Config", "qs.services", "qs.components", "Colours.", "Tokens.", "StyledWindow", "StyledRect", "StyledText", "MaterialIcon"):
    assert legacy not in background, legacy
for contract in ("PanelWindow", "CortetsuScreens.screens", "CortetsuConfig.wallpaperEnabled", "ShellState.ComponentRef", "sourceComponent: Wallpaper"):
    assert contract in background, contract

print("PASS: Background host is first-party and monitor-scoped")
