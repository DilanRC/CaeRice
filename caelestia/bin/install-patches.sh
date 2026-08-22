#!/usr/bin/env bash
set -euo pipefail

BASE="${HOME}/.local/share/caelestia-custom-system"
LIVE="/etc/xdg/quickshell/caelestia"
PATCHES="$BASE/patches"
OWNED="$BASE/modules-owned"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATOR="$SCRIPT_DIR/migrate-bottom-hub-from-main.py"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$BASE/reinstall-backups/patch-install-$STAMP"
TMP="$(mktemp -d -t caerice-preflight.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$BACKUP"

declare -A INITIAL_STATE

patch_state_live() {
    local patch_file="$1"
    if sudo patch --dry-run -R -p1 -d "$LIVE" < "$patch_file" >/dev/null 2>&1; then
        printf 'ALREADY'
    elif sudo patch --dry-run -p1 -d "$LIVE" < "$patch_file" >/dev/null 2>&1; then
        printf 'READY'
    else
        printf 'CONFLICT'
    fi
}

patch_state_temp() {
    local patch_file="$1"
    if patch --dry-run -R -p1 -d "$TMP" < "$patch_file" >/dev/null 2>&1; then
        printf 'ALREADY'
    elif patch --dry-run -p1 -d "$TMP" < "$patch_file" >/dev/null 2>&1; then
        printf 'READY'
    else
        printf 'CONFLICT'
    fi
}

echo "==> PREFLIGHT: ESTADO ACTUAL"
while IFS=$'\t' read -r patchname rel; do
    [[ "$patchname" == "patch" ]] && continue
    p="$PATCHES/$patchname"
    state="$(patch_state_live "$p")"
    INITIAL_STATE["$rel"]="$state"
    printf '%-9s %s\n' "$state" "$rel"

    if [[ -f "$LIVE/$rel" ]]; then
        mkdir -p "$TMP/$(dirname "$rel")"
        sudo cp "$LIVE/$rel" "$TMP/$rel"
        sudo chown "$USER":"$(id -gn)" "$TMP/$rel"
    fi
done < "$PATCHES/MANIFEST.tsv"

# El runtime puede estar en un tercer estado legítimo: CaeRice main ya
# aplicado. Simulamos la migración en una copia temporal y volvemos a validar
# todos los patches antes de modificar /etc/xdg.
if [[ -f "$MIGRATOR" ]]; then
    echo
    echo "==> PREFLIGHT: SIMULACIÓN main -> BottomHub"
    python3 "$MIGRATOR" "$TMP"
fi

echo
echo "==> PREFLIGHT: ESTADO OBJETIVO"
preflight_failed=0
while IFS=$'\t' read -r patchname rel; do
    [[ "$patchname" == "patch" ]] && continue
    p="$PATCHES/$patchname"
    state="$(patch_state_temp "$p")"

    if [[ "${INITIAL_STATE[$rel]:-CONFLICT}" == "CONFLICT" && "$state" == "ALREADY" ]]; then
        printf '%-9s %s\n' "MIGRATE" "$rel"
    else
        printf '%-9s %s\n' "$state" "$rel"
    fi

    if [[ "$state" == "CONFLICT" ]]; then
        preflight_failed=1
    fi
done < "$PATCHES/MANIFEST.tsv"

if (( preflight_failed )); then
    echo
    echo "CONFLICT: la simulación no llega a un estado instalable."
    echo "Abortado antes de modificar nada."
    exit 20
fi

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

# CustomDock deja de ser owned en BottomHub; conservarlo en el backup antes
# de retirarlo del runtime para que el rollback sea explícito.
if [[ -f "$OWNED/modules/BottomHub.qml" && ! -f "$OWNED/modules/CustomDock.qml" && -f "$LIVE/modules/CustomDock.qml" ]]; then
    mkdir -p "$BACKUP/modules"
    sudo cp "$LIVE/modules/CustomDock.qml" "$BACKUP/modules/CustomDock.qml"
    sudo chown "$USER":"$(id -gn)" "$BACKUP/modules/CustomDock.qml"
fi

echo "Backup: $BACKUP"

if [[ -f "$MIGRATOR" ]]; then
    echo
echo "==> MIGRACIÓN DE RUNTIME CaeRice main -> BottomHub"
    sudo python3 "$MIGRATOR" "$LIVE"
fi

echo
echo "==> APLICANDO PATCHES"
while IFS=$'\t' read -r patchname rel; do
    [[ "$patchname" == "patch" ]] && continue
    p="$PATCHES/$patchname"

    if sudo patch --dry-run -R -p1 -d "$LIVE" < "$p" >/dev/null 2>&1; then
        echo "SKIP ya aplicado: $rel"
    elif sudo patch --dry-run -p1 -d "$LIVE" < "$p" >/dev/null 2>&1; then
        sudo patch -p1 -d "$LIVE" < "$p"
    else
        echo "ERROR: $rel cambió después del preflight; no continúo." >&2
        echo "Backup disponible en: $BACKUP" >&2
        exit 21
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

if [[ -f "$OWNED/modules/BottomHub.qml" && ! -f "$OWNED/modules/CustomDock.qml" && -f "$LIVE/modules/CustomDock.qml" ]]; then
    sudo rm -f "$LIVE/modules/CustomDock.qml"
    echo "PURGE stale: modules/CustomDock.qml"
fi

echo
echo "Instalación de patches completada."
echo "Backup: $BACKUP"
