# Status Pill checks

`test-status-pill.sh` validates the source contract for hidden, single-state,
combined-state and removal behavior: the component starts with no active states,
contracts to zero width, keeps the fixed `REC → DND → Awake` order, uses the
three shared singletons, and introduces no timer, process or detached shell call.
The production `BottomHub.qml` binds those values to `Recorder`, `Notifs`, and
`IdleInhibitor`, so every monitor renders the same source without starting another
backend.

Run the deterministic gate from the repository root:

```bash
cortetsu/tests/test-status-pill.sh
```

The repository installer owns `BottomHub.qml` and `StatusPill.qml` together.
Do not apply a one-off patch to `/etc`; use `scripts/install-cortetsu.sh`, whose
preflight and backup flow covers every owned Bottom Hub module. Wallpaper
Manager is outside this feature and is not modified by the Status Pill source.

The acceptance eval is separate from the gate and can be run with:

```bash
caelestia/evals/status-pill-eval.sh
```
