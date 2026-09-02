#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
echo "install-patches.sh legacy: los parches solo se aplican en staging"
exec "$REPO/scripts/install-caerice.sh" "$@"
