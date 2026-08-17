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
        cp = subprocess.run(command, text=True, capture_output=True, timeout=20, check=False)
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
    req(isinstance(data, dict), f"{label}: root is not object")
    return data if isinstance(data, dict) else {}


qml = [
    MOD / "GamingController.qml",
    MOD / "gaming/Wrapper.qml",
    MOD / "gaming/Content.qml",
    MOD / "gaming/AdvancedProfileControls.qml",
]
helpers = [BIN / "caerice-gaming-probe", BIN / "caerice-gaming-profile"]

for path in qml + helpers:
    req(path.is_file(), f"missing {path.relative_to(REPO)}")

for path in helpers:
    if path.is_file():
        try:
            compile(path.read_text(encoding="utf-8"), str(path), "exec")
        except SyntaxError as exc:
            errors.append(f"{path.name}: {exc}")

for path in [item for item in qml if item.suffix == ".qml" and item.is_file()]:
    text = path.read_text(encoding="utf-8")
    if "Colours." in text:
        req("import qs.services" in text, f"{path.name}: Colours without qs.services")
    if "Tokens." in text:
        req("import Caelestia.Config" in text, f"{path.name}: Tokens without Caelestia.Config")
    req("#" not in text, f"{path.name}: possible hardcoded hex color")

controller = (MOD / "GamingController.qml").read_text(encoding="utf-8") if (MOD / "GamingController.qml").is_file() else ""
req('target: "gaming"' in controller, "GamingController missing IPC target gaming")
req('name: "gamingcenter"' in controller, "GamingController missing shortcut")

wrapper = (MOD / "gaming/Wrapper.qml").read_text(encoding="utf-8") if (MOD / "gaming/Wrapper.qml").is_file() else ""
req("AdvancedProfileControls" in wrapper, "Gaming wrapper does not integrate advanced profile controls")

profile_text = (BIN / "caerice-gaming-profile").read_text(encoding="utf-8") if (BIN / "caerice-gaming-profile").is_file() else ""
for needle in [
    "ALLOWED_SCALERS",
    "ALLOWED_FILTERS",
    "game_width",
    "output_width",
    "adaptive_sync",
    "--mangoapp",
    "--adaptive-sync",
    "%command%",
    "launch_options",
    "steam_vdf_mutation",
    "profile_applied_by_this_launch",
]:
    req(needle in profile_text, f"gaming profile missing {needle}")

# Safety model: the helper generates Steam Launch Options but never edits Steam
# VDF configuration on the user's behalf. Opening a game is deliberately a
# normal `steam -applaunch` and reports that this launch did not apply the
# generated profile automatically.
req("localconfig.vdf" not in profile_text, "gaming profile unexpectedly references Steam localconfig.vdf")
req("compatibilitytool.vdf" not in profile_text, "gaming profile unexpectedly references compatibilitytool.vdf")

# appid must be validated/canonicalized exactly once, centrally, before any
# subcommand branch touches it - not re-implemented per get/set/delete/
# command/copy/open (see scripts/features/test-gaming-appid.py for the real
# execution coverage: "00123" vs "123" duplicate-profile prevention,
# rejection of Unicode digits/signs/whitespace, uint32 bounds).
req("def canonical_appid" in profile_text, "gaming profile missing canonical_appid()")
req("args.appid = canonical_appid(args.appid)" in profile_text,
    "gaming profile does not canonicalize args.appid centrally before dispatch")
req(profile_text.count("canonical_appid(args.appid)") == 1,
    "gaming profile calls canonical_appid(args.appid) more than once - validation should not be duplicated per subcommand")

probe = run_json([sys.executable, str(BIN / "caerice-gaming-probe")], "gaming-probe") if not errors else {}
if probe:
    req(isinstance(probe.get("installed_games"), list), "gaming-probe installed_games not list")
    req(isinstance(probe.get("proton_versions"), list), "gaming-probe proton_versions not list")
    req(isinstance(probe.get("running_related"), list), "gaming-probe running_related not list")

profiles = run_json([sys.executable, str(BIN / "caerice-gaming-profile"), "list"], "gaming-profile list") if not errors else {}
if profiles:
    req(isinstance(profiles.get("profiles"), list), "gaming profiles not list")
    req(profiles.get("schema") == 3, "gaming profile schema is not v3")
    req(profiles.get("steam_vdf_mutation") is False, "gaming profile claims Steam VDF mutation")
    for item in profiles.get("profiles", []):
        if not isinstance(item, dict):
            errors.append("gaming profile list contains a non-object item")
            continue
        req(isinstance(item.get("profile"), dict), "gaming profile list item missing profile")
        req("ready" in item, "gaming profile list item missing readiness state")
        req("launch_options" in item, "gaming profile list item missing launch_options")

print("===== GAMING CENTER VALIDATION =====")
if errors:
    for error in errors:
        print("ERROR:", error)
    print(f"FAIL: {len(errors)} error(es)")
    raise SystemExit(1)

print("status: OK")
print("probe: valid")
print("profiles: schema v3, reversible, Gamescope-safe option whitelist")
print("Steam integration: generates %command% launch options; VDF mutation remains disabled")
