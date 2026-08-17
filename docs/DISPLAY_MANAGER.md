# CaeRice Display Manager

Branch: `feature/display-manager`

Reserved bind: `Super+Shift+O`.

Display Manager reuses the same native `ContentWindow` integration model as Hardware Center. Its controller is always light; the actual UI/probe tree is loaded only while the panel is open.

## Current phase

This phase is intentionally **read-only with respect to the live monitor layout**.

Implemented:

- native `DisplayController.qml` + `display/Wrapper.qml` integration;
- `Super+Shift+O` and IPC target `display`;
- monitor inventory from `hyprctl -j monitors all`;
- workspace inventory from `hyprctl -j workspaces`;
- DRM connector → card → GPU vendor mapping from `/sys/class/drm`;
- current geometry, refresh, scale, transform, DPMS, VRR/current-format fields when Hyprland reports them;
- topology canvas using the candidate logical coordinates;
- per-output candidate mode, scale and X/Y editing;
- current workspace, DPMS and GPU/card visibility;
- a separate `caerice-display-plan` helper that validates the candidate and produces the exact future `hyprctl keyword monitor ...` commands without executing them;
- overlap warnings and guardrails for unknown outputs, invalid modes, unsafe scales, duplicate outputs, transforms and disabling every output;
- full installer, development updater and validator.

## Safety boundary

`caerice-display-probe` never changes the display configuration.

`caerice-display-plan` is also dry-run only. Its output explicitly contains:

```json
{"applied": false}
```

No command produced by the planner is executed in this phase.

The next write-capable phase must implement the complete transaction:

1. build and validate a full candidate layout;
2. snapshot the existing monitor configuration;
3. apply the candidate only as a temporary preview;
4. display a visible countdown inside Display Manager;
5. require explicit **Keep layout** confirmation;
6. automatically revert on timeout, shell failure or rejection;
7. persist only after confirmation;
8. verify the persisted layout after reload.

There will be no normal UI for raw EDID mutation, arbitrary modelines, GPU overclocking or permanent writes without a preview/revert path.

## Files

- `caelestia/bin/caerice-display-probe`
- `caelestia/bin/caerice-display-plan`
- `caelestia/modules-owned/modules/DisplayController.qml`
- `caelestia/modules-owned/modules/display/Wrapper.qml`
- `caelestia/modules-owned/modules/display/Content.qml`
- `scripts/features/install-display-manager.sh`
- `scripts/features/update-display-manager.sh`
- `scripts/features/validate-display-manager.py`

## Install

```fish
cd ~/CaeRice
git switch feature/display-manager
git pull --ff-only
bash scripts/features/install-display-manager.sh
```

Then restart Caelestia and open:

```text
Super+Shift+O
```

or:

```fish
qs -c caelestia ipc call display open
```

## Dry-run diagnostics

```fish
python3 scripts/features/validate-display-manager.py
~/.local/bin/caerice-display-probe | jq
```

Inside the UI, edit a candidate and press **Dry run candidate** or `P`. The generated monitor lines are for review only until the timed preview transaction is implemented and QA'd on the real machine.
