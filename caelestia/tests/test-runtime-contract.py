#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
build = (repo / "caelestia/bin/build-runtime.sh").read_text(encoding="utf-8")
installer = (repo / "scripts/install-caerice.sh").read_text(encoding="utf-8")
rollback = (repo / "caelestia/bin/rollback-runtime.sh").read_text(encoding="utf-8")
wrapper = (repo / "caelestia/bin/caelestia").read_text(encoding="utf-8")
composer = (repo / "caelestia/bin/compose-panels.py").read_text(encoding="utf-8")
content = (repo / "caelestia/modules-owned/modules/calendar/Content.qml").read_text(encoding="utf-8")
cli = (repo / "scripts/cortetsu").read_text(encoding="utf-8")
compatibility = json.loads((repo / "caelestia/compatibility.json").read_text(encoding="utf-8"))
composition = json.loads((repo / "caelestia/composition.json").read_text(encoding="utf-8"))

assert compatibility["project"] == "Cortetsu"
assert compatibility["caelestiaShell"]["upstreamTag"] == "v2.4.0"
assert compatibility["caelestiaShell"]["upstreamCommit"] == "24aa15eefdb146350d2548c0a015b04eddbd1008"
assert compatibility["sourceOfTruth"] == "https://github.com/DilanRC/Cortetsu.git"
assert composition["description"].startswith("Single staged Cortetsu")

for marker in (
    "CORTETSU_DATA_ROOT",
    "CORTETSU_RUNTIME_ROOT",
    "CORTETSU_UPSTREAM_SOURCE",
    'git -C "$UPSTREAM" archive',
    "STAGING=",
    "atomic_link",
    "test-calendar-credentials.py",
    "test-calendar-polish.py",
    "test-runtime-contract.py",
    "is_managed_generation",
    "legacy-previous",
    "runtime anterior sin metadatos Cortetsu",
):
    assert marker in build, marker
assert 'cp -a "$PACKAGE_ROOT' not in build
assert "/etc/xdg/quickshell/caelestia" not in build

for marker in (
    'find "$REPO/caelestia/bin" -maxdepth 1 -type f -name \'caerice-*\'',
    'canonical="cortetsu-${name#caerice-}"',
    "cortetsu-rollback",
    "install-theme-bridge.py",
    "systemctl --user daemon-reload",
    'atomic_symlink "$REPO" "$DATA_ROOT/repository"',
    'atomic_symlink "$REPO/scripts/cortetsu" "$BIN_DIR/cortetsu"',
):
    assert marker in installer, marker
assert "sudo " not in installer

for marker in (
    "atomic_link",
    "build.lock",
    "is_managed_generation",
    "BUILD.json",
    "previous no es una generación Cortetsu administrada",
):
    assert marker in rollback, marker
assert "ln -sfn" not in rollback

assert 'runtime="$runtime_root/current"' in wrapper
assert "exec /usr/bin/caelestia" in wrapper
assert "required_imports" in composer
assert "invalid composed marker count" in composer

for marker in (
    "function onCalendarChanged()",
    "requestCalendarSync(true)",
    'phase === "LONG_BREAK"',
    "eventOccursOnDate",
):
    assert marker in content, marker

for marker in (
    'LEGACY_PREVIOUS="$RUNTIME_ROOT/legacy-previous"',
    "is_managed_generation",
    "legacy-unmanaged",
    "previous no administrado por Cortetsu",
    "verify_generation current",
):
    assert marker in cli, marker

print(
    "PASS: Cortetsu staged runtime, legacy migration, installed CLI, complete helpers, "
    "safe rollback, and Calendar lifecycle contract"
)
