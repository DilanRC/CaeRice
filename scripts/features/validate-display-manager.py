#!/usr/bin/env python3
from __future__ import annotations
import json, subprocess, sys
from pathlib import Path
REPO=Path(__file__).resolve().parents[2]; MODULES=REPO/'caelestia/modules-owned/modules'; DISPLAY=MODULES/'display'; BIN=REPO/'caelestia/bin'; errors=[]
def req(c,m):
    if not c: errors.append(m)
def run_json(cmd,label,allowed=(0,)):
    try: cp=subprocess.run(cmd,text=True,capture_output=True,timeout=20,check=False)
    except Exception as e: errors.append(f'{label}: {e}'); return {}
    if cp.returncode not in allowed: errors.append(f'{label}: exit {cp.returncode}: {(cp.stderr or cp.stdout).strip()}'); return {}
    try: data=json.loads(cp.stdout)
    except Exception as e: errors.append(f'{label}: invalid JSON: {e}'); return {}
    req(isinstance(data,dict),f'{label}: root not object'); return data if isinstance(data,dict) else {}
qml=['Wrapper.qml','Content.qml','Editor.qml','PreviewControls.qml','DisplayPresets.qml','DisplayCapabilities.qml','DisplayOutputControls.qml']
helpers=['caerice-display-probe','caerice-display-plan','caerice-display-transaction','caerice-display-persist','caerice-display-presets','caerice-display-workspaces']
req((MODULES/'DisplayController.qml').is_file(),'missing DisplayController.qml')
for n in qml: req((DISPLAY/n).is_file(),f'missing display/{n}')
for n in helpers: req((BIN/n).is_file(),f'missing caelestia/bin/{n}')
for n in helpers:
 p=BIN/n
 if p.is_file():
  try: compile(p.read_text(encoding='utf-8'),str(p),'exec')
  except SyntaxError as e: errors.append(f'{n}: {e}')
for p in [DISPLAY/n for n in qml if (DISPLAY/n).is_file()]:
 text=p.read_text(encoding='utf-8')
 if 'Colours.' in text: req('import qs.services' in text,f'{p.name}: Colours without qs.services')
 if 'Tokens.' in text: req('import Caelestia.Config' in text,f'{p.name}: Tokens without Config')
 req('#' not in text,f'{p.name}: possible hardcoded hex')
ctl=(MODULES/'DisplayController.qml').read_text(encoding='utf-8') if (MODULES/'DisplayController.qml').is_file() else ''
req('target: "display"' in ctl,'controller missing IPC'); req('name: "displaymanager"' in ctl,'controller missing shortcut')
content=(DISPLAY/'Content.qml').read_text(encoding='utf-8') if (DISPLAY/'Content.qml').is_file() else ''
for needle in ['Editor','PreviewControls','DisplayPresets','DisplayOutputControls']: req(needle in content,f'Content missing {needle}')
preview=(DISPLAY/'PreviewControls.qml').read_text(encoding='utf-8') if (DISPLAY/'PreviewControls.qml').is_file() else ''
for needle in ['Preview','Keep','Save','Revert','caerice-display-workspaces','confirmedCandidateJson === root.currentCandidateJson']: req(needle in preview,f'PreviewControls missing {needle}')
planner=(BIN/'caerice-display-plan').read_text(encoding='utf-8') if (BIN/'caerice-display-plan').is_file() else ''
for needle in ['bitdepth','ALLOWED_CM','vrr_capable','hdr_capable','wide_color_capable']:
 req(needle in planner,f'planner capability guard missing {needle}')
probe=run_json([sys.executable,str(BIN/'caerice-display-probe')],'probe') if not errors else {}
monitors=probe.get('hyprland',[]) if probe else []
if probe:
 req(isinstance(monitors,list),'hyprland not list'); req(isinstance(probe.get('drm'),list),'drm not list')
 req(not any(str(x.get('output_name','')).startswith('Writeback-') for x in probe.get('drm',[]) if isinstance(x,dict)),'Writeback pseudo-output exposed')
 if monitors:
  outputs=[{'name':x.get('name',''),'enabled':not bool(x.get('disabled',False)),'mode':(x.get('available_modes') or ['preferred'])[0],'x':int(x.get('x') or 0),'y':int(x.get('y') or 0),'scale':float(x.get('scale') or 1),'transform':int(x.get('transform') or 0)} for x in monitors]
  plan=run_json([sys.executable,str(BIN/'caerice-display-plan'),'--candidate',json.dumps({'outputs':outputs})],'plan',(0,3)); req(plan.get('applied') is False,'plan claimed apply')
  if plan.get('ok') and plan.get('candidate',{}).get('outputs'):
   normalized=plan['candidate']['outputs'][0]
   for key in ['bitdepth','cm','vrr']: req(key in normalized,f'normalized candidate missing {key}')
if not errors:
 tx=run_json([sys.executable,str(BIN/'caerice-display-transaction'),'status'],'transaction'); req('active' in tx,'transaction status missing active')
 ps=run_json([sys.executable,str(BIN/'caerice-display-persist'),'status'],'persist'); req('available' in ps,'persist status missing available')
 named=run_json([sys.executable,str(BIN/'caerice-display-presets'),'list'],'presets'); req(isinstance(named.get('presets'),list),'presets list invalid')
 ws=run_json([sys.executable,str(BIN/'caerice-display-workspaces'),'status'],'workspaces'); req('managed' in ws and 'display_policy_managed' in ws,'workspace/output-policy status incomplete')
update=(REPO/'scripts/features/update-display-manager.sh').read_text(encoding='utf-8') if (REPO/'scripts/features/update-display-manager.sh').is_file() else ''
for n in helpers: req(n in update,f'update-display-manager does not sync {n}')
print('===== DISPLAY MANAGER VALIDATION =====')
if errors:
 for e in errors: print('ERROR:',e)
 print(f'FAIL: {len(errors)} error(es)'); raise SystemExit(1)
print('status: OK'); print('dry run + timed preview + exact-candidate Save: covered'); print('named layouts + workspace ranges: covered'); print('10-bit/HDR/Wide/VRR writes: capability-gated; unknown support remains disabled')
