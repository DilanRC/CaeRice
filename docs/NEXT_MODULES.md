# Post-Hardware module boundaries

## Retained module: Display Manager

Reserved bind: `Super+Shift+O`.

Scope:
- Monitor inventory from Hyprland/DRM.
- Resolution, refresh, scale, transform and position.
- Laptop/dual/external topology presets.
- Safe dry-run, timed preview, keep/revert and persistent save workflow.
- HDR/10-bit/Wide/VRR controls only when support is established.
- Generated Hyprland monitor configuration with backup and rollback.

Non-goals:
- Raw EDID editing.
- Unsafe custom modelines without a separate expert workflow.

## Retired modules

Gaming Center and Cortetsu Updater were intentionally removed from the product and repository. They must not be installed, wired into `ScreenState`/`Panels`/`ContentWindow`, expose IPC targets, or leave helpers in `~/.local/bin`.

Game configuration and repository/upstream updates are handled manually outside Cortetsu's QML runtime.
