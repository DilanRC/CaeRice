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
            "        clip: session.visible\n",
            "        clip: sidebar.visible || session.visible\n",
            "Panels OSD clip",
        ),
        (
            "            sidebarOrSessionVisible: session.visible\n",
            "            sidebarOrSessionVisible: sidebar.visible || session.visible\n",
            "Panels OSD visibility",
        ),
        (
            "        anchors.rightMargin: 0\n        clip: false\n",
            "        anchors.rightMargin: sidebar.width * (1 - sidebar.offsetScale)\n        clip: sidebar.visible\n",
            "Panels session geometry",
        ),
    ]

    for old, new, label in required_replacements:
        text, did = replace_required(text, old, new, label)
        changed = changed or did

    tolerant_replacements = [
        (
            "        anchors.bottom: sidebar.visible ? sidebar.top : utilities.top\n        anchors.right: parent.right\n",
            "        anchors.bottom: sidebar.visible ? parent.bottom : utilities.top\n        anchors.right: sidebar.left\n",
        ),
        (
            "        anchors.bottom: utilities.top\n        anchors.right: parent.right\n",
            "        anchors.bottom: sidebar.visible ? parent.bottom : utilities.top\n        anchors.right: sidebar.left\n",
        ),
        (
            "        anchors.horizontalCenter: parent.horizontalCenter\n        anchors.bottom: parent.bottom\n",
            "        anchors.top: notifications.bottom\n        anchors.bottom: utilities.top\n        anchors.right: parent.right\n        anchors.topMargin: -notifications.anchors.topMargin\n",
        ),
        (
            "        screenState: root.screenState\n        popouts: popoutsWrapper.content\n",
            "        screenState: root.screenState\n        sidebar: sidebar\n        popouts: popoutsWrapper.content\n",
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
        and "+ sidebarRegion.width" not in text
        and "height: panel.height * (1 - root.panels.sidebar.offsetScale) + root.borderThickness" in text
    )
    target_signature = (
        "y: root.win.height - height - panel.dockOffset" in text
        and "+ sidebarRegion.width" in text
        and "x: root.win.width - width" in text
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
        "        width: panel.width * (1 - root.panels.session.offsetScale) + root.borderThickness\n",
        "        width: panel.width * (1 - root.panels.session.offsetScale) + root.borderThickness + sidebarRegion.width\n",
    )
    changed = changed or did

    text, did = replace_if_present(
        text,
        "        width: panel.width\n        height: panel.height * (1 - root.panels.sidebar.offsetScale) + root.borderThickness\n",
        "        x: root.win.width - width\n        width: panel.width * (1 - root.panels.sidebar.offsetScale) + root.borderThickness\n",
    )
    changed = changed or did

    return write_if_changed(path, text, changed)


def migrate_sidebar(root: Path) -> bool:
    path = root / "modules/sidebar/Wrapper.qml"
    if not path.is_file():
        return False
    text = path.read_text(encoding="utf-8")
    changed = False

    text, did = replace_if_present(
        text,
        "    // Bottom Hub: open above the 64px bar + 2px margin + 6px breathing room.\n"
        "    // Closed state slides the complete panel below the screen edge.\n"
        "    anchors.bottomMargin:\n"
        "        72 +\n"
        "        (-implicitHeight - 5 - 72) * offsetScale\n\n"
        "    implicitWidth: Math.min(520, parent.width - 16)\n"
        "    implicitHeight: Math.min(430, parent.height * 0.55)\n",
        "    anchors.rightMargin: (-implicitWidth - 5) * offsetScale\n"
        "    implicitWidth: Tokens.sizes.sidebar.width\n",
    )
    changed = changed or did

    text, did = replace_if_present(
        text,
        "        anchors.fill: parent\n",
        "        anchors.top: parent.top\n"
        "        anchors.bottom: parent.bottom\n"
        "        anchors.left: parent.left\n"
        "        anchors.leftMargin: Tokens.padding.large\n"
        "        anchors.margins: CUtils.clamp(anchors.leftMargin - Config.border.thickness, 0, anchors.leftMargin)\n"
        "        anchors.bottomMargin: 0\n",
    )
    changed = changed or did

    text, did = replace_if_present(
        text,
        "            implicitWidth: root.implicitWidth\n",
        "            implicitWidth: Tokens.sizes.sidebar.width - content.anchors.leftMargin - content.anchors.margins\n",
    )
    changed = changed or did
    return write_if_changed(path, text, changed)


def migrate_utilities(root: Path) -> bool:
    path = root / "modules/utilities/Wrapper.qml"
    if not path.is_file():
        return False
    text = path.read_text(encoding="utf-8")
    if "// Bottom Hub: independent popover" not in text:
        return False

    text = text.replace(
        "import qs.components\nimport qs.modules.bar.popouts as BarPopouts\n",
        "import qs.components\nimport qs.modules.sidebar as Sidebar\nimport qs.modules.bar.popouts as BarPopouts\n",
        1,
    )
    text = text.replace(
        "    required property ScreenState screenState\n    required property BarPopouts.Wrapper popouts\n",
        "    required property ScreenState screenState\n    required property Sidebar.Wrapper sidebar\n    required property BarPopouts.Wrapper popouts\n    property real horizontalStretch\n",
        1,
    )
    text = text.replace(
        "    readonly property bool shouldBeActive: screenState.utilities && Config.utilities.enabled && !(screenState.session && Config.session.enabled)\n",
        "    readonly property bool shouldBeActive: screenState.sidebar || (screenState.utilities && Config.utilities.enabled && !(screenState.session && Config.session.enabled))\n",
        1,
    )
    text = text.replace(
        "    property real offsetScale: shouldBeActive ? 0 : 1\n",
        "    property real offsetScale: shouldBeActive ? 0 : 1\n    property real sidebarLerp\n",
        1,
    )
    start = text.index("    // Bottom Hub: independent popover")
    end = text.index("    opacity: 1 - offsetScale", start)
    text = (
        text[:start]
        + "    anchors.bottomMargin: (-implicitHeight - 5) * offsetScale\n"
        + "    implicitHeight: content.implicitHeight + totalPadding\n"
        + "    implicitWidth: sidebar.width * (1 - sidebar.offsetScale) * horizontalStretch * sidebarLerp + Tokens.sizes.utilities.width * (1 - sidebarLerp)\n"
        + text[end:]
    )
    behavior = "    Behavior on offsetScale {\n"
    states = (
        "    states: State {\n"
        "        name: \"attachedToSidebar\"\n"
        "        when: root.screenState.sidebar\n\n"
        "        PropertyChanges {\n"
        "            root.sidebarLerp: 1\n"
        "        }\n"
        "    }\n\n"
        "    transitions: [\n"
        "        Transition {\n"
        "            from: \"\"\n\n"
        "            Anim {\n"
        "                property: \"sidebarLerp\"\n"
        "                duration: Tokens.anim.durations.expressiveDefaultSpatial / 2\n"
        "                easing: Tokens.anim.standardAccel\n"
        "            }\n"
        "        },\n"
        "        Transition {\n"
        "            to: \"\"\n\n"
        "            Anim {\n"
        "                property: \"sidebarLerp\"\n"
        "                duration: Tokens.anim.durations.expressiveDefaultSpatial / 2\n"
        "                easing: Tokens.anim.standardDecel\n"
        "            }\n"
        "        }\n"
        "    ]\n\n"
    )
    text = text.replace(behavior, states + behavior, 1)
    return write_if_changed(path, text, True)


def main() -> None:
    parser = argparse.ArgumentParser(description="Migra un runtime CaeRice main al layout BottomHub")
    parser.add_argument("root", type=Path, help="raíz de Caelestia (real o copia temporal)")
    args = parser.parse_args()
    root = args.root.resolve()

    changed = []
    for name, fn in (
        ("shell.qml", migrate_shell),
        ("modules/sidebar/Wrapper.qml", migrate_sidebar),
        ("modules/utilities/Wrapper.qml", migrate_utilities),
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
