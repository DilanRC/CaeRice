#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
MODULES = REPO / "caelestia/modules-owned/modules"

scripts = [
    "scripts/features/audit-theme-colours.py",
    "scripts/features/validate-clipboard-qml.py",
    "scripts/features/validate-hardware-center.py",
    "scripts/features/validate-display-manager.py",
    "scripts/features/test-wallpaper-manager.py",
    "scripts/features/test-diagnose-sad-wiring.py",
    "scripts/features/test-wire-sad-shell.py",
    "scripts/features/test-bottom-hub-target.py",
    "scripts/features/test-retained-overlay-wiring.py",
]

retired_paths = [
    "caelestia/modules-owned/modules/GamingController.qml",
    "caelestia/modules-owned/modules/gaming",
    "caelestia/modules-owned/modules/UpdaterController.qml",
    "caelestia/modules-owned/modules/updater",
    "caelestia/bin/caerice-gaming-probe",
    "caelestia/bin/caerice-gaming-profile",
    "caelestia/bin/caerice-upstream-audit",
    "caelestia/bin/caerice-updater",
    "caelestia/bin/caerice-updater-commit-base",
    "scripts/features/install-gaming-center.sh",
    "scripts/features/update-gaming-center.sh",
    "scripts/features/validate-gaming-center.py",
    "scripts/features/test-gaming-appid.py",
    "scripts/features/install-caerice-updater.sh",
    "scripts/features/update-caerice-updater.sh",
    "scripts/features/validate-caerice-updater.py",
    "scripts/features/test-updater-ref-injection.py",
]

failed: list[str] = []

print("===== SAD CONSOLIDATED VALIDATION =====")
for rel in scripts:
    path = REPO / rel
    if not path.is_file():
        print("MISSING", rel)
        failed.append(rel)
        continue
    cp = subprocess.run(
        [sys.executable, str(path)],
        cwd=REPO,
        text=True,
        capture_output=True,
        check=False,
    )
    print(f"\n--- {rel} ---")
    print(cp.stdout, end="")
    if cp.stderr:
        print(cp.stderr, end="")
    if cp.returncode != 0:
        failed.append(rel)

print("\n--- retired centers repository guard ---")
retired_found = [rel for rel in retired_paths if (REPO / rel).exists()]
if retired_found:
    for rel in retired_found:
        print("ERROR: retired Gaming/Updater artifact still exists:", rel)
    failed.append("retired-centers-repository-guard")
else:
    print("Gaming/Updater repository artifacts: absent")

separator_re = re.compile(r"}\s*;\s*[A-Za-z_][A-Za-z0-9_.]*\s*{")
qml_separator_errors: list[str] = []
if MODULES.is_dir():
    for path in sorted(MODULES.rglob("*.qml")):
        text = path.read_text(encoding="utf-8")
        match = separator_re.search(text)
        if match:
            line = text.count("\n", 0, match.start()) + 1
            qml_separator_errors.append(f"{path.relative_to(REPO)}:{line}")

print("\n--- global QML structural guard ---")
if qml_separator_errors:
    for item in qml_separator_errors:
        print("ERROR: invalid semicolon between declarative QML child objects:", item)
    failed.append("global-qml-structural-guard")
else:
    print("QML child-object separator scan: OK")

if failed:
    print("\nSAD STATUS: FAIL")
    print("failed:", ", ".join(failed))
    raise SystemExit(1)

print("\nSAD STATUS: OK")
