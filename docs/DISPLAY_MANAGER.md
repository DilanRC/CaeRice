# CaeRice Display Manager — skeleton

Branch: `feature/display-manager`

Reserved bind after integration: `Super+Shift+O`.

This branch starts from the completed Hardware Center candidate so it can reuse
the same controller → native `ContentWindow` → Wrapper/Loader architecture.

## Current skeleton

`caelestia/bin/caerice-display-probe` is intentionally read-only. It combines:

- `hyprctl -j monitors all`
- DRM connector state under `/sys/class/drm`
- connector → DRM card → GPU vendor mapping
- current geometry, refresh, scale, transform, focus and available modes

It does not issue `hyprctl keyword monitor`, change DPMS or edit configuration.

## Planned UI

- monitor cards for internal eDP and external outputs;
- live topology canvas with drag positioning;
- resolution/refresh/scale/transform controls;
- primary/focus role and workspace-range presets;
- GPU/connector ownership visibility;
- HDR/10-bit controls only if driver/Hyprland/output support is actually reported;
- saved named layouts.

## Safety contract

Every write must follow:

1. build a complete candidate monitor layout;
2. validate it against currently connected outputs/modes;
3. snapshot existing Hyprland monitor configuration;
4. apply as a temporary preview;
5. start a visible revert countdown;
6. persist only after explicit confirmation;
7. automatically revert on timeout/failure.

No raw EDID editing or unsafe custom modelines in the normal UI.

## First probe test

```fish
cd ~/CaeRice
git switch feature/display-manager
python3 caelestia/bin/caerice-display-probe | jq
```

The next implementation pass will add the native QML shell and a dry-run layout
planner before any write capability is introduced.
