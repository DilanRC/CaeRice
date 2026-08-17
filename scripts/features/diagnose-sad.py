#!/usr/bin/env python3
from __future__ import annotations
import hashlib, json, os, re, subprocess, sys
from pathlib import Path

REPO=Path(__file__).resolve().parents[2]
LIVE=Path('/etc/xdg/quickshell/caelestia')
UID=os.getuid()
errors=[]; warnings=[]; rows=[]

def sha(p):
 try:return hashlib.sha256(p.read_bytes()).hexdigest()
 except OSError:return ''
def cmd(args,timeout=20):
 try:return subprocess.run(args,text=True,capture_output=True,timeout=timeout,check=False)
 except Exception as e:return None
def check_file(rel):
 src=REPO/'caelestia/modules-owned'/rel; live=LIVE/rel
 same=src.is_file() and live.is_file() and sha(src)==sha(live)
 rows.append({'path':rel,'repo':src.is_file(),'live':live.is_file(),'match':same})
 if not same: warnings.append(f'live mismatch: {rel}')

def json_helper(name,args=None):
 path=Path.home()/'.local/bin'/name
 if not path.is_file(): warnings.append(f'missing installed helper: {name}'); return
 cp=cmd([str(path)]+(args or []),25)
 if not cp or cp.returncode!=0: errors.append(f'{name}: failed'); return
 try: json.loads(cp.stdout)
 except Exception as e: errors.append(f'{name}: invalid JSON: {e}')

for rel in [
 'modules/HardwareController.qml','modules/hardware/Wrapper.qml','modules/hardware/Content.qml',
 'modules/DisplayController.qml','modules/display/Wrapper.qml','modules/display/Content.qml','modules/display/Editor.qml','modules/display/PreviewControls.qml','modules/display/DisplayPresets.qml','modules/display/DisplayCapabilities.qml',
 'modules/GamingController.qml','modules/gaming/Wrapper.qml','modules/gaming/Content.qml','modules/gaming/AdvancedProfileControls.qml',
 'modules/UpdaterController.qml','modules/updater/Wrapper.qml','modules/updater/Content.qml',
]: check_file(rel)

json_helper('caerice-hardware-probe')
json_helper('caerice-hardware-power')
json_helper('caerice-display-probe')
json_helper('caerice-display-transaction',['status'])
json_helper('caerice-display-persist',['status'])
json_helper('caerice-display-presets',['list'])
json_helper('caerice-display-workspaces',['status'])
json_helper('caerice-gaming-probe')
json_helper('caerice-gaming-profile',['list'])
json_helper('caerice-updater',['status'])
json_helper('caerice-updater-commit-base',['status'])

ipc={}
for target in ['hardware','display','gaming','updater']:
 cp=cmd(['qs','-c','caelestia','ipc','call',target,'isOpen'],8)
 ipc[target]={'ok':bool(cp and cp.returncode==0),'output':(cp.stdout.strip() if cp else '')}
 if not ipc[target]['ok']: warnings.append(f'IPC target unavailable: {target}')

auto={}
for action in ['is-enabled','is-active']:
 cp=cmd(['systemctl','--user',action,'caerice-power-auto.service'],8)
 auto[action]=cp.stdout.strip() if cp else 'unknown'

qml_errors=[]
root=Path(f'/run/user/{UID}/quickshell/by-id')
logs=sorted(root.glob('*/log.qslog'),key=lambda p:p.stat().st_mtime if p.exists() else 0,reverse=True) if root.exists() else []
if logs:
 cp=cmd(['strings',str(logs[0])],15)
 if cp:
  for line in cp.stdout.splitlines():
   if re.search(r'@.*\.qml\[[0-9]+:-1\]: (ReferenceError|TypeError|Error:)',line) and not re.search(r'Received event|windowtitle|activewindow|got toplevel',line,re.I): qml_errors.append(line)
   elif re.search(r'(Type .* unavailable|Binding loop detected|Cannot assign)',line) and ('@' in line or '.qml' in line): qml_errors.append(line)
if qml_errors: errors.extend([f'QML: {x}' for x in qml_errors[:20]])

print('===== SAD LIVE DIAGNOSTICS =====')
for r in rows: print(('MATCH ' if r['match'] else 'MISS  ')+r['path'])
print('\nIPC:',json.dumps(ipc,ensure_ascii=False))
print('Power Auto:',json.dumps(auto,ensure_ascii=False))
print('QML log:',str(logs[0]) if logs else 'none')
print('QML errors:',len(qml_errors))
if warnings:
 print('\nWARNINGS'); [print('-',x) for x in warnings]
if errors:
 print('\nERRORS'); [print('-',x) for x in errors]
 print('\nSAD DIAGNOSTIC: FAIL'); raise SystemExit(1)
print('\nSAD DIAGNOSTIC: OK' if not warnings else '\nSAD DIAGNOSTIC: OK_WITH_WARNINGS')
