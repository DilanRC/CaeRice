#!/usr/bin/env bash
set -euo pipefail

BASE="${HOME}/.local/share/cortetsu/upstream"
LIVE="/etc/xdg/quickshell/caelestia"
STAMP="$(date +%Y%m%d-%H%M%S)"

INSTALLED="$(pacman -Q caelestia-shell | awk '{print $2}')"
PKGVER="${INSTALLED%%-*}"
TAG="v${PKGVER}"

# For the user's currently installed 2.3.0 package, this is the exact official
# release commit behind tag v2.3.0.
EXPECTED_TAG="v2.3.0"
EXPECTED_COMMIT="94d5eb9e6fe9c6b1f69e663d9ed410a441e2d67f"

UPSTREAM="$BASE/upstream-git"
PATCHES="$BASE/patches"
OWNED="$BASE/modules-owned"
USERCFG="$BASE/user-config"
LEGACY="$BASE/legacy"
BACKUPS="$BASE/reinstall-backups"
SNAPSHOTS="$BASE/snapshots"

echo "Installed: caelestia-shell $INSTALLED"
echo "Source tag: $TAG"

if [[ "$TAG" != "$EXPECTED_TAG" ]]; then
    echo "ERROR: este migrador fue preparado para $EXPECTED_TAG, pero detecté $TAG." >&2
    echo "No voy a mezclar bases de versiones." >&2
    exit 2
fi

mkdir -p "$BASE" "$LEGACY" "$BACKUPS" "$SNAPSHOTS" "$USERCFG"

# Preserve the old full-file strategy as rollback material.
if [[ -d "$BASE/files" ]]; then
    LEGACY_DST="$LEGACY/full-files-$STAMP"
    cp -a "$BASE/files" "$LEGACY_DST"
    echo "Legacy snapshot: $LEGACY_DST"
fi

rm -rf "$UPSTREAM.new"
git clone --quiet --depth 1 --branch "$TAG" \
    https://github.com/caelestia-dots/shell.git \
    "$UPSTREAM.new"

ACTUAL_COMMIT="$(git -C "$UPSTREAM.new" rev-parse HEAD)"

echo "Official tag commit: $ACTUAL_COMMIT"

if [[ "$ACTUAL_COMMIT" != "$EXPECTED_COMMIT" ]]; then
    echo "ERROR: $TAG resolvió a un commit inesperado." >&2
    echo "Esperado: $EXPECTED_COMMIT" >&2
    echo "Actual:   $ACTUAL_COMMIT" >&2
    exit 3
fi

rm -rf "$UPSTREAM"
mv "$UPSTREAM.new" "$UPSTREAM"

NATIVE_CANDIDATES=(
  "shell.qml"
  "components/ScreenState.qml"
  "services/Hypr.qml"
  "utils/NetworkConnection.qml"
  "modules/Shortcuts.qml"
  "modules/launcher/AppList.qml"
  "modules/launcher/Content.qml"
  "modules/launcher/ContentList.qml"
  "modules/launcher/Wrapper.qml"
  "modules/drawers/Regions.qml"
  "modules/drawers/Panels.qml"
  "modules/drawers/ContentWindow.qml"
)

OWNED_FILES=(
  "modules/CustomDock.qml"
  "modules/OverviewController.qml"
  "modules/overview/Wrapper.qml"
  "modules/overview/Content.qml"
  "modules/overview/WindowCard.qml"
)

rm -rf "$PATCHES.new" "$OWNED.new"
mkdir -p "$PATCHES.new" "$OWNED.new"

printf "patch\tpath\n" > "$PATCHES.new/MANIFEST.tsv"

echo
echo "==> Generando patches"
for rel in "${NATIVE_CANDIDATES[@]}"; do
    up="$UPSTREAM/$rel"
    live="$LIVE/$rel"

    if [[ ! -f "$up" ]]; then
        echo "SKIP upstream missing: $rel"
        continue
    fi

    if [[ ! -f "$live" ]]; then
        echo "SKIP live missing: $rel"
        continue
    fi

    if cmp -s "$up" "$live"; then
        echo "UPSTREAM: $rel"
        continue
    fi

    name="${rel//\//__}.patch"
    status=0
    diff -u \
        --label "a/$rel" \
        --label "b/$rel" \
        "$up" "$live" > "$PATCHES.new/$name" || status=$?

    if [[ "$status" -gt 1 ]]; then
        echo "ERROR creando patch para $rel" >&2
        exit 4
    fi

    printf "%s\t%s\n" "$name" "$rel" >> "$PATCHES.new/MANIFEST.tsv"
    echo "PATCH: $rel"
done

echo
echo "==> Capturando módulos propios"
for rel in "${OWNED_FILES[@]}"; do
    src="$LIVE/$rel"

    if [[ -f "$src" ]]; then
        dst="$OWNED.new/$rel"
        mkdir -p "$(dirname "$dst")"
        sudo cp "$src" "$dst"
        sudo chown "$USER":"$(id -gn)" "$dst"
        echo "OWNED: $rel"
    else
        echo "AVISO: no existe $rel"
    fi
done

rm -rf "$PATCHES" "$OWNED"
mv "$PATCHES.new" "$PATCHES"
mv "$OWNED.new" "$OWNED"

if [[ -f "$HOME/.config/caelestia/hypr-user.lua" ]]; then
    mkdir -p "$USERCFG/.config/caelestia"
    cp "$HOME/.config/caelestia/hypr-user.lua" \
       "$USERCFG/.config/caelestia/hypr-user.lua"
fi

cat > "$BASE/PATCH_BASE_INFO.txt" <<EOF
generated_at=$(date --iso-8601=seconds)
installed_package=$INSTALLED
upstream_tag=$TAG
upstream_commit=$ACTUAL_COMMIT
upstream_repo=https://github.com/caelestia-dots/shell
live_root=$LIVE
EOF

cat > "$BASE/bin/verify-patches.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

BASE="${HOME}/.local/share/cortetsu/upstream"
LIVE="/etc/xdg/quickshell/caelestia"
PATCHES="$BASE/patches"
OWNED="$BASE/modules-owned"

echo "===== PATCHES ====="
while IFS=$'\t' read -r patchname rel; do
    [[ "$patchname" == "patch" ]] && continue
    p="$PATCHES/$patchname"

    if sudo patch --dry-run -R -p1 -d "$LIVE" < "$p" >/dev/null 2>&1; then
        printf 'APPLIED   %s\n' "$rel"
    elif sudo patch --dry-run -p1 -d "$LIVE" < "$p" >/dev/null 2>&1; then
        printf 'MISSING   %s\n' "$rel"
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
EOF

cat > "$BASE/bin/install-patches.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

BASE="${HOME}/.local/share/cortetsu/upstream"
LIVE="/etc/xdg/quickshell/caelestia"
PATCHES="$BASE/patches"
OWNED="$BASE/modules-owned"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$BASE/reinstall-backups/patch-install-$STAMP"

mkdir -p "$BACKUP"

echo "==> PREFLIGHT"
while IFS=$'\t' read -r patchname rel; do
    [[ "$patchname" == "patch" ]] && continue
    p="$PATCHES/$patchname"

    if sudo patch --dry-run -R -p1 -d "$LIVE" < "$p" >/dev/null 2>&1; then
        echo "ALREADY  $rel"
    elif sudo patch --dry-run -p1 -d "$LIVE" < "$p" >/dev/null 2>&1; then
        echo "READY    $rel"
    else
        echo "CONFLICT $rel"
        echo "Abortado antes de modificar nada."
        exit 20
    fi
done < "$PATCHES/MANIFEST.tsv"

echo
echo "==> BACKUP"
while IFS=$'\t' read -r patchname rel; do
    [[ "$patchname" == "patch" ]] && continue
    if [[ -f "$LIVE/$rel" ]]; then
        mkdir -p "$BACKUP/$(dirname "$rel")"
        sudo cp "$LIVE/$rel" "$BACKUP/$rel"
        sudo chown "$USER":"$(id -gn)" "$BACKUP/$rel"
    fi
done < "$PATCHES/MANIFEST.tsv"

while IFS= read -r -d '' src; do
    rel="${src#$OWNED/}"
    if [[ -f "$LIVE/$rel" ]]; then
        mkdir -p "$BACKUP/$(dirname "$rel")"
        sudo cp "$LIVE/$rel" "$BACKUP/$rel"
        sudo chown "$USER":"$(id -gn)" "$BACKUP/$rel"
    fi
done < <(find "$OWNED" -type f -print0)

echo
echo "==> APLICANDO PATCHES"
while IFS=$'\t' read -r patchname rel; do
    [[ "$patchname" == "patch" ]] && continue
    p="$PATCHES/$patchname"

    if sudo patch --dry-run -R -p1 -d "$LIVE" < "$p" >/dev/null 2>&1; then
        echo "SKIP ya aplicado: $rel"
    else
        sudo patch -p1 -d "$LIVE" < "$p"
    fi
done < "$PATCHES/MANIFEST.tsv"

echo
echo "==> MÓDULOS PROPIOS"
while IFS= read -r -d '' src; do
    rel="${src#$OWNED/}"
    dst="$LIVE/$rel"
    sudo mkdir -p "$(dirname "$dst")"
    sudo install -m 0644 "$src" "$dst"
    echo "OWNED: $rel"
done < <(find "$OWNED" -type f -print0)

echo
echo "Backup: $BACKUP"
EOF

cat > "$BASE/bin/sync-owned.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

BASE="${HOME}/.local/share/cortetsu/upstream"
LIVE="/etc/xdg/quickshell/caelestia"
OWNED="$BASE/modules-owned"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$BASE/snapshots/owned-before-sync-$STAMP"

mkdir -p "$BACKUP"

while IFS= read -r -d '' src; do
    rel="${src#$OWNED/}"
    live="$LIVE/$rel"

    if [[ -f "$live" ]]; then
        mkdir -p "$BACKUP/$(dirname "$rel")"
        cp "$src" "$BACKUP/$rel"
        sudo cp "$live" "$src"
        sudo chown "$USER":"$(id -gn)" "$src"
        echo "SYNC $rel"
    fi
done < <(find "$OWNED" -type f -print0)

if [[ -f "$HOME/.config/caelestia/hypr-user.lua" ]]; then
    mkdir -p "$BASE/user-config/.config/caelestia"
    cp "$HOME/.config/caelestia/hypr-user.lua" \
       "$BASE/user-config/.config/caelestia/hypr-user.lua"
fi

echo "Backup previo: $BACKUP"
EOF

chmod +x \
    "$BASE/bin/verify-patches.sh" \
    "$BASE/bin/install-patches.sh" \
    "$BASE/bin/sync-owned.sh"

echo
echo "===== VERIFICACIÓN INICIAL ====="
bash "$BASE/bin/verify-patches.sh"

echo
echo "===== PATCH BASE ====="
cat "$BASE/PATCH_BASE_INFO.txt"

echo
echo "LISTO"
