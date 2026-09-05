#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HELPER="$REPO/cortetsu/bin/ensure-upstream.sh"
SOURCE="${CORTETSU_UPSTREAM_TEST_SOURCE:-}"
EXPECTED_TAG="v2.4.0"
EXPECTED_COMMIT="24aa15eefdb146350d2548c0a015b04eddbd1008"

if [[ -z "$SOURCE" ]]; then
    for candidate in \
        "$HOME/.local/share/caelestia-custom-system/upstream-git" \
        "$HOME/.local/share/cortetsu/upstream/upstream-git"
    do
        if git -C "$candidate" cat-file -e "$EXPECTED_COMMIT^{commit}" 2>/dev/null; then
            SOURCE="$candidate"
            break
        fi
    done
fi

if [[ -z "$SOURCE" ]]; then
    printf 'SKIP: no exact local Caelestia source available for upstream bootstrap regression\n'
    exit 0
fi

git -C "$SOURCE" cat-file -e "$EXPECTED_COMMIT^{commit}" 2>/dev/null || {
    printf 'SKIP: supplied source does not contain %s\n' "$EXPECTED_COMMIT"
    exit 0
}

tmp="$(mktemp -d -t cortetsu-upstream-test-XXXXXX)"
trap 'rm -rf "$tmp"' EXIT
fake_home="$tmp/home"
legacy="$fake_home/.local/share/caelestia-custom-system/upstream-git"
cache="$fake_home/.cache/cortetsu/upstream/caelestia-shell"
mkdir -p "$(dirname "$legacy")" "$cache"
printf 'broken cache\n' > "$cache/NOT_A_REPO"

git clone --local --no-checkout "$SOURCE" "$legacy" >/dev/null 2>&1

resolved="$(
    HOME="$fake_home" \
    XDG_CACHE_HOME="$fake_home/.cache" \
    bash "$HELPER"
)"

[[ "$resolved" == "$cache" ]]
git -C "$resolved" cat-file -e "$EXPECTED_COMMIT:shell.qml"
[[ "$(git -C "$resolved" rev-list -n 1 "$EXPECTED_TAG")" == "$EXPECTED_COMMIT" ]]
[[ "$(git -C "$resolved" remote get-url origin)" == "https://github.com/caelestia-dots/shell.git" ]]
compgen -G "${cache}.invalid-*" >/dev/null

rm -rf "$legacy"
resolved_again="$(
    HOME="$fake_home" \
    XDG_CACHE_HOME="$fake_home/.cache" \
    bash "$HELPER"
)"
[[ "$resolved_again" == "$cache" ]]
[[ "$(git -C "$resolved_again" rev-parse "$EXPECTED_COMMIT^{commit}")" == "$EXPECTED_COMMIT" ]]

printf 'PASS: exact upstream cache self-heals, seeds from legacy once, and stays idempotent without legacy state\n'
