#!/usr/bin/env python3
from __future__ import annotations
import hashlib, json, os, re, subprocess
from pathlib import Path

REPO=Path(__file__).resolve().parents[2]
LIVE=Path(os.environ.get('CAERICE_LIVE_ROOT','/etc/xdg/quickshell/caelestia'))
UID=os.getuid()
errors=[]; warnings=[]; rows=[]

# feature -> (Controller instantiated in shell.qml, ScreenState.qml flag,
# Panels.qml Wrapper id). All four SAD centers are meant to be persistently
# mounted at shell.qml top level (not lazily created), so if any of these
# three integration points is missing the feature is completely unreachable
# even though its module files are byte-identical to source (see MATCH rows
# above) and validate-sad.py / the module file drift check both report OK.
WIRING={
 'hardware':{'controller':'HardwareController','flag':'hardware'},
 'display':{'controller':'DisplayController','flag':'displayManager'},
 'gaming':{'controller':'GamingController','flag':'gamingCenter'},
 'updater':{'controller':'UpdaterController','flag':'updaterCenter'},
}

def read(rel):
 p=LIVE/rel
 try:return p.read_text(encoding='utf-8')
 except OSError:return None

def check_wiring():
 shell=read('shell.qml'); screen=read('components/ScreenState.qml'); panels=read('modules/drawers/Panels.qml')
 wired={}
 for feature,spec in WIRING.items():
  missing=[]
  if shell is None or f"{spec['controller']} {{}}" not in shell: missing.append('shell.qml controller')
  if screen is None or f"property bool {spec['flag']}" not in screen: missing.append('ScreenState.qml flag')
  if panels is None or f"id: {spec['flag']}" not in panels: missing.append('Panels.qml Wrapper')
  wired[feature]=not missing
  if missing: errors.append(f'{feature}: not wired into live shell ({", ".join(missing)}) - feature is unreachable despite matching module files')
 return wired

def sha(p):
 try:return hashlib.sha256(p.read_bytes()).hexdigest()
 except OSError:return ''
def cmd(args,timeout=20):
 try:return subprocess.run(args,text=True,capture_output=True,timeout=timeout,check=False)
 except Exception:return None
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

def main():
 for rel in [
  'modules/HardwareController.qml','modules/hardware/Wrapper.qml','modules/hardware/Content.qml',
  'modules/DisplayController.qml','modules/display/Wrapper.qml','modules/display/Content.qml','modules/display/Editor.qml','modules/display/PreviewControls.qml','modules/display/DisplayPresets.qml','modules/display/DisplayCapabilities.qml','modules/display/DisplayOutputControls.qml',
  'modules/GamingController.qml','modules/gaming/Wrapper.qml','modules/gaming/Content.qml','modules/gaming/AdvancedProfileControls.qml',
  'modules/UpdaterController.qml','modules/updater/Wrapper.qml','modules/updater/Content.qml','modules/updater/CommitBaseControl.qml',
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

 wired=check_wiring()

 ipc={}
 for target in ['hardware','display','gaming','updater']:
  cp=cmd(['qs','-c','caelestia','ipc','call',target,'isOpen'],8)
  out=(cp.stdout.strip() if cp else '')
  # `qs ipc call` exits 0 even when the target doesn't exist - it just prints
  # "Target not found." to stdout. A bare returncode check therefore reports
  # a dead controller as healthy. Require a real boolean reply instead.
  ok=bool(cp and cp.returncode==0 and out in ('true','false'))
  ipc[target]={'ok':ok,'output':out}
  if not ok:
   if wired.get(target):
    errors.append(f'IPC target wired but not responding: {target} -> {out!r}')
   else:
    warnings.append(f'IPC target unavailable: {target} (not wired, see wiring errors above)')

 auto={}
 for action in ['is-enabled','is-active']:
  cp=cmd(['systemctl','--user',action,'caerice-power-auto.service'],8)
  auto[action]=cp.stdout.strip() if cp else 'unknown'

 persistent=[]
 cp=cmd(['ps','-eo','pid=,args='],10)
 if cp:
  for line in cp.stdout.splitlines():
   if re.search(r'caerice-(hardware-(probe|power)|display-(probe|plan|persist|presets|workspaces)|gaming-(probe|profile)|updater($|\s))',line) and 'diagnose-sad.py' not in line:
    persistent.append(line.strip())
 if persistent: warnings.extend([f'helper still running: {line}' for line in persistent[:12]])

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
 print('\nWiring:',json.dumps(wired,ensure_ascii=False))
 print('IPC:',json.dumps(ipc,ensure_ascii=False))
 print('Power Auto:',json.dumps(auto,ensure_ascii=False))
 print('Unexpected persistent helpers:',len(persistent))
 print('QML log:',str(logs[0]) if logs else 'none')
 print('QML errors:',len(qml_errors))
 if warnings:
  print('\nWARNINGS'); [print('-',x) for x in warnings]
 if errors:
  print('\nERRORS'); [print('-',x) for x in errors]
  print('\nSAD DIAGNOSTIC: FAIL'); raise SystemExit(1)
 print('\nSAD DIAGNOSTIC: OK' if not warnings else '\nSAD DIAGNOSTIC: OK_WITH_WARNINGS')


if __name__ == '__main__':
 main()
