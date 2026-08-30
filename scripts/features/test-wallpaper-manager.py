#!/usr/bin/env python3
"""Regression guards for manager contracts that do not require a running shell."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

content = (ROOT / "caelestia/modules-owned/modules/wallpaper/Content.qml").read_text(encoding="utf-8")
controller = (ROOT / "caelestia/modules-owned/modules/WallpaperController.qml").read_text(encoding="utf-8")
patch = (ROOT / "caelestia/patches/services__Wallpapers.qml.patch").read_text(encoding="utf-8")
canonical = (ROOT / "scripts/features/apply-canonical-sad-wiring.sh").read_text(encoding="utf-8")
hypr = (ROOT / "config/hypr-user.lua").read_text(encoding="utf-8")
hub = (ROOT / "caelestia/modules-owned/modules/BottomHub.qml").read_text(encoding="utf-8")
shortcuts_patch = (ROOT / "caelestia/patches/modules__Shortcuts.qml.patch").read_text(encoding="utf-8")

for other in ("launcher", "session", "dashboard", "utilities", "sidebar", "overview", "clipboard", "hardware", "displayManager"):
    assert other in controller, f"controller does not exclude {other}"
for controller_file in ("OverviewController.qml", "ClipboardController.qml", "HardwareController.qml", "DisplayController.qml"):
    assert "state.wallpaperManager = false;" in (ROOT / "caelestia/modules-owned/modules" / controller_file).read_text(encoding="utf-8")
assert "orbitPhase" in content and "orbitMotion.restart()" in content
assert "Orbit.satelliteAngle(index, root.orbitEntries.length, root.orbitPhase)" in content
assert "root.windowIndex = root.currentIndex;" in content
assert "Orbit.shortestSteps" in content and "Orbit.satelliteTarget" in content
assert "cache: false" in content and "StyledClippingRect" in content and "Mask { maskSource: octagonMask }" in content
assert "layer.enabled: true" in content and "visible: true" in content and "required property int index" in content
assert "headerHeight" in content and "footerHeight" in content and "orbitRegion.height / 2" in content
assert "x: orbitRegion.width / 2 + Math.cos(angle) * radiusX - width / 2" in content
assert "y: orbitRegion.height / 2 + Math.sin(angle) * radiusY - height / 2" in content
assert "orbitRegion.x +" not in content and "orbitRegion.y +" not in content
assert "onClicked: root.cancel()" in content and "contentWidth: categoryRow.width" in content
assert "qsTr(\"%1 · %2 / %3\")" in content
assert 'if (Colours.scheme === "dynamic") Wallpapers.previewColourLock = true;' in content
assert "if (Wallpapers.actualCurrent !== currentPath) {\n            Wallpapers.previewColourLock" not in content
assert "--features display" in canonical
assert '"SUPER + SHIFT + W"' in hypr and '"SUPER + W"' in hypr
assert '"SUPER + SHIFT + E"' not in hypr
for path in ("toggleLauncherFor", "toggleSidebarFor", "toggleUtilitiesFor"):
    start = hub.index(f"function {path}")
    assert "wallpaperManager = false" in hub[start:start + 520], path
assert "customDock\", \"launcher" in shortcuts_patch
assert "screenState.wallpaperManager = false;" in shortcuts_patch
assert "Wallpapers.stopPreview(); Wallpapers.setRandom()" in content
for needle in ("previewGeneration += 1", "queuedPreviewPath", "requestGeneration !== root.previewGeneration", "requestPath !== root.previewPath", "!root.showPreview"):
    assert needle in patch, needle
print("test-wallpaper-manager: OK (A→B→cancel and A→apply→close are generation-guarded)")
