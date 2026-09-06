#!/usr/bin/env python3
"""Runs the CortetsuRegional.js logic under Node against mocked HTTP
fixtures (test-regional.node.js) and statically checks that the patched
upstream files delegate to CortetsuRegional instead of GlobalConfig.

No real network call is made anywhere in this test: the Open-Meteo,
Nominatim and ip-api response shapes are hand-built fixtures fed straight
to the pure parser functions.
"""
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MODULES = ROOT / "cortetsu/modules"

node = shutil.which("node")
assert node, "node is required to run test-regional.node.js"

result = subprocess.run(
    [node, str(ROOT / "cortetsu/tests/test-regional.node.js")],
    capture_output=True,
    text=True,
    check=False,
)
assert result.returncode == 0, f"test-regional.node.js failed:\n{result.stdout}\n{result.stderr}"
print(result.stdout.strip())

# Static contract: the singleton exists, is pure/pragma-library backed, and
# never duplicates CortetsuConfig as a second source of truth.
regional_qml = (MODULES / "CortetsuRegional.qml").read_text(encoding="utf-8")
regional_js = (MODULES / "CortetsuRegional.js").read_text(encoding="utf-8")
assert "pragma Singleton" in regional_qml
assert regional_js.startswith(".pragma library")
assert "readonly property bool useTwelveHourClock: CortetsuConfig.useTwelveHourClock" in regional_qml
assert "readonly property bool useFahrenheit: CortetsuConfig.useFahrenheit" in regional_qml
assert "readonly property string weatherLocation: CortetsuConfig.weatherLocation" in regional_qml
assert "property bool useTwelveHourClock:" not in regional_qml.split("readonly property bool useTwelveHourClock")[0], \
    "CortetsuRegional must not declare its own mutable copy of the preference"
assert "GlobalConfig" not in regional_qml and "GlobalConfig" not in regional_js
assert "import Caelestia" not in regional_qml and "import Caelestia" not in regional_js
assert "Caelestia.Config" not in regional_qml and "Caelestia.Config" not in regional_js

# Static contract: the patch wires Weather.qml / DesktopClock.qml /
# Forecast.qml to CortetsuRegional and never re-introduces GlobalConfig on
# an added ("+") line.
patch = (ROOT / "caelestia/patches/services__RegionalConfig.qml.patch").read_text(encoding="utf-8")
added_lines = [line for line in patch.splitlines() if line.startswith("+") and not line.startswith("+++")]
removed_lines = [line for line in patch.splitlines() if line.startswith("-") and not line.startswith("---")]

assert any("GlobalConfig" in line for line in removed_lines), \
    "expected the patch to still show the pristine GlobalConfig lines it replaces"
assert not any("GlobalConfig" in line for line in added_lines), \
    "the patch must never add a new GlobalConfig reference"
for needle in (
    'import "../modules"',
    "CortetsuRegional.clockPattern",
    "CortetsuRegional.formatTemperature(temp)",
    "CortetsuRegional.parseLocationQuery(CortetsuRegional.weatherLocation)",
    "CortetsuRegional.buildIpLookupUrl()",
    "CortetsuRegional.parseIpLookupResponse(response)",
    "CortetsuRegional.ipApiRateLimit(metadata?.statusCode, metadata?.headers)",
    "CortetsuRegional.fixCityName(cityName)",
    "CortetsuRegional.buildReverseGeocodeUrl(lat, lon, lang)",
    "CortetsuRegional.parseReverseGeocodeResponse(json)",
    "CortetsuRegional.buildGeocodeUrl(cityName, lang)",
    "CortetsuRegional.parseGeocodeResponse(JSON.parse(text))",
    "CortetsuRegional.parseForecastResponse(JSON.parse(text))",
    "CortetsuRegional.buildForecastUrl(lat, lon)",
    "target: CortetsuRegional",
    "CortetsuRegional.useTwelveHourClock",
    "CortetsuRegional.hourPattern",
):
    assert needle in patch, f"patch missing expected delegation: {needle}"

print("test-regional: OK (mocked-HTTP JS logic + patch/singleton static contract)")
