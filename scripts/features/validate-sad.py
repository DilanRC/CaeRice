#!/usr/bin/env python3
from __future__ import annotations
import subprocess, sys
from pathlib import Path
REPO=Path(__file__).resolve().parents[2]
scripts=[
 'scripts/features/audit-theme-colours.py',
 'scripts/features/validate-clipboard-qml.py',
 'scripts/features/validate-hardware-center.py',
 'scripts/features/validate-display-manager.py',
 'scripts/features/validate-gaming-center.py',
 'scripts/features/validate-caerice-updater.py',
]
failed=[]
print('===== SAD CONSOLIDATED VALIDATION =====')
for rel in scripts:
 p=REPO/rel
 if not p.is_file(): print('MISSING',rel); failed.append(rel); continue
 cp=subprocess.run([sys.executable,str(p)],cwd=REPO,text=True,capture_output=True,check=False)
 print(f'\n--- {rel} ---')
 print(cp.stdout,end='')
 if cp.stderr: print(cp.stderr,end='')
 if cp.returncode!=0: failed.append(rel)
if failed:
 print('\nSAD STATUS: FAIL'); print('failed:',', '.join(failed)); raise SystemExit(1)
print('\nSAD STATUS: OK')
