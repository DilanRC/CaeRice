#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
MOD = REPO / "caelestia/modules-owned/modules"
BIN = REPO / "caelestia/bin"
errors: list[str] = []


def req(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def run_json(command: list[str], label: str) -> dict:
    try:
        cp = subprocess.run(command, text=True, capture_output=True, timeout=25, check=False)
    except Exception as exc:
        errors.append(f"{label}: {exc}")
        return {}
    if cp.returncode != 0:
        errors.append(f"{label}: exit {cp.returncode}: {(cp.stderr or cp.stdout).strip()}")
        return {}
    try:
        data = json.loads(cp.stdout)
    except Exception as exc:
        errors.append(f"{label}: invalid JSON: {exc}")
        return {}
    req(isinstance(data, dict), f"{label}: root not object")
    return data if isinstance(data, dict) else {}


helpers = [
    BIN / "caerice-upstream-audit",
    BIN / "caerice-updater",
    BIN / "caerice-updater-commit-base",
]
qml = [
    MOD / "UpdaterController.qml",
    MOD / "updater/Wrapper.qml",
    MOD / "updater/Content.qml",
    MOD / "updater/CommitBaseControl.qml",
]

for path in qml + helpers:
    req(path.is_file(), f"missing {path.relative_to(REPO)}")

for path in helpers:
    if path.is_file():
        try:
            compile(path.read_text(encoding="utf-8"), str(path), "exec")
        except SyntaxError as exc:
            errors.append(f"{path.name}: {exc}")

for path in qml[1:]:
    if path.is_file():
        text = path.read_text(encoding="utf-8")
        if "Colours." in text:
            req("import qs.services" in text, f"{path.name}: Colours without qs.services")
        if "Tokens." in text:
            req("import Caelestia.Config" in text, f"{path.name}: Tokens without Config")
        req("#" not in text, f"{path.name}: possible hardcoded hex")

controller = (MOD / "UpdaterController.qml").read_text(encoding="utf-8") if (MOD / "UpdaterController.qml").is_file() else ""
req('target: "updater"' in controller, "UpdaterController missing IPC target")
req('name: "updatercenter"' in controller, "UpdaterController missing shortcut")

wrapper = (MOD / "updater/Wrapper.qml").read_text(encoding="utf-8") if (MOD / "updater/Wrapper.qml").is_file() else ""
req("CommitBaseControl" in wrapper, "Updater wrapper does not integrate CommitBaseControl")

audit = run_json([sys.executable, str(BIN / "caerice-upstream-audit")], "upstream audit") if not errors else {}
if audit:
    req(isinstance(audit.get("patches"), list), "audit patches not list")
    req(audit.get("live_tree_present") in (True, False), "audit live_tree_present missing")
    pipeline = audit.get("pipeline", [])
    req(isinstance(pipeline, list), "audit pipeline not list")
    req("package-update-separate" in pipeline, "audit safety pipeline missing package separation")
    req("snapshot" in pipeline and "apply" in pipeline and "verify" in pipeline and "rollback" in pipeline, "audit safety pipeline incomplete")
    req("separate" in str(audit.get("safety", "")).lower(), "audit safety text does not state package separation")

status = run_json([sys.executable, str(BIN / "caerice-updater"), "status"], "updater status") if not errors else {}
if status:
    req(status.get("ok") is True, "updater status not ok")

commit_status = run_json([sys.executable, str(BIN / "caerice-updater-commit-base"), "status"], "commit-base status") if not errors else {}
if commit_status:
    for key in ["base_dirty", "other_dirty", "ready"]:
        req(key in commit_status, f"commit-base status missing {key}")

updater_text = (BIN / "caerice-updater").read_text(encoding="utf-8") if (BIN / "caerice-updater").is_file() else ""
for needle in [
    "--confirm",
    "live_matches_candidate",
    "snapshot()",
    "rollback(",
    "install-clipboard-qml.sh",
    "validate-clipboard-qml.py",
    '"package_updated": False',
    "update the Caelestia package separately first",
]:
    req(needle in updater_text, f"updater safety/rebuild path missing {needle}")

# The updater must not invoke pacman/yay/paru to perform an upgrade itself.
# Reading the installed package version with `pacman -Q` is allowed.
for forbidden in [
    '["pacman", "-Syu"]',
    '["paru", "-Syu"]',
    '["yay", "-Syu"]',
    "sudo pacman -Syu",
    "paru -Syu",
    "yay -Syu",
]:
    req(forbidden not in updater_text, f"updater unexpectedly performs package upgrade via {forbidden}")

# Verify the rebuild order because every later native center extends the same
# ScreenState/Panels/ContentWindow chain created by Clipboard.
order = [
    "install-patches.sh",
    "install-clipboard-qml.sh",
    "install-hardware-center.sh",
    "install-display-manager.sh",
    "install-gaming-center.sh",
    "install-caerice-updater.sh",
]
positions = [updater_text.find(name) for name in order]
req(all(position >= 0 for position in positions), "updater rebuild list is incomplete")
if all(position >= 0 for position in positions):
    req(positions == sorted(positions), "updater rebuild order is not patches -> Clipboard -> Hardware -> Display -> Gaming -> Updater")

commit_text = (BIN / "caerice-updater-commit-base").read_text(encoding="utf-8") if (BIN / "caerice-updater-commit-base").is_file() else ""
for needle in ["--confirm", "COMMIT", "other_dirty", "push_performed"]:
    req(needle in commit_text, f"commit-base guard missing {needle}")

update_script = (REPO / "scripts/features/update-caerice-updater.sh").read_text(encoding="utf-8") if (REPO / "scripts/features/update-caerice-updater.sh").is_file() else ""
req("caerice-updater-commit-base" in update_script, "updater live sync omits commit-base helper")

install_script = (REPO / "scripts/features/install-caerice-updater.sh").read_text(encoding="utf-8") if (REPO / "scripts/features/install-caerice-updater.sh").is_file() else ""
req("caerice-updater-commit-base" in install_script, "updater installer omits commit-base helper")

print("===== CAERICE UPDATER VALIDATION =====")
if errors:
    for error in errors:
        print("ERROR:", error)
    print(f"FAIL: {len(errors)} error(es)")
    raise SystemExit(1)

print("status: OK")
print("discover/status: valid")
print("package update: explicitly separate; updater performs no package-manager upgrade")
print("apply: explicit confirmation + snapshot + Clipboard-first rebuild + verify + rollback guarded")
print("patch-base commit: guarded, local-only, blocks unrelated dirty files")
