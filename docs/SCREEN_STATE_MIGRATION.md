# Cortetsu screen state migration

## Boundary

`components/ScreenState.qml` remains the persistent compatibility store. It
instantiates `modules/CortetsuScreenState.qml`, which exposes the retained
overlay contract to first-party controllers without moving geometry, popouts,
tray ownership, or wallpaper side effects into state.

The adapter is intentionally transitional: `legacyState` is the only storage
source until every consumer has moved to the contract. Writes to retained
flags go through `setRetained(flag, value)`, and invalid flag names are
rejected.

## Migrated consumers

These controllers now read and write through `cortetsuState`:

- `CalendarController`
- `ClipboardController`
- `HardwareController`
- `DisplayController`
- `WallpaperController`
- `OverviewController`

They pass `cortetsuState.legacyState` to the compatibility `OverlayPolicy`
because launcher, session, dashboard, utilities, and sidebar still live in
the upstream state object.

## Policy rules

`CortetsuOverlayPolicy.js` owns only state transitions. It can close retained
flags, close all compatible panel flags, and open one retained flag
exclusively. Geometry, popouts, tray ownership, preview windows, and wallpaper
start/stop effects remain in their callers.

The static gate is
`scripts/features/test-cortetsu-screen-state.py`. The runtime build executes
it together with the existing retained-overlay and Wallpaper Manager tests.
