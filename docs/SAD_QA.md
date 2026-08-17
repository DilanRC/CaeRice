# SAD final QA checklist

Run only after syncing branch `sad` to the live Caelestia tree.

## Automated

```fish
cd ~/CaeRice
git switch sad
git pull --ff-only
python3 scripts/features/validate-sad.py
python3 scripts/features/diagnose-sad.py
```

Expected before merge: consolidated validation `SAD STATUS: OK`, live diagnostics without QML errors, and repo/live hashes matching for all installed CaeRice-owned modules.

## Global regressions

- `Super` opens Launcher and clicks work.
- `Super+D` toggles Dock.
- `Super+V` opens Clipboard.
- `Super+Tab` opens Overview.
- `Super+H` opens Hardware Center.
- `Super+Shift+O` opens Display Manager.
- `Super+Shift+G` opens Gaming Center.
- `Super+Shift+U` opens CaeRice Updater.
- Empty space **inside** every panel does not close it.
- Clicking outside each panel closes it.
- `Esc` closes the active panel.
- Changing a Caelestia colour scheme recolours all new panels without hardcoded accents.

## Hardware Center regression

Run the existing `docs/HARDWARE_CENTER_QA.md`. Auto power rules must preserve the user's current enable/disable state across the SAD update.

## Display Manager

### Inventory

- eDP/HDMI connector names and GPU ownership match reality.
- `Writeback-*` never appears as a physical output.
- mode/Hz/scale/position/transform match `hyprctl -j monitors all`.
- unknown HDR/wide-colour capability displays as unknown, not supported.

### Candidate editor

- resolution/refresh cycles only through `availableModes`.
- scale and X/Y controls modify only the candidate before Preview.
- transform stays 0–7.
- disabling the final enabled output is blocked.
- Laptop/Dual/External built-in candidates behave sensibly for connected outputs.
- named layouts save/load/delete; loaded layout requires a new Dry run/Preview before Save.

### Transaction safety

Use a harmless visible change such as a temporary position offset or alternate supported refresh rate:

1. Dry run.
2. Preview.
3. Do not Keep; verify automatic rollback at ~15 s.
4. Preview again and Revert manually.
5. Preview again, Keep, then verify Save becomes available only for that exact candidate.
6. Change the candidate after Keep; Save must become disabled.

Only after those pass, persist a desired candidate and verify:

- backup created;
- reload succeeds;
- live layout matches;
- managed workspace block maps 1–10 to primary/internal and 11–20 to external/fallback.

Reconnect HDMI and repeat Dual topology once before merge.

## Gaming Center

### Inventory

- installed Steam titles and AppIDs match local manifests.
- Steam library paths are valid.
- Proton/GE-Proton inventory is sensible.
- GameMode/NVIDIA runtime state degrades cleanly when idle/unavailable.

### Profiles

Select a harmless test title and verify:

- GameMode toggle;
- MangoHud toggle;
- Gamescope toggle;
- default/integrated/NVIDIA GPU cycle;
- FPS cap;
- Gamescope game/output resolution presets;
- scaler whitelist: auto/integer/fit/fill/stretch;
- filter whitelist: linear/nearest/fsr/nis/pixel;
- FSR/NIS sharpness only;
- adaptive-sync toggle;
- fullscreen toggle;
- Save profile produces JSON under `~/.config/caerice/gaming-profiles.json`;
- `caerice-gaming-profile command` shows the expected argv/environment without launching;
- Launch starts through Steam and the wrappers disappear with the process tree.

Confirm Steam VDF files were not modified by Gaming Center.

## CaeRice Updater

Do not test Apply against an arbitrary ref. Use a known candidate and keep the system package update separate.

- Discover returns package/base/manifest/live inventory.
- Fetch stores the explicit ref under the updater cache.
- Test performs no live `/etc` write.
- Review classifications are visible and conflicts block Apply.
- Apply without `--confirm APPLY` is rejected.
- Apply is rejected if live raw target hashes differ from the tested candidate.
- Apply creates a full live snapshot before patching.
- a forced validator failure in an isolated QA scenario triggers rollback.
- explicit Rollback restores the selected snapshot.
- patch-base commit helper requires `--confirm COMMIT`.
- patch-base commit helper refuses unrelated dirty files.
- commit helper creates only a local commit and never pushes.

## Resource lifecycle

After closing Display/Gaming/Updater:

```fish
ps -ef | grep -E 'caerice-(display|gaming|updater)' | grep -v grep
```

Expected: no telemetry/helper loop remains. Detached Display preview watchdog is the only temporary exception while a preview countdown is active. Hardware Auto remains the only intentionally persistent CaeRice service when explicitly enabled.

## Merge rule

` sad ` is merge-ready only when:

- all automated validators pass;
- no QML errors remain;
- all four new/changed centers pass real mouse/touchpad/keybind testing;
- Display preview rollback is physically verified;
- Gaming launches one test title correctly;
- Updater Fetch/Test guards are verified;
- installer/rebuild path completes from the repo;
- no regression exists in Launcher, Dock, Clipboard, Overview or Hardware Center.
