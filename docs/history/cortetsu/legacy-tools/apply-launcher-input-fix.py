#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import tempfile
from pathlib import Path

LIVE = Path('/etc/xdg/quickshell/caelestia/modules/drawers/Regions.qml')

BAD = '''    R {
        panel: root.panels.launcher
        y: panel.y + root.borderThickness
        height: panel.height * (1 - root.panels.launcher.offsetScale) + root.borderThickness
    }
'''

UPSTREAM = '''    R {
        panel: root.panels.launcher
        y: root.win.height - height
        height: panel.height * (1 - root.panels.launcher.offsetScale) + root.borderThickness
    }
'''

GOOD = '''    R {
        panel: root.panels.launcher
        // Launcher.Wrapper is lifted above CustomDock by dockOffset. Keep the
        // upstream window-coordinate input-region formula and subtract exactly
        // the same offset so the visible panel and Wayland input region match.
        y: root.win.height - height - panel.dockOffset
        height: panel.height * (1 - root.panels.launcher.offsetScale) + root.borderThickness
    }
'''


def install(text: str) -> None:
    with tempfile.NamedTemporaryFile('w', encoding='utf-8', delete=False) as tmp:
        tmp.write(text)
        tmp_path = Path(tmp.name)
    try:
        subprocess.run(['sudo', 'install', '-m', '0644', str(tmp_path), str(LIVE)], check=True)
    finally:
        tmp_path.unlink(missing_ok=True)


def main() -> None:
    if not LIVE.exists():
        raise SystemExit(f'ERROR: no existe {LIVE}')

    text = LIVE.read_text(encoding='utf-8')
    if 'y: root.win.height - height - panel.dockOffset' in text:
        print('Launcher input region: ya corregida')
        return

    if BAD in text:
        text = text.replace(BAD, GOOD, 1)
    elif UPSTREAM in text:
        text = text.replace(UPSTREAM, GOOD, 1)
    else:
        raise SystemExit('ERROR: no reconozco el bloque launcher de Regions.qml; no toqué nada')

    install(text)
    print('Launcher input region: corregida')
    print('El panel visible y su región de clic ahora usan el mismo dockOffset.')


if __name__ == '__main__':
    main()
