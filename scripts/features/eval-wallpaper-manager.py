#!/usr/bin/env python3
"""Deterministic quality eval for the manager's bounded orbital policy."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
helper = (ROOT / "caelestia/modules-owned/modules/wallpaper/OrbitModel.js").read_text(encoding="utf-8")
content = (ROOT / "caelestia/modules-owned/modules/wallpaper/Content.qml").read_text(encoding="utf-8")
checks = {
    "bounded_to_12": "Math.min(12, count)" in helper,
    "wrap_safe_empty": "if (count <= 0)" in helper,
    "unicode_paths_untouched": "entries.filter" in helper and "encode" not in helper,
    "no_second_backend": "execDetached" not in content and "Quickshell.exec" not in content,
    "native_preview_apply": "Wallpapers.preview(" in content and "Wallpapers.setWallpaper(" in content,
    "real_orbit_motion": "orbitPhase" in content and "Orbit.satelliteAngle" in content and "NumberAnimation" in content,
    "bounded_responsive_categories": "Math.min(12" in content and "Flickable" in content,
    "safe_preview_assets": content.count("cache: false") >= 3 and "Image.Error" in content,
}
assert all(checks.values()), checks
print(json.dumps({"ok": True, "score": sum(checks.values()), "total": len(checks), "checks": checks}, ensure_ascii=False))
