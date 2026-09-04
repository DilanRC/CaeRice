#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${HOME}/.local/bin"
DATA_ROOT="${CORTETSU_DATA_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/cortetsu}"
SYSTEMD_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

atomic_symlink() {
    local target="$1"
    local link="$2"
    local temporary="${link}.tmp.$$"
    rm -f "$temporary"
    ln -s "$target" "$temporary"
    mv -Tf "$temporary" "$link"
}

if [[ -x "$REPO/scripts/migrate-cortetsu-v2.sh" ]]; then
    "$REPO/scripts/migrate-cortetsu-v2.sh"
fi

printf '==> Cortetsu: validación y construcción aislada\n'
"$REPO/caelestia/bin/check-package-updates.sh" || true
"$REPO/caelestia/bin/build-runtime.sh"

printf '==> Helpers Cortetsu\n'
mkdir -p "$BIN_DIR" "$DATA_ROOT"
while IFS= read -r -d '' source; do
    name="$(basename "$source")"
    install -m 0755 "$source" "$BIN_DIR/$name"
done < <(find "$REPO/caelestia/bin" -maxdepth 1 -type f -name 'cortetsu-*' -print0 | sort -z)

# Low-level shell rollback remains available for recovery. Normal operation uses
# `cortetsu rollback`, which reverts the full system generation.
install -m 0755 "$REPO/caelestia/bin/rollback-runtime.sh" "$BIN_DIR/cortetsu-rollback"
install -m 0755 "$REPO/caelestia/bin/caelestia" "$BIN_DIR/caelestia"

if [[ -x "$REPO/scripts/cortetsu" ]]; then
    atomic_symlink "$REPO" "$DATA_ROOT/repository"
    atomic_symlink "$REPO/scripts/cortetsu" "$BIN_DIR/cortetsu"
fi

printf '==> Dotfiles Cortetsu\n'
python3 "$REPO/core/dotfiles.py" apply --repo "$REPO"

printf '==> Ciclo de vida del shell\n'
python3 "$REPO/core/shell_lifecycle.py" migrate

printf '==> Integración de tema\n'
if [[ -f "$REPO/scripts/features/install-theme-bridge.py" ]]; then
    python3 "$REPO/scripts/features/install-theme-bridge.py"
fi

systemctl --user daemon-reload >/dev/null 2>&1 || true

# Preserve the user's explicit opt-in when migrating the renamed power service.
if [[ -f "$DATA_ROOT/.power-auto-was-enabled" && -f "$SYSTEMD_USER_DIR/cortetsu-power-auto.service" ]]; then
    if systemctl --user enable --now cortetsu-power-auto.service >/dev/null 2>&1; then
        rm -f "$DATA_ROOT/.power-auto-was-enabled"
        printf 'Power automation: opt-in restored\n'
    else
        printf 'WARN: no se pudo reactivar cortetsu-power-auto.service; el marcador se conserva\n' >&2
    fi
fi

printf '==> Generación unificada Cortetsu\n'
python3 "$REPO/core/system.py" promote --repo "$REPO"

# Never enable shell supervision implicitly. Once the user has explicitly
# adopted it, is-enabled is our durable opt-in. Restarting also recovers a
# previously adopted service that became inactive because an older unit used
# Quickshell's --daemonize flag under Type=simple.
if systemctl --user is-enabled --quiet cortetsu-shell.service 2>/dev/null; then
    if systemctl --user restart cortetsu-shell.service; then
        printf 'Shell supervision: adopted service running on promoted runtime\n'
    else
        printf 'WARN: cortetsu-shell.service está habilitado pero no pudo arrancar\n' >&2
    fi
fi

runtime_root="${CORTETSU_RUNTIME_ROOT:-${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/cortetsu}"
printf '\nCortetsu runtime: %s/current\n' "$runtime_root"
printf 'Dotfiles runtime: %s/dotfiles/current\n' "$DATA_ROOT"
printf 'System runtime: %s/system/current\n' "$DATA_ROOT"
printf 'No se escribió /etc/xdg/quickshell/caelestia.\n'
printf 'cortetsu-shell.service no se habilita implícitamente; una adopción existente sí se conserva.\n'
printf 'Rollback completo: cortetsu rollback\n'
printf 'Supervisión: cortetsu shell status\n'
