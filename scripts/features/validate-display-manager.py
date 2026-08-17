#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
MODULES = REPO / "caelestia/modules-owned/modules"
DISPLAY = MODULES / "display"
BIN = REPO / "caelestia/bin"

errors: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def run_json(command: list[str], label: str) -> dict:
    try:
        cp = subprocess.run(command, text=True, capture_output=True, timeout=12, check=False)
    except (OSError, subprocess.SubprocessError) as exc:
        errors.append(f"{label}: {exc}")
        return {}
    if cp.returncode != 0:
        errors.append(f"{label}: exit {cp.returncode}: {(cp.stderr or cp.stdout).strip()}")
        return {}
    try:
        parsed = json.loads(cp.stdout)
    except json.JSONDecodeError as exc:
        errors.append(f"{label}: JSON inválido: {exc}")
        return {}
    require(isinstance(parsed, dict), f"{label}: raíz JSON no es objeto")
    return parsed if isinstance(parsed, dict) else {}


required = [
    MODULES / "DisplayController.qml",
    DISPLAY / "Wrapper.qml",
    DISPLAY / "Content.qml",
    BIN / "caerice-display-probe",
    BIN / "caerice-display-plan",
]
for path in required:
    require(path.is_file(), f"falta {path.relative_to(REPO)}")

for path in [BIN / "caerice-display-probe", BIN / "caerice-display-plan"]:
    if path.exists():
        try:
            compile(path.read_text(encoding="utf-8"), str(path), "exec")
        except SyntaxError as exc:
            errors.append(f"{path.name}: SyntaxError {exc}")

for path in [DISPLAY / "Wrapper.qml", DISPLAY / "Content.qml"]:
    if path.exists():
        text = path.read_text(encoding="utf-8")
        if "Colours." in text:
            require("import qs.services" in text, f"{path.name}: Colours sin qs.services")
        if "Tokens." in text:
            require("import Caelestia.Config" in text, f"{path.name}: Tokens sin Caelestia.Config")
        require("#" not in text, f"{path.name}: posible color hex hardcodeado")

controller = (MODULES / "DisplayController.qml").read_text(encoding="utf-8") if (MODULES / "DisplayController.qml").exists() else ""
require('target: "display"' in controller, "DisplayController: falta IPC target display")
require('name: "displaymanager"' in controller, "DisplayController: falta shortcut displaymanager")

content = (DISPLAY / "Content.qml").read_text(encoding="utf-8") if (DISPLAY / "Content.qml").exists() else ""
for needle in ["outsidePanel", "Dry run candidate", "caerice-display-plan", "closeDisplayManager", "topologyCanvas"]:
    require(needle in content, f"Content.qml: falta {needle}")

if not errors:
    probe = run_json([sys.executable, str(BIN / "caerice-display-probe")], "display-probe")
    monitors = probe.get("hyprland", []) if probe else []
    require(isinstance(monitors, list), "display-probe: hyprland no es array")
    if isinstance(monitors, list) and monitors:
        outputs = []
        for monitor in monitors:
            if not isinstance(monitor, dict):
                continue
            modes = monitor.get("available_modes", []) if isinstance(monitor.get("available_modes"), list) else []
            mode = modes[0] if modes else "preferred"
            outputs.append({
                "name": monitor.get("name", ""),
                "enabled": not bool(monitor.get("disabled", False)),
                "mode": mode,
                "x": int(monitor.get("x") or 0),
                "y": int(monitor.get("y") or 0),
                "scale": float(monitor.get("scale") or 1),
                "transform": int(monitor.get("transform") or 0),
            })
        cp = subprocess.run(
            [sys.executable, str(BIN / "caerice-display-plan"), "--candidate", json.dumps({"outputs": outputs})],
            text=True,
            capture_output=True,
            timeout=12,
            check=False,
        )
        try:
            plan = json.loads(cp.stdout)
        except json.JSONDecodeError as exc:
            errors.append(f"display-plan: JSON inválido: {exc}")
        else:
            require(plan.get("applied") is False, "display-plan: dry run afirmó haber aplicado cambios")
            require(isinstance(plan.get("commands"), list), "display-plan: commands no es array")

print("===== DISPLAY MANAGER VALIDATION =====")
if errors:
    for item in errors:
        print(f"ERROR: {item}")
    print(f"FAIL: {len(errors)} error(es)")
    raise SystemExit(1)
print("status: OK")
print("write path: disabled; planner is dry-run only")
