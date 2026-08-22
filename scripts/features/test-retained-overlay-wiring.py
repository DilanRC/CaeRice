#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]

spec = importlib.util.spec_from_file_location(
    "bottom_hub_target",
    REPO / "caelestia/bin/check-bottom-hub-target.py",
)
assert spec and spec.loader
bottom_hub_target = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bottom_hub_target)

from wire_sad_shell import ensure_or_member, ensure_statement


def base_content() -> str:
    return '''StyledWindow {
    onHasFullscreenChanged: {
        screenState.launcher = false;
        screenState.session = false;
        screenState.dashboard = false;
        screenState.overview = false;
        panels.popouts.close();
    }

    WlrLayershell.layer: screenState.overview ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: screenState.overview || screenState.launcher || screenState.session ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: screenState.overview ? null : (hasFullscreen ? emptyRegion : regions)

    HyprlandFocusGrab {
        active: {
            if (s.overview)
                return true;
            return false;
        }
        windows: [root]
        onCleared: {
            root.screenState.overview = false;
            panels.popouts.hasCurrent = false;
        }
    }

    StyledRect {
        opacity: root.screenState.overview ? 0.58 : (root.screenState.clipboard ? 0.48 : 0)
    }
}
'''


def wire_flag(texts: dict[str, str], flag: str) -> None:
    ensure_statement(
        texts,
        "content",
        "    onHasFullscreenChanged: {",
        "\n        panels.popouts.close();",
        f"        screenState.{flag} = false;",
    )
    ensure_or_member(
        texts,
        "content",
        "WlrLayershell.layer: screenState.overview",
        " ? WlrLayer.Overlay",
        f"screenState.{flag}",
    )
    ensure_or_member(
        texts,
        "content",
        "WlrLayershell.keyboardFocus: screenState.overview",
        " || screenState.launcher",
        f"screenState.{flag}",
    )
    ensure_or_member(
        texts,
        "content",
        "mask: screenState.overview",
        " ? null",
        f"screenState.{flag}",
    )
    ensure_or_member(
        texts,
        "content",
        "if (s.overview",
        ")\n                return true;",
        f"s.{flag}",
    )
    ensure_statement(
        texts,
        "content",
        "        onCleared: {",
        "\n            panels.popouts.hasCurrent = false;",
        f"            root.screenState.{flag} = false;",
    )


def screen_state(flags: tuple[str, ...]) -> str:
    return "Item {\n" + "".join(f"    property bool {flag}\n" for flag in flags) + "}\n"


def validate_content(text: str, flags: tuple[str, ...]) -> bool:
    with tempfile.TemporaryDirectory(prefix="retained-overlay-") as td:
        root = Path(td)
        (root / "components").mkdir(parents=True)
        (root / "components/ScreenState.qml").write_text(screen_state(flags), encoding="utf-8")
        return bottom_hub_target.check_content_window(root, text)


def main() -> None:
    texts = {"content": base_content()}
    for flag in ("clipboard", "hardware", "displayManager"):
        wire_flag(texts, flag)

    expected_flags = ("overview", "clipboard", "hardware", "displayManager")
    if not validate_content(texts["content"], expected_flags):
        raise SystemExit("FAIL: sequential retained overlay wiring did not satisfy BottomHub invariants")
    print("PASS sequential-composition")

    before = texts["content"]
    wire_flag(texts, "clipboard")
    wire_flag(texts, "hardware")
    if texts["content"] != before:
        raise SystemExit("FAIL: re-running Clipboard/Hardware wiring changed an already-composed ContentWindow")
    print("PASS composed-idempotency")

    # A later Display member must survive re-running the older installers.
    for needle in (
        "screenState.displayManager ? WlrLayer.Overlay",
        "screenState.displayManager || screenState.launcher",
        "screenState.displayManager ? null",
        "s.displayManager)",
        "root.screenState.displayManager = false;",
    ):
        if needle not in texts["content"]:
            raise SystemExit(f"FAIL: retained Display member lost after idempotent wiring: {needle}")
    print("PASS later-overlay-preserved")

    print("Retained overlay wiring tests: OK")


if __name__ == "__main__":
    main()
