#!/usr/bin/env bash
set -euo pipefail

BASE="${HOME}/.local/share/cortetsu/upstream"
FILES="$BASE/files"
LIVE="/etc/xdg/quickshell/caelestia"

echo "===== DRIFT CAELESTIA ====="
while IFS= read -r -d '' src; do
    rel="${src#$FILES/etc/xdg/quickshell/caelestia/}"
    dst="$LIVE/$rel"

    if [[ ! -f "$dst" ]]; then
        printf 'MISSING  %s\n' "$rel"
    elif cmp -s "$src" "$dst"; then
        printf 'OK       %s\n' "$rel"
    else
        printf 'CHANGED  %s\n' "$rel"
    fi
done < <(find "$FILES/etc/xdg/quickshell/caelestia" -type f -print0 | sort -z)

echo
echo "===== DRIFT USER CONFIG ====="
for rel in \
    ".config/caelestia/hypr-user.lua" \
    ".config/hypr/hyprland.lua"
do
    src="$FILES/home/$rel"
    dst="$HOME/$rel"

    if [[ ! -f "$src" ]]; then
        continue
    elif [[ ! -f "$dst" ]]; then
        printf 'MISSING  ~/%s\n' "$rel"
    elif cmp -s "$src" "$dst"; then
        printf 'OK       ~/%s\n' "$rel"
    else
        printf 'CHANGED  ~/%s\n' "$rel"
    fi
done
