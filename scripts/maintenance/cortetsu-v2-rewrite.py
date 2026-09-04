#!/usr/bin/env python3
"""One-shot Cortetsu v2 repository namespace migration.

This script is intentionally deleted by the workflow after it rewrites the tree.
Historical/provenance documents are preserved verbatim under docs/history.
"""
from __future__ import annotations

import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def run(*args: str) -> None:
    subprocess.run(["git", *args], cwd=ROOT, check=True)


def rename_token(value: str) -> str:
    return (
        value.replace("CAERICE", "CORTETSU")
        .replace("CaeRice", "Cortetsu")
        .replace("Caerice", "Cortetsu")
        .replace("caerice", "cortetsu")
    )


# Preserve historical truth instead of rewriting it into fake Cortetsu history.
history_moves = {
    "docs/MIGRATION_FROM_CAERICE.md": "docs/history/MIGRATION_FROM_CAERICE.md",
    "docs/RECONCILIATION_2026-08-28.md": "docs/history/RECONCILIATION_2026-08-28.md",
}
for source, destination in history_moves.items():
    if (ROOT / source).exists():
        (ROOT / destination).parent.mkdir(parents=True, exist_ok=True)
        run("mv", source, destination)

# Rename every active tracked path carrying the retired namespace.
paths = git("ls-files", "-z").split("\0")
for source in sorted((p for p in paths if p), key=lambda p: p.count("/"), reverse=True):
    if source.startswith("docs/history/") or source == "docs/PROVENANCE.md":
        continue
    destination = rename_token(source)
    if destination != source and (ROOT / source).exists():
        (ROOT / destination).parent.mkdir(parents=True, exist_ok=True)
        run("mv", source, destination)

# Rewrite active text. Keep external/upstream Caelestia identifiers where they
# genuinely refer to the upstream project, but make all Cortetsu-owned runtime
# and state namespaces canonical.
replacements = (
    ("CAERICE", "CORTETSU"),
    ("CaeRice", "Cortetsu"),
    ("Caerice", "Cortetsu"),
    ("caerice", "cortetsu"),
    ("${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia", "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/cortetsu"),
    ("~/.config/quickshell/caelestia", "~/.config/quickshell/cortetsu"),
    ("$HOME/.config/quickshell/caelestia", "$HOME/.config/quickshell/cortetsu"),
    (".local/share/caelestia-custom-system", ".local/share/cortetsu/upstream"),
    ("caelestia-custom-system", "cortetsu/upstream"),
)

skip = {
    "docs/PROVENANCE.md",
    "scripts/maintenance/cortetsu-v2-rewrite.py",
}
for relative in (p for p in git("ls-files").splitlines() if p):
    if relative in skip or relative.startswith("docs/history/"):
        continue
    path = ROOT / relative
    if not path.is_file():
        continue
    raw = path.read_bytes()
    if b"\0" in raw:
        continue
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        continue
    updated = text
    for old, new in replacements:
        updated = updated.replace(old, new)
    if updated != text:
        path.write_text(updated, encoding="utf-8")

print("Cortetsu v2 namespace rewrite prepared")
