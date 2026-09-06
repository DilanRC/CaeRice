#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPATIBILITY="$REPO/cortetsu/contracts/upstream-compatibility.json"
CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
CANONICAL="${CORTETSU_UPSTREAM_CACHE:-$CACHE_HOME/cortetsu/upstream/caelestia-shell}"

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

[[ -f "$COMPATIBILITY" ]] || fail "falta contrato upstream: $COMPATIBILITY"

readarray -t contract < <(
    python3 - "$COMPATIBILITY" <<'PY'
import json
import sys
from pathlib import Path
payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
base = payload["caelestiaShell"]
print(base["upstreamTag"])
print(base["upstreamCommit"])
print(base.get("upstreamRepo", "https://github.com/caelestia-dots/shell.git"))
PY
)
TAG="${contract[0]}"
COMMIT="${contract[1]}"
UPSTREAM_REPO="${CORTETSU_UPSTREAM_REPO:-${contract[2]}}"

repo_has_exact_base() {
    local path="$1" resolved=""
    git -C "$path" rev-parse --git-dir >/dev/null 2>&1 || return 1
    if git -C "$path" cat-file -e "$TAG^{commit}" 2>/dev/null; then
        resolved="$(git -C "$path" rev-list -n 1 "$TAG")"
        [[ "$resolved" == "$COMMIT" ]] || return 1
    elif ! git -C "$path" cat-file -e "$COMMIT^{commit}" 2>/dev/null; then
        return 1
    fi
    git -C "$path" cat-file -e "$COMMIT:shell.qml" 2>/dev/null
}

fetch_exact_base() {
    local path="$1"
    git -C "$path" remote get-url origin >/dev/null 2>&1 || git -C "$path" remote add origin "$UPSTREAM_REPO"
    git -C "$path" remote set-url origin "$UPSTREAM_REPO"
    git -C "$path" fetch --force --depth=1 origin "refs/tags/$TAG:refs/tags/$TAG" >/dev/null 2>&1 || \
        git -C "$path" fetch --force --depth=1 origin "$COMMIT" >/dev/null 2>&1 || \
        return 1
    repo_has_exact_base "$path"
}

if [[ -n "${CORTETSU_UPSTREAM_SOURCE:-}" ]]; then
    repo_has_exact_base "$CORTETSU_UPSTREAM_SOURCE" || fail "CORTETSU_UPSTREAM_SOURCE no contiene $TAG@$COMMIT: $CORTETSU_UPSTREAM_SOURCE"
    printf '%s\n' "$CORTETSU_UPSTREAM_SOURCE"
    exit 0
fi

if repo_has_exact_base "$CANONICAL"; then
    printf '%s\n' "$CANONICAL"
    exit 0
fi

mkdir -p "$(dirname "$CANONICAL")"
if [[ -e "$CANONICAL" ]]; then
    quarantine="${CANONICAL}.invalid-$(date +%Y%m%d-%H%M%S)"
    mv "$CANONICAL" "$quarantine"
    printf 'WARN: cache upstream inválida archivada en %s\n' "$quarantine" >&2
fi

temporary="${CANONICAL}.tmp.$$"
rm -rf "$temporary"
trap 'rm -rf "$temporary"' EXIT

legacy_candidates=(
    "$HOME/.local/share/caelestia-custom-system/upstream-git"
    "$HOME/.local/share/cortetsu/upstream/upstream-git"
)
seeded=no
for candidate in "${legacy_candidates[@]}"; do
    if repo_has_exact_base "$candidate"; then
        printf '==> Reutilizando checkout upstream existente como semilla: %s\n' "$candidate" >&2
        if git clone --local --no-checkout "$candidate" "$temporary" >/dev/null 2>&1; then
            git -C "$temporary" remote set-url origin "$UPSTREAM_REPO"
            seeded=yes
            break
        fi
        rm -rf "$temporary"
    fi
done

if [[ "$seeded" != yes ]]; then
    printf '==> Inicializando cache upstream Cortetsu desde %s\n' "$UPSTREAM_REPO" >&2
    git init -q "$temporary"
    git -C "$temporary" remote add origin "$UPSTREAM_REPO"
fi

if ! repo_has_exact_base "$temporary"; then
    printf '==> Obteniendo base exacta %s (%s)\n' "$TAG" "$COMMIT" >&2
    fetch_exact_base "$temporary" || fail "no se pudo obtener la base exacta $TAG@$COMMIT"
fi

repo_has_exact_base "$temporary" || fail "la cache upstream preparada no coincide con $TAG@$COMMIT"
mv "$temporary" "$CANONICAL"
trap - EXIT
printf '%s\n' "$CANONICAL"
