#!/usr/bin/env bash
set -euo pipefail

BASE="${HOME}/.local/share/caelestia-custom-system"
LIVE="/etc/xdg/quickshell/caelestia"
OWNED="$BASE/modules-owned"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$BASE/snapshots/owned-before-sync-$STAMP"

mkdir -p "$BACKUP"

while IFS= read -r -d '' src; do
    rel="${src#$OWNED/}"
    live="$LIVE/$rel"

    if [[ -f "$live" ]]; then
        mkdir -p "$BACKUP/$(dirname "$rel")"
        cp "$src" "$BACKUP/$rel"
        sudo cp "$live" "$src"
        sudo chown "$USER":"$(id -gn)" "$src"
        echo "SYNC $rel"
    fi
done < <(find "$OWNED" -type f -print0)

if [[ -f "$HOME/.config/caelestia/hypr-user.lua" ]]; then
    mkdir -p "$BASE/user-config/.config/caelestia"
    cp "$HOME/.config/caelestia/hypr-user.lua" \
       "$BASE/user-config/.config/caelestia/hypr-user.lua"
fi

echo "Backup previo: $BACKUP"
