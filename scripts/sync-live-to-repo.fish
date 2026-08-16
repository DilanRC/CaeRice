#!/usr/bin/env fish

set -l repo (git rev-parse --show-toplevel 2>/dev/null)
if test -z "$repo"
    echo 'ERROR: ejecuta este script dentro del clon local de CaeRice.' >&2
    exit 1
end

set -l src "$HOME/.local/share/caelestia-custom-system"
if not test -d "$src"
    echo "ERROR: no existe $src" >&2
    exit 2
end

if test (git -C "$repo" branch --show-current) != main
    echo 'ERROR: la sincronización del estado estable debe ejecutarse desde main.' >&2
    echo 'Cambia con: git switch main' >&2
    exit 3
end

mkdir -p "$repo/caelestia" "$repo/config"

# Git conserva el estado reproducible. No copiamos upstream-git, backups ni snapshots.
for item in patches modules-owned user-config bin PATCH_BASE_INFO.txt
    if test -e "$src/$item"
        rm -rf "$repo/caelestia/$item"
        cp -a "$src/$item" "$repo/caelestia/$item"
    end
end

if test -f "$HOME/.config/caelestia/hypr-user.lua"
    cp "$HOME/.config/caelestia/hypr-user.lua" "$repo/config/hypr-user.lua"
end

# Conserva también los migradores usados durante esta sesión si siguen en Descargas.
mkdir -p "$repo/scripts/history"
for f in \
    caelestia-maintenance-v2.sh \
    caelestia-rebuild-upstream-base.sh \
    caelestia-migrate-v2.1-official-tag.sh
    if test -f "$HOME/Descargas/$f"
        cp "$HOME/Descargas/$f" "$repo/scripts/history/$f"
    end
end

# Nunca subir artefactos regenerables o potencialmente sensibles por accidente.
rm -rf "$repo/caelestia/upstream-git" \
       "$repo/caelestia/upstream-package" \
       "$repo/caelestia/legacy" \
       "$repo/caelestia/snapshots" \
       "$repo/caelestia/reinstall-backups"

git -C "$repo" add -A -- README.md .gitignore caelestia config scripts docs

if git -C "$repo" diff --cached --quiet
    echo 'No hay cambios nuevos para subir.'
    exit 0
end

set -l stamp (date '+%Y-%m-%d %H:%M')
git -C "$repo" commit -m "sync: capture live Caelestia state $stamp"
git -C "$repo" push origin main

echo
echo 'CaeRice quedó sincronizado con el estado real de la máquina.'
