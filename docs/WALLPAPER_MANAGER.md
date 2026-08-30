# Wallpaper Manager

`SUPER + SHIFT + W` opens the native Caelestia wallpaper manager on the focused screen. The Bottom Hub thumbnail opens it on that Hub's screen.

The manager uses only `qs.services.Wallpapers`: preview, apply, random and category metadata. It never invokes a second wallpaper command or assumes a wallpaper directory. Previewed dynamic colours remain owned by `Wallpapers` and `Colours`.

The orbital view has one central crop and at most twelve satellite images. Images load asynchronously at bounded source sizes. Wheel input keeps one pending direction during the 220 ms rotation; Left/Right, Enter/Space and Escape map to move, apply and cancel. Categories are `ALL` plus values from `Wallpapers.getCategoryFor`.

## Installation and rollback

Do not run deployment during development. Default staging never writes a live target:

```bash
python3 scripts/features/install-wallpaper-manager.py --stage /tmp/caerice-wallpaper-stage
```

`update-wallpaper-manager.py` has the same stage-only contract and refuses to overwrite an existing stage.

At an approved deployment use explicit `--apply`; it validates all exact targets, wires a temporary copy with `display,wallpaper`, applies the pristine-v2.3.0 service patch there, preflights launcher JSON, then writes a timestamped manifest-backed backup before replacing any target:

```bash
python3 scripts/features/install-wallpaper-manager.py --apply --production \
  --live /etc/xdg/quickshell/caelestia \
  --usercfg /home/dilan/.config/caelestia/shell.json \
  --hypr-usercfg /home/dilan/.config/caelestia/hypr-user.lua \
  --backup-root /home/dilan/.local/share/caelestia-custom-system/snapshots
```

Run the privileged file install as Dilan, not through a root environment with an implicit `$HOME`; use `pkexec env HOME=/home/dilan ...` or an equivalent sudo command with all three explicit user paths above.

Rollback restores that timestamped backup, including `services/Wallpapers.qml`, the owned modules, `hypr-user.lua`, and `shell.json`:

```bash
python3 scripts/features/install-wallpaper-manager.py --rollback /path/to/wallpaper-manager-timestamp
```

The configurator itself is idempotent, preserves file mode, and creates no backup when no change is required.

## Gates

```bash
for script in scripts/features/test-*.py scripts/features/validate-*.py scripts/features/eval-*.py; do
  PYTHONDONTWRITEBYTECODE=1 python3 "$script"
done
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input caelestia/modules-owned/modules/wallpaper/tests/TestOrbit.qml
```
