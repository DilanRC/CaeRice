#!/usr/bin/env python3
"""Guard launcher applications against Cortetsu shell cgroup ownership."""

from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
PATCH = REPO / "caelestia/patches/modules__launcher__services__Apps.qml.patch"
MANIFEST = REPO / "caelestia/patches/MANIFEST.tsv"

text = PATCH.read_text(encoding="utf-8")
manifest = MANIFEST.read_text(encoding="utf-8")

assert "--- a/modules/launcher/services/Apps.qml" in text
assert '"systemd-run"' in text
for token in ('"--user"', '"--scope"', '"--collect"', '"--unit"', '"--"'):
    assert token in text, f"falta opción de scope: {token}"
assert "+            entry.execute();" not in text
assert "entry.workingDirectory" in text
assert "Date.now()" in text
assert "modules__launcher__services__Apps.qml.patch\tmodules/launcher/services/Apps.qml" in manifest

print("PASS: launcher applications use independent systemd scopes")
