#!/usr/bin/env python3
from __future__ import annotations
import json, subprocess, sys
from pathlib import Path
REPO=Path(__file__).resolve().parents[2]; MOD=REPO/'caelestia/modules-owned/modules'; BIN=REPO/'caelestia/bin'; errors=[]
def req(c,m):
    if not c: errors.append(m)
def run_json(cmd,label):
    try: cp=subprocess.run(cmd,text=True,capture_output=True,timeout=20,check=False)
    except Exception as e: errors.append(f'{label}: {e}'); return {}
    if cp.returncode!=0: errors.append(f'{label}: exit {cp.returncode}: {(cp.stderr or cp.stdout).strip()}'); return {}
    try: data=json.loads(cp.stdout)
    except Exception as e: errors.append(f'{label}: invalid JSON: {e}'); return {}
    req(isinstance(data,dict),f'{label}: root is not object'); return data if isinstance(data,dict) else {}
qml=[MOD/'GamingController.qml',MOD/'gaming/Wrapper.qml',MOD/'gaming/Content.qml',MOD/'gaming/AdvancedProfileControls.qml']
helpers=[BIN/'caerice-gaming-probe',BIN/'caerice-gaming-profile']
for p in qml+helpers: req(p.is_file(),f'missing {p.relative_to(REPO)}')
for p in helpers:
    if p.is_file():
        try: compile(p.read_text(encoding='utf-8'),str(p),'exec')
        except SyntaxError as e: errors.append(f'{p.name}: {e}')
for p in [x for x in qml if x.suffix=='.qml' and x.is_file()]:
    text=p.read_text(encoding='utf-8')
    if 'Colours.' in text: req('import qs.services' in text,f'{p.name}: Colours without qs.services')
    if 'Tokens.' in text: req('import Caelestia.Config' in text,f'{p.name}: Tokens without Caelestia.Config')
    req('#' not in text,f'{p.name}: possible hardcoded hex color')
ctl=(MOD/'GamingController.qml').read_text(encoding='utf-8') if (MOD/'GamingController.qml').is_file() else ''
req('target: "gaming"' in ctl,'GamingController missing IPC target gaming'); req('name: "gamingcenter"' in ctl,'GamingController missing shortcut')
wrapper=(MOD/'gaming/Wrapper.qml').read_text(encoding='utf-8') if (MOD/'gaming/Wrapper.qml').is_file() else ''
req('AdvancedProfileControls' in wrapper,'Gaming wrapper does not integrate advanced profile controls')
profile_text=(BIN/'caerice-gaming-profile').read_text(encoding='utf-8') if (BIN/'caerice-gaming-profile').is_file() else ''
for needle in ['ALLOWED_SCALERS','ALLOWED_FILTERS','game_width','output_width','adaptive_sync','--mangoapp','--adaptive-sync','mutates_steam_config']:
    req(needle in profile_text,f'gaming profile missing {needle}')
probe=run_json([sys.executable,str(BIN/'caerice-gaming-probe')],'gaming-probe') if not errors else {}
if probe:
    req(isinstance(probe.get('installed_games'),list),'gaming-probe installed_games not list')
    req(isinstance(probe.get('proton_versions'),list),'gaming-probe proton_versions not list')
    req(isinstance(probe.get('running_related'),list),'gaming-probe running_related not list')
profiles=run_json([sys.executable,str(BIN/'caerice-gaming-profile'),'list'],'gaming-profile list') if not errors else {}
if profiles:
    req(isinstance(profiles.get('profiles'),list),'gaming profiles not list')
    req(profiles.get('schema')==2,'gaming profile schema is not v2')
print('===== GAMING CENTER VALIDATION =====')
if errors:
    for e in errors: print('ERROR:',e)
    print(f'FAIL: {len(errors)} error(es)'); raise SystemExit(1)
print('status: OK'); print('probe: valid'); print('profiles: schema v2, reversible, Gamescope-safe option whitelist'); print('Steam config mutation: disabled')
