# Wallpaper Manager

`SUPER + SHIFT + W` opens the native Caelestia wallpaper manager on the focused screen. The Bottom Hub thumbnail opens it on that Hub's screen.

The manager uses only `qs.services.Wallpapers`: preview, apply, random and category metadata. It never invokes a second wallpaper command or assumes a wallpaper directory. Previewed dynamic colours remain owned by `Wallpapers` and `Colours`.

V2 opens neutrally: it reselects `Wallpapers.actualCurrent`, aligns the orbit and focus, and does not preview. Path resolution uses an exact match first, then a basename only when it identifies one list entry, so canonical symlink paths remain safe and duplicate names never select arbitrarily. Explicit navigation coalesces wheel and touchpad deltas at 120 angle units or 40 pixel units. Each event emits at most one move and leaves a residual below its threshold; an opposite direction replaces the old residual. A single 220 ms timer previews only the final stable candidate; navigation replacement, category/model changes, close, Apply and Random cancel it. Cancel and every other-overlay exit call `stopPreview`.

Overlay exclusion is global across screens. A native shortcut, drawer toggle, gesture, controller or Bottom Hub action that opens any competing retained overlay closes Wallpaper Manager on every screen. Opening Wallpaper Manager clears competing overlays on every screen.

The orbital view has one central crossfading crop and at most eleven octagonal satellite images. The selected image is never duplicated in the orbit. Each image loads asynchronously at bounded source sizes. Satellite scale, opacity and z-order derive from its sine/cosine orbit depth. The responsive 900×680 maximum panel keeps centered category chips, concise metadata, native Caelestia buttons, Apply as the primary action and Random as secondary. Categories are `ALL` plus values from `Wallpapers.getCategoryFor`.

## Installation and rollback

Do not run deployment during development. Default staging never writes a live target:

```bash
python3 scripts/features/install-wallpaper-manager.py --stage /tmp/caerice-wallpaper-stage
```

`update-wallpaper-manager.py` has the same stage-only contract and refuses to overwrite an existing stage.

At an approved deployment use explicit `--apply`; it validates all exact targets, wires a temporary copy with `display,wallpaper`, and prepares `Wallpapers.qml` fail-closed. A pristine v2.3.0 service receives the patch. A service that already has every V1 generation, cancellation, queue, request-token, and stale-result guard is retained unchanged for a V1→V2 upgrade. Any partial or conflicting service aborts before backup or replacement. Before changing a live target, the installer writes the complete backup manifest; replacements use same-filesystem temporary files plus `os.replace`. Any post-mutation exception automatically restores the manifest before failing. The installer then preflights launcher JSON and writes a timestamped manifest-backed backup before replacing any target:

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
