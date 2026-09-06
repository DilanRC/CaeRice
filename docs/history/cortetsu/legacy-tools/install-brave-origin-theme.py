#!/usr/bin/env python3
from __future__ import annotations

import grp
import json
import os
import pwd
import shutil
import subprocess
import tempfile
from pathlib import Path

HOME = Path.home()
REPO = Path(__file__).resolve().parents[2]
SOURCE_HOOK = REPO / "cortetsu/bin/cortetsu-scheme-posthook"
TARGET_HOOK = HOME / ".local/bin/caelestia-scheme-posthook"
LEGACY_HOOK = HOME / ".local/bin/caelestia-scheme-posthook.legacy"
CLI_JSON = HOME / ".config/caelestia/cli.json"
STATE = HOME / ".local/state/caelestia/scheme.json"
POLICY_DIR = Path("/etc/brave/policies/managed")
POLICY = POLICY_DIR / "caelestia.json"
MARKER = "CORTETSU_BRAVE_ORIGIN_BRIDGE = True"


def run(*args: str, check: bool = True, capture: bool = False):
    return subprocess.run(args, text=True, capture_output=capture, check=check)


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


def detect_browser() -> str | None:
    for name in ("brave-origin", "brave-origin-stable"):
        path = shutil.which(name)
        if path:
            return path
    return None


def preserve_existing_hook() -> None:
    if not TARGET_HOOK.exists():
        return
    current = TARGET_HOOK.read_text(encoding="utf-8", errors="replace")
    if MARKER in current:
        return
    if LEGACY_HOOK.exists():
        print("postHook previo: ya existe copia legacy; se conserva")
        return
    shutil.copy2(TARGET_HOOK, LEGACY_HOOK)
    LEGACY_HOOK.chmod(0o755)
    print("postHook previo preservado en:", LEGACY_HOOK)


def install_hook() -> None:
    if not SOURCE_HOOK.exists():
        raise SystemExit(f"ERROR: falta {SOURCE_HOOK}")
    preserve_existing_hook()
    TARGET_HOOK.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SOURCE_HOOK, TARGET_HOOK)
    TARGET_HOOK.chmod(0o755)

    cfg = read_json(CLI_JSON)
    theme = cfg.setdefault("theme", {})
    if not isinstance(theme, dict):
        raise SystemExit("ERROR: theme en cli.json no es un objeto")
    theme["postHook"] = str(TARGET_HOOK)
    # Do not force enableChromium on or off. If the user later installs a
    # browser handled natively by Caelestia, its existing setting keeps
    # working; Brave Origin is handled independently by this adapter.
    write_json(CLI_JSON, cfg)
    print("postHook Cortetsu:", TARGET_HOOK)


def initial_policy() -> str:
    state = read_json(STATE)
    colour = None
    for key in ("surface", "background", "surfaceContainer"):
        raw = state.get(key)
        if isinstance(raw, str):
            value = raw.strip().lstrip("#")
            if len(value) == 6:
                try:
                    int(value, 16)
                except ValueError:
                    continue
                colour = value.upper()
                break
    if not colour:
        colour = "0D0E12"
    return json.dumps(
        {"BrowserThemeColor": f"#{colour}", "BrowserColorScheme": "device"},
        separators=(",", ":"),
    ) + "\n"


def provision_policy() -> None:
    user = pwd.getpwuid(os.getuid()).pw_name
    group = grp.getgrgid(os.getgid()).gr_name

    run("sudo", "mkdir", "-p", str(POLICY_DIR))

    if POLICY.exists():
        backup = POLICY.with_name("caelestia.json.pre-cortetsu")
        if not backup.exists():
            run("sudo", "cp", "-a", str(POLICY), str(backup))
            print("policy previa preservada en:", backup)

    with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as tmp:
        tmp.write(initial_policy())
        tmp_path = Path(tmp.name)
    try:
        # Only this one policy file is writable by the desktop user. The
        # surrounding managed-policy directory remains owned by root.
        run(
            "sudo",
            "install",
            "-m",
            "0644",
            "-o",
            user,
            "-g",
            group,
            str(tmp_path),
            str(POLICY),
        )
    finally:
        tmp_path.unlink(missing_ok=True)

    print("Brave managed policy:", POLICY)
    print("policy owner:", f"{user}:{group}")


def apply_and_verify(browser: str) -> None:
    cp = run(str(TARGET_HOOK), check=False, capture=True)
    if cp.stderr.strip():
        print(cp.stderr.strip())
    if cp.returncode:
        raise SystemExit(f"ERROR: postHook devolvió {cp.returncode}")

    try:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
    except Exception as exc:
        raise SystemExit(f"ERROR: no pude validar {POLICY}: {exc}")

    colour = policy.get("BrowserThemeColor")
    if not isinstance(colour, str) or not colour.startswith("#"):
        raise SystemExit("ERROR: BrowserThemeColor no quedó válido")

    print("Brave Origin executable:", browser)
    print("BrowserThemeColor:", colour)
    print("BrowserColorScheme:", policy.get("BrowserColorScheme"))
    print("refresh-platform-policy: solicitado")


def main() -> None:
    browser = detect_browser()
    if not browser:
        raise SystemExit("ERROR: no encuentro brave-origin ni brave-origin-stable en PATH")

    print("===== BRAVE ORIGIN THEME BRIDGE =====")
    install_hook()
    provision_policy()
    apply_and_verify(browser)
    print("\nOK: los próximos `caelestia scheme set ...` actualizarán Brave Origin automáticamente.")


if __name__ == "__main__":
    main()
