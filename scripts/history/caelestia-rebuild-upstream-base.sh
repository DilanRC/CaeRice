#!/usr/bin/env bash
set -euo pipefail

PKGNAME="caelestia-shell"
INSTALLED="$(pacman -Q "$PKGNAME" | awk '{print $2}')"
WORK="${HOME}/.cache/caelestia-upstream-rebuild"
AUR="$WORK/aur"
OUT="$WORK/out"

echo "Installed: $PKGNAME $INSTALLED"

rm -rf "$WORK"
mkdir -p "$WORK" "$OUT"

echo
echo "==> Clonando historial AUR"
git clone --quiet "https://aur.archlinux.org/${PKGNAME}.git" "$AUR"
cd "$AUR"

echo
echo "==> Buscando commit AUR exacto para $INSTALLED"

MATCH=""
while read -r commit; do
    srcinfo="$(git show "${commit}:.SRCINFO" 2>/dev/null || true)"
    [[ -n "$srcinfo" ]] || continue

    pkgver="$(awk -F' = ' '$1 ~ /^[[:space:]]*pkgver$/ {print $2; exit}' <<<"$srcinfo")"
    pkgrel="$(awk -F' = ' '$1 ~ /^[[:space:]]*pkgrel$/ {print $2; exit}' <<<"$srcinfo")"
    epoch="$(awk -F' = ' '$1 ~ /^[[:space:]]*epoch$/ {print $2; exit}' <<<"$srcinfo")"

    [[ -n "$pkgver" && -n "$pkgrel" ]] || continue

    version="${pkgver}-${pkgrel}"
    if [[ -n "$epoch" && "$epoch" != "0" ]]; then
        version="${epoch}:${version}"
    fi

    if [[ "$version" == "$INSTALLED" ]]; then
        MATCH="$commit"
        break
    fi
done < <(git rev-list --all)

if [[ -z "$MATCH" ]]; then
    echo "ERROR: no encontré en el historial AUR un commit con versión $INSTALLED." >&2
    exit 2
fi

echo "Commit AUR: $MATCH"
git checkout --quiet "$MATCH"

echo
echo "==> PKGBUILD seleccionado"
grep -E '^(pkgname|pkgver|pkgrel|epoch|source|sha256sums)' PKGBUILD || true

echo
echo "==> Intentando reconstruir el paquete sin instalarlo"
echo "Si faltan makedepends, makepkg lo indicará y se detendrá."
echo

makepkg --noconfirm --cleanbuild

PKGFILE="$(find . -maxdepth 1 -type f \
    \( -name "${PKGNAME}-${INSTALLED}-*.pkg.tar.zst" \
       -o -name "${PKGNAME}-${INSTALLED}-*.pkg.tar.xz" \) \
    -print -quit)"

if [[ -z "$PKGFILE" ]]; then
    echo "ERROR: makepkg terminó pero no encuentro el paquete reconstruido." >&2
    exit 3
fi

cp "$PKGFILE" "$OUT/"
FINAL="$OUT/$(basename "$PKGFILE")"

echo
echo "==> Copiando archive exacto al cache de pacman"
sudo cp "$FINAL" /var/cache/pacman/pkg/

echo
echo "LISTO"
echo "Archive:"
echo "  $FINAL"
echo
echo "Ahora vuelve a ejecutar:"
echo "  bash ~/Descargas/caelestia-maintenance-v2.sh"
