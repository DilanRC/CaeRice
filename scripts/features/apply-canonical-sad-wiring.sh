#!/usr/bin/env bash
set -euo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO" ]] || { echo "ERROR: ejecuta dentro de Cortetsu" >&2; exit 1; }
LIVE="/etc/xdg/quickshell/caelestia"
USERCFG="$HOME/.config/hypr/hypr-user.lua"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.local/share/cortetsu/upstream/snapshots/update-sad-$STAMP"
STAGE="$BACKUP/stage"

for f in "$LIVE/shell.qml" "$LIVE/components/ScreenState.qml" "$LIVE/modules/drawers/ContentWindow.qml" "$LIVE/modules/drawers/Panels.qml" "$USERCFG"; do
    [[ -f "$f" ]] || { echo "ERROR: falta $f (Hardware Center debe estar instalado primero)" >&2; exit 2; }
done

mkdir -p "$BACKUP/components" "$BACKUP/modules/drawers" "$BACKUP/user-config" "$STAGE"
cp "$LIVE/shell.qml" "$BACKUP/shell.qml"
cp "$LIVE/components/ScreenState.qml" "$BACKUP/components/ScreenState.qml"
cp "$LIVE/modules/drawers/ContentWindow.qml" "$BACKUP/modules/drawers/ContentWindow.qml"
cp "$LIVE/modules/drawers/Panels.qml" "$BACKUP/modules/drawers/Panels.qml"
cp "$USERCFG" "$BACKUP/user-config/hypr-user.lua"

# Canonical retained wiring deliberately uses wire_sad_shell.py's default
# feature set. Keeping a narrower --features subset here caused Wallpaper
# Manager modules/policy to be installed without the ScreenState/controller/
# drawer wiring they require.
WIRE_JSON="$(python3 "$REPO/scripts/features/wire_sad_shell.py" --live "$LIVE" --usercfg "$USERCFG" --stage "$STAGE")"
echo "Wiring: $WIRE_JSON"
python3 -c 'import json,sys; d=json.loads(sys.argv[1]); sys.exit(0 if d.get("ok") else 1)' "$WIRE_JSON" || exit 2

sudo install -m 0644 "$STAGE/shell.qml" "$LIVE/shell.qml"
sudo install -m 0644 "$STAGE/components/ScreenState.qml" "$LIVE/components/ScreenState.qml"
sudo install -m 0644 "$STAGE/modules/drawers/Panels.qml" "$LIVE/modules/drawers/Panels.qml"
sudo install -m 0644 "$STAGE/modules/drawers/ContentWindow.qml" "$LIVE/modules/drawers/ContentWindow.qml"
install -m 0644 "$STAGE/user-config/hypr-user.lua" "$USERCFG"

echo "Canonical Hardware/Display/Wallpaper wiring applied."
echo "Backup: $BACKUP"
