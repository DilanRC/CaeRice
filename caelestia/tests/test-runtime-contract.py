#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

repo = Path(__file__).resolve().parents[2]
build = (repo / "caelestia/bin/build-runtime.sh").read_text(encoding="utf-8")
ensure_upstream = (repo / "caelestia/bin/ensure-upstream.sh").read_text(encoding="utf-8")
installer = (repo / "scripts/install-cortetsu.sh").read_text(encoding="utf-8")
migration = (repo / "scripts/migrate-cortetsu-v2.sh").read_text(encoding="utf-8")
legacy_process_migration = (repo / "core/migrate_legacy_processes.py").read_text(encoding="utf-8")
wallpaper_daemon = (repo / "caelestia/bin/cortetsu-wallpaper-color-daemon").read_text(encoding="utf-8")
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
assert compatibility["caelestiaShell"]["upstreamRepo"] == "https://github.com/caelestia-dots/shell.git"
assert compatibility["sourceOfTruth"] == "https://github.com/DilanRC/Cortetsu.git"
assert composition["description"].startswith("Single staged Cortetsu")

for marker in (
    "CORTETSU_DATA_ROOT", "CORTETSU_RUNTIME_ROOT", "ensure-upstream.sh",
    'git -C "$UPSTREAM" archive', "STAGING=", "atomic_link",
    "test-calendar-credentials.py", "test-calendar-polish.py", "test-runtime-contract.py",
    "is_managed_generation",
):
    assert marker in build, marker
assert 'cp -a "$PACKAGE_ROOT' not in build
assert "/etc/xdg/quickshell/caelestia" not in build
assert "CAERICE_" not in build and "caerice-" not in build

for marker in (
    "CORTETSU_UPSTREAM_SOURCE",
    "CORTETSU_UPSTREAM_CACHE",
    "caelestia-custom-system/upstream-git",
    "repo_has_exact_base",
    "git clone --local --no-checkout",
    "git -C \"$path\" fetch --force --depth=1 origin",
    "https://github.com/caelestia-dots/shell.git",
):
    assert marker in ensure_upstream, marker

for marker in (
    "scripts/migrate-cortetsu-v2.sh",
    'find "$REPO/caelestia/bin" -maxdepth 1 -type f -name \'cortetsu-*\'',
    "cortetsu-rollback",
    'core/theme.py" check',
    'core/theme.py" adopt',
    "systemctl --user daemon-reload",
    'atomic_symlink "$REPO" "$DATA_ROOT/repository"',
    'atomic_symlink "$REPO/scripts/cortetsu" "$BIN_DIR/cortetsu"',
):
    assert marker in installer, marker
assert "install-theme-bridge.py" not in installer
assert "canonical=" not in installer
assert "sudo " not in installer
assert "legacy-processes) legacy_processes_cmd" in cli

for marker in (
    'calendar-client.json" "$CONFIG_HOME/cortetsu/calendar-client.json"',
    'pomodoro.json" "$STATE_HOME/cortetsu/pomodoro.json"',
    'for old in "$HOME"/.local/bin/caerice-*',
    'OLD_UNIT="caerice-power-auto.service"',
    'BACKUP="$DATA_ROOT/migrations/$STAMP"',
):
    assert marker in migration, marker

for marker in ("legacy-processes.lock", "DEFERRED", "NO_PROCESS_SIGNALING", "caerice-pomodoro", "caelestia-wallpaper-color-daemon"):
    assert marker in legacy_process_migration, marker
assert "pkill" not in legacy_process_migration and "killpg" not in legacy_process_migration
assert "flock -n 9" in wallpaper_daemon and "caelestia-wallpaper-color-daemon" not in wallpaper_daemon
apply_wallpaper = (repo / "caelestia/bin/cortetsu-apply-wallpaper-colors").read_text(encoding="utf-8")
assert "cortetsu-scheme-posthook" not in apply_wallpaper

for marker in (
    "atomic_link", "build.lock", "is_managed_generation", "BUILD.json",
    "previous no es una generación Cortetsu administrada",
):
    assert marker in rollback, marker
assert "ln -sfn" not in rollback

assert 'runtime="$runtime_root/current"' in wrapper
assert "/quickshell/cortetsu" in wrapper
assert "exec /usr/bin/caelestia" in wrapper
assert "required_imports" in composer and "invalid composed marker count" in composer

for marker in (
    "function onCalendarChanged()", "requestCalendarSync(true)",
    'phase === "LONG_BREAK"', "eventOccursOnDate",
):
    assert marker in content, marker

for marker in (
    "is_managed_generation", "verify_generation current", "CORTETSU_RUNTIME_ROOT",
    "theme_cmd check",
):
    assert marker in cli, marker
assert "CAERICE_" not in cli and "caerice-" not in cli

print("PASS: Cortetsu v2 canonical namespace, self-healing upstream, staged runtime, native theme ownership, migration, helpers and rollback contract")
