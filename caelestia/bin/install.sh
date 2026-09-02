#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
echo "install.sh legacy: usando el runtime versionado de CaeRice"
exec "$REPO/scripts/install-caerice.sh" "$@"
