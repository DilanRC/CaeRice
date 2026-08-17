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
    "scripts/features/validate-gaming-center.py",
    "scripts/features/validate-caerice-updater.py",
]
failed: list[str] = []

print("===== SAD CONSOLIDATED VALIDATION =====")
for rel in scripts:
    path = REPO / rel
    if not path.is_file():
        print("MISSING", rel)
        failed.append(rel)
        continue
    cp = subprocess.run([sys.executable, str(path)], cwd=REPO, text=True, capture_output=True, check=False)
    print(f"\n--- {rel} ---")
    print(cp.stdout, end="")
    if cp.stderr:
        print(cp.stderr, end="")
    if cp.returncode != 0:
        failed.append(rel)

# Cross-center structural QML guard. Semantic validators can miss parser errors
# when compact declarative child objects are separated with a JavaScript-style
# semicolon, e.g. `StateLayer { ... }; StyledText { ... }`.
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
