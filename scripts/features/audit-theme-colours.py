#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
TARGETS = [
    REPO / "caelestia/modules-owned/modules/CustomDock.qml",
    REPO / "caelestia/modules-owned/modules/clipboard",
    REPO / "caelestia/modules-owned/modules/overview",
    REPO / "caelestia/patches/modules__launcher__AppList.qml.patch",
    REPO / "caelestia/patches/modules__launcher__Content.qml.patch",
    REPO / "caelestia/patches/modules__launcher__ContentList.qml.patch",
    REPO / "caelestia/patches/modules__launcher__Wrapper.qml.patch",
]

HEX = re.compile(r"#[0-9a-fA-F]{3,8}\b")
NAMED = re.compile(r'(?i)["\'](?:black|white)["\']')
RAW_COLOUR = re.compile(r'\bcolor\s*:\s*["\'](?!transparent["\'])[^"\']+["\']')
ALPHA = re.compile(r"\bQt\.alpha\s*\(")
LIGHTER = re.compile(r"\bQt\.lighter\s*\(")
OPACITY = re.compile(r"\bopacity\s*:\s*(?:0(?:\.\d+)?|1(?:\.0+)?)\b")


def files():
    for target in TARGETS:
        if target.is_file():
            yield target
        elif target.is_dir():
            yield from sorted(target.rglob("*.qml"))


def main() -> None:
    blockers = []
    review = []
    print("===== CORTETSU THEME AUDIT =====")
    for path in files():
        rel = path.relative_to(REPO)
        for no, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            stripped = line.strip()
            if not stripped or stripped.startswith("//") or stripped.startswith("*"):
                continue
            if HEX.search(line) or NAMED.search(line) or RAW_COLOUR.search(line):
                blockers.append((rel, no, stripped))
            elif ALPHA.search(line) or LIGHTER.search(line) or OPACITY.search(line):
                review.append((rel, no, stripped))

    print("\nBLOCKERS: hardcoded hex/named/raw colour strings")
    if not blockers:
        print("  none")
    else:
        for rel, no, line in blockers:
            print(f"  {rel}:{no}: {line}")

    print("\nREVIEW: alpha/lighter/opacity (may be intentional)")
    if not review:
        print("  none")
    else:
        for rel, no, line in review:
            print(f"  {rel}:{no}: {line}")

    print("\nSUMMARY")
    print("  blockers:", len(blockers))
    print("  review:", len(review))
    print("  palette source expected: Colours.palette / Colours.tPalette / Tokens")

    if blockers:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
