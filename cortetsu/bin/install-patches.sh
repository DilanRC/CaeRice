#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
echo "install-patches.sh legacy: Cortetsu aplica los parches únicamente en staging"
exec "$REPO/scripts/install-cortetsu.sh" "$@"
