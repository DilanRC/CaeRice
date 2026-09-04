#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def rewrite(path: str, transform) -> None:
    target = ROOT / path
    text = target.read_text(encoding="utf-8")
    updated = transform(text)
    if updated != text:
        target.write_text(updated, encoding="utf-8")


# Remove the mechanically duplicated environment fallbacks created by the
# namespace rewrite. Cortetsu has one canonical variable per location.
for relative in [
    "caelestia/bin/build-runtime.sh",
    "caelestia/bin/rollback-runtime.sh",
    "caelestia/bin/caelestia",
    "scripts/cortetsu",
    "scripts/install-cortetsu.sh",
    "scripts/features/test-cortetsu-build.py",
]:
    path = ROOT / relative
    if not path.exists():
        continue
    text = path.read_text(encoding="utf-8")
    text = text.replace(
        '${CORTETSU_DATA_ROOT:-${CORTETSU_DATA_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/cortetsu}}',
        '${CORTETSU_DATA_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/cortetsu}',
    )
    text = text.replace(
        '${CORTETSU_RUNTIME_ROOT:-${CORTETSU_RUNTIME_ROOT:-${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/cortetsu}}',
        '${CORTETSU_RUNTIME_ROOT:-${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/cortetsu}',
    )
    text = text.replace(
        '${CORTETSU_UPSTREAM_SOURCE:-${CORTETSU_UPSTREAM_SOURCE:-$HOME/.local/share/cortetsu/upstream/upstream-git}}',
        '${CORTETSU_UPSTREAM_SOURCE:-$HOME/.local/share/cortetsu/upstream/upstream-git}',
    )
    path.write_text(text, encoding="utf-8")

# Calendar and Focus state are Cortetsu-owned, not Caelestia-owned.
def calendar(text: str) -> str:
    text = text.replace('LEGACY_SERVICE = "cortetsu-google-calendar"\n', '')
    text = text.replace(
        'config = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "caelestia"',
        'config = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "cortetsu"',
    )
    text = text.replace(
        'cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "caelestia"',
        'cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "cortetsu"',
    )
    text = re.sub(
        r'def secret_get\(\) -> str \| None:\n    current = _secret_lookup\(SERVICE\)\n    if current:\n        return current\n    legacy = _secret_lookup\(LEGACY_SERVICE\)\n    if legacy:\n        try:\n            secret_set\(legacy\)\n        except \(CalendarError, OSError, subprocess\.SubprocessError\):\n            pass\n    return legacy\n',
        'def secret_get() -> str | None:\n    return _secret_lookup(SERVICE)\n',
        text,
    )
    text = text.replace(
        '    for service in (SERVICE, LEGACY_SERVICE):\n        subprocess.run(\n            [tool, "clear", "service", service],',
        '    for service in (SERVICE,):\n        subprocess.run(\n            [tool, "clear", "service", service],',
    )
    return text

rewrite("caelestia/bin/cortetsu-calendar", calendar)
rewrite(
    "caelestia/bin/cortetsu-pomodoro",
    lambda text: text.replace('return state_home / "caelestia/pomodoro.json"', 'return state_home / "cortetsu/pomodoro.json"'),
)

# Hidden pages must be cold. Preserve user-visible cadence only while visible.
for relative, interval in [
    ("caelestia/modules-owned/modules/hardware/EnergyPage.qml", "2000"),
    ("caelestia/modules-owned/modules/hardware/PowerPage.qml", "2500"),
    ("caelestia/modules-owned/modules/hardware/PowerAutomationPage.qml", "3500"),
]:
    path = ROOT / relative
    if not path.exists():
        continue
    text = path.read_text(encoding="utf-8")
    text = text.replace(
        f"Timer {{\n        interval: {interval}\n        repeat: true\n        running: true",
        f"Timer {{\n        interval: {interval}\n        repeat: true\n        running: root.visible",
    )
    text = text.replace("    Component.onCompleted: refresh()", "    Component.onCompleted: { if (root.visible) refresh(); }\n    onVisibleChanged: { if (visible) refresh(); }")
    path.write_text(text, encoding="utf-8")

# Hub motion: restrained, fast, and tied to the upstream motion token system.
def hub_button(text: str) -> str:
    text = text.replace("scale: mouse.containsMouse ? 1.10 : 1", "scale: mouse.containsMouse ? 1.06 : 1")
    text = text.replace("duration: 110\n            easing.type: Easing.OutCubic", "duration: Tokens.anim.durations.expressiveFastSpatial\n            easing: Tokens.anim.expressiveFastSpatial")
    text = text.replace("ColorAnimation { duration: 110 }", "ColorAnimation {\n                duration: Tokens.anim.durations.expressiveFastEffects\n                easing: Tokens.anim.expressiveFastEffects\n            }")
    return text

rewrite("caelestia/modules-owned/modules/HubButton.qml", hub_button)

# Remove the legacy alias loop from the installer; canonical helpers are copied
# directly. The one-shot migration script handles old installed names safely.
def installer(text: str) -> str:
    text = text.replace("printf '==> Helpers y aliases de compatibilidad\\n'", "printf '==> Helpers Cortetsu\\n'")
    old = '''while IFS= read -r -d '' source; do\n    name="$(basename "$source")"\n    install -m 0755 "$source" "$BIN_DIR/$name"\n    canonical="cortetsu-${name#cortetsu-}"\n    atomic_symlink "$name" "$BIN_DIR/$canonical"\ndone < <(find "$REPO/caelestia/bin" -maxdepth 1 -type f -name 'cortetsu-*' -print0 | sort -z)\n\ninstall -m 0755 "$REPO/caelestia/bin/rollback-runtime.sh" "$BIN_DIR/cortetsu-rollback"\natomic_symlink "cortetsu-rollback" "$BIN_DIR/cortetsu-rollback"\n'''
    new = '''while IFS= read -r -d '' source; do\n    name="$(basename "$source")"\n    install -m 0755 "$source" "$BIN_DIR/$name"\ndone < <(find "$REPO/caelestia/bin" -maxdepth 1 -type f -name 'cortetsu-*' -print0 | sort -z)\n\ninstall -m 0755 "$REPO/caelestia/bin/rollback-runtime.sh" "$BIN_DIR/cortetsu-rollback"\n'''
    text = text.replace(old, new)
    text = text.replace(
        'printf \'==> Cortetsu: validación y construcción aislada\\n\'\n',
        'if [[ -x "$REPO/scripts/migrate-cortetsu-v2.sh" ]]; then\n    "$REPO/scripts/migrate-cortetsu-v2.sh"\nfi\n\nprintf \'==> Cortetsu: validación y construcción aislada\\n\'\n',
    )
    return text

rewrite("scripts/install-cortetsu.sh", installer)

# Current manifest: no active legacy compatibility contract.
(ROOT / "cortetsu.toml").write_text('''schema = 2\n\n[project]\nname = "Cortetsu"\nkind = "dotfiles-platform"\nstage = "v2-modern"\nsource_of_truth = "git-main"\nplatforms = ["CachyOS", "Arch Linux"]\n\n[identity]\norigin = "Coined from Cortés + tetsu (iron)."\nstyle = "samurai-inspired, restrained, technical"\ncanonical_command = "cortetsu"\n\n[stack]\ncompositor = "Hyprland"\nshell_base = "Caelestia"\nwidgets = "Quickshell"\n\n[upstream.caelestia]\npackage = "caelestia-shell"\ninstalled_version = "2.4.0-1"\ntag = "v2.4.0"\ncommit = "24aa15eefdb146350d2548c0a015b04eddbd1008"\npackage_runtime = "/etc/xdg/quickshell/caelestia"\n\n[runtime]\nmode = "versioned-user-generations"\ncurrent = "~/.config/quickshell/cortetsu/current"\nprevious = "~/.config/quickshell/cortetsu/previous"\ngenerations = "~/.local/share/cortetsu/builds"\npackage_runtime_policy = "read-only"\n\n[compatibility]\nactive_legacy = false\nhistory_only = true\n\n[entrypoints]\ncli = "scripts/cortetsu"\ninstaller = "scripts/cortetsu install"\nstatic_tests = "scripts/cortetsu test"\nruntime_verification = "scripts/cortetsu verify"\naudit = "scripts/cortetsu audit"\n\n[product]\ncurrent_modules = ["bottom-hub", "overview", "clipboard", "hardware", "display", "wallpaper", "calendar", "pomodoro"]\nretired_modules = ["gaming-center", "updater"]\nplanned_layers = ["packages", "dotfiles", "profiles", "themes", "generations", "actions", "scenes"]\n\n[safety]\nwrite_strategy = "build-validate-promote-verify"\nallow_secrets_in_git = false\nallow_blind_upstream_overwrite = false\nrequire_capability_detection = true\nrequire_real_runtime_verification = true\n''', encoding="utf-8")

print("Cortetsu v2 polish applied")
