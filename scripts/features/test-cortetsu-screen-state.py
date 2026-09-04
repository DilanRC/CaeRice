#!/usr/bin/env python3
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
state = (repo / "caelestia/modules-owned/modules/CortetsuScreenState.qml").read_text(encoding="utf-8")
policy = (repo / "caelestia/modules-owned/modules/CortetsuOverlayPolicy.js").read_text(encoding="utf-8")
patch = (repo / "caelestia/patches/components__ScreenState.qml.patch").read_text(encoding="utf-8")

for flag in ("overview", "calendar", "clipboard", "hardware", "displayManager", "wallpaperManager"):
    assert f"property bool {flag}" in state, flag
    assert flag in policy, flag
for derived in ("retainedOverlayOpen", "requiresOverlayLayer", "requiresFullInputMask", "requiresWindowKeyboardFocus"):
    assert derived in state and derived in patch, derived
assert "required property QtObject legacyState" in state
assert "function closeRetainedOverlays" in state
assert "function openExclusive" in policy
assert "Geometry" in policy and "popouts" in policy and "wallpaper side effects" in policy
print("PASS: Cortetsu screen state and overlay policy preserve the legacy boundary")
