#!/usr/bin/env python3
"""Remove only Cortetsu-replaced wallpaper actions from a Caelestia JSON config."""
from __future__ import annotations

import argparse
import json
import os
import stat
import shutil
import tempfile
from pathlib import Path

REPLACED = {"Wallpaper", "Random"}
DEFAULT_RETAINED = [
    ("Calculator", "calculate", "Do simple math equations (powered by Qalc)", ["autocomplete", "calc"]),
    ("Scheme", "palette", "Change the current colour scheme", ["autocomplete", "scheme"]),
    ("Variant", "colors", "Change the current scheme variant", ["autocomplete", "variant"]),
    ("Light", "light_mode", "Change the scheme to light mode", ["setMode", "light"]),
    ("Dark", "dark_mode", "Change the scheme to dark mode", ["setMode", "dark"]),
    ("Shutdown", "power_settings_new", "Shutdown the system", ["poweroff"]),
    ("Reboot", "cached", "Reboot the system", ["reboot"]),
    ("Logout", "exit_to_app", "Log out of the current session", ["logout"]),
    ("Lock", "lock", "Lock the current session", ["loginctl", "lock-session"]),
    ("Sleep", "bedtime", "Suspend then hibernate", ["suspendThenHibernate"]),
    ("Settings", "settings", "Configure the shell", ["caelestia", "shell", "nexus", "open"]),
]


def default_actions() -> list[dict]:
    result = []
    for name, icon, description, command in DEFAULT_RETAINED:
        action = {"name": name, "icon": icon, "description": description, "command": command}
        if name in {"Shutdown", "Reboot", "Logout"}:
            action["dangerous"] = True
        result.append(action)
    return result


def transform(config: dict) -> tuple[dict, bool]:
    launcher = config.setdefault("launcher", {})
    current = launcher.get("actions")
    if current is None:
        launcher["actions"] = default_actions()
        return config, True
    if not isinstance(current, list):
        raise ValueError("launcher.actions must be an array")
    retained = [item for item in current if not isinstance(item, dict) or item.get("name") not in REPLACED]
    if retained == current:
        return config, False
    launcher["actions"] = retained
    return config, True


def atomic_write(path: Path, payload: str) -> None:
    mode = stat.S_IMODE(path.stat().st_mode)
    fd, name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(payload)
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(name, mode)
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def configure(path: Path, backup_dir: Path | None = None, dry_run: bool = False) -> bool:
    config = json.loads(path.read_text(encoding="utf-8"))
    config, changed = transform(config)
    if not changed or dry_run:
        return changed
    if backup_dir:
        backup_dir.mkdir(parents=True, exist_ok=True)
        timestamped_backup = Path(tempfile.mkdtemp(prefix="wallpaper-manager-", dir=backup_dir))
        shutil.copy2(path, timestamped_backup / path.name)
    atomic_write(path, json.dumps(config, ensure_ascii=False, indent=2) + "\n")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--backup-dir", type=Path, help="parent for a timestamped rollback backup")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    if not args.dry_run and not args.backup_dir:
        parser.error("--backup-dir is required unless --dry-run is used")
    changed = configure(args.config, args.backup_dir, args.dry_run)
    print(json.dumps({"ok": True, "changed": changed, "dryRun": args.dry_run}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
