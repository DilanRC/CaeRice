#!/usr/bin/env bash
set -euo pipefail
REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO" ]] || { echo "ERROR: ejecuta dentro de Cortetsu" >&2; exit 1; }
bash "$REPO/scripts/features/sync-retained-sad.sh"
