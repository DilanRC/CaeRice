#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DOCK_REPO = REPO / "caelestia/modules-owned/modules/BottomHub.qml"
DOCK_LIVE = Path("/etc/xdg/quickshell/caelestia/modules/BottomHub.qml")
LAUNCHER_LIVE = Path("/etc/xdg/quickshell/caelestia/modules/launcher/AppList.qml")

# Historical cleanup kept for idempotency. Older dock revisions rendered a
# dedicated push-pin badge. BottomHub does not need it because right-click on
# the whole icon already toggles favouriteApps.
DOCK_PIN_BLOCK = '''                                Item {
                                    id: dockPinButton

                                    visible: appItem.modelData.pinned || mouse.containsMouse || pinMouse.containsMouse
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.topMargin: 1
                                    anchors.rightMargin: 1
                                    width: 20
                                    height: 20
                                    z: 4

                                    StyledRect {
                                        anchors.fill: parent
                                        radius: Tokens.rounding.full
                                        color: pinMouse.containsMouse
                                            ? Colours.palette.m3secondaryContainer
                                            : appItem.modelData.pinned
                                                ? Colours.palette.m3surfaceContainerHighest
                                                : Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.78)
                                    }

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "push_pin"
                                        fill: appItem.modelData.pinned ? 1 : 0
                                        color: appItem.modelData.pinned || pinMouse.containsMouse
                                            ? Colours.palette.m3primary
                                            : Colours.palette.m3onSurfaceVariant
                                        fontStyle: Tokens.font.icon.small
                                    }

                                    MouseArea {
                                        id: pinMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: event => {
                                            win.togglePinned(appItem.modelData);
                                            event.accepted = true;
                                        }
                                    }
                                }

'''

LAUNCHER_PIN_BLOCK = '''            MaterialIcon {
                visible: app.favourite

                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 8
                anchors.rightMargin: 9

                text: "push_pin"
                fill: 1
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.small
            }

'''


def patch_text(text: str, block: str) -> tuple[str, bool]:
    if block not in text:
        return text, False
    return text.replace(block, "", 1), True


def install_text_as_root(text: str, target: Path) -> None:
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as tmp:
        tmp.write(text)
        tmp_path = Path(tmp.name)
    try:
        subprocess.run(
            ["sudo", "install", "-m", "0644", str(tmp_path), str(target)],
            check=True,
        )
    finally:
        tmp_path.unlink(missing_ok=True)


def patch_dock() -> bool:
    text = DOCK_REPO.read_text(encoding="utf-8")
    text, changed = patch_text(text, DOCK_PIN_BLOCK)

    if "Qt.RightButton" not in text or "win.togglePinned(" not in text:
        raise SystemExit("ERROR: BottomHub perdió la acción de clic derecho para fijar apps")

    if changed:
        DOCK_REPO.write_text(text, encoding="utf-8")
        print("BottomHub repo: badges de pin eliminados")
    else:
        print("BottomHub repo: ya no tiene badges de pin")

    if DOCK_LIVE.exists():
        subprocess.run(
            ["sudo", "install", "-m", "0644", str(DOCK_REPO), str(DOCK_LIVE)],
            check=True,
        )
        print("BottomHub live: actualizado")

    return changed


def patch_launcher_live() -> None:
    if not LAUNCHER_LIVE.exists():
        print("Launcher live: AppList.qml no encontrado; omitido")
        return

    text = LAUNCHER_LIVE.read_text(encoding="utf-8")
    text, changed = patch_text(text, LAUNCHER_PIN_BLOCK)

    if "Qt.RightButton" not in text or "toggleFavourite(app.modelData)" not in text:
        raise SystemExit("ERROR: AppList.qml no conserva clic derecho para fijar apps")

    if changed:
        install_text_as_root(text, LAUNCHER_LIVE)
        print("Launcher live: indicador visual de pin eliminado")
    else:
        print("Launcher live: ya no tiene indicador visual de pin")


def save_repo_change(changed: bool) -> None:
    if not changed:
        return

    subprocess.run(
        ["git", "-C", str(REPO), "add", str(DOCK_REPO.relative_to(REPO))],
        check=False,
    )
    status = subprocess.run(
        ["git", "-C", str(REPO), "status", "--porcelain", "--", str(DOCK_REPO.relative_to(REPO))],
        text=True,
        capture_output=True,
        check=False,
    ).stdout.strip()
    if not status:
        return

    commit = subprocess.run(
        [
            "git",
            "-C",
            str(REPO),
            "commit",
            "-m",
            "fix(bottom-hub): hide favourite badges",
            "--",
            str(DOCK_REPO.relative_to(REPO)),
        ],
        text=True,
        capture_output=True,
        check=False,
    )
    if commit.returncode != 0:
        print("WARN: no pude hacer commit automático de BottomHub:", commit.stderr.strip())
        return

    push = subprocess.run(
        ["git", "-C", str(REPO), "push"],
        text=True,
        capture_output=True,
        check=False,
    )
    print("GitHub push BottomHub:", "OK" if push.returncode == 0 else "falló; ejecuta git push")


def main() -> None:
    changed = patch_dock()
    patch_launcher_live()
    save_repo_change(changed)

    print("\nFavoritos: clic derecho sobre una app = fijar/quitar del Bottom Hub")
    print("No se muestran badges de pin sobre los iconos.")


if __name__ == "__main__":
    main()
