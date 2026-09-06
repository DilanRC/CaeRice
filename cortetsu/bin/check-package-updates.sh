#!/usr/bin/env bash
set -euo pipefail
for pkg in quickshell-git; do
    installed="$(pacman -Q "$pkg" 2>/dev/null || true)"
    candidate="$(pacman -Si "$pkg" 2>/dev/null | awk '$1 == "Version" {print $3; exit}' || true)"
    printf '%s\tinstalled=%s\tcandidate=%s\t' "$pkg" "${installed#* }" "${candidate:-unavailable}"
    if [[ -n "$candidate" && "$installed" != *" $candidate" ]]; then
        echo UPDATE
    else
        echo OK
    fi
done
