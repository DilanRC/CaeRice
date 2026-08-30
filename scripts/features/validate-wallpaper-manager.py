#!/usr/bin/env python3
"""Static contract gate for the native CaeRice Wallpaper Manager."""
from __future__ import annotations

import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path("/home/dilan/.local/share/caelestia-custom-system/upstream-git")


def require(path: Path, *needles: str) -> None:
    text = path.read_text(encoding="utf-8")
    for needle in needles:
        assert needle in text, f"{path.relative_to(ROOT)} missing {needle!r}"


def main() -> None:
    content = ROOT / "caelestia/modules-owned/modules/wallpaper/Content.qml"
    require(content, "Orbit.visible", "Orbit.satelliteAngle", "orbitPhase", "Math.min(12", "asynchronous: true", "sourceSize.width", "retainWhileLoading", "cache: false", "Wallpapers.setRandom()", "StyledClippingRect", "Mask { maskSource: octagonMask }", "layer.enabled: true", "visible: true", "required property int index", "headerHeight", "footerHeight")
    content_text = content.read_text(encoding="utf-8")
    assert "GridView" not in content_text and "Quickshell.exec" not in content_text
    assert "Orbit.visible(filteredEntries, currentIndex" not in content_text, "fixed slots would only swap sources"
    assert 'if (Colours.scheme === "dynamic") Wallpapers.previewColourLock = true;' in content_text
    require(ROOT / "caelestia/modules-owned/modules/WallpaperController.qml", "wallpaperManager", "CustomShortcut", 'name: "wallpapermanager"')
    require(ROOT / "caelestia/modules-owned/modules/BottomHub.qml", "openWallpaperFor", "Wallpapers.actualCurrent")
    require(ROOT / "config/hypr-user.lua", "SUPER + SHIFT + W", "caelestia:wallpapermanager")
    with tempfile.TemporaryDirectory(prefix="wallpaper-patch-") as tmp:
        stage = Path(tmp)
        target = stage / "services"
        target.mkdir()
        shutil.copy2(SOURCE / "services/Wallpapers.qml", target / "Wallpapers.qml")
        patch = ROOT / "caelestia/patches/services__Wallpapers.qml.patch"
        result = subprocess.run(["patch", "--dry-run", "-p1", "-d", str(stage)], input=patch.read_text(encoding="utf-8"), text=True, capture_output=True)
        assert result.returncode == 0, result.stdout + result.stderr
    print("validate-wallpaper-manager: OK (native API, bounded images, patch applies to pristine v2.3.0 fixture)")


if __name__ == "__main__":
    main()
