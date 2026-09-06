from pathlib import Path

repo = Path(__file__).resolve().parents[2]
modules = repo / "cortetsu/modules"
config = (modules / "CortetsuConfig.qml").read_text(encoding="utf-8")
hub = (modules / "BottomHub.qml").read_text(encoding="utf-8")
app_list = (modules / "launcher/AppList.qml").read_text(encoding="utf-8")
content = (modules / "launcher/Content.qml").read_text(encoding="utf-8")
content_list = (modules / "launcher/ContentList.qml").read_text(encoding="utf-8")
wrapper = (modules / "launcher/Wrapper.qml").read_text(encoding="utf-8")
apps_service = (modules / "launcher/services/Apps.qml").read_text(encoding="utf-8")
actions_service = (modules / "launcher/services/Actions.qml").read_text(encoding="utf-8")
schemes_service = (modules / "launcher/services/Schemes.qml").read_text(encoding="utf-8")
variants_service = (modules / "launcher/services/M3Variants.qml").read_text(encoding="utf-8")
manifest = (repo / "caelestia/patches/MANIFEST.tsv").read_text(encoding="utf-8")
desktop_clock = (modules / "background/DesktopClock.qml").read_text(encoding="utf-8")
spectrum = (repo / "cortetsu/services/CortetsuSpectrum.qml").read_text(encoding="utf-8")

assert "pragma Singleton" in config
assert "XDG_CONFIG_HOME" in config and "/cortetsu/preferences.json" in config
for marker in ("favouriteApps", "hiddenApps", "hiddenTrayIcons", "terminalCommand", "actionPrefix", "specialPrefix", "actions", "enableDangerousActions", "useFuzzyApps", "useFuzzyWallpapers", "smartScheme", "wallpaperDirectory", "wallpaperEnabled", "desktopClockEnabled", "desktopClockPosition", "borderThickness", "useTwelveHourClock", "useFahrenheit", "useFahrenheitPerformance", "weatherLocation", "audioIncrement", "brightnessIncrement", "maxVolume", "visualiserBars", "defaultPlayer", "playerAliases", "toastAudioOutputChanged", "toastAudioInputChanged", "toastNowPlaying", "notificationExpire", "suppressNotificationsInFullscreen", "notificationDefaultExpireTimeout", "notificationFullscreenExpireTimeout", "notificationActionOnClick", "toastDndChanged", "toastGameModeChanged", "vimKeybinds", "workspacesShown", "function load", "function save", "function setFavouriteApps", "function setHiddenApps", "function setHiddenTrayIcons", "function setWorkspacesShown"):
    assert marker in config, marker
assert "GlobalConfig.launcher.favouriteApps" not in hub
assert "GlobalConfig.bar.tray.hiddenIcons" not in hub
assert "GlobalConfig.bar.workspaces.shown" not in hub
assert "import Caelestia" not in desktop_clock
assert "CortetsuRegional.useTwelveHourClock" in desktop_clock
assert "Time.hourStr" in desktop_clock and "Time.format" in desktop_clock
assert "CortetsuConfig.visualiserBars" in spectrum
assert "command -v cava" in spectrum
assert "Caelestia" not in spectrum
for marker in ("CortetsuConfig.favouriteApps", "CortetsuConfig.hiddenTrayIcons", "CortetsuConfig.workspacesShown", "CortetsuConfig.setFavouriteApps"):
    assert marker in hub, marker

# The launcher used to finish this migration via four small
# GlobalConfig->CortetsuConfig patches stacked on top of the base launcher
# patches (modules__launcher__CortetsuConfig.qml.patch,
# CortetsuConfigMore, SearchPreferences, RemainingConfig). The launcher is
# now fully first-party under cortetsu/modules/launcher: no GlobalConfig
# anywhere, and those four patch names (plus the four base launcher
# patches they used to sit on top of) are gone for good.
launcher_files = {
    "AppList.qml": app_list,
    "Content.qml": content,
    "ContentList.qml": content_list,
    "Wrapper.qml": wrapper,
    "services/Apps.qml": apps_service,
    "services/Actions.qml": actions_service,
    "services/Schemes.qml": schemes_service,
    "services/M3Variants.qml": variants_service,
}
for name, text in launcher_files.items():
    assert "GlobalConfig" not in text, f"launcher/{name} still references GlobalConfig"

assert "CortetsuConfig.favouriteApps" in app_list
assert "CortetsuConfig.setFavouriteApps" in app_list
assert "CortetsuConfig.actionPrefix" in app_list
assert "CortetsuConfig.terminalCommand" in app_list
assert "CortetsuConfig.hiddenApps" in apps_service
assert "CortetsuConfig.useFuzzyApps" in apps_service
assert "CortetsuConfig.terminalCommand" in apps_service
assert "CortetsuConfig.specialPrefix" in apps_service
assert "CortetsuConfig.actionPrefix" in content
assert "CortetsuConfig.vimKeybinds" in content
assert "CortetsuConfig.actionPrefix" in content_list
assert actions_service.count("CortetsuConfig.actionPrefix") == 2
assert schemes_service.count("CortetsuConfig.actionPrefix") == 1
assert variants_service.count("CortetsuConfig.actionPrefix") == 1
for svc in (actions_service, schemes_service, variants_service):
    assert "CortetsuConfig.useFuzzyApps" in svc, "search services must share the unified useFuzzyApps flag"

gone_patches = (
    "modules__launcher__AppList.qml.patch",
    "modules__launcher__Content.qml.patch",
    "modules__launcher__ContentList.qml.patch",
    "modules__launcher__Wrapper.qml.patch",
    "modules__launcher__services__Apps.qml.patch",
    "modules__launcher__CortetsuConfig.qml.patch",
    "modules__launcher__CortetsuConfigMore.qml.patch",
    "modules__launcher__SearchPreferences.qml.patch",
    "modules__launcher__RemainingConfig.qml.patch",
)
for name in gone_patches:
    assert name not in manifest, f"{name} must not be listed in MANIFEST.tsv anymore"
    assert not (repo / "caelestia/patches" / name).exists(), f"{name} must be deleted"

print("PASS: Cortetsu functional preferences use an XDG-owned contract")
