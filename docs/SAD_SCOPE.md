# SAD scope

The retained SAD stack is:

- Hardware Center (`Super+H`) — prerequisite and hardware/power telemetry.
- Display Manager (`Super+Shift+O`) — safe display inspection, preview and persistence.

Gaming Center and Cortetsu Updater are retired. They are not part of installation, validation, live diagnostics or release acceptance.

`update-sad.sh` is the canonical convergence entrypoint: it preserves Hardware, synchronizes Display, removes legacy Gaming/Updater wiring and purges their installed artifacts/state.
