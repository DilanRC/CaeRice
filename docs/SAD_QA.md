# SAD QA

## Repository

Run:

```bash
python3 scripts/features/validate-sad.py
```

Expected: `SAD STATUS: OK`.

## Live runtime

Run:

```bash
python3 scripts/features/diagnose-sad.py
```

Expected:
- Hardware and Display wiring are true.
- Hardware and Display IPC return `true` or `false`.
- Gaming and Updater IPC targets are absent.
- No retired Gaming/Updater QML or helper remains.
- No QML runtime errors.

## Manual acceptance

Verify Hardware pages, Display dry-run/preview/keep/save/revert, monitor hotplug and normal keyboard/mouse/touchpad interaction.
