#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
MODULES = REPO / "cortetsu/modules"
HARDWARE = MODULES / "hardware"
BIN = REPO / "cortetsu/bin"

QML_REQUIRED = [
    "Wrapper.qml",
    "Content.qml",
    "MetricCard.qml",
    "HistoryGraph.qml",
    "OverviewPage.qml",
    "PerformancePage.qml",
    "ProcessesPage.qml",
    "SensorsPage.qml",
    "IOPage.qml",
    "PowerPage.qml",
    "PowerAutomationPage.qml",
    "EnergyPage.qml",
    "KeybindsPage.qml",
]
HELPERS = [
    "cortetsu-hardware-probe",
    "cortetsu-hardware-power",
    "cortetsu-power-auto",
    "cortetsu-power-auto-control",
    "cortetsu-keybinds",
]

errors: list[str] = []
warnings: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def run_json(command: list[str], label: str) -> dict:
    try:
        cp = subprocess.run(command, text=True, capture_output=True, timeout=15, check=False)
    except (OSError, subprocess.SubprocessError) as exc:
        errors.append(f"{label}: no se pudo ejecutar: {exc}")
        return {}
    if cp.returncode != 0:
        errors.append(f"{label}: exit={cp.returncode}: {(cp.stderr or cp.stdout).strip()}")
        return {}
    try:
        parsed = json.loads(cp.stdout)
    except json.JSONDecodeError as exc:
        errors.append(f"{label}: JSON inválido: {exc}")
        return {}
    if not isinstance(parsed, dict):
        errors.append(f"{label}: la raíz JSON no es un objeto")
        return {}
    return parsed


require((MODULES / "HardwareController.qml").is_file(), "falta HardwareController.qml")
for name in QML_REQUIRED:
    require((HARDWARE / name).is_file(), f"falta hardware/{name}")
for name in HELPERS:
    require((BIN / name).is_file(), f"falta cortetsu/bin/{name}")
require((REPO / "config/systemd/user/cortetsu-power-auto.service").is_file(), "falta cortetsu-power-auto.service")

for path in [HARDWARE / name for name in QML_REQUIRED if (HARDWARE / name).exists()]:
    text = path.read_text(encoding="utf-8")
    if "Colours." in text:
        require("import qs.services" in text, f"{path.name}: usa Colours sin import qs.services")
    if "Tokens." in text:
        require("import Caelestia.Config" in text, f"{path.name}: usa Tokens sin import Caelestia.Config")
    hardcoded = [m.group(0) for m in re.finditer(r"#[0-9a-fA-F]{6,8}\b", text)]
    if hardcoded:
        errors.append(f"{path.name}: colores hex hardcodeados: {', '.join(sorted(set(hardcoded)))}")

content = (HARDWARE / "Content.qml").read_text(encoding="utf-8") if (HARDWARE / "Content.qml").exists() else ""
for label in ["Overview", "Performance", "Processes", "Sensors", "I/O", "Power", "Auto", "Energy", "Keybinds"]:
    require(f'qsTr("{label}")' in content, f"Content.qml: falta pestaña {label}")
require("Qt.Key_9" in content, "Content.qml: navegación 1-9 incompleta")
require("EnergyPage {}" in content, "Content.qml: EnergyPage no está conectada")
require("KeybindsPage {}" in content, "Content.qml: KeybindsPage no está conectada")
require("outsidePanel" in content and "root.closeHardware()" in content, "Content.qml: cierre exterior seguro ausente")

wrapper = (HARDWARE / "Wrapper.qml").read_text(encoding="utf-8") if (HARDWARE / "Wrapper.qml").exists() else ""
require("Loader" in wrapper and "active: root.shouldBeActive" in wrapper, "Wrapper.qml: Loader no se descarga al cerrar")

for name in HELPERS:
    path = BIN / name
    if not path.exists():
        continue
    source = path.read_text(encoding="utf-8")
    try:
        compile(source, str(path), "exec")
    except SyntaxError as exc:
        errors.append(f"{name}: SyntaxError: {exc}")

power_source = (BIN / "cortetsu-hardware-power").read_text(encoding="utf-8") if (BIN / "cortetsu-hardware-power").exists() else ""
for forbidden in ["scaling_governor).write", "energy_performance_preference).write", "power_dpm_force_performance_level).write"]:
    require(forbidden not in power_source, f"power helper contiene escritura directa no permitida: {forbidden}")
require("VALID_PROFILES" in power_source and "power-saver" in power_source and "balanced" in power_source and "performance" in power_source,
        "power helper: whitelist de perfiles incompleta")

if not errors:
    probe = run_json([sys.executable, str(BIN / "cortetsu-hardware-probe")], "hardware-probe #1")
    if probe:
        # A second sample makes delta-based CPU/process/network/disk metrics meaningful.
        probe = run_json([sys.executable, str(BIN / "cortetsu-hardware-probe")], "hardware-probe #2")
        for key in ["cpu", "memory", "disk", "disk_io", "network", "gpus", "processes"]:
            require(key in probe, f"hardware-probe: falta clave {key}")

    power = run_json([sys.executable, str(BIN / "cortetsu-hardware-power")], "hardware-power")
    if power:
        for key in ["profiles", "ac", "battery", "cpu", "gpus"]:
            require(key in power, f"hardware-power: falta clave {key}")

    control = run_json([sys.executable, str(BIN / "cortetsu-power-auto-control"), "status"], "power-auto-control")
    if control:
        for key in ["config", "service", "last", "events"]:
            require(key in control, f"power-auto-control: falta clave {key}")

install = (REPO / "scripts/features/install-hardware-center.sh").read_text(encoding="utf-8")
update = (REPO / "scripts/features/update-hardware-center.sh").read_text(encoding="utf-8")
for needle in ["cortetsu-hardware-power", "cortetsu-power-auto", "cortetsu-power-auto-control", "cortetsu-keybinds", "cortetsu-power-auto.service"]:
    if needle not in install:
        errors.append(f"install-hardware-center.sh no instala {needle}")
    if needle not in update:
        errors.append(f"update-hardware-center.sh no sincroniza {needle}")

print("===== HARDWARE CENTER VALIDATION =====")
print(f"QML pages: {len(QML_REQUIRED)}")
print(f"helpers: {len(HELPERS)}")
if warnings:
    print("\nWARNINGS")
    for item in warnings:
        print(f"  WARN: {item}")
if errors:
    print("\nERRORS")
    for item in errors:
        print(f"  ERROR: {item}")
    print(f"\nFAIL: {len(errors)} error(es)")
    raise SystemExit(1)

print("status: OK")
print("resource model: UI/probes unload with Hardware Center; Auto daemon remains opt-in")
