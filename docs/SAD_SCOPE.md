# SAD engineering scope freeze

This file freezes the feature scope implemented on branch `sad` before physical-machine QA. Items below are engineering-complete candidates; runtime acceptance is tracked separately in `docs/SAD_QA.md`.

## Hardware Center

Status: **feature complete / regression only**.

- Overview, Performance, Processes, Sensors, I/O, Power, Auto and Energy.
- automatic AC/battery profile service is opt-in and already covered by its dedicated QA.
- no new Hardware Center features are added in SAD; only regressions block merge.

## Display Manager

Status: **feature complete candidate**.

Implemented scope:

- native ContentWindow integration;
- monitor/workspace/DRM inventory;
- AMD/NVIDIA connector ownership;
- Writeback filtering;
- topology editor plus drag-to-position;
- mode/refresh/scale/X/Y/transform/output enable state;
- Laptop/Dual/External built-in candidates;
- named layouts;
- capability-gated SDR/10-bit/Wide/HDR/VRR model;
- dry-run planner;
- timed live preview;
- detached watchdog;
- explicit Keep/Revert;
- exact-candidate Save;
- rollback snapshot includes configured color/bitdepth/VRR as well as geometry;
- atomic persistent geometry + color/bitdepth/VRR + workspace policy;
- managed workspace ranges 1–10 / 11–20;
- full standalone install/update/validation paths.

Primary-role policy for persistence is intentionally deterministic rather than a separate mutable compositor concept: internal/eDP is primary when present, otherwise the first enabled output; 11–20 use the first enabled non-eDP output and fall back to primary. Runtime focus remains Hyprland's normal focused-monitor state and is not persisted as a fabricated "primary monitor" flag.

## Gaming Center

Status: **feature complete candidate**.

Implemented scope:

- native ContentWindow integration;
- Steam library and manifest inventory;
- Proton/GE-Proton inventory;
- GameMode/Gamescope/MangoHud/Wine/NVIDIA status;
- Library/Profile/Runtime UI;
- atomic per-game profile schema;
- GameMode, MangoHud and Gamescope profile controls;
- Gamescope FPS, game/output resolution, scaler, filter, sharpness, adaptive-sync and fullscreen;
- default/integrated/NVIDIA process-local GPU prefixes;
- exact Steam `%command%` Launch Options generation;
- clipboard copy workflow;
- normal Steam open action with explicit no-false-claim semantics;
- no Steam VDF mutation;
- full install/update/validation paths.

Proton versions are inventoried but compatibility-tool selection remains in Steam for this release. This is a deliberate safety boundary, not an unfinished hidden writer: SAD does not silently rewrite Steam CompatToolMapping/VDF state.

## CaeRice Updater

Status: **feature complete candidate**.

Implemented scope:

- native ContentWindow integration;
- Discover / Fetch / Test / Review;
- isolated upstream candidate cache;
- patch classification;
- explicit package-update separation;
- exact tested-candidate/live hash guard;
- full live snapshot;
- explicit APPLY confirmation;
- rebuild order native patches → Clipboard → Hardware → Display → Gaming → Updater;
- post-apply validation;
- rollback on failure;
- explicit rollback command;
- guarded local patch-base commit;
- no automatic push;
- no automatic system package update;
- full install/update/validation paths.

## Reproducibility

Status: **feature complete candidate**.

- `scripts/install-caerice.sh` reconstructs Clipboard explicitly instead of relying on an already-customized live tree.
- `scripts/features/install-sad.sh` integrates the post-Hardware centers.
- `scripts/features/update-sad.sh` synchronizes the integrated centers.
- `scripts/features/validate-sad.py` runs the consolidated validators.
- `scripts/features/diagnose-sad.py` checks live hashes/helpers/IPC/QML logs/resource lifecycle.
- `scripts/features/sad-finish.sh` provides the single pre-QA synchronization/validation entrypoint.

## Not merge criteria

"Feature complete candidate" does not mean runtime accepted. The branch remains unmerged until the real-machine checks in `docs/SAD_QA.md` pass, especially Wayland pointer input, HDMI hotplug, timed display rollback, a real Steam Launch Options profile, updater guards, and clean rebuild reproducibility.
