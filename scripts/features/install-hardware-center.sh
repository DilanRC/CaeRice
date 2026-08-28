#!/usr/bin/env bash
set -euo pipefail

REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO" ]]; then
    echo "ERROR: ejecuta este script dentro del clon de CaeRice." >&2
    exit 1
fi

LIVE="/etc/xdg/quickshell/caelestia"
USERCFG="$HOME/.config/caelestia/hypr-user.lua"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.local/share/caelestia-custom-system/snapshots/hardware-center-$STAMP"
STAGE="$BACKUP/stage"
SRC="$REPO/caelestia/modules-owned/modules"
PROBE_SRC="$REPO/caelestia/bin/caerice-hardware-probe"
PROBE_DST="$HOME/.local/bin/caerice-hardware-probe"
POWER_SRC="$REPO/caelestia/bin/caerice-hardware-power"
POWER_DST="$HOME/.local/bin/caerice-hardware-power"
AUTO_SRC="$REPO/caelestia/bin/caerice-power-auto"
AUTO_DST="$HOME/.local/bin/caerice-power-auto"
AUTO_CTL_SRC="$REPO/caelestia/bin/caerice-power-auto-control"
AUTO_CTL_DST="$HOME/.local/bin/caerice-power-auto-control"
KEYBINDS_SRC="$REPO/caelestia/bin/caerice-keybinds"
KEYBINDS_DST="$HOME/.local/bin/caerice-keybinds"
UNIT_SRC="$REPO/config/systemd/user/caerice-power-auto.service"
UNIT_DST="$HOME/.config/systemd/user/caerice-power-auto.service"
VALIDATOR="$REPO/scripts/features/validate-hardware-center.py"

for f in \
    "$LIVE/shell.qml" \
    "$LIVE/components/ScreenState.qml" \
    "$LIVE/modules/drawers/ContentWindow.qml" \
    "$LIVE/modules/drawers/Panels.qml" \
    "$USERCFG"; do
    [[ -f "$f" ]] || { echo "ERROR: falta $f" >&2; exit 2; }
done

for f in \
    "$SRC/HardwareController.qml" \
    "$PROBE_SRC" \
    "$POWER_SRC" \
    "$AUTO_SRC" \
    "$AUTO_CTL_SRC" \
    "$KEYBINDS_SRC" \
    "$UNIT_SRC" \
    "$VALIDATOR"; do
    [[ -f "$f" ]] || { echo "ERROR: falta $f" >&2; exit 3; }
done

for f in \
    Wrapper.qml \
    Content.qml \
    MetricCard.qml \
    HistoryGraph.qml \
    OverviewPage.qml \
    PerformancePage.qml \
    ProcessesPage.qml \
    SensorsPage.qml \
    IOPage.qml \
    PowerPage.qml \
    PowerAutomationPage.qml \
    EnergyPage.qml \
    KeybindsPage.qml; do
    [[ -f "$SRC/hardware/$f" ]] || { echo "ERROR: falta hardware/$f" >&2; exit 3; }
done

echo "==> Hardware Center preflight"
python3 "$PROBE_SRC" | python3 -m json.tool >/dev/null
sleep 0.2
python3 "$PROBE_SRC" | python3 -m json.tool >/dev/null
python3 "$POWER_SRC" | python3 -m json.tool >/dev/null
python3 "$AUTO_CTL_SRC" status | python3 -m json.tool >/dev/null
echo "telemetry: OK"

mkdir -p \
    "$BACKUP/components" \
    "$BACKUP/modules/drawers" \
    "$BACKUP/user-config" \
    "$STAGE/components" \
    "$STAGE/modules/drawers" \
    "$STAGE/user-config"

sudo cp "$LIVE/shell.qml" "$BACKUP/shell.qml"
sudo cp "$LIVE/components/ScreenState.qml" "$BACKUP/components/ScreenState.qml"
sudo cp "$LIVE/modules/drawers/ContentWindow.qml" "$BACKUP/modules/drawers/ContentWindow.qml"
sudo cp "$LIVE/modules/drawers/Panels.qml" "$BACKUP/modules/drawers/Panels.qml"
cp "$USERCFG" "$BACKUP/user-config/hypr-user.lua"
sudo chown -R "$USER:$(id -gn)" "$BACKUP"

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


def replace_first(key: str, candidates: list[tuple[str, str]], marker: str) -> None:
    if marker in texts[key]:
        return
    for old, new in candidates:
        if old in texts[key]:
            texts[key] = texts[key].replace(old, new, 1)
            return
    raise SystemExit(f"PREFLIGHT ERROR [{key}]: no encontré contexto para {marker}")


replace_first(
    "screen",
    [
        (
            "    property bool clipboard\n    property bool dashboard",
            "    property bool clipboard\n    property bool hardware\n    property bool dashboard",
        ),
        (
            "    property bool overview\n    property bool dashboard",
            "    property bool overview\n    property bool hardware\n    property bool dashboard",
        ),
    ],
    "property bool hardware",
)

replace_first(
    "shell",
    [
        (
            "    ClipboardController {}\n    BatteryMonitor {}",
            "    ClipboardController {}\n    HardwareController {}\n    BatteryMonitor {}",
        ),
        (
            "    OverviewController {}\n    BatteryMonitor {}",
            "    OverviewController {}\n    HardwareController {}\n    BatteryMonitor {}",
        ),
    ],
    "HardwareController {}",
)

replace_first(
    "panels",
    [
        (
            "import qs.modules.clipboard as Clipboard\nimport qs.modules.notifications as Notifications",
            "import qs.modules.clipboard as Clipboard\nimport qs.modules.hardware as Hardware\nimport qs.modules.notifications as Notifications",
        ),
        (
            "import qs.modules.overview as Overview\nimport qs.modules.notifications as Notifications",
            "import qs.modules.overview as Overview\nimport qs.modules.hardware as Hardware\nimport qs.modules.notifications as Notifications",
        ),
    ],
    "import qs.modules.hardware as Hardware",
)

replace_first(
    "panels",
    [
        (
            "    readonly property alias clipboard: clipboard\n    readonly property alias dashboard: dashboard",
            "    readonly property alias clipboard: clipboard\n    readonly property alias hardware: hardware\n    readonly property alias dashboard: dashboard",
        ),
        (
            "    readonly property alias overview: overview\n    readonly property alias dashboard: dashboard",
            "    readonly property alias overview: overview\n    readonly property alias hardware: hardware\n    readonly property alias dashboard: dashboard",
        ),
    ],
    "readonly property alias hardware: hardware",
)

hardware_wrapper = '''    Hardware.Wrapper {
        id: hardware

        screen: root.screen
        screenState: root.screenState

        anchors.fill: parent
    }

'''
if "id: hardware" not in texts["panels"]:
    if "    Dashboard.Wrapper {" not in texts["panels"]:
        raise SystemExit("PREFLIGHT ERROR [panels]: falta Dashboard.Wrapper")
    texts["panels"] = texts["panels"].replace(
        "    Dashboard.Wrapper {",
        hardware_wrapper + "    Dashboard.Wrapper {",
        1,
    )

# Hardware shares ContentWindow with Overview, Clipboard and Display Manager.
# Ensure its membership in each native interaction span without requiring it
# to be adjacent to Clipboard or to panels.popouts; later retained overlays
# are preserved verbatim.
try:
    ensure_statement(
        texts,
        "content",
        "    onHasFullscreenChanged: {",
        "\n        panels.popouts.close();",
        "        screenState.hardware = false;",
    )
    ensure_or_member(
        texts,
        "content",
        "WlrLayershell.layer: screenState.overview",
        " ? WlrLayer.Overlay",
        "screenState.hardware",
    )
    ensure_or_member(
        texts,
        "content",
        "WlrLayershell.keyboardFocus: screenState.overview",
        " || screenState.launcher",
        "screenState.hardware",
    )
    ensure_or_member(
        texts,
        "content",
        "mask: screenState.overview",
        " ? null",
        "screenState.hardware",
    )
    ensure_or_member(
        texts,
        "content",
        "if (s.overview",
        ")\n                return true;",
        "s.hardware",
    )
    ensure_statement(
        texts,
        "content",
        "        onCleared: {",
        "\n            panels.popouts.hasCurrent = false;",
        "            root.screenState.hardware = false;",
    )
except WiringError as exc:
    raise SystemExit(str(exc))

hardware_bind = '''hl.bind(
    "SUPER + H",
    hl.dsp.global("caelestia:hardware")
)'''
if hardware_bind not in texts["user"]:
    anchors = [
        '''hl.bind(
    "SUPER + V",
    hl.dsp.global("caelestia:clipboard")
)''',
        '''hl.bind(
    "SUPER + I",
    hl.dsp.global("caelestia:nexus")
)''',
    ]
    for anchor in anchors:
        if anchor in texts["user"]:
            texts["user"] = texts["user"].replace(
                anchor,
                anchor + "\n\n-- Hardware Center QML nativo\n" + hardware_bind,
                1,
            )
            break
    else:
        raise SystemExit("PREFLIGHT ERROR [user]: no encontré ancla para SUPER+H")

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

print("Native Hardware Center integration staged successfully")
PY

sudo install -m 0644 "$STAGE/shell.qml" "$LIVE/shell.qml"
sudo install -m 0644 "$STAGE/components/ScreenState.qml" "$LIVE/components/ScreenState.qml"
sudo install -m 0644 "$STAGE/modules/drawers/Panels.qml" "$LIVE/modules/drawers/Panels.qml"
sudo install -m 0644 "$STAGE/modules/drawers/ContentWindow.qml" "$LIVE/modules/drawers/ContentWindow.qml"
install -m 0644 "$STAGE/user-config/hypr-user.lua" "$USERCFG"

sudo install -m 0644 "$SRC/HardwareController.qml" "$LIVE/modules/HardwareController.qml"
sudo mkdir -p "$LIVE/modules/hardware"
for qml in "$SRC/hardware/"*.qml; do
    sudo install -m 0644 "$qml" "$LIVE/modules/hardware/$(basename "$qml")"
done

mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user"
install -m 0755 "$PROBE_SRC" "$PROBE_DST"
install -m 0755 "$POWER_SRC" "$POWER_DST"
install -m 0755 "$AUTO_SRC" "$AUTO_DST"
install -m 0755 "$AUTO_CTL_SRC" "$AUTO_CTL_DST"
install -m 0755 "$KEYBINDS_SRC" "$KEYBINDS_DST"
install -m 0644 "$UNIT_SRC" "$UNIT_DST"
systemctl --user daemon-reload

# Preserve the user's opt-in state. Installation never enables Auto by itself.
if systemctl --user is-enabled --quiet caerice-power-auto.service 2>/dev/null; then
    systemctl --user try-restart caerice-power-auto.service >/dev/null 2>&1 || true
fi

hyprctl reload >/dev/null

python3 "$VALIDATOR"

echo
echo "Hardware Center instalado."
echo "Backup: $BACKUP"
echo "Probe: $PROBE_DST"
echo "Power: $POWER_DST"
echo "Pages: Overview · Performance · Processes · Sensors · I/O · Power · Auto · Energy · Keybinds"
echo "Auto service: instalado, no se habilita automáticamente."
echo
echo "Reinicia Caelestia:"
echo "  pkill -TERM -x qs"
echo "  sleep 1"
echo "  caelestia shell -d"
echo
echo "Después prueba Super+H o:"
echo "  qs -c caelestia ipc call hardware open"
