#!/usr/bin/env bash
set -euo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO" ]]; then
    echo "ERROR: ejecuta este script dentro del clon de Cortetsu." >&2
    exit 1
fi

LIVE="/etc/xdg/quickshell/caelestia"
USERCFG="$HOME/.config/caelestia/hypr-user.lua"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.local/share/cortetsu/upstream/snapshots/clipboard-qml-$STAMP"
STAGE="$BACKUP/stage"
SRC="$REPO/caelestia/modules-owned/modules"

for f in \
    "$LIVE/shell.qml" \
    "$LIVE/components/ScreenState.qml" \
    "$LIVE/modules/drawers/ContentWindow.qml" \
    "$LIVE/modules/drawers/Panels.qml" \
    "$USERCFG"; do
    [[ -f "$f" ]] || { echo "ERROR: falta $f" >&2; exit 2; }
done

for f in \
    "$SRC/ClipboardController.qml" \
    "$SRC/clipboard/Wrapper.qml" \
    "$SRC/clipboard/Content.qml" \
    "$SRC/clipboard/ClipboardItem.qml"; do
    [[ -f "$f" ]] || { echo "ERROR: falta $f en el repo" >&2; exit 3; }
done

python3 "$REPO/scripts/features/validate-clipboard-qml.py"

mkdir -p "$BACKUP/components" "$BACKUP/modules/drawers" "$BACKUP/user-config"
sudo cp "$LIVE/shell.qml" "$BACKUP/shell.qml"
sudo cp "$LIVE/components/ScreenState.qml" "$BACKUP/components/ScreenState.qml"
sudo cp "$LIVE/modules/drawers/ContentWindow.qml" "$BACKUP/modules/drawers/ContentWindow.qml"
sudo cp "$LIVE/modules/drawers/Panels.qml" "$BACKUP/modules/drawers/Panels.qml"
cp "$USERCFG" "$BACKUP/user-config/hypr-user.lua"
sudo chown -R "$USER:$(id -gn)" "$BACKUP"
mkdir -p "$STAGE/components" "$STAGE/modules/drawers" "$STAGE/user-config"

export REPO LIVE USERCFG STAGE
python3 <<'PY'
from pathlib import Path
import os
import sys

repo = Path(os.environ["REPO"])
live = Path(os.environ["LIVE"])
usercfg = Path(os.environ["USERCFG"])
stage = Path(os.environ["STAGE"])
sys.path.insert(0, str(repo / "scripts/features"))

from wire_sad_shell import WiringError, ensure_or_member, ensure_statement

targets = {
    "screen": live / "components/ScreenState.qml",
    "shell": live / "shell.qml",
    "panels": live / "modules/drawers/Panels.qml",
    "content": live / "modules/drawers/ContentWindow.qml",
    "user": usercfg,
}
texts = {k: p.read_text(encoding="utf-8") for k, p in targets.items()}


def plan(key, old, new, marker):
    text = texts[key]
    if marker in text:
        return
    if old not in text:
        raise SystemExit(f"PREFLIGHT ERROR [{key}]: no encontré el contexto esperado para {marker}")
    texts[key] = text.replace(old, new, 1)


plan(
    "screen",
    "    property bool overview\n    property bool dashboard",
    "    property bool overview\n    property bool clipboard\n    property bool dashboard",
    "property bool clipboard",
)

plan(
    "shell",
    "    OverviewController {}\n    BatteryMonitor {}",
    "    OverviewController {}\n    ClipboardController {}\n    BatteryMonitor {}",
    "ClipboardController {}",
)

plan(
    "panels",
    "import qs.modules.overview as Overview\nimport qs.modules.notifications as Notifications",
    "import qs.modules.overview as Overview\nimport qs.modules.clipboard as Clipboard\nimport qs.modules.notifications as Notifications",
    "import qs.modules.clipboard as Clipboard",
)
plan(
    "panels",
    "    readonly property alias overview: overview\n    readonly property alias dashboard: dashboard",
    "    readonly property alias overview: overview\n    readonly property alias clipboard: clipboard\n    readonly property alias dashboard: dashboard",
    "readonly property alias clipboard: clipboard",
)
plan(
    "panels",
    "    Overview.Wrapper {\n        id: overview\n\n        screen: root.screen\n        screenState: root.screenState\n\n        anchors.fill: parent\n    }\n\n    Dashboard.Wrapper {",
    "    Overview.Wrapper {\n        id: overview\n\n        screen: root.screen\n        screenState: root.screenState\n\n        anchors.fill: parent\n    }\n\n    Clipboard.Wrapper {\n        id: clipboard\n\n        screen: root.screen\n        screenState: root.screenState\n\n        anchors.fill: parent\n    }\n\n    Dashboard.Wrapper {",
    "id: clipboard",
)

# ContentWindow is a shared integration surface. Clipboard may be followed by
# Hardware/Display members, so never require adjacency to panels.popouts or
# launcher. Ensure Clipboard is a member of each native interaction span while
# preserving every retained overlay already present.
try:
    ensure_statement(
        texts,
        "content",
        "    onHasFullscreenChanged: {",
        "\n        panels.popouts.close();",
        "        screenState.clipboard = false;",
    )
    ensure_or_member(
        texts,
        "content",
        "WlrLayershell.layer: screenState.overview",
        " ? WlrLayer.Overlay",
        "screenState.clipboard",
    )
    ensure_or_member(
        texts,
        "content",
        "WlrLayershell.keyboardFocus: screenState.overview",
        " || screenState.launcher",
        "screenState.clipboard",
    )
    ensure_or_member(
        texts,
        "content",
        "mask: screenState.overview",
        " ? null",
        "screenState.clipboard",
    )
    ensure_or_member(
        texts,
        "content",
        "if (s.overview",
        ")\n                return true;",
        "s.clipboard",
    )
    ensure_statement(
        texts,
        "content",
        "        onCleared: {",
        "\n            panels.popouts.hasCurrent = false;",
        "            root.screenState.clipboard = false;",
    )
except WiringError as exc:
    raise SystemExit(str(exc))

plan(
    "content",
    "        opacity: root.screenState.overview ? 0.58 : ((root.screenState.session && Config.session.enabled) || panels.popouts.detachedMode !== \"\" ? 0.5 : 0)",
    "        opacity: root.screenState.overview ? 0.58 : (root.screenState.clipboard ? 0.48 : ((root.screenState.session && Config.session.enabled) || panels.popouts.detachedMode !== \"\" ? 0.5 : 0))",
    "root.screenState.clipboard ? 0.48",
)

clipboard_bind = '''hl.bind(
    "SUPER + V",
    hl.dsp.global("caelestia:clipboard")
)'''
if clipboard_bind not in texts["user"]:
    anchor = '''hl.bind(
    "SUPER + I",
    hl.dsp.global("caelestia:nexus")
)'''
    if anchor not in texts["user"]:
        raise SystemExit("PREFLIGHT ERROR [user]: no encontré el bind de SUPER+I")
    texts["user"] = texts["user"].replace(
        anchor,
        anchor + '\n\n-- Clipboard QML nativo\n' + clipboard_bind,
        1,
    )

# Todo se genera primero en un staging propiedad del usuario. No intentamos
# escribir directamente en /etc desde Python.
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

print("Native Clipboard integration staged successfully")
PY

# Solo después de que TODO el preflight y staging terminó correctamente,
# instalamos los archivos root-owned de forma controlada.
sudo install -m 0644 "$STAGE/shell.qml" "$LIVE/shell.qml"
sudo install -m 0644 "$STAGE/components/ScreenState.qml" "$LIVE/components/ScreenState.qml"
sudo install -m 0644 "$STAGE/modules/drawers/Panels.qml" "$LIVE/modules/drawers/Panels.qml"
sudo install -m 0644 "$STAGE/modules/drawers/ContentWindow.qml" "$LIVE/modules/drawers/ContentWindow.qml"
install -m 0644 "$STAGE/user-config/hypr-user.lua" "$USERCFG"

sudo install -m 0644 "$SRC/ClipboardController.qml" "$LIVE/modules/ClipboardController.qml"
sudo mkdir -p "$LIVE/modules/clipboard"
sudo install -m 0644 "$SRC/clipboard/Wrapper.qml" "$LIVE/modules/clipboard/Wrapper.qml"
sudo install -m 0644 "$SRC/clipboard/Content.qml" "$LIVE/modules/clipboard/Content.qml"
sudo install -m 0644 "$SRC/clipboard/ClipboardItem.qml" "$LIVE/modules/clipboard/ClipboardItem.qml"

hyprctl reload >/dev/null

echo
echo "Clipboard QML instalado en el árbol live."
echo "Backup: $BACKUP"
echo
echo "IMPORTANTE: Caelestia tiene settings.watchFiles=false, así que reinicia el shell antes de probar Super+V."
echo "No desinstales clipse: clipse -listen sigue siendo el backend de historial."
