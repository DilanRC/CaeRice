#!/usr/bin/env python3
from __future__ import annotations

import configparser
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
from datetime import datetime
from pathlib import Path

HOME = Path.home()
REPO = Path(__file__).resolve().parents[2]
LIVE = Path('/etc/xdg/quickshell/caelestia')
SHELL_JSON = HOME / '.config/caelestia/shell.json'
CLI_JSON = HOME / '.config/caelestia/cli.json'
KITTY_CONF = HOME / '.config/kitty/kitty.conf'
SCHEME_STATE = HOME / '.local/state/caelestia/scheme.json'
SNAP_ROOT = HOME / '.local/share/cortetsu/upstream/snapshots'
PACK = REPO / 'caelestia/schemes/cortetsu-pack'
PRESERVED = REPO / 'caelestia/schemes/local-preserved/latest'
INVENTORY = REPO / 'caelestia/schemes/local-preserved/inventory.json'
KITTY_TEMPLATE = REPO / 'caelestia/templates/kitty-cortetsu.conf'


def run(*args: str, check: bool = True, capture: bool = False):
    return subprocess.run(args, text=True, capture_output=capture, check=check)


def read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    try:
        obj = json.loads(path.read_text(encoding='utf-8'))
    except json.JSONDecodeError as exc:
        raise SystemExit(f'ERROR: JSON inválido en {path}: {exc}')
    if not isinstance(obj, dict):
        raise SystemExit(f'ERROR: {path} no contiene un objeto JSON')
    return obj


def write_json(path: Path, obj: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + '.tmp')
    tmp.write_text(json.dumps(obj, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    tmp.replace(path)


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def tree(root: Path) -> dict[str, str]:
    return {str(p.relative_to(root)): digest(p) for p in sorted(root.rglob('*.txt')) if p.is_file()}


def scheme_root() -> Path:
    cp = run('python3', '-c', 'from caelestia.utils.paths import scheme_data_dir; print(scheme_data_dir)', capture=True)
    path = Path(cp.stdout.strip())
    if not path.is_dir():
        raise SystemExit(f'ERROR: no existe scheme_data_dir: {path}')
    return path


def backup_file(path: Path, backup: Path, rel: str) -> None:
    if path.exists():
        dst = backup / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, dst)


def clone_official(dest: Path) -> Path:
    run('git', 'clone', '--quiet', '--depth', '1', '--filter=blob:none', '--sparse', 'https://github.com/caelestia-dots/cli.git', str(dest))
    run('git', '-C', str(dest), 'sparse-checkout', 'set', 'src/caelestia/data/schemes')
    return dest / 'src/caelestia/data/schemes'


def preserve_before_touch(local_root: Path, upstream_root: Path, backup: Path, stamp: str) -> dict:
    local, upstream = tree(local_root), tree(upstream_root)
    changed = sorted(rel for rel, sha in local.items() if rel not in upstream or upstream[rel] != sha)
    families = sorted(p.name for p in local_root.iterdir() if p.is_dir())

    print('\n===== SCHEMES PREEXISTENTES — ANTES DE TOCAR NADA =====')
    print('scheme_data_dir:', local_root)
    print('familias:', ', '.join(families) or '<ninguna>')
    print('archivos añadidos/modificados frente al upstream actual:', len(changed))
    for rel in changed:
        print('  LOCAL:', rel)

    run('sudo', 'cp', '-a', str(local_root), str(backup / 'schemes-before'))
    run('sudo', 'chown', '-R', f'{os.getuid()}:{os.getgid()}', str(backup / 'schemes-before'))

    if PRESERVED.exists():
        shutil.rmtree(PRESERVED)
    for rel in changed:
        dst = PRESERVED / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(local_root / rel, dst)

    info = {'capturedAt': stamp, 'schemeDataDir': str(local_root), 'families': families, 'localFiles': changed, 'hashes': local}
    write_json(INVENTORY, info)
    return info


def validate_scheme(path: Path) -> None:
    keys = set()
    for no, line in enumerate(path.read_text(encoding='utf-8').splitlines(), 1):
        if not line.strip():
            continue
        parts = line.split()
        if len(parts) != 2 or not re.fullmatch(r'[0-9A-Fa-f]{6}', parts[1]):
            raise SystemExit(f'ERROR: scheme inválido {path}:{no}: {line}')
        keys.add(parts[0])
    required = {'background', 'surface', 'onSurface', 'primary', 'secondary', 'tertiary', 'error'} | {f'term{i}' for i in range(16)}
    if missing := sorted(required - keys):
        raise SystemExit(f'ERROR: faltan keys en {path}: {missing}')


def install_catalog(local_root: Path, upstream_root: Path) -> tuple[int, int]:
    print('\n===== COMPLETANDO CATÁLOGO OFICIAL =====')
    official = 0
    for src in sorted(upstream_root.rglob('*.txt')):
        dst = local_root / src.relative_to(upstream_root)
        if dst.exists():
            continue
        run('sudo', 'mkdir', '-p', str(dst.parent))
        run('sudo', 'install', '-m', '0644', str(src), str(dst))
        official += 1
        print('ADD official:', dst.relative_to(local_root))

    run('python3', str(REPO / 'scripts/features/generate-cortetsu-schemes.py'))
    print('\n===== CORTETSU SCHEME PACK =====')
    custom = 0
    for src in sorted(PACK.rglob('*.txt')):
        validate_scheme(src)
        dst = local_root / src.relative_to(PACK)
        if dst.exists():
            print('KEEP existing:', dst.relative_to(local_root))
            continue
        run('sudo', 'mkdir', '-p', str(dst.parent))
        run('sudo', 'install', '-m', '0644', str(src), str(dst))
        custom += 1
        print('ADD Cortetsu:', dst.relative_to(local_root))
    return official, custom


def enable_theme_bridge(backup: Path) -> None:
    print('\n===== THEME BRIDGE =====')
    backup_file(CLI_JSON, backup, 'config/cli.json')
    cfg = read_json(CLI_JSON)
    theme = cfg.setdefault('theme', {})
    if not isinstance(theme, dict):
        raise SystemExit('ERROR: theme en cli.json no es objeto')

    always = ('enableTerm', 'enableHypr', 'enableGtk', 'enableQt')
    for key in always:
        theme[key] = True
    optional = {
        'enableChromium': ('brave', 'chromium', 'google-chrome-stable'),
        'enableSpicetify': ('spicetify',), 'enableBtop': ('btop',),
        'enableNvtop': ('nvtop',), 'enableHtop': ('htop',),
        'enableCava': ('cava',), 'enableFuzzel': ('fuzzel',),
        'enableDiscord': ('discord', 'vesktop', 'equibop'), 'enableZed': ('zed',),
    }
    for key, commands in optional.items():
        if any(shutil.which(cmd) for cmd in commands):
            theme[key] = True
    write_json(CLI_JSON, cfg)
    print(json.dumps(theme, indent=2, ensure_ascii=False))

    if KITTY_TEMPLATE.exists():
        target = HOME / '.config/caelestia/templates/kitty-cortetsu.conf'
        backup_file(target, backup, 'config/kitty-template.conf')
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(KITTY_TEMPLATE, target)

        backup_file(KITTY_CONF, backup, 'config/kitty.conf')
        KITTY_CONF.parent.mkdir(parents=True, exist_ok=True)
        text = KITTY_CONF.read_text(encoding='utf-8') if KITTY_CONF.exists() else ''
        include = 'include ~/.local/state/caelestia/theme/kitty-cortetsu.conf'
        if include not in text:
            if text and not text.endswith('\n'):
                text += '\n'
            text += '\n# Cortetsu: Caelestia active scheme\n' + include + '\n'
            KITTY_CONF.write_text(text, encoding='utf-8')
        print('Kitty bridge: OK')


def entries() -> list[dict[str, str]]:
    roots = [HOME / '.local/share/applications', Path('/usr/local/share/applications'), Path('/usr/share/applications')]
    out, seen = [], set()
    for root in roots:
        if not root.is_dir():
            continue
        for path in sorted(root.rglob('*.desktop')):
            rel = path.relative_to(root)
            parts = list(rel.parts); parts[-1] = parts[-1][:-8]
            eid = '-'.join(parts)
            if eid.lower() in seen:
                continue
            parser = configparser.ConfigParser(interpolation=None, strict=False); parser.optionxform = str
            try:
                parser.read(path, encoding='utf-8'); sec = parser['Desktop Entry']
            except Exception:
                continue
            if sec.get('Hidden', 'false').lower() == 'true' or sec.get('NoDisplay', 'false').lower() == 'true':
                continue
            seen.add(eid.lower())
            out.append({'id': eid, 'name': sec.get('Name', ''), 'exec': sec.get('Exec', ''), 'wmclass': sec.get('StartupWMClass', '')})
    return out


def find_entry(items: list[dict[str, str]], needle: str):
    n = needle.lower(); candidates = []
    for item in items:
        fields = [item['id'].lower(), item['name'].lower(), item['exec'].lower(), item['wmclass'].lower()]
        if not any(n in f for f in fields):
            continue
        score = (100 if item['id'].lower() == n else 0) + (50 if item['id'].lower().startswith(n) else 0) + (30 if n in item['id'].lower() else 0) + (20 if n in item['exec'].lower() else 0)
        candidates.append((score, item))
    return max(candidates, key=lambda x: x[0])[1] if candidates else None


def seed_dock(backup: Path) -> list[str]:
    print('\n===== DOCK: FAVORITOS PERSISTENTES =====')
    backup_file(SHELL_JSON, backup, 'config/shell.json')
    cfg = read_json(SHELL_JSON)
    launcher = cfg.setdefault('launcher', {})
    current = launcher.get('favouriteApps', []) or []
    if not isinstance(current, list):
        raise SystemExit('ERROR: launcher.favouriteApps no es array')

    app_entries, added = entries(), []
    for needle in ('kitty', 'dolphin', 'brave', 'spotify', 'github', 'claude'):
        item = find_entry(app_entries, needle)
        if not item:
            continue
        eid = item['id']
        matched = False
        for pattern in current:
            try:
                if re.search(pattern, eid, re.IGNORECASE): matched = True; break
            except re.error:
                if pattern == eid: matched = True; break
        if not matched:
            current.append(eid); added.append(eid)
            print('PIN:', eid, '|', item['name'])
    launcher['favouriteApps'] = current
    write_json(SHELL_JSON, cfg)
    print('favouriteApps:', json.dumps(current, ensure_ascii=False))
    return added


def reapply_current() -> None:
    state = read_json(SCHEME_STATE)
    name = str(state.get('name', '')).strip()
    if not name:
        return
    cmd = ['caelestia', 'scheme', 'set', '-n', name]
    for flag, key in (('-f', 'flavour'), ('-m', 'mode'), ('-v', 'variant')):
        value = str(state.get(key, '')).strip()
        if value: cmd += [flag, value]
    cp = run(*cmd, check=False, capture=True)
    if cp.returncode:
        print('WARN: no se pudo reaplicar el esquema actual:', cp.stderr.strip())
    else:
        print('Esquema actual reaplicado:', name)


def git_backup() -> None:
    run('git', '-C', str(REPO), 'add', 'caelestia/schemes', 'caelestia/modules-owned/modules/CustomDock.qml', check=False)
    status = run('git', '-C', str(REPO), 'status', '--porcelain', capture=True, check=False).stdout.strip()
    if not status:
        return
    commit = run('git', '-C', str(REPO), 'commit', '-m', 'theme: preserve local schemes, add theme pack and dock pins', check=False, capture=True)
    if commit.returncode:
        print('WARN: no pude hacer commit automático:', commit.stderr.strip()); return
    push = run('git', '-C', str(REPO), 'push', check=False, capture=True)
    print('GitHub push:', 'OK' if push.returncode == 0 else 'falló; ejecuta git push')


def main() -> None:
    if not shutil.which('caelestia') or not shutil.which('git'):
        raise SystemExit('ERROR: necesito caelestia y git en PATH')
    stamp = datetime.now().astimezone().strftime('%Y%m%d-%H%M%S')
    backup = SNAP_ROOT / f'theme-dock-{stamp}'; backup.mkdir(parents=True, exist_ok=True)
    local_root = scheme_root()

    with tempfile.TemporaryDirectory(prefix='cortetsu-cli-') as td:
        upstream = clone_official(Path(td) / 'cli')
        info = preserve_before_touch(local_root, upstream, backup, stamp)
        official_added, custom_added = install_catalog(local_root, upstream)

    enable_theme_bridge(backup)
    pinned = seed_dock(backup)
    run('python3', str(REPO / 'scripts/features/patch-dock-pins.py'))
    reapply_current()
    git_backup()

    print('\n===== RESULTADO =====')
    print('backup:', backup)
    print('locales preservados:', len(info['localFiles']))
    print('archivos oficiales nuevos:', official_added)
    print('schemes Cortetsu nuevos:', custom_added)
    print('pins sembrados:', ', '.join(pinned) or '<ninguno>')
    print("reinicio requerido: pkill -TERM -f 'qs -c caelestia'; sleep 1; caelestia shell -d")


if __name__ == '__main__':
    main()
