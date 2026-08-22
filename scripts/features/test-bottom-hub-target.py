#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CHECKER = REPO / "caelestia/bin/check-bottom-hub-target.py"
REL = "modules/drawers/ContentWindow.qml"


def screen_state(flags: tuple[str, ...]) -> str:
    return "Item {\n" + "".join(f"    property bool {flag}\n" for flag in flags) + "}\n"


def content_window(flags: tuple[str, ...], *, omit_from: str | None = None, clipboard_scrim: bool = True) -> str:
    screen_flags = [f"screenState.{flag}" for flag in flags]
    s_flags = [f"s.{flag}" for flag in flags]

    def members(values: list[str], context: str) -> str:
        filtered = values
        if omit_from == context:
            filtered = values[:-1]
        return " || ".join(filtered)

    fullscreen_flags = flags if omit_from != "fullscreen" else flags[:-1]
    cleared_flags = flags if omit_from != "cleared" else flags[:-1]

    opacity = "opacity: root.screenState.overview ? 0.58 : 0"
    if "clipboard" in flags and clipboard_scrim:
        opacity = "opacity: root.screenState.overview ? 0.58 : (root.screenState.clipboard ? 0.48 : 0)"

    return f'''StyledWindow {{
    onHasFullscreenChanged: {{
{''.join(f'        screenState.{flag} = false;\n' for flag in fullscreen_flags)}        panels.popouts.close();
    }}

    WlrLayershell.layer: {members(screen_flags, "layer")} ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: {members(screen_flags, "keyboard")} || screenState.launcher || screenState.session ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: {members(screen_flags, "mask")} ? null : (hasFullscreen ? emptyRegion : regions)

    HyprlandFocusGrab {{
        active: {{
            if ({members(s_flags, "active")})
                return true;
            return false;
        }}
        windows: [root]
        onCleared: {{
{''.join(f'            root.screenState.{flag} = false;\n' for flag in cleared_flags)}            panels.popouts.hasCurrent = false;
        }}
    }}

    StyledRect {{
        {opacity}
    }}
}}
'''


def run_case(name: str, flags: tuple[str, ...], *, expected: bool, omit_from: str | None = None, clipboard_scrim: bool = True) -> None:
    with tempfile.TemporaryDirectory(prefix="bottom-hub-target-") as td:
        root = Path(td)
        (root / "components").mkdir(parents=True)
        (root / "modules/drawers").mkdir(parents=True)
        (root / "components/ScreenState.qml").write_text(screen_state(flags), encoding="utf-8")
        (root / REL).write_text(
            content_window(flags, omit_from=omit_from, clipboard_scrim=clipboard_scrim),
            encoding="utf-8",
        )
        cp = subprocess.run(
            [sys.executable, str(CHECKER), str(root), REL],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
        actual = cp.returncode == 0
        if actual != expected:
            raise SystemExit(
                f"FAIL {name}: expected={expected} actual={actual} rc={cp.returncode} stderr={cp.stderr.strip()}"
            )
        print(f"PASS {name}")


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
    print("BottomHub semantic target tests: OK")


if __name__ == "__main__":
    main()
