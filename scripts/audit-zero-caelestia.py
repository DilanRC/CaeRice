#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from pathlib import Path


PATTERNS = {
    "GlobalConfig": re.compile(r"\bGlobalConfig\b"),
    "Caelestia.Config": re.compile(r"\bCaelestia\.Config\b"),
    "Caelestia import": re.compile(r"^\s*import\s+Caelestia(?:\.|\s|$)", re.MULTILINE),
    "qs.services": re.compile(r"^\s*import\s+qs\.services(?:\.|\s|$)", re.MULTILINE),
    "qs.components": re.compile(r"^\s*import\s+qs\.components(?:\.|\s|$)", re.MULTILINE),
    "Colours": re.compile(r"\bColours\b"),
    "Tokens": re.compile(r"\bTokens\b"),
    "StyledRect": re.compile(r"\bStyledRect\b"),
    "StyledText": re.compile(r"\bStyledText\b"),
    "MaterialIcon": re.compile(r"\bMaterialIcon\b"),
    "caelestia CLI": re.compile(r"(?<![A-Za-z0-9_-])caelestia(?:\s|$)"),
    "caelestia IPC": re.compile(r"caelestia:"),
    "caelestia path": re.compile(r"(?:/|\$\{?[^}\s]*)(?:\.config/)?(?:quickshell/)?caelestia(?:/|\b)"),
}

ACTIVE_ROOTS = (
    "caelestia/modules-owned",
    "caelestia/patches",
    "caelestia/bin",
    "config",
    "core",
    "scripts",
)

EXCLUDED_PARTS = {"tests", "evals", "history", "historical", "recovery", "__pycache__"}
TEXT_SUFFIXES = {"", ".qml", ".js", ".py", ".sh", ".fish", ".service", ".tsv", ".json", ".patch", ".conf"}


def active_files(root: Path):
    for relative_root in ACTIVE_ROOTS:
        base = root / relative_root
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if not path.is_file() or path.suffix not in TEXT_SUFFIXES:
                continue
            relative = path.relative_to(root)
            if EXCLUDED_PARTS.intersection(relative.parts):
                continue
            if relative == Path("scripts/audit-zero-caelestia.py"):
                continue
            if relative.parts[:2] == ("scripts", "features"):
                continue
            yield path


def audit(root: Path) -> dict[str, list[str]]:
    findings = {name: [] for name in PATTERNS}
    for path in active_files(root):
        text = path.read_text(encoding="utf-8", errors="ignore")
        relative = path.relative_to(root)
        if path.suffix == ".patch":
            continue
        for name, pattern in PATTERNS.items():
            for match in pattern.finditer(text):
                line = text.count("\n", 0, match.start()) + 1
                findings[name].append(f"{relative}:{line}")
    patches = sorted((root / "caelestia/patches").glob("*.patch"))
    if patches:
        findings["Caelestia patches"] = [str(path.relative_to(root)) for path in patches]
    return {name: paths for name, paths in findings.items() if paths}


def main() -> int:
    parser = argparse.ArgumentParser(description="Fail when operational Cortetsu code depends on Caelestia")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--quiet", action="store_true")
    args = parser.parse_args()
    findings = audit(args.root.resolve())
    if not args.quiet:
        for name, paths in findings.items():
            print(f"{name}: {len(paths)}")
            for path in paths[:10]:
                print(f"  {path}")
    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main())
