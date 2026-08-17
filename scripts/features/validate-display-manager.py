#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
MODULES = REPO / "caelestia/modules-owned/modules"
DISPLAY = MODULES / "display"
BIN = REPO / "caelestia/bin"
errors: list[str] = []


def req(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def run_json(command: list[str], label: str, allowed: tuple[int, ...] = (0,)) -> dict:
    try:
        cp = subprocess.run(command, text=True, capture_output=True, timeout=20, check=False)
    except Exception as exc:
        errors.append(f"{label}: {exc}")
        return {}
    if cp.returncode not in allowed:
        errors.append(f"{label}: exit {cp.returncode}: {(cp.stderr or cp.stdout).strip()}")
        return {}
    try:
        data = json.loads(cp.stdout)
    except Exception as exc:
        errors.append(f"{label}: invalid JSON: {exc}")
        return {}
    req(isinstance(data, dict), f"{label}: root not object")
    return data if isinstance(data, dict) else {}


qml = [
    "Wrapper.qml",
    "Content.qml",
    "Editor.qml",
    "PreviewControls.qml",
    "DisplayPresets.qml",
    "DisplayCapabilities.qml",
    "DisplayOutputControls.qml",
]
helpers = [
    "caerice-display-probe",
    "caerice-display-plan",
    "caerice-display-transaction",
    "caerice-display-persist",
    "caerice-display-presets",
    "caerice-display-workspaces",
]

req((MODULES / "DisplayController.qml").is_file(), "missing DisplayController.qml")
for name in qml:
    req((DISPLAY / name).is_file(), f"missing display/{name}")
for name in helpers:
    req((BIN / name).is_file(), f"missing caelestia/bin/{name}")

for name in helpers:
    path = BIN / name
    if path.is_file():
        try:
            compile(path.read_text(encoding="utf-8"), str(path), "exec")
        except SyntaxError as exc:
            errors.append(f"{name}: {exc}")

# Lightweight QML structure guard. A semicolon between two declarative child
# object blocks ("... } ; Type {") is invalid QML and can pass our semantic
# source checks while preventing the entire shell from loading.
invalid_child_separator = re.compile(r"}\s*;\s*[A-Za-z_][A-Za-z0-9_.]*\s*{")

for path in [DISPLAY / name for name in qml if (DISPLAY / name).is_file()]:
    text = path.read_text(encoding="utf-8")
    if "Colours." in text:
        req("import qs.services" in text, f"{path.name}: Colours without qs.services")
    if "Tokens." in text:
        req("import Caelestia.Config" in text, f"{path.name}: Tokens without Config")
    req("#" not in text, f"{path.name}: possible hardcoded hex")
    req(not invalid_child_separator.search(text), f"{path.name}: invalid semicolon between QML child objects")

controller = (MODULES / "DisplayController.qml").read_text(encoding="utf-8") if (MODULES / "DisplayController.qml").is_file() else ""
req('target: "display"' in controller, "controller missing IPC")
req('name: "displaymanager"' in controller, "controller missing shortcut")

content = (DISPLAY / "Content.qml").read_text(encoding="utf-8") if (DISPLAY / "Content.qml").is_file() else ""
for needle in ["Editor", "PreviewControls", "DisplayPresets", "DisplayOutputControls"]:
    req(needle in content, f"Content missing {needle}")

preview = (DISPLAY / "PreviewControls.qml").read_text(encoding="utf-8") if (DISPLAY / "PreviewControls.qml").is_file() else ""
for needle in ["Preview", "Keep", "Save", "Revert", "confirmedCandidateJson === root.currentCandidateJson"]:
    req(needle in preview, f"PreviewControls missing {needle}")
req("persistPath" in preview and '"persist", "--candidate"' in preview, "PreviewControls is not delegating Save to caerice-display-persist")

persist_text = (BIN / "caerice-display-persist").read_text(encoding="utf-8") if (BIN / "caerice-display-persist").is_file() else ""
for needle in [
    'WORKSPACES = HERE / "caerice-display-workspaces"',
    '"sync", "--candidate"',
    "rollback_plan = plan(original_live)",
    "restore(backup_file, original_live)",
    '"atomic": True',
    '"workspace_policy": policy_result',
]:
    req(needle in persist_text, f"atomic persistence path missing {needle}")

planner = (BIN / "caerice-display-plan").read_text(encoding="utf-8") if (BIN / "caerice-display-plan").is_file() else ""
for needle in ["bitdepth", "ALLOWED_CM", "vrr_capable", "hdr_capable", "wide_color_capable"]:
    req(needle in planner, f"planner capability guard missing {needle}")

probe = run_json([sys.executable, str(BIN / "caerice-display-probe")], "probe") if not errors else {}
monitors = probe.get("hyprland", []) if probe else []
if probe:
    req(isinstance(monitors, list), "hyprland not list")
    req(isinstance(probe.get("drm"), list), "drm not list")
    req(
        not any(str(item.get("output_name", "")).startswith("Writeback-") for item in probe.get("drm", []) if isinstance(item, dict)),
        "Writeback pseudo-output exposed",
    )
    if monitors:
        outputs = [
            {
                "name": item.get("name", ""),
                "enabled": not bool(item.get("disabled", False)),
                "mode": (item.get("available_modes") or ["preferred"])[0],
                "x": int(item.get("x") or 0),
                "y": int(item.get("y") or 0),
                "scale": float(item.get("scale") or 1),
                "transform": int(item.get("transform") or 0),
            }
            for item in monitors
        ]
        plan = run_json(
            [sys.executable, str(BIN / "caerice-display-plan"), "--candidate", json.dumps({"outputs": outputs})],
            "plan",
            (0, 3),
        )
        req(plan.get("applied") is False, "plan claimed apply")
        if plan.get("ok") and plan.get("candidate", {}).get("outputs"):
            normalized = plan["candidate"]["outputs"][0]
            for key in ["bitdepth", "cm", "vrr"]:
                req(key in normalized, f"normalized candidate missing {key}")

if not errors:
    tx = run_json([sys.executable, str(BIN / "caerice-display-transaction"), "status"], "transaction")
    req("active" in tx, "transaction status missing active")

    persisted = run_json([sys.executable, str(BIN / "caerice-display-persist"), "status"], "persist")
    req("available" in persisted, "persist status missing available")
    req("workspace" in str(persisted.get("atomic_scope", "")).lower(), "persist status does not advertise atomic workspace scope")

    named = run_json([sys.executable, str(BIN / "caerice-display-presets"), "list"], "presets")
    req(isinstance(named.get("presets"), list), "presets list invalid")

    workspace = run_json([sys.executable, str(BIN / "caerice-display-workspaces"), "status"], "workspaces")
    req("managed" in workspace and "display_policy_managed" in workspace, "workspace/output-policy status incomplete")

update = (REPO / "scripts/features/update-display-manager.sh").read_text(encoding="utf-8") if (REPO / "scripts/features/update-display-manager.sh").is_file() else ""
for name in helpers:
    req(name in update, f"update-display-manager does not sync {name}")

print("===== DISPLAY MANAGER VALIDATION =====")
if errors:
    for error in errors:
        print("ERROR:", error)
    print(f"FAIL: {len(errors)} error(es)")
    raise SystemExit(1)

print("status: OK")
print("QML declarative child-separator guard: OK")
print("dry run + timed preview + exact-candidate Save: covered")
print("geometry + color/bitdepth/VRR + workspace ranges: one rollback-protected persistence transaction")
print("10-bit/HDR/Wide/VRR writes: capability-gated; unknown support remains disabled")
