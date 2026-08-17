#!/usr/bin/env bash
set -euo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO" ]] || { echo "ERROR: ejecuta dentro de CaeRice" >&2; exit 1; }
LIVE="/etc/xdg/quickshell/caelestia"
USERCFG="$HOME/.config/caelestia/hypr-user.lua"
SRC="$REPO/caelestia/modules-owned/modules"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.local/share/caelestia-custom-system/snapshots/gaming-center-$STAMP"
STAGE="$BACKUP/stage"

for f in "$LIVE/shell.qml" "$LIVE/components/ScreenState.qml" "$LIVE/modules/drawers/ContentWindow.qml" "$LIVE/modules/drawers/Panels.qml" "$USERCFG"; do
  [[ -f "$f" ]] || { echo "ERROR: falta $f" >&2; exit 2; }
done
[[ -f "$SRC/GamingController.qml" ]] || { echo "ERROR: falta GamingController.qml" >&2; exit 3; }
for qml in "$SRC/gaming/"*.qml; do [[ -f "$qml" ]] || { echo "ERROR: falta $qml" >&2; exit 3; }; done
for f in "$REPO/caelestia/bin/caerice-gaming-probe" "$REPO/caelestia/bin/caerice-gaming-profile" "$REPO/scripts/features/validate-gaming-center.py"; do
  [[ -f "$f" ]] || { echo "ERROR: falta $f" >&2; exit 3; }
done

python3 "$REPO/scripts/features/validate-gaming-center.py"
python3 "$REPO/caelestia/bin/caerice-gaming-probe" | python3 -m json.tool >/dev/null
python3 "$REPO/caelestia/bin/caerice-gaming-profile" list | python3 -m json.tool >/dev/null

mkdir -p "$BACKUP/components" "$BACKUP/modules/drawers" "$BACKUP/user-config" "$STAGE/components" "$STAGE/modules/drawers" "$STAGE/user-config"
sudo cp "$LIVE/shell.qml" "$BACKUP/shell.qml"
sudo cp "$LIVE/components/ScreenState.qml" "$BACKUP/components/ScreenState.qml"
sudo cp "$LIVE/modules/drawers/ContentWindow.qml" "$BACKUP/modules/drawers/ContentWindow.qml"
sudo cp "$LIVE/modules/drawers/Panels.qml" "$BACKUP/modules/drawers/Panels.qml"
cp "$USERCFG" "$BACKUP/user-config/hypr-user.lua"
sudo chown -R "$USER:$(id -gn)" "$BACKUP"

export LIVE USERCFG STAGE
python3 <<'PY'
from pathlib import Path
import os
live=Path(os.environ['LIVE']); user=Path(os.environ['USERCFG']); stage=Path(os.environ['STAGE'])
files={'screen':live/'components/ScreenState.qml','shell':live/'shell.qml','panels':live/'modules/drawers/Panels.qml','content':live/'modules/drawers/ContentWindow.qml','user':user}
t={k:p.read_text(encoding='utf-8') for k,p in files.items()}

def add(key, old, new, marker):
    if marker in t[key]: return
    if old not in t[key]: raise SystemExit(f'PREFLIGHT ERROR [{key}]: missing context for {marker}')
    t[key]=t[key].replace(old,new,1)

add('screen','    property bool displayManager\n    property bool dashboard','    property bool displayManager\n    property bool gamingCenter\n    property bool dashboard','property bool gamingCenter')
add('shell','    DisplayController {}\n    BatteryMonitor {}','    DisplayController {}\n    GamingController {}\n    BatteryMonitor {}','GamingController {}')
add('panels','import qs.modules.display as Display\nimport qs.modules.notifications as Notifications','import qs.modules.display as Display\nimport qs.modules.gaming as Gaming\nimport qs.modules.notifications as Notifications','import qs.modules.gaming as Gaming')
add('panels','    readonly property alias displayManager: displayManager\n    readonly property alias dashboard: dashboard','    readonly property alias displayManager: displayManager\n    readonly property alias gamingCenter: gamingCenter\n    readonly property alias dashboard: dashboard','readonly property alias gamingCenter: gamingCenter')
if 'id: gamingCenter' not in t['panels']:
    anchor='    Dashboard.Wrapper {'
    if anchor not in t['panels']: raise SystemExit('PREFLIGHT ERROR [panels]: Dashboard.Wrapper missing')
    block='''    Gaming.Wrapper {\n        id: gamingCenter\n        screen: root.screen\n        screenState: root.screenState\n        anchors.fill: parent\n    }\n\n'''
    t['panels']=t['panels'].replace(anchor,block+anchor,1)
add('content','        screenState.displayManager = false;\n        panels.popouts.close();','        screenState.displayManager = false;\n        screenState.gamingCenter = false;\n        panels.popouts.close();','screenState.gamingCenter = false;\n        panels.popouts.close();')
add('content','screenState.overview || screenState.clipboard || screenState.hardware || screenState.displayManager ? WlrLayer.Overlay','screenState.overview || screenState.clipboard || screenState.hardware || screenState.displayManager || screenState.gamingCenter ? WlrLayer.Overlay','screenState.gamingCenter ? WlrLayer.Overlay')
add('content','screenState.overview || screenState.clipboard || screenState.hardware || screenState.displayManager || screenState.launcher','screenState.overview || screenState.clipboard || screenState.hardware || screenState.displayManager || screenState.gamingCenter || screenState.launcher','screenState.gamingCenter || screenState.launcher')
add('content','mask: screenState.overview || screenState.clipboard || screenState.hardware || screenState.displayManager ? null','mask: screenState.overview || screenState.clipboard || screenState.hardware || screenState.displayManager || screenState.gamingCenter ? null','screenState.gamingCenter ? null')
add('content','if (s.overview || s.clipboard || s.hardware || s.displayManager)\n                return true;','if (s.overview || s.clipboard || s.hardware || s.displayManager || s.gamingCenter)\n                return true;','s.gamingCenter')
add('content','            root.screenState.displayManager = false;\n            panels.popouts.hasCurrent = false;','            root.screenState.displayManager = false;\n            root.screenState.gamingCenter = false;\n            panels.popouts.hasCurrent = false;','root.screenState.gamingCenter = false;')
bind='''hl.bind(\n    "SUPER + SHIFT + G",\n    hl.dsp.global("caelestia:gamingcenter")\n)'''
if bind not in t['user']:
    anchor='''hl.bind(\n    "SUPER + SHIFT + O",\n    hl.dsp.global("caelestia:displaymanager")\n)'''
    if anchor not in t['user']: raise SystemExit('PREFLIGHT ERROR [user]: Display Manager bind missing')
    t['user']=t['user'].replace(anchor,anchor+'\n\n-- Gaming Center QML nativo\n'+bind,1)
out={'screen':stage/'components/ScreenState.qml','shell':stage/'shell.qml','panels':stage/'modules/drawers/Panels.qml','content':stage/'modules/drawers/ContentWindow.qml','user':stage/'user-config/hypr-user.lua'}
for k,p in out.items(): p.parent.mkdir(parents=True,exist_ok=True); p.write_text(t[k],encoding='utf-8')
PY

sudo install -m 0644 "$STAGE/shell.qml" "$LIVE/shell.qml"
sudo install -m 0644 "$STAGE/components/ScreenState.qml" "$LIVE/components/ScreenState.qml"
sudo install -m 0644 "$STAGE/modules/drawers/Panels.qml" "$LIVE/modules/drawers/Panels.qml"
sudo install -m 0644 "$STAGE/modules/drawers/ContentWindow.qml" "$LIVE/modules/drawers/ContentWindow.qml"
install -m 0644 "$STAGE/user-config/hypr-user.lua" "$USERCFG"
sudo install -m 0644 "$SRC/GamingController.qml" "$LIVE/modules/GamingController.qml"
sudo mkdir -p "$LIVE/modules/gaming"
for qml in "$SRC/gaming/"*.qml; do sudo install -m 0644 "$qml" "$LIVE/modules/gaming/$(basename "$qml")"; done
mkdir -p "$HOME/.local/bin"
install -m 0755 "$REPO/caelestia/bin/caerice-gaming-probe" "$HOME/.local/bin/caerice-gaming-probe"
install -m 0755 "$REPO/caelestia/bin/caerice-gaming-profile" "$HOME/.local/bin/caerice-gaming-profile"
hyprctl reload >/dev/null

echo "Gaming Center instalado. Backup: $BACKUP"
echo "Per-game profiles: Steam inventory + Gamescope/GameMode/MangoHud + process-local GPU selection."
echo "Abre con Super+Shift+G o: qs -c caelestia ipc call gaming open"
