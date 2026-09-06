#!/usr/bin/env python3
from __future__ import annotations

import configparser
import json
import os
import shutil
import subprocess
from pathlib import Path

HOME = Path.home()


def section(name: str) -> None:
    print(f"\n===== {name} =====")


def load_json(path: Path):
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        return {"__error__": str(exc)}


def desktop_entries():
    roots = [
        HOME / ".local/share/applications",
        Path("/usr/local/share/applications"),
        Path("/usr/share/applications"),
    ]
    entries = []
    for root in roots:
        if not root.is_dir():
            continue
        for path in sorted(root.glob("*.desktop")):
            parser = configparser.ConfigParser(interpolation=None, strict=False)
            parser.optionxform = str
            try:
                parser.read(path, encoding="utf-8")
                sec = parser["Desktop Entry"]
            except Exception:
                continue
            if sec.get("NoDisplay", "false").lower() == "true":
                continue
            entries.append({
                "id": path.name,
                "name": sec.get("Name", ""),
                "exec": sec.get("Exec", ""),
                "wmclass": sec.get("StartupWMClass", ""),
            })
    return entries


shell_json = HOME / ".config/caelestia/shell.json"
cli_json = HOME / ".config/caelestia/cli.json"
scheme_json = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "cortetsu/scheme.json"

section("CURRENT SCHEME")
scheme = load_json(scheme_json)
if not scheme:
    print(f"No existe {scheme_json}")
elif "__error__" in scheme:
    print("JSON ERROR:", scheme["__error__"])
else:
    for key in ("name", "flavour", "mode", "variant", "background", "surface", "primary", "secondary"):
        if key in scheme:
            print(f"{key}: {scheme[key]}")

section("INSTALLED SCHEME FAMILIES")
roots = []
for base in Path("/usr/lib").glob("python*/site-packages/caelestia/data/schemes"):
    if base.is_dir():
        roots.append(base)
for base in Path("/usr/local/lib").glob("python*/site-packages/caelestia/data/schemes"):
    if base.is_dir():
        roots.append(base)

if not roots:
    print("No encontré caelestia/data/schemes en site-packages.")
else:
    for root in roots:
        print(f"Source: {root}")
        for family in sorted(p.name for p in root.iterdir() if p.is_dir()):
            print(f"  - {family}")

section("SHELL APPEARANCE + DOCK FAVOURITES")
shell = load_json(shell_json)
if shell is None:
    print(f"No existe {shell_json}; Caelestia usa defaults.")
    favourites = []
elif "__error__" in shell:
    print("JSON ERROR:", shell["__error__"])
    favourites = []
else:
    print("appearance:")
    print(json.dumps(shell.get("appearance", {}), indent=2, ensure_ascii=False))
    favourites = shell.get("launcher", {}).get("favouriteApps", []) or []
    print("favouriteApps:")
    print(json.dumps(favourites, indent=2, ensure_ascii=False))

section("THEME TARGETS")
cli = load_json(cli_json)
if cli is None:
    print(f"No existe {cli_json}; no hay overrides explícitos del CLI.")
elif "__error__" in cli:
    print("JSON ERROR:", cli["__error__"])
else:
    print(json.dumps(cli.get("theme", {}), indent=2, ensure_ascii=False))

section("FAVOURITE DESKTOP ENTRY MATCHES")
entries = desktop_entries()
if not favourites:
    print("favouriteApps está vacío: por eso el dock solo tiene apps abiertas.")
else:
    import re
    for pattern in favourites:
        matches = []
        try:
            rx = re.compile(pattern, re.IGNORECASE)
        except re.error:
            rx = re.compile(re.escape(pattern), re.IGNORECASE)
        for entry in entries:
            if rx.search(entry["id"]):
                matches.append(entry)
        print(f"{pattern!r} -> {len(matches)} match(es)")
        for item in matches[:8]:
            print(f"    {item['id']} | {item['name']} | {item['exec']}")

section("COMMON APP DESKTOP IDS")
needles = (
    "kitty", "dolphin", "brave", "spotify", "github", "claude",
)
for needle in needles:
    matches = [
        e for e in entries
        if needle in e["id"].lower()
        or needle in e["name"].lower()
        or needle in e["exec"].lower()
        or needle in e["wmclass"].lower()
    ]
    if matches:
        print(f"{needle}:")
        for item in matches[:6]:
            print(f"  {item['id']} | {item['name']} | {item['exec']}")

section("TOOLS")
for cmd in ("caelestia", "jq", "kitty", "spotify", "github-desktop", "claude-desktop", "brave"):
    path = shutil.which(cmd)
    print(f"{cmd}: {path or 'not found'}")

print("\nAUDIT FINISHED")
