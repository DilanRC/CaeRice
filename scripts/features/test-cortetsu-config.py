from pathlib import Path

repo = Path(__file__).resolve().parents[2]
modules = repo / "caelestia/modules-owned/modules"
config = (modules / "CortetsuConfig.qml").read_text(encoding="utf-8")
hub = (modules / "BottomHub.qml").read_text(encoding="utf-8")
launcher_patch = (repo / "caelestia/patches/modules__launcher__CortetsuConfig.qml.patch").read_text(encoding="utf-8")
launcher_more_patch = (repo / "caelestia/patches/modules__launcher__CortetsuConfigMore.qml.patch").read_text(encoding="utf-8")
search_patch = (repo / "caelestia/patches/modules__launcher__SearchPreferences.qml.patch").read_text(encoding="utf-8")
remaining_patch = (repo / "caelestia/patches/modules__launcher__RemainingConfig.qml.patch").read_text(encoding="utf-8")
manifest = (repo / "caelestia/patches/MANIFEST.tsv").read_text(encoding="utf-8")

assert "pragma Singleton" in config
assert "XDG_CONFIG_HOME" in config and "/cortetsu/preferences.json" in config
for marker in ("favouriteApps", "hiddenApps", "hiddenTrayIcons", "terminalCommand", "actionPrefix", "specialPrefix", "actions", "enableDangerousActions", "useFuzzyApps", "useFuzzyWallpapers", "smartScheme", "wallpaperDirectory", "useTwelveHourClock", "useFahrenheit", "useFahrenheitPerformance", "weatherLocation", "audioIncrement", "brightnessIncrement", "maxVolume", "visualiserBars", "defaultPlayer", "playerAliases", "toastAudioOutputChanged", "toastAudioInputChanged", "toastNowPlaying", "notificationExpire", "suppressNotificationsInFullscreen", "notificationDefaultExpireTimeout", "notificationFullscreenExpireTimeout", "notificationActionOnClick", "toastDndChanged", "toastGameModeChanged", "vimKeybinds", "workspacesShown", "function load", "function save", "function setFavouriteApps", "function setHiddenApps", "function setHiddenTrayIcons", "function setWorkspacesShown"):
    assert marker in config, marker
assert "GlobalConfig.launcher.favouriteApps" not in hub
assert "GlobalConfig.bar.tray.hiddenIcons" not in hub
assert "GlobalConfig.bar.workspaces.shown" not in hub
for marker in ("CortetsuConfig.favouriteApps", "CortetsuConfig.hiddenTrayIcons", "CortetsuConfig.workspacesShown", "CortetsuConfig.setFavouriteApps"):
    assert marker in hub, marker
assert "modules__launcher__CortetsuConfig.qml.patch" in manifest
for marker in ("CortetsuConfig.favouriteApps", "CortetsuConfig.setFavouriteApps", "CortetsuConfig.actionPrefix", "CortetsuConfig.terminalCommand", 'import \"..\"', 'import \"../..\"'):
    assert marker in launcher_patch, marker
assert "CortetsuConfig.hiddenApps" in launcher_patch
assert "CortetsuConfig.useFuzzyApps" in launcher_patch
assert "CortetsuConfig.actionPrefix" in launcher_more_patch
assert "CortetsuConfig.terminalCommand" in launcher_more_patch
assert search_patch.count("CortetsuConfig.actionPrefix") == 4
assert search_patch.count("CortetsuConfig.useFuzzyApps") == 3
for marker in ("CortetsuConfig.actionPrefix", "CortetsuConfig.vimKeybinds", "CortetsuConfig.favouriteApps"):
    assert marker in remaining_patch, marker
print("PASS: Cortetsu functional preferences use an XDG-owned contract")
