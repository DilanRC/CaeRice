#!/usr/bin/env python3
from __future__ import annotations
import json, subprocess, sys
from pathlib import Path
REPO=Path(__file__).resolve().parents[2]; MOD=REPO/'caelestia/modules-owned/modules'; BIN=REPO/'caelestia/bin'; errors=[]
def req(c,m):
    if not c: errors.append(m)
def run_json(cmd,label):
    try: cp=subprocess.run(cmd,text=True,capture_output=True,timeout=25,check=False)
    except Exception as e: errors.append(f'{label}: {e}'); return {}
    if cp.returncode!=0: errors.append(f'{label}: exit {cp.returncode}: {(cp.stderr or cp.stdout).strip()}'); return {}
    try: data=json.loads(cp.stdout)
    except Exception as e: errors.append(f'{label}: invalid JSON: {e}'); return {}
    req(isinstance(data,dict),f'{label}: root not object'); return data if isinstance(data,dict) else {}
paths=[MOD/'UpdaterController.qml',MOD/'updater/Wrapper.qml',MOD/'updater/Content.qml',BIN/'caerice-upstream-audit',BIN/'caerice-updater']
for p in paths: req(p.is_file(),f'missing {p.relative_to(REPO)}')
for p in [BIN/'caerice-upstream-audit',BIN/'caerice-updater']:
    if p.is_file():
        try: compile(p.read_text(encoding='utf-8'),str(p),'exec')
        except SyntaxError as e: errors.append(f'{p.name}: {e}')
for p in [MOD/'updater/Wrapper.qml',MOD/'updater/Content.qml']:
    if p.is_file():
        text=p.read_text(encoding='utf-8')
        if 'Colours.' in text: req('import qs.services' in text,f'{p.name}: Colours without qs.services')
        if 'Tokens.' in text: req('import Caelestia.Config' in text,f'{p.name}: Tokens without Config')
        req('#' not in text,f'{p.name}: possible hardcoded hex')
ctl=(MOD/'UpdaterController.qml').read_text(encoding='utf-8') if (MOD/'UpdaterController.qml').is_file() else ''
req('target: "updater"' in ctl,'UpdaterController missing IPC target'); req('name: "updatercenter"' in ctl,'UpdaterController missing shortcut')
audit=run_json([sys.executable,str(BIN/'caerice-upstream-audit')],'upstream audit') if not errors else {}
if audit:
    req(isinstance(audit.get('patches'),list),'audit patches not list'); req(audit.get('live_tree_present') in (True,False),'audit live_tree_present missing'); req('package-update-separate' in audit.get('pipeline',[]),'audit safety pipeline missing package separation')
status=run_json([sys.executable,str(BIN/'caerice-updater'),'status'],'updater status') if not errors else {}
if status: req(status.get('ok') is True,'updater status not ok')
text=(BIN/'caerice-updater').read_text(encoding='utf-8') if (BIN/'caerice-updater').is_file() else ''
for needle in ['--confirm','live_matches_candidate','snapshot()','rollback(','package update']:
    req(needle in text,f'updater safety path missing {needle}')
print('===== CAERICE UPDATER VALIDATION =====')
if errors:
    for e in errors: print('ERROR:',e)
    print(f'FAIL: {len(errors)} error(es)'); raise SystemExit(1)
print('status: OK'); print('discover/status: valid'); print('package update: separate by design'); print('apply: explicit confirmation + snapshot + verify + rollback guarded')
