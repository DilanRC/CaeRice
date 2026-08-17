#!/usr/bin/env bash
set -euo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO" ]] || { echo "ERROR: ejecuta dentro de CaeRice" >&2; exit 1; }

bash "$REPO/scripts/features/update-hardware-center.sh"

echo
echo "==> final diagnostics"
python3 "$REPO/scripts/features/diagnose-hardware-center.py"

echo
echo "Hardware Center code path finalized."
echo "Review the UI acceptance checklist in docs/HARDWARE_CENTER_QA.md before merging."
