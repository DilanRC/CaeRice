#!/usr/bin/env python3
"""Static contract gate for the native CaeRice Wallpaper Manager."""
from __future__ import annotations

import shutil
import subprocess
import tempfile
import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path("/home/dilan/.local/share/caelestia-custom-system/upstream-git")

spec = importlib.util.spec_from_file_location("install_wallpaper_manager", ROOT / "scripts/features/install-wallpaper-manager.py")
assert spec and spec.loader
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


def require(path: Path, *needles: str) -> None:
    text = path.read_text(encoding="utf-8")
    for needle in needles:
        assert needle in text, f"{path.relative_to(ROOT)} missing {needle!r}"


def main() -> None:
    content = ROOT / "caelestia/modules-owned/modules/wallpaper/Content.qml"
    require(content, "Orbit.satellites", "Orbit.resolveCurrentIndex", "Orbit.satelliteAngle", "orbitPhase", "Math.min(12", "asynchronous: true", "sourceSize.width", "retainWhileLoading", "cache: false", "Wallpapers.setRandom()", "Mask { maskSource", "layer.enabled: true", "visible: true", "required property int index", "pendingPreviewPath", "interval: 220", "Orbit.wheelIntent", "heroCrossfade")
    content_text = content.read_text(encoding="utf-8")
    assert "GridView" not in content_text and "Quickshell.exec" not in content_text
    assert "Orbit.visible(filteredEntries, currentIndex" not in content_text, "fixed slots would only swap sources"
    assert "source: satellite.modelData.entry.path" in content_text
    if "Mask {" in content_text:
        assert "import qs.components.effects" in content_text, "Mask requires qs.components.effects"
    assert "previewCurrent" not in content_text and "openManager(): void {\n        resync();\n        forceActiveFocus();" in content_text
    assert 'if (Colours.scheme === "dynamic")\n                Wallpapers.previewColourLock = true;' in content_text
    require(ROOT / "caelestia/modules-owned/modules/WallpaperController.qml", "wallpaperManager", "CustomShortcut", 'name: "wallpapermanager"')
    require(ROOT / "caelestia/modules-owned/modules/BottomHub.qml", "openWallpaperFor", "Wallpapers.actualCurrent")
    require(ROOT / "config/hypr-user.lua", "SUPER + SHIFT + W", "caelestia:wallpapermanager")
    with tempfile.TemporaryDirectory(prefix="wallpaper-patch-") as tmp:
        stage = Path(tmp)
        target = stage / "services"
        target.mkdir()
        source = SOURCE / "services/Wallpapers.qml"
        patch = ROOT / "caelestia/patches/services__Wallpapers.qml.patch"
        shutil.copy2(source, target / "Wallpapers.qml")
        result = subprocess.run(["patch", "--batch", "--forward", "--dry-run", "-p1", "-d", str(stage)], input=patch.read_text(encoding="utf-8"), text=True, capture_output=True)
        assert result.returncode == 0, result.stdout + result.stderr
        assert installer.prepare_wallpapers_service(source, target / "Wallpapers.qml", patch, stage) == "patched"
        assert installer.is_complete_v1_service((target / "Wallpapers.qml").read_text())
        v1_source = stage / "complete-v1.qml"
        shutil.copy2(target / "Wallpapers.qml", v1_source)
        assert installer.prepare_wallpapers_service(v1_source, target / "Wallpapers.qml", patch, stage) == "already-patched"
        partial = stage / "partial.qml"
        partial.write_text(source.read_text().replace("    property bool pendingPreviewClear", "    property bool pendingPreviewClear\n    property int previewGeneration: 0"))
        try:
            installer.prepare_wallpapers_service(partial, target / "Wallpapers.qml", patch, stage)
        except RuntimeError:
            pass
        else:
            raise AssertionError("partial V1 service was accepted")
    print("validate-wallpaper-manager: OK (pristine patch and complete-V1 upgrade accepted; partial state rejected)")


if __name__ == "__main__":
    main()
