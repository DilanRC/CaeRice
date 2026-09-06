#!/usr/bin/env python3
"""Guard launcher applications against Cortetsu shell cgroup ownership."""

from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
# Launched from a Caelestia patch on top of upstream services/Apps.qml;
# now a first-party file owned outright under cortetsu/modules/launcher.
SOURCE = REPO / "cortetsu/modules/launcher/services/Apps.qml"
MANIFEST = REPO / "caelestia/patches/MANIFEST.tsv"

text = SOURCE.read_text(encoding="utf-8")
manifest = MANIFEST.read_text(encoding="utf-8")

assert '"systemd-run"' in text
for token in ('"--user"', '"--scope"', '"--collect"', '"--unit"', '"--"'):
    assert token in text, f"falta opción de scope: {token}"
assert "entry.execute();" not in text
assert "entry.workingDirectory" in text
assert "Date.now()" in text
assert "function isSteamCommand(command: list<string>): bool" in text
assert "root.launchDetached(entry, command);" in text
assert 'token.endsWith("/steam")' in text
assert "GlobalConfig" not in text
assert "CortetsuConfig.terminalCommand" in text
assert "modules__launcher__services__Apps.qml.patch" not in manifest

print("PASS: launcher applications use independent scopes; Steam stays detached")
