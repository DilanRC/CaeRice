#!/usr/bin/env python3
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
state = (repo / "caelestia/modules-owned/modules/CortetsuScreenState.qml").read_text(encoding="utf-8")
policy = (repo / "caelestia/modules-owned/modules/CortetsuOverlayPolicy.js").read_text(encoding="utf-8")
patch = (repo / "caelestia/patches/components__ScreenState.qml.patch").read_text(encoding="utf-8")
content_window_patch = (repo / "caelestia/patches/modules__drawers__ContentWindow__adapter.qml.patch").read_text(encoding="utf-8")
scrim_patch = (repo / "caelestia/patches/modules__drawers__ContentWindow__scrim-adapter.qml.patch").read_text(encoding="utf-8")
shortcuts_patch = (repo / "caelestia/patches/modules__Shortcuts.qml.patch").read_text(encoding="utf-8")
calendar = (repo / "caelestia/modules-owned/modules/CalendarController.qml").read_text(encoding="utf-8")
clipboard = (repo / "caelestia/modules-owned/modules/ClipboardController.qml").read_text(encoding="utf-8")
controllers = {
    "hardware": (repo / "caelestia/modules-owned/modules/HardwareController.qml").read_text(encoding="utf-8"),
    "displayManager": (repo / "caelestia/modules-owned/modules/DisplayController.qml").read_text(encoding="utf-8"),
    "wallpaperManager": (repo / "caelestia/modules-owned/modules/WallpaperController.qml").read_text(encoding="utf-8"),
    "overview": (repo / "caelestia/modules-owned/modules/OverviewController.qml").read_text(encoding="utf-8"),
}
hub = (repo / "caelestia/modules-owned/modules/BottomHub.qml").read_text(encoding="utf-8")

for flag in ("overview", "calendar", "clipboard", "hardware", "displayManager", "wallpaperManager"):
    assert f"property bool {flag}" in state, flag
    assert flag in policy, flag
for derived in ("retainedOverlayOpen", "requiresOverlayLayer", "requiresFullInputMask", "requiresWindowKeyboardFocus"):
    assert derived in state and derived in patch, derived
assert "required property QtObject legacyState" in state
assert "function closeRetainedOverlays" in state
assert "function closeRetainedOverlaysExcept(exceptFlag: string): void" in state
assert "function setRetained(flag: string, value: bool): bool" in state
assert "function openExclusive" in policy
assert "function isRetainedFlag(flag)" in policy
assert "function closeOtherRetained(state, exceptFlag)" in policy
assert "Geometry" in policy and "popouts" in policy and "wallpaper side effects" in policy
assert 'import "../modules"' in patch
assert "cortetsuState" in patch
assert "cortetsuState" in calendar
assert 'state.setRetained("calendar", false)' in calendar
assert 'state.setRetained("calendar", true)' in calendar
assert "OverlayPolicy.closeOtherPanels(state.legacyState)" in calendar
assert "CortetsuShellState.forScreen(screen)?.calendar" not in calendar
assert "cortetsuState" in clipboard
assert 'state.setRetained("clipboard", false)' in clipboard
assert 'state.setRetained("clipboard", true)' in clipboard
assert "CortetsuShellState.forActive()?.cortetsuState" in clipboard
assert "OverlayPolicy.closeOtherPanels(CortetsuShellState.forScreen(screen)?.cortetsuState?.legacyState)" in clipboard
assert "CortetsuShellState.forScreen(screen)?.clipboard" not in clipboard
for flag, controller in controllers.items():
    assert "cortetsuState" in controller, flag
    assert f'setRetained("{flag}"' in controller, flag
    assert f"CortetsuShellState.forScreen(screen)?.{flag}" not in controller, flag
assert "OverlayPolicy.close" in controller, flag
assert 'state.setRetained("calendar"' in hub
assert 'state.setRetained("wallpaperManager"' in hub
assert "OverlayPolicy.closeOtherPanels(state.legacyState)" in hub
assert "readonly property var cortetsuState" in hub
for wrapper, flag in (
    ("calendar/Wrapper.qml", "calendar"),
    ("clipboard/Wrapper.qml", "clipboard"),
    ("hardware/Wrapper.qml", "hardware"),
    ("display/Wrapper.qml", "displayManager"),
    ("overview/Wrapper.qml", "overview"),
    ("wallpaper/Wrapper.qml", "wallpaperManager"),
):
    wrapper_text = (repo / "caelestia/modules-owned/modules" / wrapper).read_text(encoding="utf-8")
    assert f"screenState.cortetsuState?.{flag}" in wrapper_text, wrapper
for content_file, flag in (("calendar/Content.qml", "calendar"), ("overview/Content.qml", "overview")):
    content_text = (repo / "caelestia/modules-owned/modules" / content_file).read_text(encoding="utf-8")
    assert f'cortetsuState?.setRetained("{flag}", false)' in content_text, content_file
for marker in ("closeRetainedOverlays", "requiresWindowKeyboardFocus", "requiresFullInputMask", "retainedOverlayOpen"):
    assert marker in content_window_patch, marker
assert 'screenState.cortetsuState?.setRetained("wallpaperManager", false)' in shortcuts_patch
assert "root.screenState.cortetsuState?.overview ? 0.58" in scrim_patch
for content_file, flag in (
    ("clipboard/Content.qml", "clipboard"),
    ("hardware/Content.qml", "hardware"),
    ("display/Editor.qml", "displayManager"),
    ("wallpaper/Content.qml", "wallpaperManager"),
    ("wallpaper/Wrapper.qml", "wallpaperManager"),
):
    content_text = (repo / "caelestia/modules-owned/modules" / content_file).read_text(encoding="utf-8")
    assert f'cortetsuState?.setRetained("{flag}", false)' in content_text, content_file
print("PASS: Cortetsu screen state and overlay policy preserve the legacy boundary")
