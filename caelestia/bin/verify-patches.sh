#!/usr/bin/env bash
set -euo pipefail

BASE="${HOME}/.local/share/caelestia-custom-system"
LIVE="/etc/xdg/quickshell/caelestia"
PATCHES="$BASE/patches"
OWNED="$BASE/modules-owned"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_CHECKER="$SCRIPT_DIR/check-bottom-hub-target.py"

semantic_target() {
    local rel="$1"
    [[ -f "$TARGET_CHECKER" ]] || return 1
    python3 "$TARGET_CHECKER" "$LIVE" "$rel" >/dev/null 2>&1
}

echo "===== PATCHES ====="
while IFS=$'\t' read -r patchname rel; do
    [[ "$patchname" == "patch" ]] && continue
    p="$PATCHES/$patchname"

    if sudo patch --dry-run -R -p1 -d "$LIVE" < "$p" >/dev/null 2>&1; then
        printf 'APPLIED   %s\n' "$rel"
    elif sudo patch --dry-run -p1 -d "$LIVE" < "$p" >/dev/null 2>&1; then
        printf 'MISSING   %s\n' "$rel"
    elif semantic_target "$rel"; then
        printf 'TARGET    %s\n' "$rel"
    else
        printf 'CONFLICT  %s\n' "$rel"
    fi
done < "$PATCHES/MANIFEST.tsv"

echo
echo "===== OWNED MODULES ====="
while IFS= read -r -d '' src; do
    rel="${src#$OWNED/}"
    live="$LIVE/$rel"

    if [[ ! -f "$live" ]]; then
        printf 'MISSING   %s\n' "$rel"
    elif cmp -s "$src" "$live"; then
        printf 'OK        %s\n' "$rel"
    else
        printf 'CHANGED   %s\n' "$rel"
    fi
done < <(find "$OWNED" -type f -print0 | sort -z)
