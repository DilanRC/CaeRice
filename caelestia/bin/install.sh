#!/usr/bin/env bash
set -euo pipefail

BASE="${HOME}/.local/share/caelestia-custom-system"
FILES="$BASE/files"
LIVE="/etc/xdg/quickshell/caelestia"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$BASE/reinstall-backups/$STAMP"

if [[ ! -d "$FILES" ]]; then
    echo "No existe $FILES. Ejecuta bootstrap.sh primero." >&2
    exit 1
fi

mkdir -p "$BACKUP/etc/xdg/quickshell/caelestia"
mkdir -p "$BACKUP/home/.config/caelestia"
mkdir -p "$BACKUP/home/.config/hypr"

echo "==> Backup previo: $BACKUP"

while IFS= read -r -d '' src; do
    rel="${src#$FILES/etc/xdg/quickshell/caelestia/}"
    dst="$LIVE/$rel"
    bkp="$BACKUP/etc/xdg/quickshell/caelestia/$rel"

    if [[ -f "$dst" ]]; then
        mkdir -p "$(dirname "$bkp")"
        sudo cp "$dst" "$bkp"
        sudo chown "$USER":"$(id -gn)" "$bkp"
    fi
done < <(find "$FILES/etc/xdg/quickshell/caelestia" -type f -print0)

echo "==> Aplicando archivos Caelestia"
while IFS= read -r -d '' src; do
    rel="${src#$FILES/etc/xdg/quickshell/caelestia/}"
    dst="$LIVE/$rel"
    sudo mkdir -p "$(dirname "$dst")"
    sudo install -m 0644 "$src" "$dst"
    echo "install: $rel"
done < <(find "$FILES/etc/xdg/quickshell/caelestia" -type f -print0)

for rel in \
    ".config/caelestia/hypr-user.lua" \
    ".config/hypr/hyprland.lua"
do
    src="$FILES/home/$rel"
    dst="$HOME/$rel"
    if [[ -f "$src" ]]; then
        if [[ -f "$dst" ]]; then
            mkdir -p "$BACKUP/home/$(dirname "$rel")"
            cp "$dst" "$BACKUP/home/$rel"
        fi
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        echo "install: ~/$rel"
    fi
done

echo
echo "==> Verificando checksums de la fuente"
(
    cd "$FILES"
    sha256sum -c "$BASE/MANIFEST.sha256"
)

echo
echo "Personalización aplicada."
echo "Backup previo: $BACKUP"
echo
echo "Reinicia con:"
echo "  hyprctl reload"
echo "  pkill -f 'qs -c caelestia'"
echo "  sleep 1"
echo "  caelestia shell -d"
