#!/usr/bin/env bash
set -euo pipefail
REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"; [[ -n "$REPO" ]] || exit 1
LIVE="/etc/xdg/quickshell/caelestia"
USERCFG="$HOME/.config/caelestia/hypr-user.lua"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.local/share/caelestia-custom-system/snapshots/update-sad-$STAMP"
STAGE="$BACKUP/stage"

python3 "$REPO/scripts/features/validate-sad.py"

for f in "$LIVE/shell.qml" "$LIVE/components/ScreenState.qml" "$LIVE/modules/drawers/ContentWindow.qml" "$LIVE/modules/drawers/Panels.qml" "$USERCFG"; do
    [[ -f "$f" ]] || { echo "ERROR: falta $f (¿Hardware Center instalado? es prerequisito de SAD, ver docs/SAD_SCOPE.md)" >&2; exit 2; }
done

# Snapshot before touching anything live, mirroring install-display-manager.sh
# / install-gaming-center.sh / install-caerice-updater.sh. These files are
# root:root 0644 (world-readable), so a plain cp is enough here - no sudo
# needed just to read them.
mkdir -p "$BACKUP/components" "$BACKUP/modules/drawers" "$BACKUP/user-config" "$STAGE"
cp "$LIVE/shell.qml" "$BACKUP/shell.qml"
cp "$LIVE/components/ScreenState.qml" "$BACKUP/components/ScreenState.qml"
cp "$LIVE/modules/drawers/ContentWindow.qml" "$BACKUP/modules/drawers/ContentWindow.qml"
cp "$LIVE/modules/drawers/Panels.qml" "$BACKUP/modules/drawers/Panels.qml"
cp "$USERCFG" "$BACKUP/user-config/hypr-user.lua"

# Idempotently mount Display Manager / Gaming Center / CaeRice Updater into
# shell.qml + ScreenState.qml + Panels.qml + ContentWindow.qml + Hyprland
# keybinds. This used to be missing entirely: update-sad.sh only copied
# module *.qml files, so GamingController.qml/UpdaterController.qml could
# sit on disk byte-identical to source while never being instantiated -
# diagnose-sad.py's wiring check (below) is what actually catches that
# class of bug now, but this step is the fix, not just the detector. Runs
# as the normal user: it only reads LIVE (world-readable) and USERCFG
# (user-owned) and writes the patched copies into $STAGE: no sudo needed
# until the `install` step commits them.
WIRE_JSON="$(python3 "$REPO/scripts/features/wire_sad_shell.py" --live "$LIVE" --usercfg "$USERCFG" --stage "$STAGE")"
echo "Wiring: $WIRE_JSON"
python3 -c "import json,sys; d=json.loads(sys.argv[1]); sys.exit(0 if d.get('ok') else 1)" "$WIRE_JSON" \
    || { echo "ERROR: no se pudo montar Display/Gaming/Updater en el shell en vivo (ver mensaje arriba)" >&2; exit 2; }

sudo install -m 0644 "$STAGE/shell.qml" "$LIVE/shell.qml"
sudo install -m 0644 "$STAGE/components/ScreenState.qml" "$LIVE/components/ScreenState.qml"
sudo install -m 0644 "$STAGE/modules/drawers/Panels.qml" "$LIVE/modules/drawers/Panels.qml"
sudo install -m 0644 "$STAGE/modules/drawers/ContentWindow.qml" "$LIVE/modules/drawers/ContentWindow.qml"
install -m 0644 "$STAGE/user-config/hypr-user.lua" "$USERCFG"

# Display Manager
sudo install -m 0644 "$REPO/caelestia/modules-owned/modules/DisplayController.qml" "$LIVE/modules/DisplayController.qml"
sudo mkdir -p "$LIVE/modules/display"
for qml in "$REPO/caelestia/modules-owned/modules/display/"*.qml; do sudo install -m 0644 "$qml" "$LIVE/modules/display/$(basename "$qml")"; done
for helper in caerice-display-probe caerice-display-plan caerice-display-transaction caerice-display-persist caerice-display-presets caerice-display-workspaces; do install -m 0755 "$REPO/caelestia/bin/$helper" "$HOME/.local/bin/$helper"; done

# Gaming Center
sudo install -m 0644 "$REPO/caelestia/modules-owned/modules/GamingController.qml" "$LIVE/modules/GamingController.qml"
sudo mkdir -p "$LIVE/modules/gaming"
for qml in "$REPO/caelestia/modules-owned/modules/gaming/"*.qml; do sudo install -m 0644 "$qml" "$LIVE/modules/gaming/$(basename "$qml")"; done
for helper in caerice-gaming-probe caerice-gaming-profile; do install -m 0755 "$REPO/caelestia/bin/$helper" "$HOME/.local/bin/$helper"; done

# CaeRice Updater
sudo install -m 0644 "$REPO/caelestia/modules-owned/modules/UpdaterController.qml" "$LIVE/modules/UpdaterController.qml"
sudo mkdir -p "$LIVE/modules/updater"
for qml in "$REPO/caelestia/modules-owned/modules/updater/"*.qml; do sudo install -m 0644 "$qml" "$LIVE/modules/updater/$(basename "$qml")"; done
for helper in caerice-upstream-audit caerice-updater caerice-updater-commit-base; do install -m 0755 "$REPO/caelestia/bin/$helper" "$HOME/.local/bin/$helper"; done

# hypr-user.lua keybinds only take effect after a Hyprland config reload.
hyprctl reload >/dev/null

pkill -TERM -x qs 2>/dev/null || true
sleep 1
caelestia shell -d
sleep 1

# `caelestia shell -d` may return success even when Quickshell rejects the QML
# configuration. Treat live IPC/log diagnostics as the authoritative restart
# health check so this updater never prints a false success message.
# diagnose-sad.py also verifies the wiring performed above actually landed
# (Controller instantiated, ScreenState flag, Panels Wrapper, and a real
# true/false IPC reply) - not just that the module files match source.
if ! python3 "$REPO/scripts/features/diagnose-sad.py"; then
    echo "SAD live synchronization completed, but Caelestia failed post-restart diagnostics." >&2
    echo "Backup of pre-update shell files: $BACKUP" >&2
    exit 1
fi

echo "SAD modules synchronized, Display/Gaming/Updater wired, Caelestia restarted, and live diagnostics passed."
echo "Backup: $BACKUP"
