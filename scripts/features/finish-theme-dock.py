#!/usr/bin/env python3
from __future__ import annotations

import configparser
import json
import os
import re
import shutil
import subprocess
from pathlib import Path

HOME = Path.home()
REPO = Path(__file__).resolve().parents[2]
SHELL_JSON = HOME / ".config/caelestia/shell.json"
SCHEME_STATE = HOME / ".local/state/caelestia/scheme.json"
PACK = REPO / "caelestia/schemes/caerice-pack"
BAD_AUTO_PINS = {
    "brave-hnpfjngllnobngcgfapefoaidbinmjnm-Default",  # WhatsApp Web PWA, seeded accidentally by v1
}


def run(*args: str, check: bool = True, capture: bool = False):
    return subprocess.run(args, text=True, capture_output=capture, check=check)


def read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, obj: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(obj, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    tmp.replace(path)


def scheme_root() -> Path:
    cp = run(
        "python3",
        "-c",
        "from caelestia.utils.paths import scheme_data_dir; print(scheme_data_dir)",
        capture=True,
    )
    root = Path(cp.stdout.strip())
    if not root.is_dir():
        raise SystemExit(f"ERROR: no existe scheme_data_dir: {root}")
    return root


def desktop_entries() -> list[dict[str, str]]:
    roots = [
        HOME / ".local/share/applications",
        Path("/usr/local/share/applications"),
        Path("/usr/share/applications"),
    ]
    out: list[dict[str, str]] = []
    seen: set[str] = set()
    for root in roots:
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*.desktop")):
            rel = path.relative_to(root)
            parts = list(rel.parts)
            parts[-1] = parts[-1][:-8]
            eid = "-".join(parts)
            if eid.lower() in seen:
                continue
            parser = configparser.ConfigParser(interpolation=None, strict=False)
            parser.optionxform = str
            try:
                parser.read(path, encoding="utf-8")
                sec = parser["Desktop Entry"]
            except Exception:
                continue
            if sec.get("Hidden", "false").lower() == "true" or sec.get("NoDisplay", "false").lower() == "true":
                continue
            seen.add(eid.lower())
            out.append(
                {
                    "id": eid,
                    "name": sec.get("Name", ""),
                    "exec": sec.get("Exec", ""),
                    "wmclass": sec.get("StartupWMClass", ""),
                }
            )
    return out


def candidate_score(item: dict[str, str], needle: str) -> int | None:
    n = needle.lower()
    eid = item["id"].lower()
    name = item["name"].lower()
    exe = item["exec"].lower()
    wmclass = item["wmclass"].lower()

    if not any(n in field for field in (eid, name, exe, wmclass)):
        return None

    # Browser PWAs carry the browser name in their desktop ID/Exec. They must
    # never win over the browser itself when seeding a "brave" favourite.
    if needle == "brave" and ("--app-id=" in exe or (eid.startswith("brave-") and "brave" not in name)):
        return None

    score = 0
    if eid == n:
        score += 250
    if name == n or name == f"{n} browser":
        score += 220
    if n in name:
        score += 140
    if eid.startswith(n):
        score += 90
    if n in eid:
        score += 60
    if n in wmclass:
        score += 50
    if n in exe:
        score += 40
    return score


def find_entry(items: list[dict[str, str]], needle: str):
    ranked = []
    for item in items:
        score = candidate_score(item, needle)
        if score is not None:
            ranked.append((score, item))
    return max(ranked, key=lambda pair: pair[0])[1] if ranked else None


def matches_existing(patterns: list[str], eid: str) -> bool:
    for pattern in patterns:
        try:
            if re.search(pattern, eid, re.IGNORECASE):
                return True
        except re.error:
            if pattern == eid:
                return True
    return False


def repair_favourites() -> None:
    print("\n===== DOCK: REPARACIÓN DE FAVORITOS =====")
    cfg = read_json(SHELL_JSON)
    launcher = cfg.setdefault("launcher", {})
    current = launcher.get("favouriteApps", []) or []
    if not isinstance(current, list):
        raise SystemExit("ERROR: launcher.favouriteApps no es array")

    removed = [pin for pin in current if pin in BAD_AUTO_PINS]
    if removed:
        current = [pin for pin in current if pin not in BAD_AUTO_PINS]
        for pin in removed:
            print("UNPIN accidental:", pin, "| WhatsApp Web PWA")

    items = desktop_entries()
    for needle in ("kitty", "dolphin", "brave", "spotify", "github", "claude"):
        item = find_entry(items, needle)
        if not item:
            print("NO MATCH:", needle)
            continue
        eid = item["id"]
        if matches_existing(current, eid):
            print("KEEP PIN:", eid, "|", item["name"])
            continue
        current.append(eid)
        print("PIN:", eid, "|", item["name"])

    launcher["favouriteApps"] = current
    write_json(SHELL_JSON, cfg)
    print("favouriteApps:", json.dumps(current, ensure_ascii=False))


def install_new_pack() -> int:
    print("\n===== EXPANSIÓN EXTRA DE SCHEMES =====")
    run("python3", str(REPO / "scripts/features/generate-caerice-schemes.py"))
    root = scheme_root()
    added = 0
    for src in sorted(PACK.rglob("*.txt")):
        dst = root / src.relative_to(PACK)
        if dst.exists():
            continue
        run("sudo", "mkdir", "-p", str(dst.parent))
        run("sudo", "install", "-m", "0644", str(src), str(dst))
        added += 1
        print("ADD:", dst.relative_to(root))
    print("nuevos instalados en esta pasada:", added)
    return added


def reapply_current() -> None:
    state = read_json(SCHEME_STATE)
    name = str(state.get("name", "")).strip()
    if not name:
        return
    cmd = ["caelestia", "scheme", "set", "-n", name]
    for flag, key in (("-f", "flavour"), ("-m", "mode"), ("-v", "variant")):
        value = str(state.get(key, "")).strip()
        if value:
            cmd += [flag, value]
    cp = run(*cmd, check=False, capture=True)
    if cp.returncode:
        print("WARN: no se pudo reaplicar el scheme:", cp.stderr.strip())
    else:
        print("scheme reaplicado:", name)


def save_repo_changes() -> None:
    run("git", "-C", str(REPO), "add", "caelestia/schemes", check=False)
    status = run("git", "-C", str(REPO), "status", "--porcelain", capture=True, check=False).stdout.strip()
    if not status:
        return
    cp = run(
        "git",
        "-C",
        str(REPO),
        "commit",
        "-m",
        "theme: expand curated catalog and repair dock favourites",
        check=False,
        capture=True,
    )
    if cp.returncode:
        print("WARN: commit automático no realizado:", cp.stderr.strip())
        return
    push = run("git", "-C", str(REPO), "push", check=False, capture=True)
    print("GitHub push:", "OK" if push.returncode == 0 else "falló; ejecuta git push")


def main() -> None:
    install_new_pack()
    repair_favourites()
    run("python3", str(REPO / "scripts/features/patch-dock-pins.py"))
    reapply_current()
    save_repo_changes()
    print("\n===== FIN =====")
    print("Reinicia Caelestia una vez para cargar Dock/config actualizados:")
    print("pkill -TERM -f 'qs -c caelestia'; sleep 1; caelestia shell -d")


if __name__ == "__main__":
    main()
