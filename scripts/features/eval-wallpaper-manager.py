#!/usr/bin/env python3
"""Deterministic quality eval for the manager's bounded orbital policy."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
helper = (ROOT / "caelestia/modules-owned/modules/wallpaper/OrbitModel.js").read_text(encoding="utf-8")
content = (ROOT / "caelestia/modules-owned/modules/wallpaper/Content.qml").read_text(encoding="utf-8")
controller = (ROOT / "caelestia/modules-owned/modules/WallpaperController.qml").read_text(encoding="utf-8")
wrapper = (ROOT / "caelestia/modules-owned/modules/wallpaper/Wrapper.qml").read_text(encoding="utf-8")
installer = (ROOT / "scripts/features/install-wallpaper-manager.py").read_text(encoding="utf-8")
checks = {
    "bounded_to_12": "Math.min(12, count)" in helper,
    "selected_excluded_from_satellites": "function satellites" in helper and "index !== selectedIndex" in helper and "Orbit.satellites" in content,
    "actual_path_alias_resolution": "function resolveCurrentIndex" in helper and "Orbit.resolveCurrentIndex" in content,
    "active_screen_open": "const state = CortetsuShellState.forActive()?.cortetsuState;" in controller and "CortetsuShellState.forActive()?.modelData" not in controller,
    "wrap_safe_empty": "if (count <= 0)" in helper,
    "unicode_paths_untouched": "entries.filter" in helper and "encode" not in helper,
    "no_second_backend": "execDetached" not in content and "Quickshell.exec" not in content,
    "native_preview_apply": "CortetsuWallpapers.preview(" in content and "CortetsuWallpapers.setWallpaper(" in content,
    "stable_preview_only": "interval: 220" in content and "Orbit.previewEligible" in content and "function previewEligible" in helper,
    "wheel_coalescing": "Orbit.wheelIntent" in content and "function wheelIntent" in helper and "Math.abs(total) % threshold" in helper,
    "global_overlay_exclusivity": "globalOtherOverlayOpen" in wrapper and "for (const candidate of CortetsuScreens.screens)" in wrapper and "closeCompetingPanels" in wrapper,
    "transactional_install": "def atomic_replace" in installer and "manifest = snapshot" in installer and "rollback(backup)" in installer,
    "real_orbit_motion": "orbitPhase" in content and "Orbit.satelliteAngle" in content and "NumberAnimation" in content,
    "bounded_responsive_categories": "Math.min(12" in content and "Flickable" in content and "width: Math.min(parent.width - 48, 900)" in content,
    "safe_preview_assets": content.count("cache: true") >= 4 and "Image.Error" in content,
    "bounded_prefetch": "Orbit.prefetch(filteredEntries, currentIndex, visibleLimit + 6)" in content and "Math.min(18, count)" in helper,
    "ready_gated_entry": "property bool presentationReady: false" in content and "function updatePresentationReady" in content and content.count("onStatusChanged: root.updatePresentationReady()") >= 2 and "shouldBeActive && presentationReady" in wrapper,
    "floating_dynamic_surfaces": "Item {\n        id: panel" in content and "CortetsuDesign.colorSurfaceHigh, 0.68" in content and "CortetsuDesign.colorScrim, 0.18" in wrapper,
    "current_preview_state": 'qsTr("Current") : qsTr("Preview")' in content,
    "uniform_satellite_geometry": "scale: 1" in content and "scale: (0.72 + depth * 0.38)" not in content,
    "hero_orbit_clearance": "readonly property real radiusX" in content and "readonly property real radiusY" in content and "Math.cos(angle) * radiusX" in content and "Math.sin(angle) * radiusY" in content,
    "footer_orbit_clearance": "anchors.bottomMargin: 70" in content,
    "header_orbit_clearance": "anchors.topMargin: 0" in content and "anchors.topMargin: 56" in content and "anchors.bottomMargin: -4" in content,
}
assert all(checks.values()), checks
print(json.dumps({"ok": True, "score": sum(checks.values()), "total": len(checks), "checks": checks}, ensure_ascii=False))
