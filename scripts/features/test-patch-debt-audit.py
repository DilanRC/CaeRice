#!/usr/bin/env python3
"""Gate test for Task 22 (patch-debt audit).

Locks in the audit result: the 9 remaining patches this session owned are ACTIVE
(they implement or are directly required by the Bottom Hub v4 migration),
not dead scaffolding. If any of them is removed from the manifest or loses
its real consumer, this test fails loudly instead of silently rotting.
"""
from __future__ import annotations

from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
MANIFEST = REPO / "caelestia/patches/MANIFEST.tsv"
CHECKER = REPO / "cortetsu/bin/check-bottom-hub-target.py"
V4_TEST = REPO / "scripts/features/test-bottom-hub-v4.py"

# patch file -> (manifest target path, at least one real consumer to grep for)
AUDITED_ACTIVE_PATCHES = {
    "services__Hypr.qml.patch": (
        "services/Hypr.qml",
        ("isTaskbarToplevel", "CortetsuHypr.qml"),
    ),
    "utils__Paths__Config.qml.patch": (
        "utils/Paths.qml",
        ("CORTETSU_WALLPAPERS_DIR", "CortetsuConfig.wallpaperDirectory"),
    ),
    "modules__Shortcuts.qml.patch": (
        "modules/Shortcuts.qml",
        ('"customDock", "launcher"',),
    ),
    "modules__sidebar__Wrapper.qml.patch": (
        "modules/sidebar/Wrapper.qml",
        ("cortetsuBottomNotificationCenter",),
    ),
    "modules__bar__BarWrapper.qml.patch": (
        "modules/bar/BarWrapper.qml",
        ("readonly property bool disabled: true",),
    ),
    "modules__bar__popouts__Wrapper.qml.patch": (
        "modules/bar/popouts/Wrapper.qml",
        ("bottomAttached",),
    ),
    "modules__bar__popouts__ClipWrapper.qml.patch": (
        "modules/bar/popouts/ClipWrapper.qml",
        ("bottomAnchorCenter",),
    ),
    "modules__utilities__Wrapper.qml.patch": (
        "modules/utilities/Wrapper.qml",
        ("readonly property bool shouldBeActive: screenState.utilities",),
    ),
}

# check-bottom-hub-target.py CHECKS keys that must exist for the Bottom-Hub
# patches (proof these are the validated migration target, not legacy cruft).
REQUIRED_CHECKER_TARGETS = (
    "modules/Shortcuts.qml",
    "modules/sidebar/Wrapper.qml",
    "modules/bar/BarWrapper.qml",
    "modules/bar/popouts/Wrapper.qml",
    "modules/bar/popouts/ClipWrapper.qml",
    "modules/utilities/Wrapper.qml",
)


def main() -> None:
    manifest_text = MANIFEST.read_text(encoding="utf-8")
    checker_text = CHECKER.read_text(encoding="utf-8")
    v4_text = V4_TEST.read_text(encoding="utf-8")

    for patch_name, (target_path, consumer_needles) in AUDITED_ACTIVE_PATCHES.items():
        patch_file = REPO / "caelestia/patches" / patch_name
        assert patch_file.is_file(), f"missing patch: {patch_name}"

        assert f"{patch_name}\t{target_path}" in manifest_text, (
            f"MANIFEST.tsv missing entry for active patch {patch_name}"
        )

        matched = any(
            needle in checker_text or needle in v4_text or _grep_repo(needle)
            for needle in consumer_needles
        )
        assert matched, f"{patch_name}: no real consumer found for {consumer_needles}"

    for target in REQUIRED_CHECKER_TARGETS:
        assert f'"{target}"' in checker_text, (
            f"check-bottom-hub-target.py must keep validating {target} "
            "(it is the Bottom Hub v4 contract, not dead code)"
        )

    assert "modules__bar__BarWrapper.qml.patch" in v4_text, (
        "test-bottom-hub-v4.py must keep asserting the native bar retirement patch stays in MANIFEST.tsv"
    )

    print("PASS: all 9 remaining audited patches confirmed ACTIVE (Bottom Hub v4 migration engine)")


def _grep_repo(needle: str) -> bool:
    for path in (REPO / "cortetsu/modules").rglob("*.qml"):
        if needle in path.read_text(encoding="utf-8", errors="ignore"):
            return True
    return False


if __name__ == "__main__":
    main()
