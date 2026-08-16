#!/usr/bin/env bash
set -euo pipefail

BASE="$HOME/.local/share/caelestia-custom-system"
LIVE="/etc/xdg/quickshell/caelestia"
STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BASE/bin" "$BASE/legacy" "$BASE/reinstall-backups" "$BASE/snapshots"

# -----------------------------------------------------------------------------
# 1) KEYBIND CLEANUP
# -----------------------------------------------------------------------------
CFG="$HOME/.config/caelestia/hypr-user.lua"
if [[ ! -f "$CFG" ]]; then
  echo "ERROR: no existe $CFG" >&2
  exit 1
fi

KB_BKP="$HOME/.local/share/caelestia-backups/keybind-cleanup-$STAMP"
mkdir -p "$KB_BKP"
cp "$CFG" "$KB_BKP/hypr-user.lua"

python3 - "$CFG" <<'PY'
from pathlib import Path
import re, sys
p = Path(sys.argv[1])
text = p.read_text(encoding='utf-8')
patterns = [
("Super+V -> Clipse", r'''(?ms)\n?-- ============================================================\n-- CLIPBOARD\n-- ============================================================\n\nhl\.bind\(\n    "SUPER \+ V",\n    hl\.dsp\.exec_cmd\("kitty --class clipse -e clipse"\)\n\)\n'''),
("Ctrl+Super+L -> hyprlock", r'''(?ms)\nhl\.bind\(\n    "CTRL \+ SUPER \+ L",\n    hl\.dsp\.exec_cmd\("hyprlock"\)\n\)\n'''),
("Super+Shift+E -> wlogout", r'''(?ms)\nhl\.bind\(\n    "SUPER \+ SHIFT \+ E",\n    hl\.dsp\.exec_cmd\("wlogout"\)\n\)\n'''),
("Shift+Print -> guardar área", r'''(?ms)\nhl\.bind\(\n    "SHIFT \+ Print",\n    hl\.dsp\.exec_cmd\(\n        \[\[sh -c 'mkdir -p "\$HOME/Imagenes/Screenshots"; grimblast save area "\$HOME/Imagenes/Screenshots/\$\(date \+%Y%m%d-%H%M%S\)\.png"'\]\]\n    \)\n\)\n''')]
for name, pat in patterns:
    text2, n = re.subn(pat, '\n', text, count=1)
    print(("REMOVED" if n else "NOT FOUND"), name)
    text = text2
marker = "-- KEYBINDS RESERVADOS PARA MODULOS QML"
if marker not in text:
    reservation = '''\n-- ============================================================\n-- KEYBINDS RESERVADOS PARA MODULOS QML\n-- SUPER+V       -> Clipboard\n-- SUPER+H       -> Hardware Center\n-- SUPER+SHIFT+O -> Display Manager\n-- SUPER+SHIFT+G -> Gaming Center\n-- ============================================================\n\n'''
    anchor = "-- ============================================================\n-- WALLPAPER ENGINE"
    text = text.replace(anchor, reservation + anchor, 1) if anchor in text else text + reservation
p.write_text(text, encoding='utf-8')
PY

hyprctl reload

echo
echo "Keybind backup: $KB_BKP/hypr-user.lua"

# -----------------------------------------------------------------------------
# 2) PATCH-BASED MIGRATION
# -----------------------------------------------------------------------------
PATCHES="$BASE/patches"
OWNED="$BASE/modules-owned"
UPSTREAM="$BASE/upstream-package"
USERCFG="$BASE/user-config"

PKG="$(find /var/cache/pacman/pkg -maxdepth 1 -type f \
  \( -name 'caelestia-shell-*.pkg.tar.zst' -o -name 'caelestia-shell-*.pkg.tar.xz' \) \
  -printf '%p\n' 2>/dev/null | sort -V | tail -n1)"

if [[ -z "${PKG:-}" || ! -f "$PKG" ]]; then
  echo
  echo "ERROR: no encontré el paquete caelestia-shell cacheado." >&2
  echo "No voy a inventar una base upstream." >&2
  echo "Comprueba: ls /var/cache/pacman/pkg/caelestia-shell-*.pkg.tar*" >&2
  exit 2
fi

echo
echo "Base upstream exacta: $PKG"

if [[ -d "$BASE/files" ]]; then
  cp -a "$BASE/files" "$BASE/legacy/full-files-$STAMP"
fi

rm -rf "$UPSTREAM/current" "$PATCHES.new" "$OWNED.new"
mkdir -p "$UPSTREAM/current" "$PATCHES.new" "$OWNED.new" "$USERCFG/.config/caelestia"

bsdtar -xf "$PKG" -C "$UPSTREAM/current" etc/xdg/quickshell/caelestia 2>/dev/null
UPROOT="$UPSTREAM/current/etc/xdg/quickshell/caelestia"

NATIVE=(
  shell.qml
  components/ScreenState.qml
  services/Hypr.qml
  utils/NetworkConnection.qml
  modules/Shortcuts.qml
  modules/launcher/AppList.qml
  modules/launcher/Content.qml
  modules/launcher/ContentList.qml
  modules/launcher/Wrapper.qml
  modules/drawers/Regions.qml
  modules/drawers/Panels.qml
  modules/drawers/ContentWindow.qml
)

OWNED_FILES=(
  modules/CustomDock.qml
  modules/OverviewController.qml
  modules/overview/Wrapper.qml
  modules/overview/Content.qml
  modules/overview/WindowCard.qml
)

printf 'patch\tpath\n' > "$PATCHES.new/MANIFEST.tsv"

echo
echo "==> Patches nativos"
for rel in "${NATIVE[@]}"; do
  up="$UPROOT/$rel"
  live="$LIVE/$rel"
  [[ -f "$up" && -f "$live" ]] || { echo "SKIP $rel"; continue; }
  if cmp -s "$up" "$live"; then
    echo "UPSTREAM $rel"
    continue
  fi
  name="${rel//\//__}.patch"
  set +e
  diff -u --label "a/$rel" --label "b/$rel" "$up" "$live" > "$PATCHES.new/$name"
  rc=$?
  set -e
  [[ $rc -eq 1 ]] || { echo "ERROR diff $rel" >&2; exit 3; }
  printf '%s\t%s\n' "$name" "$rel" >> "$PATCHES.new/MANIFEST.tsv"
  echo "PATCH $rel"
done

echo
echo "==> Módulos propios"
for rel in "${OWNED_FILES[@]}"; do
  src="$LIVE/$rel"
  [[ -f "$src" ]] || { echo "MISSING $rel"; continue; }
  dst="$OWNED.new/$rel"
  mkdir -p "$(dirname "$dst")"
  sudo cp "$src" "$dst"
  sudo chown "$USER":"$(id -gn)" "$dst"
  echo "OWNED $rel"
done

rm -rf "$PATCHES" "$OWNED"
mv "$PATCHES.new" "$PATCHES"
mv "$OWNED.new" "$OWNED"
cp "$CFG" "$USERCFG/.config/caelestia/hypr-user.lua"

cat > "$BASE/PATCH_BASE_INFO.txt" <<EOF
generated_at=$(date --iso-8601=seconds)
package_version=$(pacman -Q caelestia-shell 2>/dev/null | awk '{print $2}')
package_archive=$PKG
EOF

# -----------------------------------------------------------------------------
# 3) INSTALLER WITH PREFLIGHT
# -----------------------------------------------------------------------------
cat > "$BASE/bin/install-patches.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
BASE="$HOME/.local/share/caelestia-custom-system"
LIVE="/etc/xdg/quickshell/caelestia"
PATCHES="$BASE/patches"
OWNED="$BASE/modules-owned"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$BASE/reinstall-backups/patch-install-$STAMP"
mkdir -p "$BACKUP"

echo "===== PREFLIGHT ====="
while IFS=$'\t' read -r patchname rel; do
  [[ "$patchname" == patch ]] && continue
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

while IFS=$'\t' read -r patchname rel; do
  [[ "$patchname" == patch ]] && continue
  [[ -f "$LIVE/$rel" ]] || continue
  mkdir -p "$BACKUP/$(dirname "$rel")"
  sudo cp "$LIVE/$rel" "$BACKUP/$rel"
  sudo chown "$USER":"$(id -gn)" "$BACKUP/$rel"
done < "$PATCHES/MANIFEST.tsv"

while IFS= read -r -d '' src; do
  rel="${src#$OWNED/}"
  if [[ -f "$LIVE/$rel" ]]; then
    mkdir -p "$BACKUP/$(dirname "$rel")"
    sudo cp "$LIVE/$rel" "$BACKUP/$rel"
    sudo chown "$USER":"$(id -gn)" "$BACKUP/$rel"
  fi
done < <(find "$OWNED" -type f -print0)

while IFS=$'\t' read -r patchname rel; do
  [[ "$patchname" == patch ]] && continue
  p="$PATCHES/$patchname"
  if sudo patch --dry-run -R -p1 -d "$LIVE" < "$p" >/dev/null 2>&1; then
    echo "SKIP $rel"
  else
    sudo patch -p1 -d "$LIVE" < "$p"
  fi
done < "$PATCHES/MANIFEST.tsv"

while IFS= read -r -d '' src; do
  rel="${src#$OWNED/}"
  dst="$LIVE/$rel"
  sudo mkdir -p "$(dirname "$dst")"
  sudo install -m 0644 "$src" "$dst"
  echo "OWNED $rel"
done < <(find "$OWNED" -type f -print0)

echo "Backup: $BACKUP"
EOF
chmod +x "$BASE/bin/install-patches.sh"

# -----------------------------------------------------------------------------
# 4) VERIFIER
# -----------------------------------------------------------------------------
cat > "$BASE/bin/verify-patches.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
BASE="$HOME/.local/share/caelestia-custom-system"
LIVE="/etc/xdg/quickshell/caelestia"
PATCHES="$BASE/patches"
OWNED="$BASE/modules-owned"

echo "===== PATCHES ====="
while IFS=$'\t' read -r patchname rel; do
  [[ "$patchname" == patch ]] && continue
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
  if [[ ! -f "$LIVE/$rel" ]]; then
    printf 'MISSING   %s\n' "$rel"
  elif cmp -s "$src" "$LIVE/$rel"; then
    printf 'OK        %s\n' "$rel"
  else
    printf 'CHANGED   %s\n' "$rel"
  fi
done < <(find "$OWNED" -type f -print0 | sort -z)
EOF
chmod +x "$BASE/bin/verify-patches.sh"

# -----------------------------------------------------------------------------
# 5) SYNC ONLY FULLY OWNED MODULES
# -----------------------------------------------------------------------------
cat > "$BASE/bin/sync-owned.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
BASE="$HOME/.local/share/caelestia-custom-system"
LIVE="/etc/xdg/quickshell/caelestia"
OWNED="$BASE/modules-owned"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$BASE/snapshots/owned-before-sync-$STAMP"
mkdir -p "$BACKUP"
while IFS= read -r -d '' src; do
  rel="${src#$OWNED/}"
  live="$LIVE/$rel"
  [[ -f "$live" ]] || continue
  mkdir -p "$BACKUP/$(dirname "$rel")"
  cp "$src" "$BACKUP/$rel"
  sudo cp "$live" "$src"
  sudo chown "$USER":"$(id -gn)" "$src"
  echo "SYNC $rel"
done < <(find "$OWNED" -type f -print0)
cp "$HOME/.config/caelestia/hypr-user.lua" "$BASE/user-config/.config/caelestia/hypr-user.lua"
echo "Backup: $BACKUP"
EOF
chmod +x "$BASE/bin/sync-owned.sh"

echo
echo "===== VERIFICACIÓN INICIAL ====="
bash "$BASE/bin/verify-patches.sh"

echo
echo "LISTO"
echo "Patch system: $BASE"
echo "Legacy rollback: $BASE/legacy/full-files-$STAMP"
echo "Keybind backup: $KB_BKP/hypr-user.lua"
echo
echo "Después de una actualización de Caelestia:"
echo "  bash $BASE/bin/verify-patches.sh"
echo "Si solo muestra MISSING y no CONFLICT:"
echo "  bash $BASE/bin/install-patches.sh"
