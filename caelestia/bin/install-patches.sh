#!/usr/bin/env bash
set -euo pipefail

BASE="${HOME}/.local/share/caelestia-custom-system"
LIVE="/etc/xdg/quickshell/caelestia"
PATCHES="$BASE/patches"
OWNED="$BASE/modules-owned"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$BASE/reinstall-backups/patch-install-$STAMP"

mkdir -p "$BACKUP"

echo "==> PREFLIGHT"
while IFS=$'\t' read -r patchname rel; do
    [[ "$patchname" == "patch" ]] && continue
    p="$PATCHES/$patchname"

    if sudo patch --dry-run -R -p1 -d "$LIVE" < "$p" >/dev/null 2>&1; then
        echo "ALREADY  $rel"
    elif sudo patch --dry-run -p1 -d "$LIVE" < "$p" >/dev/null 2>&1; then
        echo "READY    $rel"
    else
        echo "CONFLICT $rel"
        echo "Abortado antes de modificar nada."
        exit 20
    fi
done < "$PATCHES/MANIFEST.tsv"

echo
echo "==> BACKUP"
while IFS=$'\t' read -r patchname rel; do
    [[ "$patchname" == "patch" ]] && continue
    if [[ -f "$LIVE/$rel" ]]; then
        mkdir -p "$BACKUP/$(dirname "$rel")"
        sudo cp "$LIVE/$rel" "$BACKUP/$rel"
        sudo chown "$USER":"$(id -gn)" "$BACKUP/$rel"
    fi
done < "$PATCHES/MANIFEST.tsv"

while IFS= read -r -d '' src; do
    rel="${src#$OWNED/}"
    if [[ -f "$LIVE/$rel" ]]; then
        mkdir -p "$BACKUP/$(dirname "$rel")"
        sudo cp "$LIVE/$rel" "$BACKUP/$rel"
        sudo chown "$USER":"$(id -gn)" "$BACKUP/$rel"
    fi
done < <(find "$OWNED" -type f -print0)

echo
echo "==> APLICANDO PATCHES"
while IFS=$'\t' read -r patchname rel; do
    [[ "$patchname" == "patch" ]] && continue
    p="$PATCHES/$patchname"

    if sudo patch --dry-run -R -p1 -d "$LIVE" < "$p" >/dev/null 2>&1; then
        echo "SKIP ya aplicado: $rel"
    else
        sudo patch -p1 -d "$LIVE" < "$p"
    fi
done < "$PATCHES/MANIFEST.tsv"

echo
echo "==> MÓDULOS PROPIOS"
while IFS= read -r -d '' src; do
    rel="${src#$OWNED/}"
    dst="$LIVE/$rel"
    sudo mkdir -p "$(dirname "$dst")"
    sudo install -m 0644 "$src" "$dst"
    echo "OWNED: $rel"
done < <(find "$OWNED" -type f -print0)

echo
echo "Backup: $BACKUP"
