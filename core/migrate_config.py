#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shutil
import tempfile
from datetime import datetime, timezone
from pathlib import Path


def config_home(home: Path) -> Path:
    return Path(os.environ.get("XDG_CONFIG_HOME", home / ".config")).expanduser()


def data_home(home: Path) -> Path:
    return Path(os.environ.get("XDG_DATA_HOME", home / ".local/share")).expanduser()


def payload_from_legacy(path: Path) -> dict[str, object]:
    data = json.loads(path.read_text(encoding="utf-8"))
    launcher = data.get("launcher", {})
    bar = data.get("bar", {})
    workspaces = bar.get("workspaces", {})
    tray = bar.get("tray", {})
    apps = data.get("general", {}).get("apps", {})
    shown = workspaces.get("shown", 5)
    try:
        shown = max(1, min(20, int(shown)))
    except (TypeError, ValueError):
        shown = 5
    return {
        "schema": 1,
        "favouriteApps": [x for x in launcher.get("favouriteApps", []) if isinstance(x, str)],
        "hiddenTrayIcons": [x for x in tray.get("hiddenIcons", []) if isinstance(x, str)],
        "terminalCommand": [x for x in apps.get("terminal", ["kitty"]) if isinstance(x, str)],
        "workspacesShown": shown,
    }


def atomic_write(path: Path, payload: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=path.parent, delete=False) as handle:
        temporary = Path(handle.name)
        json.dump(payload, handle, indent=2)
        handle.write("\n")
    os.chmod(temporary, 0o600)
    os.replace(temporary, path)


def migrate(home: Path, target: Path | None = None, data_root: Path | None = None) -> int:
    home = home.expanduser().resolve()
    target = target or config_home(home) / "cortetsu/preferences.json"
    data_root = data_root or data_home(home) / "cortetsu"
    legacy = config_home(home) / "caelestia/shell.json"

    if target.exists():
        json.loads(target.read_text(encoding="utf-8"))
        print(f"PASS: Cortetsu preferences already exist: {target}")
        return 0
    if not legacy.is_file():
        print("PASS: no legacy shell preferences to migrate")
        return 0

    payload = payload_from_legacy(legacy)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    backup = data_root / "migrations" / stamp / "preferences" / "legacy-shell.json"
    backup.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(legacy, backup)
    atomic_write(target, payload)
    print(f"MIGRATED preferences={target}")
    print(f"BACKUP preferences={backup}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Migrate functional preferences to Cortetsu XDG config")
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument("--target", type=Path)
    parser.add_argument("--data-root", type=Path)
    args = parser.parse_args()
    return migrate(args.home, args.target, args.data_root)


if __name__ == "__main__":
    raise SystemExit(main())
