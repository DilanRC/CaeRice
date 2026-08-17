#!/usr/bin/env python3
from __future__ import annotations

import re
import shutil
import subprocess
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
LIVE = Path("/etc/xdg/quickshell/caelestia")
CLIP_REPO = REPO / "caelestia/modules-owned/modules/clipboard/Content.qml"
CLIP_LIVE = LIVE / "modules/clipboard/Content.qml"
APP_LIVE = LIVE / "modules/launcher/AppList.qml"
APP_PATCH = REPO / "caelestia/patches/modules__launcher__AppList.qml.patch"
UPSTREAM_TAG = "v2.3.0"


def run(*args: str, check: bool = True, capture: bool = False):
    return subprocess.run(args, text=True, capture_output=capture, check=check)


def install_root(src: Path, dst: Path) -> None:
    run("sudo", "install", "-m", "0644", str(src), str(dst))


def fix_clipboard_center() -> bool:
    text = CLIP_REPO.read_text(encoding="utf-8")
    old = '''        x: Math.max(
            32,
            Math.round(
                (parent.width - width) / 2 -
                Math.min(105, parent.width * 0.05)
            )
        )
'''
    new = '''        // True monitor center. Do not compensate for the Caelestia side bar:
        // ContentWindow already spans the monitor and the previous -105px bias
        // is exactly what pushed Clipboard to the left.
        x: Math.round((parent.width - width) / 2)
'''
    changed = False
    if old in text:
        text = text.replace(old, new, 1)
        CLIP_REPO.write_text(text, encoding="utf-8")
        changed = True
        print("Clipboard: sesgo horizontal eliminado; panel centrado en el monitor")
    elif "x: Math.round((parent.width - width) / 2)" in text:
        print("Clipboard: centrado ya aplicado")
    else:
        raise SystemExit("ERROR: no reconozco el bloque x de Clipboard Content.qml")

    install_root(CLIP_REPO, CLIP_LIVE)
    return changed


def patch_launcher_text(text: str) -> tuple[str, bool]:
    changed = False

    old_click = '''            /*
             * StateLayer conserva el click izquierdo nativo.
             * Este MouseArea acepta SOLO el derecho, para pin/unpin.
             */
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton

                onClicked: {
                    root.currentIndex = index;
                    root.toggleFavourite(app.modelData);
                }
            }
'''
    new_click = '''            /*
             * Un único MouseArea controla ambos botones. En algunas versiones
             * de Qt/Quickshell el StateLayer absorbía el botón derecho antes de
             * que llegara al MouseArea right-only, por eso pin/unpin no ocurría
             * desde el launcher aunque sí funcionara en el Dock.
             */
            MouseArea {
                id: appMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor

                onEntered: root.currentIndex = index

                onClicked: event => {
                    root.currentIndex = index;

                    if (event.button === Qt.RightButton) {
                        root.toggleFavourite(app.modelData);
                        event.accepted = true;
                        return;
                    }

                    Apps.launch(app.modelData);
                    root.screenState.launcher = false;
                    event.accepted = true;
                }
            }
'''
    if old_click in text:
        text = text.replace(old_click, new_click, 1)
        changed = True
        print("Launcher: clic derecho cambiado a handler único left/right")
    elif "id: appMouse" in text and "root.toggleFavourite(app.modelData)" in text:
        print("Launcher: clic derecho robusto ya aplicado")
    else:
        raise SystemExit("ERROR: no reconozco el handler de apps del launcher")

    old_height = '''        case "scheme":
        case "variant":
            return 116;
'''
    new_height = '''        case "scheme":
            return 154;
        case "variant":
            return 116;
'''
    if old_height in text:
        text = text.replace(old_height, new_height, 1)
        changed = True

    scheme_block = r'''\n    Component \{\n        id: schemeDelegate\n.*?\n    \}\n\n    Component \{\n        id: variantDelegate'''
    match = re.search(scheme_block, text, flags=re.S)
    if not match:
        if "readonly property bool previewLight" in text:
            print("Launcher: selector premium de schemes ya aplicado")
            return text, changed
        raise SystemExit("ERROR: no encontré schemeDelegate para actualizar")

    replacement = r'''
    Component {
        id: schemeDelegate

        Item {
            id: scheme

            required property var modelData

            width: root.cellWidth
            height: root.cellHeight

            readonly property bool selected: GridView.isCurrentItem
            readonly property bool current:
                `${modelData?.name} ${modelData?.flavour}` === Schemes.currentScheme

            readonly property var previewSwatches: [
                modelData?.colours?.surface,
                modelData?.colours?.primary,
                modelData?.colours?.secondary,
                modelData?.colours?.tertiary,
                modelData?.colours?.error,
                modelData?.colours?.onSurface
            ]

            readonly property bool previewLight: {
                const raw = String(modelData?.colours?.surface ?? "").replace("#", "");
                if (raw.length !== 6)
                    return false;
                const r = parseInt(raw.slice(0, 2), 16);
                const g = parseInt(raw.slice(2, 4), 16);
                const b = parseInt(raw.slice(4, 6), 16);
                return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255 > 0.56;
            }

            StyledRect {
                anchors.fill: parent
                anchors.margins: 4
                radius: Tokens.rounding.large
                color: scheme.selected
                    ? Colours.palette.m3secondaryContainer
                    : Colours.palette.m3surfaceContainerLow
                border.width: scheme.current ? 1 : 0
                border.color: Colours.palette.m3primary
            }

            StateLayer {
                anchors.fill: parent
                anchors.margins: 4
                radius: Tokens.rounding.large
                onEntered: root.currentIndex = index
                onClicked: scheme.modelData?.onClicked(root)
            }

            Row {
                id: swatches
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 17
                spacing: 6

                Repeater {
                    model: scheme.previewSwatches

                    delegate: Rectangle {
                        required property var modelData
                        width: Math.max(15, (swatches.width - 30) / 6)
                        height: 24
                        radius: 8
                        color: modelData
                            ? `#${modelData}`
                            : Colours.palette.m3surfaceContainerHighest
                        border.width: 1
                        border.color: Qt.alpha(Colours.palette.m3outline, 0.34)
                    }
                }
            }

            StyledText {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: swatches.bottom
                anchors.topMargin: 13
                anchors.leftMargin: 14
                anchors.rightMargin: 14

                text: scheme.modelData?.name ?? ""
                font: Tokens.font.body.medium
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            StyledText {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 102
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                text: `${scheme.modelData?.flavour ?? "default"} · ${scheme.previewLight ? qsTr("Light") : qsTr("Dark")}`
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            MaterialIcon {
                visible: scheme.current
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 9
                anchors.rightMargin: 10
                text: "check_circle"
                fill: 1
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.small
            }
        }
    }

    Component {
        id: variantDelegate'''

    text = text[:match.start()] + replacement + text[match.end():]
    changed = True
    print("Launcher: scheme cards ampliadas a 6 colores + familia/flavour + dark/light")
    return text, changed


def ensure_delegate_indices(text: str) -> tuple[str, bool]:
    """Bind GridView's injected index role explicitly in every custom delegate.

    With pragma ComponentBehavior: Bound, relying on an undeclared `index`
    identifier is not safe. The click handlers were receiving mouse events but
    aborted at `root.currentIndex = index` with ReferenceError before launching
    apps, toggling pins or applying schemes.
    """
    changed = False
    delegates = {
        "app": "required property DesktopEntry modelData",
        "action": "required property var modelData",
        "calc": "required property var modelData",
        "scheme": "required property var modelData",
        "variant": "required property var modelData",
    }

    for delegate_id, model_line in delegates.items():
        already = re.search(
            rf"id:\s*{re.escape(delegate_id)}\b.*?{re.escape(model_line)}\s*\n\s*required property int index\b",
            text,
            flags=re.S,
        )
        if already:
            continue

        pattern = re.compile(
            rf"(id:\s*{re.escape(delegate_id)}\b.*?\n\s*{re.escape(model_line)})(\s*\n)",
            flags=re.S,
        )
        match = pattern.search(text)
        if not match:
            raise SystemExit(f"ERROR: no encontré modelData del delegate {delegate_id}")

        insertion = match.group(1) + "\n            required property int index" + match.group(2)
        text = text[:match.start()] + insertion + text[match.end():]
        changed = True
        print(f"Launcher: index role ligado explícitamente en {delegate_id}Delegate")

    return text, changed


def regenerate_app_patch(live_text: str) -> None:
    with tempfile.TemporaryDirectory(prefix="caerice-shell-") as td:
        root = Path(td) / "shell"
        run(
            "git", "clone", "--quiet", "--depth", "1", "--branch", UPSTREAM_TAG,
            "https://github.com/caelestia-dots/shell.git", str(root)
        )
        upstream = root / "modules/launcher/AppList.qml"
        live_tmp = Path(td) / "AppList.qml"
        live_tmp.write_text(live_text, encoding="utf-8")
        cp = subprocess.run(
            [
                "diff", "-u",
                "--label", "a/modules/launcher/AppList.qml",
                "--label", "b/modules/launcher/AppList.qml",
                str(upstream), str(live_tmp)
            ],
            text=True,
            capture_output=True,
            check=False,
        )
        if cp.returncode not in (0, 1):
            raise SystemExit(f"ERROR: diff devolvió {cp.returncode}: {cp.stderr}")
        if cp.returncode == 0:
            raise SystemExit("ERROR: AppList live no difiere del upstream; no genero patch vacío")
        APP_PATCH.write_text(cp.stdout, encoding="utf-8")
        print("Launcher: patch reproducible regenerado contra Caelestia v2.3.0")


def fix_launcher() -> bool:
    if not APP_LIVE.exists():
        raise SystemExit(f"ERROR: no existe {APP_LIVE}")
    text = APP_LIVE.read_text(encoding="utf-8")
    text, changed = patch_launcher_text(text)
    text, index_changed = ensure_delegate_indices(text)
    changed = changed or index_changed
    if changed:
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as tmp:
            tmp.write(text)
            tmp_path = Path(tmp.name)
        try:
            install_root(tmp_path, APP_LIVE)
        finally:
            tmp_path.unlink(missing_ok=True)
    regenerate_app_patch(text)
    return changed


def save_repo_changes() -> None:
    paths = [
        str(CLIP_REPO.relative_to(REPO)),
        str(APP_PATCH.relative_to(REPO)),
    ]
    run("git", "-C", str(REPO), "add", *paths, check=False)
    status = run("git", "-C", str(REPO), "status", "--porcelain", "--", *paths, capture=True, check=False).stdout.strip()
    if not status:
        print("Git: no hay cambios nuevos que guardar")
        return
    commit = run(
        "git", "-C", str(REPO), "commit", "-m",
        "fix(theme-dock): bind launcher delegate indices",
        "--", *paths, check=False, capture=True
    )
    if commit.returncode:
        raise SystemExit("ERROR: git commit falló:\n" + commit.stderr)
    push = run("git", "-C", str(REPO), "push", check=False, capture=True)
    if push.returncode:
        raise SystemExit("ERROR: git push falló:\n" + push.stderr)
    print("GitHub push: OK")


def main() -> None:
    print("===== FINALIZE THEME-DOCK =====")
    fix_clipboard_center()
    fix_launcher()
    save_repo_changes()
    print("\nReinicia Caelestia para validar:")
    print("pkill -TERM -x qs; sleep 1; caelestia shell -d")
    print("\nPruebas:")
    print("  1) Super+V: Clipboard debe quedar geométricamente centrado.")
    print("  2) Super: clic izquierdo abre; clic derecho fija/quita del Dock.")
    print("  3) >scheme <texto>: clic/Enter aplica el scheme.")
    print("  4) log.qslog no debe contener 'ReferenceError: index is not defined'.")


if __name__ == "__main__":
    main()
