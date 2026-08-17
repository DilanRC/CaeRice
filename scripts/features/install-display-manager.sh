#!/usr/bin/env bash
set -euo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$REPO" ]] || { echo "ERROR: ejecuta dentro de CaeRice" >&2; exit 1; }

LIVE="/etc/xdg/quickshell/caelestia"
USERCFG="$HOME/.config/caelestia/hypr-user.lua"
SRC="$REPO/caelestia/modules-owned/modules"
PROBE_SRC="$REPO/caelestia/bin/caerice-display-probe"
PLAN_SRC="$REPO/caelestia/bin/caerice-display-plan"
TX_SRC="$REPO/caelestia/bin/caerice-display-transaction"
VALIDATOR="$REPO/scripts/features/validate-display-manager.py"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.local/share/caelestia-custom-system/snapshots/display-manager-$STAMP"
STAGE="$BACKUP/stage"

for f in "$LIVE/shell.qml" "$LIVE/components/ScreenState.qml" "$LIVE/modules/drawers/ContentWindow.qml" "$LIVE/modules/drawers/Panels.qml" "$USERCFG"; do
    [[ -f "$f" ]] || { echo "ERROR: falta $f" >&2; exit 2; }
done
for f in \
    "$SRC/DisplayController.qml" \
    "$SRC/display/Wrapper.qml" \
    "$SRC/display/Content.qml" \
    "$SRC/display/Editor.qml" \
    "$SRC/display/PreviewControls.qml" \
    "$PROBE_SRC" "$PLAN_SRC" "$TX_SRC" "$VALIDATOR"; do
    [[ -f "$f" ]] || { echo "ERROR: falta $f" >&2; exit 3; }
done

python3 "$VALIDATOR"

mkdir -p "$BACKUP/components" "$BACKUP/modules/drawers" "$BACKUP/user-config" \
    "$STAGE/components" "$STAGE/modules/drawers" "$STAGE/user-config"
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

live = Path(os.environ["LIVE"])
usercfg = Path(os.environ["USERCFG"])
stage = Path(os.environ["STAGE"])
targets = {
    "screen": live / "components/ScreenState.qml",
    "shell": live / "shell.qml",
    "panels": live / "modules/drawers/Panels.qml",
    "content": live / "modules/drawers/ContentWindow.qml",
    "user": usercfg,
}
texts = {k: p.read_text(encoding="utf-8") for k, p in targets.items()}


def replace_once(key, old, new, marker):
    if marker in texts[key]:
        return
    if old not in texts[key]:
        raise SystemExit(f"PREFLIGHT ERROR [{key}]: no encontré contexto para {marker}")
    texts[key] = texts[key].replace(old, new, 1)

replace_once(
    "screen",
    "    property bool hardware\n    property bool dashboard",
    "    property bool hardware\n    property bool displayManager\n    property bool dashboard",
    "property bool displayManager",
)
replace_once(
    "shell",
    "    HardwareController {}\n    BatteryMonitor {}",
    "    HardwareController {}\n    DisplayController {}\n    BatteryMonitor {}",
    "DisplayController {}",
)
replace_once(
    "panels",
    "import qs.modules.hardware as Hardware\nimport qs.modules.notifications as Notifications",
    "import qs.modules.hardware as Hardware\nimport qs.modules.display as Display\nimport qs.modules.notifications as Notifications",
    "import qs.modules.display as Display",
)
replace_once(
    "panels",
    "    readonly property alias hardware: hardware\n    readonly property alias dashboard: dashboard",
    "    readonly property alias hardware: hardware\n    readonly property alias displayManager: displayManager\n    readonly property alias dashboard: dashboard",
    "readonly property alias displayManager: displayManager",
)

wrapper = '''    Display.Wrapper {
        id: displayManager

        screen: root.screen
        screenState: root.screenState

        anchors.fill: parent
    }

'''
if "id: displayManager" not in texts["panels"]:
    anchor = "    Dashboard.Wrapper {"
    if anchor not in texts["panels"]:
        raise SystemExit("PREFLIGHT ERROR [panels]: falta Dashboard.Wrapper")
    texts["panels"] = texts["panels"].replace(anchor, wrapper + anchor, 1)

replace_once(
    "content",
    "        screenState.hardware = false;\n        panels.popouts.close();",
    "        screenState.hardware = false;\n        screenState.displayManager = false;\n        panels.popouts.close();",
    "screenState.displayManager = false;\n        panels.popouts.close();",
)
replace_once(
    "content",
    "screenState.overview || screenState.clipboard || screenState.hardware ? WlrLayer.Overlay",
    "screenState.overview || screenState.clipboard || screenState.hardware || screenState.displayManager ? WlrLayer.Overlay",
    "screenState.displayManager ? WlrLayer.Overlay",
)
replace_once(
    "content",
    "screenState.overview || screenState.clipboard || screenState.hardware || screenState.launcher",
    "screenState.overview || screenState.clipboard || screenState.hardware || screenState.displayManager || screenState.launcher",
    "screenState.displayManager || screenState.launcher",
)
replace_once(
    "content",
    "mask: screenState.overview || screenState.clipboard || screenState.hardware ? null",
    "mask: screenState.overview || screenState.clipboard || screenState.hardware || screenState.displayManager ? null",
    "screenState.displayManager ? null",
)
replace_once(
    "content",
    "if (s.overview || s.clipboard || s.hardware)\n                return true;",
    "if (s.overview || s.clipboard || s.hardware || s.displayManager)\n                return true;",
    "s.displayManager",
)
replace_once(
    "content",
    "            root.screenState.hardware = false;\n            panels.popouts.hasCurrent = false;",
    "            root.screenState.hardware = false;\n            root.screenState.displayManager = false;\n            panels.popouts.hasCurrent = false;",
    "root.screenState.displayManager = false;",
)

bind = '''hl.bind(
    "SUPER + SHIFT + O",
    hl.dsp.global("caelestia:displaymanager")
)'''
if bind not in texts["user"]:
    anchor = '''hl.bind(
    "SUPER + H",
    hl.dsp.global("caelestia:hardware")
)'''
    if anchor not in texts["user"]:
        raise SystemExit("PREFLIGHT ERROR [user]: no encontré bind SUPER+H")
    texts["user"] = texts["user"].replace(anchor, anchor + "\n\n-- Display Manager QML nativo\n" + bind, 1)

out = {
    "screen": stage / "components/ScreenState.qml",
    "shell": stage / "shell.qml",
    "panels": stage / "modules/drawers/Panels.qml",
    "content": stage / "modules/drawers/ContentWindow.qml",
    "user": stage / "user-config/hypr-user.lua",
}
for key, path in out.items():
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(texts[key], encoding="utf-8")
print("Native Display Manager integration staged successfully")
PY

sudo install -m 0644 "$STAGE/shell.qml" "$LIVE/shell.qml"
sudo install -m 0644 "$STAGE/components/ScreenState.qml" "$LIVE/components/ScreenState.qml"
sudo install -m 0644 "$STAGE/modules/drawers/Panels.qml" "$LIVE/modules/drawers/Panels.qml"
sudo install -m 0644 "$STAGE/modules/drawers/ContentWindow.qml" "$LIVE/modules/drawers/ContentWindow.qml"
install -m 0644 "$STAGE/user-config/hypr-user.lua" "$USERCFG"

sudo install -m 0644 "$SRC/DisplayController.qml" "$LIVE/modules/DisplayController.qml"
sudo mkdir -p "$LIVE/modules/display"
for qml in "$SRC/display/"*.qml; do
    sudo install -m 0644 "$qml" "$LIVE/modules/display/$(basename "$qml")"
done
mkdir -p "$HOME/.local/bin"
install -m 0755 "$PROBE_SRC" "$HOME/.local/bin/caerice-display-probe"
install -m 0755 "$PLAN_SRC" "$HOME/.local/bin/caerice-display-plan"
install -m 0755 "$TX_SRC" "$HOME/.local/bin/caerice-display-transaction"

hyprctl reload >/dev/null

echo
echo "Display Manager instalado."
echo "Backup: $BACKUP"
echo "Preview: 15 s con auto-revert; Keep conserva la sesión pero aún no persiste al reiniciar."
echo "Reinicia Caelestia y prueba Super+Shift+O."
echo "IPC: qs -c caelestia ipc call display open"
