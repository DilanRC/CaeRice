#!/usr/bin/env bash
set -euo pipefail

DATA_ROOT="${CORTETSU_DATA_ROOT:-${CAERICE_DATA_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/cortetsu}}"
RUNTIME_ROOT="${CORTETSU_RUNTIME_ROOT:-${CAERICE_RUNTIME_ROOT:-${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia}}"

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

atomic_link() {
    local target="$1"
    local link="$2"
    local temporary="${link}.tmp.$$"
    rm -f "$temporary"
    ln -s "$target" "$temporary"
    mv -Tf "$temporary" "$link"
}

mkdir -p "$DATA_ROOT" "$RUNTIME_ROOT"
exec 9>"$DATA_ROOT/build.lock"
flock -n 9 || fail "hay una construcción o rollback de Cortetsu en curso"

[[ -L "$RUNTIME_ROOT/current" ]] || fail "no existe el enlace current"
[[ -L "$RUNTIME_ROOT/previous" ]] || fail "no existe una generación previous"
current="$(readlink -f "$RUNTIME_ROOT/current" || true)"
previous="$(readlink -f "$RUNTIME_ROOT/previous" || true)"
[[ -f "$current/shell.qml" ]] || fail "current no es una generación válida: $current"
[[ -f "$previous/shell.qml" ]] || fail "previous no es una generación válida: $previous"

atomic_link "$previous" "$RUNTIME_ROOT/current"
atomic_link "$current" "$RUNTIME_ROOT/previous"
[[ "$(readlink -f "$RUNTIME_ROOT/current")" == "$previous" ]] || fail "falló la conmutación atómica"
printf 'ROLLED BACK current=%s previous=%s\n' "$previous" "$current"
