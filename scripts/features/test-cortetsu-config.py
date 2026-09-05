from pathlib import Path

repo = Path(__file__).resolve().parents[2]
modules = repo / "caelestia/modules-owned/modules"
config = (modules / "CortetsuConfig.qml").read_text(encoding="utf-8")
hub = (modules / "BottomHub.qml").read_text(encoding="utf-8")
launcher_patch = (repo / "caelestia/patches/modules__launcher__CortetsuConfig.qml.patch").read_text(encoding="utf-8")
manifest = (repo / "caelestia/patches/MANIFEST.tsv").read_text(encoding="utf-8")

assert "pragma Singleton" in config
assert "XDG_CONFIG_HOME" in config and "/cortetsu/preferences.json" in config
for marker in ("favouriteApps", "hiddenTrayIcons", "workspacesShown", "function load", "function save", "function setFavouriteApps", "function setHiddenTrayIcons", "function setWorkspacesShown"):
    assert marker in config, marker
assert "GlobalConfig.launcher.favouriteApps" not in hub
assert "GlobalConfig.bar.tray.hiddenIcons" not in hub
assert "GlobalConfig.bar.workspaces.shown" not in hub
for marker in ("CortetsuConfig.favouriteApps", "CortetsuConfig.hiddenTrayIcons", "CortetsuConfig.workspacesShown", "CortetsuConfig.setFavouriteApps"):
    assert marker in hub, marker
assert "modules__launcher__CortetsuConfig.qml.patch" in manifest
for marker in ("CortetsuConfig.favouriteApps", "CortetsuConfig.setFavouriteApps", 'import \"..\"', 'import \"../..\"'):
    assert marker in launcher_patch, marker
print("PASS: Cortetsu functional preferences use an XDG-owned contract")
