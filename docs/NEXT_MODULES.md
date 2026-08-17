# Post-Hardware Center module boundaries

These modules are intentionally separated into independent feature branches after
Hardware Center is merged. They should reuse the same native ContentWindow,
`ScreenState`/controller/Wrapper/Loader architecture, Caelestia colour/token
system and reproducible installer pattern.

## Display Manager — `feature/display-manager`

Reserved bind: `Super+Shift+O`.

Scope:
- Monitor inventory from Hyprland/DRM.
- Resolution, refresh, scale, transform, position and primary-role presets.
- Explicit eDP/HDMI topology and GPU/connector visibility.
- Safe preview/apply/revert workflow with a timeout before persistence.
- HDR/10-bit controls only when Hyprland/driver/output report support.
- Generated Hyprland monitor config with backup and rollback.

Non-goals:
- Raw EDID editing.
- Unsafe custom modelines without a separate expert workflow.

## Gaming Center — `feature/gaming-center`

Reserved bind: `Super+Shift+G`.

Scope:
- Detect Steam, Gamescope, GameMode, MangoHud, Proton/Wine and relevant launchers.
- Show AMD/NVIDIA availability and which GPU a game/process is using.
- Per-game launch profiles built from reversible environment/options.
- FPS/frametime/VRAM/temperature integration where existing tools expose it.
- Central launcher for game-specific presets without permanently forcing global GPU state.

Non-goals:
- Overclocking, voltage changes or bypassing anti-cheat.

## CaeRice Updater — `feature/caerice-updater`

Scope:
- Detect installed Caelestia package/version and current upstream tag/commit.
- Compare the live tree and CaeRice patch base before any update.
- Dry-run every native patch against the proposed upstream version.
- Snapshot live state before update/rebase.
- Classify patches as clean, offset/fuzz, conflict or obsolete.
- Never update Caelestia and apply CaeRice in one irreversible step.
- Provide rollback instructions and machine-readable audit output.

These skeleton branches must stay read-only until their probes and safety model
are validated on the real machine.
