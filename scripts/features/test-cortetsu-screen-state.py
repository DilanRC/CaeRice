#!/usr/bin/env python3
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
state = (repo / "caelestia/modules-owned/modules/CortetsuScreenState.qml").read_text(encoding="utf-8")
policy = (repo / "caelestia/modules-owned/modules/CortetsuOverlayPolicy.js").read_text(encoding="utf-8")
patch = (repo / "caelestia/patches/components__ScreenState.qml.patch").read_text(encoding="utf-8")
calendar = (repo / "caelestia/modules-owned/modules/CalendarController.qml").read_text(encoding="utf-8")
clipboard = (repo / "caelestia/modules-owned/modules/ClipboardController.qml").read_text(encoding="utf-8")

for flag in ("overview", "calendar", "clipboard", "hardware", "displayManager", "wallpaperManager"):
    assert f"property bool {flag}" in state, flag
    assert flag in policy, flag
for derived in ("retainedOverlayOpen", "requiresOverlayLayer", "requiresFullInputMask", "requiresWindowKeyboardFocus"):
    assert derived in state and derived in patch, derived
assert "required property QtObject legacyState" in state
assert "function closeRetainedOverlays" in state
assert "function setRetained(flag: string, value: bool): bool" in state
assert "function openExclusive" in policy
assert "Geometry" in policy and "popouts" in policy and "wallpaper side effects" in policy
assert 'import "../modules"' in patch
assert "cortetsuState" in patch
assert "cortetsuState" in calendar
assert 'state.setRetained("calendar", false)' in calendar
assert 'state.setRetained("calendar", true)' in calendar
assert "OverlayPolicy.closeOtherPanels(state.legacyState)" in calendar
assert "ShellState.forScreen(screen)?.calendar" not in calendar
assert "cortetsuState" in clipboard
assert 'state.setRetained("clipboard", false)' in clipboard
assert 'state.setRetained("clipboard", true)' in clipboard
assert "ShellState.forActive()?.cortetsuState" in clipboard
assert "OverlayPolicy.closeOtherPanels(ShellState.forScreen(screen)?.cortetsuState?.legacyState)" in clipboard
assert "ShellState.forScreen(screen)?.clipboard" not in clipboard
print("PASS: Cortetsu screen state and overlay policy preserve the legacy boundary")
