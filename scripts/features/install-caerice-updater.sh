#!/usr/bin/env bash
set -euo pipefail
REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO" ]] || { echo "ERROR: ejecuta dentro de CaeRice" >&2; exit 1; }
LIVE="/etc/xdg/quickshell/caelestia"
USERCFG="$HOME/.config/caelestia/hypr-user.lua"
SRC="$REPO/caelestia/modules-owned/modules"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.local/share/caelestia-custom-system/snapshots/updater-center-$STAMP"
STAGE="$BACKUP/stage"
for f in "$LIVE/shell.qml" "$LIVE/components/ScreenState.qml" "$LIVE/modules/drawers/ContentWindow.qml" "$LIVE/modules/drawers/Panels.qml" "$USERCFG"; do [[ -f "$f" ]] || { echo "ERROR: falta $f" >&2; exit 2; }; done
for f in "$SRC/UpdaterController.qml" "$SRC/updater/Wrapper.qml" "$SRC/updater/Content.qml" "$REPO/caelestia/bin/caerice-upstream-audit" "$REPO/caelestia/bin/caerice-updater"; do [[ -f "$f" ]] || { echo "ERROR: falta $f" >&2; exit 3; }; done
python3 "$REPO/caelestia/bin/caerice-upstream-audit" | python3 -m json.tool >/dev/null
mkdir -p "$BACKUP/components" "$BACKUP/modules/drawers" "$BACKUP/user-config" "$STAGE/components" "$STAGE/modules/drawers" "$STAGE/user-config"
sudo cp "$LIVE/shell.qml" "$BACKUP/shell.qml"; sudo cp "$LIVE/components/ScreenState.qml" "$BACKUP/components/ScreenState.qml"; sudo cp "$LIVE/modules/drawers/ContentWindow.qml" "$BACKUP/modules/drawers/ContentWindow.qml"; sudo cp "$LIVE/modules/drawers/Panels.qml" "$BACKUP/modules/drawers/Panels.qml"; cp "$USERCFG" "$BACKUP/user-config/hypr-user.lua"; sudo chown -R "$USER:$(id -gn)" "$BACKUP"
export LIVE USERCFG STAGE
python3 <<'PY'
from pathlib import Path
import os
live=Path(os.environ['LIVE']); user=Path(os.environ['USERCFG']); stage=Path(os.environ['STAGE'])
f={'screen':live/'components/ScreenState.qml','shell':live/'shell.qml','panels':live/'modules/drawers/Panels.qml','content':live/'modules/drawers/ContentWindow.qml','user':user}; t={k:p.read_text(encoding='utf-8') for k,p in f.items()}
def add(k,o,n,m):
    if m in t[k]: return
    if o not in t[k]: raise SystemExit(f'PREFLIGHT ERROR [{k}]: missing {m}')
    t[k]=t[k].replace(o,n,1)
add('screen','    property bool gamingCenter\n    property bool dashboard','    property bool gamingCenter\n    property bool updaterCenter\n    property bool dashboard','property bool updaterCenter')
add('shell','    GamingController {}\n    BatteryMonitor {}','    GamingController {}\n    UpdaterController {}\n    BatteryMonitor {}','UpdaterController {}')
add('panels','import qs.modules.gaming as Gaming\nimport qs.modules.notifications as Notifications','import qs.modules.gaming as Gaming\nimport qs.modules.updater as Updater\nimport qs.modules.notifications as Notifications','import qs.modules.updater as Updater')
add('panels','    readonly property alias gamingCenter: gamingCenter\n    readonly property alias dashboard: dashboard','    readonly property alias gamingCenter: gamingCenter\n    readonly property alias updaterCenter: updaterCenter\n    readonly property alias dashboard: dashboard','readonly property alias updaterCenter: updaterCenter')
if 'id: updaterCenter' not in t['panels']:
    anchor='    Dashboard.Wrapper {'
    if anchor not in t['panels']: raise SystemExit('PREFLIGHT ERROR [panels]: Dashboard.Wrapper missing')
    block='''    Updater.Wrapper {\n        id: updaterCenter\n        screen: root.screen\n        screenState: root.screenState\n        anchors.fill: parent\n    }\n\n'''; t['panels']=t['panels'].replace(anchor,block+anchor,1)
add('content','        screenState.gamingCenter = false;\n        panels.popouts.close();','        screenState.gamingCenter = false;\n        screenState.updaterCenter = false;\n        panels.popouts.close();','screenState.updaterCenter = false;\n        panels.popouts.close();')
add('content','screenState.overview || screenState.clipboard || screenState.hardware || screenState.displayManager || screenState.gamingCenter ? WlrLayer.Overlay','screenState.overview || screenState.clipboard || screenState.hardware || screenState.displayManager || screenState.gamingCenter || screenState.updaterCenter ? WlrLayer.Overlay','screenState.updaterCenter ? WlrLayer.Overlay')
add('content','screenState.overview || screenState.clipboard || screenState.hardware || screenState.displayManager || screenState.gamingCenter || screenState.launcher','screenState.overview || screenState.clipboard || screenState.hardware || screenState.displayManager || screenState.gamingCenter || screenState.updaterCenter || screenState.launcher','screenState.updaterCenter || screenState.launcher')
add('content','mask: screenState.overview || screenState.clipboard || screenState.hardware || screenState.displayManager || screenState.gamingCenter ? null','mask: screenState.overview || screenState.clipboard || screenState.hardware || screenState.displayManager || screenState.gamingCenter || screenState.updaterCenter ? null','screenState.updaterCenter ? null')
add('content','if (s.overview || s.clipboard || s.hardware || s.displayManager || s.gamingCenter)\n                return true;','if (s.overview || s.clipboard || s.hardware || s.displayManager || s.gamingCenter || s.updaterCenter)\n                return true;','s.updaterCenter')
add('content','            root.screenState.gamingCenter = false;\n            panels.popouts.hasCurrent = false;','            root.screenState.gamingCenter = false;\n            root.screenState.updaterCenter = false;\n            panels.popouts.hasCurrent = false;','root.screenState.updaterCenter = false;')
bind='''hl.bind(\n    "SUPER + SHIFT + U",\n    hl.dsp.global("caelestia:updatercenter")\n)'''
if bind not in t['user']:
    anchor='''hl.bind(\n    "SUPER + SHIFT + G",\n    hl.dsp.global("caelestia:gamingcenter")\n)'''
    if anchor not in t['user']: raise SystemExit('PREFLIGHT ERROR [user]: Gaming Center bind missing')
    t['user']=t['user'].replace(anchor,anchor+'\n\n-- CaeRice Updater QML nativo\n'+bind,1)
out={'screen':stage/'components/ScreenState.qml','shell':stage/'shell.qml','panels':stage/'modules/drawers/Panels.qml','content':stage/'modules/drawers/ContentWindow.qml','user':stage/'user-config/hypr-user.lua'}
for k,p in out.items(): p.parent.mkdir(parents=True,exist_ok=True); p.write_text(t[k],encoding='utf-8')
PY
sudo install -m 0644 "$STAGE/shell.qml" "$LIVE/shell.qml"; sudo install -m 0644 "$STAGE/components/ScreenState.qml" "$LIVE/components/ScreenState.qml"; sudo install -m 0644 "$STAGE/modules/drawers/Panels.qml" "$LIVE/modules/drawers/Panels.qml"; sudo install -m 0644 "$STAGE/modules/drawers/ContentWindow.qml" "$LIVE/modules/drawers/ContentWindow.qml"; install -m 0644 "$STAGE/user-config/hypr-user.lua" "$USERCFG"
sudo install -m 0644 "$SRC/UpdaterController.qml" "$LIVE/modules/UpdaterController.qml"; sudo mkdir -p "$LIVE/modules/updater"; sudo install -m 0644 "$SRC/updater/Wrapper.qml" "$LIVE/modules/updater/Wrapper.qml"; sudo install -m 0644 "$SRC/updater/Content.qml" "$LIVE/modules/updater/Content.qml"
mkdir -p "$HOME/.local/bin"; install -m 0755 "$REPO/caelestia/bin/caerice-upstream-audit" "$HOME/.local/bin/caerice-upstream-audit"; install -m 0755 "$REPO/caelestia/bin/caerice-updater" "$HOME/.local/bin/caerice-updater"
hyprctl reload >/dev/null
echo "CaeRice Updater instalado. Backup: $BACKUP"; echo "Abre con Super+Shift+U o: qs -c caelestia ipc call updater open"
