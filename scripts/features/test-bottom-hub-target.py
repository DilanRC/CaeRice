#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CHECKER_PATH = REPO / "caelestia/bin/check-bottom-hub-target.py"
MIGRATOR_PATH = REPO / "caelestia/bin/migrate-bottom-hub-from-main.py"
REL = "modules/drawers/ContentWindow.qml"

spec = importlib.util.spec_from_file_location("bottom_hub_target_checker", CHECKER_PATH)
if spec is None or spec.loader is None:
    raise SystemExit(f"No pude cargar {CHECKER_PATH}")
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)

migrator_spec = importlib.util.spec_from_file_location("bottom_hub_migrator", MIGRATOR_PATH)
if migrator_spec is None or migrator_spec.loader is None:
    raise SystemExit(f"No pude cargar {MIGRATOR_PATH}")
migrator = importlib.util.module_from_spec(migrator_spec)
migrator_spec.loader.exec_module(migrator)


def screen_state(flags: tuple[str, ...]) -> str:
    return "Item {\n" + "".join(f"    property bool {flag}\n" for flag in flags) + "}\n"


def content_window(
    flags: tuple[str, ...],
    *,
    omit_from: str | None = None,
    clipboard_scrim: bool = True,
) -> str:
    screen_flags = [f"screenState.{flag}" for flag in flags]
    s_flags = [f"s.{flag}" for flag in flags]

    def members(values: list[str], context: str) -> str:
        filtered = values[:-1] if omit_from == context else values
        return " || ".join(filtered)

    fullscreen_flags = flags[:-1] if omit_from == "fullscreen" else flags
    cleared_flags = flags[:-1] if omit_from == "cleared" else flags
    fullscreen_lines = "".join(
        f"        screenState.{flag} = false;\n" for flag in fullscreen_flags
    )
    cleared_lines = "".join(
        f"            root.screenState.{flag} = false;\n" for flag in cleared_flags
    )

    opacity = "opacity: root.screenState.overview ? 0.58 : 0"
    if "clipboard" in flags and clipboard_scrim:
        opacity = (
            "opacity: root.screenState.overview ? 0.58 : "
            "(root.screenState.clipboard ? 0.48 : 0)"
        )

    return (
        "StyledWindow {\n"
        "    onHasFullscreenChanged: {\n"
        f"{fullscreen_lines}"
        "        panels.popouts.close();\n"
        "    }\n\n"
        f"    WlrLayershell.layer: {members(screen_flags, 'layer')} ? WlrLayer.Overlay : WlrLayer.Top\n"
        f"    WlrLayershell.keyboardFocus: {members(screen_flags, 'keyboard')} || screenState.launcher || screenState.session ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None\n"
        f"    mask: {members(screen_flags, 'mask')} ? null : (hasFullscreen ? emptyRegion : regions)\n\n"
        "    HyprlandFocusGrab {\n"
        "        active: {\n"
        f"            if ({members(s_flags, 'active')})\n"
        "                return true;\n"
        "            return false;\n"
        "        }\n"
        "        windows: [root]\n"
        "        onCleared: {\n"
        f"{cleared_lines}"
        "            panels.popouts.hasCurrent = false;\n"
        "        }\n"
        "    }\n\n"
        "    StyledRect {\n"
        f"        {opacity}\n"
        "    }\n"
        "}\n"
    )


def run_case(
    name: str,
    flags: tuple[str, ...],
    *,
    expected: bool,
    omit_from: str | None = None,
    clipboard_scrim: bool = True,
) -> None:
    with tempfile.TemporaryDirectory(prefix="bottom-hub-target-") as td:
        root = Path(td)
        (root / "components").mkdir(parents=True)
        (root / "modules/drawers").mkdir(parents=True)
        (root / "components/ScreenState.qml").write_text(
            screen_state(flags), encoding="utf-8"
        )
        text = content_window(
            flags,
            omit_from=omit_from,
            clipboard_scrim=clipboard_scrim,
        )
        (root / REL).write_text(text, encoding="utf-8")
        actual = checker.check_content_window(root, text)
        if actual != expected:
            raise SystemExit(
                f"FAIL {name}: expected={expected} actual={actual}"
            )
        print(f"PASS {name}")


def run_panels_tolerant_migration() -> None:
    with tempfile.TemporaryDirectory(prefix="bottom-hub-panels-") as td:
        root = Path(td)
        panels = root / "modules/drawers/Panels.qml"
        panels.parent.mkdir(parents=True)
        panels.write_text(
            "import qs.modules.overview as Overview\n"
            "Item {\n"
            "    id: root\n"
            "    readonly property alias overview: overview\n"
            "    Item {\n"
            "        id: osdWrapper\n"
            "        clip: sidebar.visible || session.visible\n"
            "        Osd.Wrapper {\n"
            "            sidebarOrSessionVisible: sidebar.visible || session.visible\n"
            "        }\n"
            "    }\n"
            "    Item {\n"
            "        id: sessionWrapper\n"
            "        anchors.rightMargin: sidebar.width * (1 - sidebar.offsetScale)\n"
            "        clip: sidebar.visible\n"
            "    }\n"
            "    Overview.Wrapper {\n"
            "        id: overview\n"
            "    }\n"
            "    Toasts.Toasts {\n"
            "        anchors.bottom: utilities.top\n"
            "        anchors.right: parent.right\n"
            "    }\n"
            "    Utilities.Wrapper {\n"
            "        screenState: root.screenState\n"
            "        popouts: popoutsWrapper.content\n"
            "    }\n"
            "    Sidebar.Wrapper {\n"
            "        anchors.horizontalCenter: parent.horizontalCenter\n"
            "        anchors.bottom: parent.bottom\n"
            "    }\n"
            "}\n",
            encoding="utf-8",
        )
        assert migrator.migrate_panels(root) is True
        text = panels.read_text(encoding="utf-8")
        if not checker.check_panels(root, text):
            raise SystemExit("FAIL panels-tolerant-migration")
        print("PASS panels-tolerant-migration")


def run_sidebar_migration() -> None:
    with tempfile.TemporaryDirectory(prefix="bottom-hub-sidebar-") as td:
        root = Path(td)
        sidebar = root / "modules/sidebar/Wrapper.qml"
        sidebar.parent.mkdir(parents=True)
        sidebar.write_text(
            "Item {\n"
            "    id: root\n"
            "    // Bottom Hub: open above the 64px bar + 2px margin + 6px breathing room.\n"
            "    // Closed state slides the complete panel below the screen edge.\n"
            "    anchors.bottomMargin:\n"
            "        72 +\n"
            "        (-implicitHeight - 5 - 72) * offsetScale\n\n"
            "    implicitWidth: Math.min(520, parent.width - 16)\n"
            "    implicitHeight: Math.min(430, parent.height * 0.55)\n"
            "    Item {\n"
            "        anchors.fill: parent\n"
            "        Loader {\n"
            "            implicitWidth: root.implicitWidth\n"
            "        }\n"
            "    }\n"
            "}\n",
            encoding="utf-8",
        )
        assert migrator.migrate_sidebar(root) is True
        text = sidebar.read_text(encoding="utf-8")
        text = text.replace('    id: root\n', '    id: root\n    objectName: "caericeNativeSidebar"\n')
        sidebar.write_text(text, encoding="utf-8")
        if not checker.check_sidebar(root, text):
            raise SystemExit("FAIL sidebar-native-migration")
        print("PASS sidebar-native-migration")


def run_regions_migration() -> None:
    with tempfile.TemporaryDirectory(prefix="bottom-hub-regions-") as td:
        root = Path(td)
        regions = root / "modules/drawers/Regions.qml"
        regions.parent.mkdir(parents=True)
        regions.write_text(
            "Item {\n"
            "    R {\n"
            "        y: root.win.height - height - panel.dockOffset\n"
            "        width: panel.width * (1 - root.panels.session.offsetScale) + root.borderThickness\n"
            "    }\n"
            "    R {\n"
            "        panel: root.panels.sidebar\n"
            "        width: panel.width\n"
            "        height: panel.height * (1 - root.panels.sidebar.offsetScale) + root.borderThickness\n"
            "    }\n"
            "}\n",
            encoding="utf-8",
        )
        assert migrator.migrate_regions(root) is True
        text = regions.read_text(encoding="utf-8")
        if not checker.check_regions(root, text):
            raise SystemExit("FAIL regions-native-migration")
        print("PASS regions-native-migration")


def main() -> None:
    run_case("overview-base", ("overview",), expected=True)
    run_case(
        "layered-retained-overlays",
        ("overview", "clipboard", "hardware", "displayManager"),
        expected=True,
    )
    run_case(
        "missing-display-from-mask",
        ("overview", "clipboard", "hardware", "displayManager"),
        expected=False,
        omit_from="mask",
    )
    run_case(
        "missing-display-from-cleared",
        ("overview", "clipboard", "hardware", "displayManager"),
        expected=False,
        omit_from="cleared",
    )
    run_case(
        "clipboard-scrim-regression",
        ("overview", "clipboard", "hardware", "displayManager"),
        expected=False,
        clipboard_scrim=False,
    )
    run_panels_tolerant_migration()
    run_sidebar_migration()
    run_regions_migration()
    print("BottomHub semantic target tests: OK")


if __name__ == "__main__":
    main()
