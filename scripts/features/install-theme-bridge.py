#!/usr/bin/env python3
from __future__ import annotations

import json
import shutil
from pathlib import Path

HOME = Path.home()
REPO = Path(__file__).resolve().parents[2]
CLI_JSON = HOME / ".config/caelestia/cli.json"
KITTY_CONF = HOME / ".config/kitty/kitty.conf"
KITTY_TEMPLATE = REPO / "caelestia/templates/kitty-cortetsu.conf"


def read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    obj = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(obj, dict):
        raise SystemExit(f"ERROR: {path} no contiene un objeto JSON")
    return obj


def write_json(path: Path, obj: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(obj, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    tmp.replace(path)


def main() -> None:
    cfg = read_json(CLI_JSON)
    theme = cfg.setdefault("theme", {})
    if not isinstance(theme, dict):
        raise SystemExit("ERROR: theme en cli.json no es objeto")

    for key in ("enableTerm", "enableHypr", "enableGtk", "enableQt"):
        theme[key] = True

    optional = {
        "enableChromium": ("brave", "chromium", "google-chrome-stable"),
        "enableSpicetify": ("spicetify",),
        "enableBtop": ("btop",),
        "enableNvtop": ("nvtop",),
        "enableHtop": ("htop",),
        "enableCava": ("cava",),
        "enableFuzzel": ("fuzzel",),
        "enableDiscord": ("discord", "vesktop", "equibop"),
        "enableZed": ("zed",),
    }
    for key, commands in optional.items():
        if any(shutil.which(cmd) for cmd in commands):
            theme[key] = True

    write_json(CLI_JSON, cfg)

    target = HOME / ".config/caelestia/templates/kitty-cortetsu.conf"
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(KITTY_TEMPLATE, target)

    KITTY_CONF.parent.mkdir(parents=True, exist_ok=True)
    text = KITTY_CONF.read_text(encoding="utf-8") if KITTY_CONF.exists() else ""
    include = "include ~/.local/state/caelestia/theme/kitty-cortetsu.conf"
    if include not in text:
        if text and not text.endswith("\n"):
            text += "\n"
        text += "\n# Cortetsu: Caelestia active scheme\n" + include + "\n"
        KITTY_CONF.write_text(text, encoding="utf-8")

    print("Theme bridge: OK")
    print(json.dumps(theme, indent=2, ensure_ascii=False))
    print("Kitty template:", target)


if __name__ == "__main__":
    main()
