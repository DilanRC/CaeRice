#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path


def replace_required(text: str, old: str, new: str, label: str) -> tuple[str, bool]:
    if new in text:
        return text, False
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"ERROR: {label}: esperaba exactamente 1 coincidencia antigua, encontré {count}")
    return text.replace(old, new, 1), True


def replace_if_present(text: str, old: str, new: str) -> tuple[str, bool]:
    if new in text:
        return text, False
    if old not in text:
        return text, False
    return text.replace(old, new, 1), True


def write_if_changed(path: Path, text: str, changed: bool) -> bool:
    if changed:
        path.write_text(text, encoding="utf-8")
    return changed


def migrate_shell(root: Path) -> bool:
    path = root / "shell.qml"
    if not path.is_file():
        return False
    text = path.read_text(encoding="utf-8")
    if "    BottomHub {}\n" in text:
        return False
    if "    CustomDock {}\n" not in text:
        return False
    text, changed = replace_required(
        text,
        "    CustomDock {}\n",
        "    BottomHub {}\n",
        "shell.qml CustomDock -> BottomHub",
    )
    return write_if_changed(path, text, changed)


def migrate_panels(root: Path) -> bool:
    path = root / "modules/drawers/Panels.qml"
    if not path.is_file():
        return False
    text = path.read_text(encoding="utf-8")

    # Firma del CaeRice anterior: Overview ya estaba integrado. Un upstream
    # limpio no debe pasar por esta migración.
    if "import qs.modules.overview as Overview" not in text or "    Overview.Wrapper {\n" not in text:
        return False

    changed = False
    required_replacements = [
        (
            "        clip: sidebar.visible || session.visible\n",
            "        clip: session.visible\n",
            "Panels OSD clip",
        ),
        (
            "            sidebarOrSessionVisible: sidebar.visible || session.visible\n",
            "            sidebarOrSessionVisible: session.visible\n",
            "Panels OSD visibility",
        ),
        (
            "        anchors.rightMargin: sidebar.width * (1 - sidebar.offsetScale)\n        clip: sidebar.visible\n",
            "        anchors.rightMargin: 0\n        clip: false\n",
            "Panels session geometry",
        ),
    ]

    for old, new, label in required_replacements:
        text, did = replace_required(text, old, new, label)
        changed = changed or did

    tolerant_replacements = [
        (
            "        anchors.bottom: sidebar.visible ? parent.bottom : utilities.top\n        anchors.right: sidebar.left\n",
            "        anchors.bottom: sidebar.visible ? sidebar.top : utilities.top\n        anchors.right: parent.right\n",
        ),
        (
            "        anchors.bottom: utilities.top\n        anchors.right: parent.right\n",
            "        anchors.bottom: sidebar.visible ? sidebar.top : utilities.top\n        anchors.right: parent.right\n",
        ),
        (
            "        anchors.top: notifications.bottom\n        anchors.bottom: utilities.top\n        anchors.right: parent.right\n        anchors.topMargin: -notifications.anchors.topMargin\n",
            "        anchors.horizontalCenter: parent.horizontalCenter\n        anchors.bottom: parent.bottom\n",
        ),
    ]

    for old, new in tolerant_replacements:
        text, did = replace_if_present(text, old, new)
        changed = changed or did

    return write_if_changed(path, text, changed)


def migrate_regions(root: Path) -> bool:
    path = root / "modules/drawers/Regions.qml"
    if not path.is_file():
        return False
    text = path.read_text(encoding="utf-8")

    # El comentario del patch histórico cambió entre iteraciones, por eso no
    # se usa como firma. La geometría del launcher desplazado + el ancho de
    # sesión que suma sidebarRegion sí identifican el estado CaeRice anterior.
    legacy_signature = (
        "y: root.win.height - height - panel.dockOffset" in text
        and "+ sidebarRegion.width" in text
    )
    target_signature = (
        "y: root.win.height - height - panel.dockOffset" in text
        and "+ sidebarRegion.width" not in text
        and "height: panel.height * (1 - root.panels.sidebar.offsetScale) + root.borderThickness" in text
    )
    if not legacy_signature and not target_signature:
        return False

    changed = False

    old_comment = (
        "    /*\n"
        "     * The launcher is lifted above CustomDock by Wrapper.dockOffset.\n"
        "     * Preserve upstream's window-coordinate region formula and subtract the\n"
        "     * same offset. Using panel.y here mixes coordinate spaces and leaves the\n"
        "     * visible launcher outside the Wayland input region.\n"
        "     */\n"
    )
    new_comment = (
        "    /*\n"
        "     * The launcher is lifted above BottomHub by Wrapper.dockOffset.\n"
        "     * Preserve upstream's window-coordinate region formula and subtract the\n"
        "     * same offset so the visible launcher remains inside the Wayland input mask.\n"
        "     */\n"
    )
    text, did = replace_if_present(text, old_comment, new_comment)
    changed = changed or did

    text, did = replace_if_present(
        text,
        "        width: panel.width * (1 - root.panels.session.offsetScale) + root.borderThickness + sidebarRegion.width\n",
        "        width: panel.width * (1 - root.panels.session.offsetScale) + root.borderThickness\n",
    )
    changed = changed or did

    text, did = replace_if_present(
        text,
        "        x: root.win.width - width\n        width: panel.width * (1 - root.panels.sidebar.offsetScale) + root.borderThickness\n",
        "        width: panel.width\n        height: panel.height * (1 - root.panels.sidebar.offsetScale) + root.borderThickness\n",
    )
    changed = changed or did

    return write_if_changed(path, text, changed)


def main() -> None:
    parser = argparse.ArgumentParser(description="Migra un runtime CaeRice main al layout BottomHub")
    parser.add_argument("root", type=Path, help="raíz de Caelestia (real o copia temporal)")
    args = parser.parse_args()
    root = args.root.resolve()

    changed = []
    for name, fn in (
        ("shell.qml", migrate_shell),
        ("modules/drawers/Panels.qml", migrate_panels),
        ("modules/drawers/Regions.qml", migrate_regions),
    ):
        if fn(root):
            changed.append(name)

    if changed:
        print("MIGRATED " + ", ".join(changed))
    else:
        print("MIGRATION no-op")


if __name__ == "__main__":
    main()
