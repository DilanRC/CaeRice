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


def run_json(command: list[str], label: str, allowed_codes=(0,)) -> dict:
    try:
        cp = subprocess.run(command, text=True, capture_output=True, timeout=12, check=False)
    except (OSError, subprocess.SubprocessError) as exc:
        errors.append(f"{label}: {exc}")
        return {}
    if cp.returncode not in allowed_codes:
        errors.append(f"{label}: exit {cp.returncode}: {(cp.stderr or cp.stdout).strip()}")
        return {}
    try:
        parsed = json.loads(cp.stdout)
    except json.JSONDecodeError as exc:
        errors.append(f"{label}: JSON inválido: {exc}")
        return {}
    require(isinstance(parsed, dict), f"{label}: raíz JSON no es objeto")
    return parsed if isinstance(parsed, dict) else {}


qml_required = ["Wrapper.qml", "Content.qml", "Editor.qml", "PreviewControls.qml"]
helpers = [
    "caerice-display-probe",
    "caerice-display-plan",
    "caerice-display-transaction",
    "caerice-display-persist",
]

require((MODULES / "DisplayController.qml").is_file(), "falta DisplayController.qml")
for name in qml_required:
    require((DISPLAY / name).is_file(), f"falta display/{name}")
for name in helpers:
    require((BIN / name).is_file(), f"falta caelestia/bin/{name}")

for name in helpers:
    path = BIN / name
    if path.exists():
        try:
            compile(path.read_text(encoding="utf-8"), str(path), "exec")
        except SyntaxError as exc:
            errors.append(f"{name}: SyntaxError {exc}")

for path in [DISPLAY / name for name in qml_required if (DISPLAY / name).exists()]:
    text = path.read_text(encoding="utf-8")
    if "Colours." in text:
        require("import qs.services" in text, f"{path.name}: Colours sin qs.services")
    if "Tokens." in text:
        require("import Caelestia.Config" in text, f"{path.name}: Tokens sin Caelestia.Config")
    require("#" not in text, f"{path.name}: posible color hex hardcodeado")

controller = (MODULES / "DisplayController.qml").read_text(encoding="utf-8") if (MODULES / "DisplayController.qml").exists() else ""
require('target: "display"' in controller, "DisplayController: falta IPC target display")
require('name: "displaymanager"' in controller, "DisplayController: falta shortcut displaymanager")

editor = (DISPLAY / "Editor.qml").read_text(encoding="utf-8") if (DISPLAY / "Editor.qml").exists() else ""
for needle in ["outsidePanel", "Dry run candidate", "caerice-display-plan", "closeDisplayManager", "topologyCanvas"]:
    require(needle in editor, f"Editor.qml: falta {needle}")

content = (DISPLAY / "Content.qml").read_text(encoding="utf-8") if (DISPLAY / "Content.qml").exists() else ""
require("PreviewControls" in content and "Editor" in content, "Content.qml: wrapper Editor/PreviewControls incompleto")
preview_qml = (DISPLAY / "PreviewControls.qml").read_text(encoding="utf-8") if (DISPLAY / "PreviewControls.qml").exists() else ""
for needle in ["Preview", "Keep", "Save", "Revert", "caerice-display-transaction", "caerice-display-persist", "confirmedCandidateJson"]:
    require(needle in preview_qml, f"PreviewControls.qml: falta {needle}")
require("confirmedCandidateJson === root.currentCandidateJson" in preview_qml,
        "PreviewControls.qml: Save no exige el candidato exacto confirmado")

probe = {}
if not errors:
    probe = run_json([sys.executable, str(BIN / "caerice-display-probe")], "display-probe")
    monitors = probe.get("hyprland", []) if probe else []
    drm = probe.get("drm", []) if probe else []
    require(isinstance(monitors, list), "display-probe: hyprland no es array")
    require(isinstance(drm, list), "display-probe: drm no es array")
    if isinstance(drm, list):
        require(not any(str(item.get("output_name", "")).startswith("Writeback-") for item in drm if isinstance(item, dict)),
                "display-probe: expone pseudo-output DRM Writeback")
    if isinstance(monitors, list) and monitors:
        outputs = []
        for monitor in monitors:
            if not isinstance(monitor, dict):
                continue
            modes = monitor.get("available_modes", []) if isinstance(monitor.get("available_modes"), list) else []
            current = "preferred"
            width = int(monitor.get("width") or 0)
            height = int(monitor.get("height") or 0)
            refresh = float(monitor.get("refresh_hz") or 0)
            best_delta = 99999.0
            for mode in modes:
                text = str(mode)
                try:
                    wh, hz = text.split("@", 1)
                    w, h = wh.split("x", 1)
                    delta = abs(float(hz.removesuffix("Hz")) - refresh)
                except ValueError:
                    continue
                if int(w) == width and int(h) == height and delta < best_delta:
                    current = text
                    best_delta = delta
            outputs.append({
                "name": monitor.get("name", ""),
                "enabled": not bool(monitor.get("disabled", False)),
                "mode": current,
                "x": int(monitor.get("x") or 0),
                "y": int(monitor.get("y") or 0),
                "scale": float(monitor.get("scale") or 1),
                "transform": int(monitor.get("transform") or 0),
            })
        plan = run_json(
            [sys.executable, str(BIN / "caerice-display-plan"), "--candidate", json.dumps({"outputs": outputs})],
            "display-plan",
            allowed_codes=(0, 3),
        )
        require(plan.get("applied") is False, "display-plan: dry run afirmó haber aplicado cambios")
        require(isinstance(plan.get("commands"), list), "display-plan: commands no es array")

if not errors:
    tx = run_json([sys.executable, str(BIN / "caerice-display-transaction"), "status"], "display-transaction status")
    require("active" in tx, "display-transaction: status sin active")
    persist = run_json([sys.executable, str(BIN / "caerice-display-persist"), "status"], "display-persist status")
    for key in ["available", "managed", "config"]:
        require(key in persist, f"display-persist: status sin {key}")

install = (REPO / "scripts/features/install-display-manager.sh").read_text(encoding="utf-8") if (REPO / "scripts/features/install-display-manager.sh").exists() else ""
update = (REPO / "scripts/features/update-display-manager.sh").read_text(encoding="utf-8") if (REPO / "scripts/features/update-display-manager.sh").exists() else ""
for needle in ["caerice-display-probe", "caerice-display-plan", "caerice-display-transaction", "DisplayController.qml"]:
    require(needle in install, f"install-display-manager.sh no instala {needle}")
    require(needle in update, f"update-display-manager.sh no sincroniza {needle}")
require("caerice-display-persist" in update, "update-display-manager.sh no sincroniza caerice-display-persist")

print("===== DISPLAY MANAGER VALIDATION =====")
if errors:
    for item in errors:
        print(f"ERROR: {item}")
    print(f"FAIL: {len(errors)} error(es)")
    raise SystemExit(1)
print("status: OK")
print("dry run: validated")
print("timed preview backend: present; auto-revert watchdog available")
print("persistence helper: present; Save requires the exact candidate confirmed by Keep")
