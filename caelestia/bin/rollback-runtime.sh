#!/usr/bin/env bash
set -euo pipefail
RUNTIME="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia"
[[ -e "$RUNTIME/previous" ]] || { echo "ERROR: no existe build previous" >&2; exit 1; }
current="$(readlink -f "$RUNTIME/current")"
previous="$(readlink -f "$RUNTIME/previous")"
ln -sfn "$previous" "$RUNTIME/current"
ln -sfn "$current" "$RUNTIME/previous"
echo "ROLLED BACK: $RUNTIME/current -> $previous"
