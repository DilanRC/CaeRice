#!/usr/bin/env python3
"""Deterministic V2 interaction regressions without a running shell."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MODULES = ROOT / "caelestia/modules-owned/modules"
content = (MODULES / "wallpaper/Content.qml").read_text(encoding="utf-8")
wrapper = (MODULES / "wallpaper/Wrapper.qml").read_text(encoding="utf-8")
orbit = (MODULES / "wallpaper/OrbitModel.js").read_text(encoding="utf-8")
policy = (MODULES / "OverlayPolicy.js").read_text(encoding="utf-8")
wallpaper_controller = (MODULES / "WallpaperController.qml").read_text(encoding="utf-8")
patch = (ROOT / "caelestia/patches/services__Wallpapers.qml.patch").read_text(encoding="utf-8")
canonical = (ROOT / "scripts/features/apply-canonical-sad-wiring.sh").read_text(encoding="utf-8")
hypr = (ROOT / "config/hypr-user.lua").read_text(encoding="utf-8")
hub = (MODULES / "BottomHub.qml").read_text(encoding="utf-8")
shortcuts_patch = (ROOT / "caelestia/patches/modules__Shortcuts.qml.patch").read_text(encoding="utf-8")


def body(name: str) -> str:
    start = content.index(f"function {name}")
    return content[start:content.find("\n    function ", start + 1)]


# Neutral open: actualCurrent determines selection, then focus, with no preview path.
open_body = body("openManager")
resync_body = body("resync")
assert "resync();" in open_body and "forceActiveFocus();" in open_body
assert "Wallpapers.preview" not in open_body
assert "Wallpapers.actualCurrent" in resync_body and "Orbit.resolveCurrentIndex" in resync_body
assert "Orbit.resolveCurrentIndex" in body("selectCategory")
assert "function resolveCurrentIndex" in orbit and "function basename" in orbit

# A→B→C→D has one timer and the final stable candidate is the sole preview call.
assert content.count("Timer {") == 1
assert "interval: 220" in content
timer_body = content[content.index("id: previewTimer"):content.index("NumberAnimation {", content.index("id: previewTimer"))]
assert "Orbit.previewEligible" in timer_body
assert "Wallpapers.preview(root.pendingPreviewPath)" in timer_body
assert "previewTimer.restart()" in body("queuePreview")
assert "cancelPreview();" in body("requestTarget")

# Close, category/model reset, apply and random erase delayed work; active preview stops.
cancel_body = body("cancelPreview")
assert "previewTimer.stop();" in cancel_body and "Wallpapers.stopPreview();" in cancel_body
assert "cancelPreview();" in body("selectCategory") and "Wallpapers.preview" not in body("selectCategory")
assert "cancelPreview();" in resync_body
assert "previewTimer.stop();" in body("apply") and "Wallpapers.previewColourLock = true;" in body("apply")
assert "cancelPreview();" in body("random") and "Wallpapers.setRandom();" in body("random")
assert "closeManager();" in wrapper and "Wallpapers.stopPreview();" in wrapper
assert "globalOtherOverlayOpen" in wrapper and "onGlobalOtherOverlayOpenChanged" in wrapper
assert "for (const candidate of Screens.screens)" in wrapper
assert "OverlayPolicy.hasCompetingPanel" in wrapper and "closeCompetingPanels();" in wrapper

# Wheel/trackpad input is thresholded by real MouseArea deltas and stays bounded.
assert "event.angleDelta.y" in content and "event.pixelDelta.y" in content
assert "Orbit.wheelIntent" in content and "function wheelIntent" in orbit
assert "Math.sign(total)" in orbit and "direction: total > 0 ? -1 : 1" in orbit
assert "Math.abs(total) % threshold" in orbit and "Math.sign(accumulator) !== Math.sign(delta)" in orbit
assert "function previewEligible" in orbit
assert "queuedDirection = replacementDirection;" in content

# One policy covers both orders, including notification/sidebar and all retained overlays.
for other in ("launcher", "session", "dashboard", "utilities", "sidebar", "overview", "clipboard", "hardware", "displayManager", "wallpaperManager"):
    assert other in policy, f"policy does not exclude {other}"
for controller_file in ("OverviewController.qml", "ClipboardController.qml", "HardwareController.qml", "DisplayController.qml"):
    controller = (MODULES / controller_file).read_text(encoding="utf-8")
    assert "OverlayPolicy.closeOtherPanels" in controller and "for (const screen of Screens.screens)" in controller
assert "OverlayPolicy.closeForWallpaper" in wallpaper_controller and "for (const screen of Screens.screens)" in wallpaper_controller
assert "OverlayPolicy.closeOtherPanels(state);" in hub
assert "toggleSidebarFor" in hub and "state.sidebar = !wasOpen;" in hub
assert "const state = ShellState.forActive();" in wallpaper_controller
assert "ShellState.forActive()?.modelData" not in wallpaper_controller
assert "closeOtherPanels();\n        state.wallpaperManager = true;" in wallpaper_controller

# V2 visual and native-service contracts.
for needle in ("Orbit.satellites", "Math.min(12", "Math.cos(angle)", "Math.sin(angle)", "depth", "scale:", "opacity:", "z:", "Mask { maskSource", "outgoingHeroPath", "heroCrossfade", "TextButton", "IconTextButton"):
    assert needle in content, needle
assert "source: satellite.modelData.entry.path" in content
assert "root.selectSatellite(satellite.modelData.index)" in content
if "Mask {" in content:
    assert "import qs.components.effects" in content
assert "Image {\n            anchors.fill: parent; anchors.margins" not in content
assert 'if (Colours.scheme === "dynamic")\n                Wallpapers.previewColourLock = true;' in content
assert "--features display" in canonical
assert '"SUPER + SHIFT + W"' in hypr and '"SUPER + W"' in hypr
assert '"SUPER + SHIFT + E"' not in hypr
assert "customDock\", \"launcher" in shortcuts_patch
for needle in ("previewGeneration += 1", "queuedPreviewPath", "requestGeneration !== root.previewGeneration", "requestPath !== root.previewPath", "!root.showPreview"):
    assert needle in patch, needle

print("test-wallpaper-manager: OK (neutral open, final-candidate debounce, cancellation, wheel reversal, and two-way overlay exclusion)")
