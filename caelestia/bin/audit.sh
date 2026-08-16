#!/usr/bin/env bash
set -euo pipefail

BASE="${HOME}/.local/share/caelestia-custom-system"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$BASE/audit/$STAMP"

mkdir -p "$OUT"

run() {
    local name="$1"
    shift
    echo "==> $name"
    {
        echo "\$ $*"
        echo
        "$@"
    } > "$OUT/$name.txt" 2>&1 || true
}

run_shell() {
    local name="$1"
    shift
    echo "==> $name"
    {
        echo "\$ $*"
        echo
        bash -lc "$*"
    } > "$OUT/$name.txt" 2>&1 || true
}

echo "Auditoría: $OUT"

# ---------------- system ----------------
run_shell system-info '
echo "DATE=$(date --iso-8601=seconds)"
echo "HOST=$(hostname)"
echo "KERNEL=$(uname -r)"
echo
cat /etc/os-release
echo
lscpu | sed -n "1,30p"
echo
free -h
echo
lsblk -o NAME,SIZE,FSTYPE,FSUSE%,MOUNTPOINTS,MODEL
'

run_shell boot '
systemd-analyze
echo
systemd-analyze blame | head -60
echo
systemd-analyze critical-chain
'

run_shell processes '
ps -eo pid,ppid,user,comm,%cpu,%mem,rss,args --sort=-rss | head -80
'

# ---------------- keybinds ----------------
run_shell hypr-binds-text '
hyprctl binds
'

run_shell hypr-binds-json '
hyprctl -j binds
'

run_shell keybind-source '
echo "===== hypr-user.lua ====="
sed -n "1,260p" ~/.config/caelestia/hypr-user.lua 2>/dev/null || true
echo
echo "===== hyprland.lua ====="
sed -n "1,260p" ~/.config/hypr/hyprland.lua 2>/dev/null || true
echo
echo "===== Caelestia shortcuts ====="
grep -RniE "CustomShortcut|hl\\.bind|kb[A-Z]|global\\(" \
  /etc/xdg/quickshell/caelestia/modules/Shortcuts.qml \
  ~/.config/caelestia ~/.config/hypr 2>/dev/null | head -400
'

python3 - "$OUT/hypr-binds-json.txt" "$OUT/keybind-duplicates.txt" <<'PY'
import json, sys, re
src, dst = sys.argv[1], sys.argv[2]
raw = open(src, encoding="utf-8", errors="replace").read()
start = raw.find("[")
if start < 0:
    open(dst,"w").write("No JSON bind data found.\n")
    raise SystemExit
try:
    data = json.loads(raw[start:])
except Exception as e:
    open(dst,"w").write(f"Could not parse binds JSON: {e}\n")
    raise SystemExit

groups = {}
for b in data:
    sig = (
        b.get("submap",""),
        b.get("modmask"),
        b.get("key",""),
        b.get("keycode"),
        bool(b.get("release")),
        bool(b.get("locked")),
    )
    groups.setdefault(sig, []).append(b)

with open(dst, "w", encoding="utf-8") as f:
    dups = [(k,v) for k,v in groups.items() if len(v) > 1]
    f.write(f"Total binds: {len(data)}\n")
    f.write(f"Combinaciones duplicadas exactas: {len(dups)}\n\n")
    for sig, items in sorted(dups, key=lambda x: str(x[0])):
        f.write(f"=== {sig} ===\n")
        for b in items:
            f.write(
                f"dispatcher={b.get('dispatcher')} "
                f"arg={b.get('arg')} "
                f"description={b.get('description','')}\n"
            )
        f.write("\n")
PY

# ---------------- packages ----------------
run_shell packages-explicit '
pacman -Qqe
'

run_shell packages-orphans '
pacman -Qdtq
'

run_shell packages-foreign '
pacman -Qm
'

run_shell packages-native '
pacman -Qn
'

run_shell packages-info '
LC_ALL=C pacman -Qi
'

python3 - "$OUT/packages-info.txt" "$OUT/packages-by-size.tsv" <<'PY'
import sys, re
src, dst = sys.argv[1], sys.argv[2]
text = open(src, encoding="utf-8", errors="replace").read()

units = {"B":1, "KiB":1024, "MiB":1024**2, "GiB":1024**3}
rows=[]
for block in re.split(r"\n(?=Name\s*:)", text):
    fields={}
    for line in block.splitlines():
        if " : " in line:
            k,v=line.split(" : ",1)
            fields[k.strip()]=v.strip()
    name=fields.get("Name")
    size=fields.get("Installed Size")
    reason=fields.get("Install Reason","")
    if not name or not size:
        continue
    m=re.match(r"([\d.]+)\s+(\w+)", size)
    if not m:
        continue
    b=float(m.group(1))*units.get(m.group(2),1)
    rows.append((b,name,size,reason))

rows.sort(reverse=True)
with open(dst,"w",encoding="utf-8") as f:
    f.write("bytes\tpackage\tsize\treason\n")
    for b,n,s,r in rows:
        f.write(f"{int(b)}\t{n}\t{s}\t{r}\n")
PY

# ---------------- services ----------------
run_shell system-services-enabled '
systemctl list-unit-files --state=enabled --no-pager
'

run_shell system-services-running '
systemctl --type=service --state=running --no-pager
'

run_shell user-services-enabled '
systemctl --user list-unit-files --state=enabled --no-pager
'

run_shell user-services-running '
systemctl --user --type=service --state=running --no-pager
'

run_shell timers '
systemctl list-timers --all --no-pager
echo
echo "===== USER ====="
systemctl --user list-timers --all --no-pager
'

# ---------------- storage / cache ----------------
run_shell storage '
df -hT
echo
echo "===== HOME TOP ====="
du -xhd1 "$HOME" 2>/dev/null | sort -h | tail -30
echo
echo "===== USER CACHE ====="
du -sh "$HOME/.cache" 2>/dev/null || true
du -sh "$HOME/.cache/yay" 2>/dev/null || true
du -sh "$HOME/.cache/paru" 2>/dev/null || true
du -sh "$HOME/.local/share/Trash" 2>/dev/null || true
echo
echo "===== JOURNAL ====="
journalctl --disk-usage
'

run_shell privileged-storage '
sudo du -sh /var/cache/pacman/pkg 2>/dev/null || true
sudo du -sh /var/lib/systemd/coredump 2>/dev/null || true
sudo du -sh /.snapshots 2>/dev/null || true
'

run_shell btrfs '
sudo btrfs filesystem usage / 2>/dev/null || true
echo
sudo btrfs subvolume list -t / 2>/dev/null || true
echo
command -v snapper >/dev/null && sudo snapper list || true
'

# ---------------- optional ecosystems ----------------
run_shell optional-runtime '
if command -v flatpak >/dev/null; then
  echo "===== FLATPAK ====="
  flatpak list --columns=application,size,installation
fi
if command -v docker >/dev/null; then
  echo
  echo "===== DOCKER ====="
  docker system df
fi
if command -v podman >/dev/null; then
  echo
  echo "===== PODMAN ====="
  podman system df
fi
'

# ---------------- graphics / display ----------------
run_shell graphics '
lspci -nnk | grep -EA4 "VGA|3D|Display"
echo
echo "===== NVIDIA ====="
command -v nvidia-smi >/dev/null && nvidia-smi || true
echo
echo "===== MONITORS ====="
hyprctl monitors all
'

# ---------------- summary ----------------
python3 - "$OUT" <<'PY'
from pathlib import Path
import sys, re

out=Path(sys.argv[1])

def body(name):
    p=out/name
    if not p.exists():
        return ""
    s=p.read_text(errors="replace")
    parts=s.split("\n\n",1)
    return parts[1] if len(parts)==2 else s

orph=[x.strip() for x in body("packages-orphans.txt").splitlines() if x.strip()]
foreign=[x.strip() for x in body("packages-foreign.txt").splitlines() if x.strip()]

dups=body("keybind-duplicates.txt")
m=re.search(r"Combinaciones duplicadas exactas:\s*(\d+)",dups)
dupcount=int(m.group(1)) if m else -1

sizep=out/"packages-by-size.tsv"
tops=[]
if sizep.exists():
    lines=sizep.read_text(errors="replace").splitlines()[1:21]
    for line in lines:
        parts=line.split("\t")
        if len(parts)>=4:
            tops.append((parts[1],parts[2],parts[3]))

summary = []
summary.append("===== RESUMEN DE AUDITORÍA =====")
summary.append(f"Directorio: {out}")
summary.append("")
summary.append(f"Huérfanos actuales: {len(orph)}")
for x in orph:
    summary.append(f"  - {x}")
summary.append("")
summary.append(f"Paquetes foráneos/AUR/locales: {len(foreign)}")
for x in foreign[:40]:
    summary.append(f"  - {x}")
if len(foreign)>40:
    summary.append(f"  ... +{len(foreign)-40}")
summary.append("")
summary.append(f"Keybinds duplicados exactos: {dupcount}")
summary.append("  Ver keybind-duplicates.txt")
summary.append("")
summary.append("Top 20 paquetes por tamaño:")
for n,s,r in tops:
    summary.append(f"  {s:>10}  {n}  [{r}]")
summary.append("")
summary.append("Archivos a revisar para debloat:")
summary.append("  - packages-orphans.txt")
summary.append("  - packages-by-size.tsv")
summary.append("  - system-services-enabled.txt")
summary.append("  - user-services-enabled.txt")
summary.append("  - storage.txt")
summary.append("  - privileged-storage.txt")
summary.append("  - btrfs.txt")
summary.append("")
summary.append("NO se ha eliminado ni deshabilitado nada.")

(out/"SUMMARY.txt").write_text("\n".join(summary)+"\n")
print("\n".join(summary))
PY

echo
echo "Auditoría terminada:"
echo "  $OUT"
echo
echo "Pásame:"
echo "  $OUT/SUMMARY.txt"
echo "  $OUT/keybind-duplicates.txt"
echo "  $OUT/system-services-enabled.txt"
echo "  $OUT/user-services-enabled.txt"
echo "  $OUT/storage.txt"
