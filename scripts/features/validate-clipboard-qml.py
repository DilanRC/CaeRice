#!/usr/bin/env python3
from pathlib import Path
import sys

repo = Path(__file__).resolve().parents[2]
qml_dir = repo / "caelestia/modules-owned/modules/clipboard"

errors = []
for path in sorted(qml_dir.glob("*.qml")):
    text = path.read_text(encoding="utf-8")

    if "Colours." in text and "import qs.services" not in text:
        errors.append(f"{path.relative_to(repo)}: usa Colours pero no importa qs.services")

    if "Tokens." in text and "import Caelestia.Config" not in text:
        errors.append(f"{path.relative_to(repo)}: usa Tokens pero no importa Caelestia.Config")

if errors:
    print("VALIDATION FAILED")
    for error in errors:
        print(f"  - {error}")
    sys.exit(1)

print("Clipboard QML static validation: OK")
