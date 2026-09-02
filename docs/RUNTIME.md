# CaeRice runtime ownership

CaeRice never writes `/etc/xdg/quickshell/caelestia`. That path belongs to the
`caelestia-shell` package. The source of truth is `DilanRC/CaeRice`.

`scripts/install-caerice.sh` archives clean Caelestia `v2.4.0`, applies the
versioned patches and owned modules in a staging directory, runs the gates, and
only then atomically promotes:

- builds: `~/.local/share/caerice/builds/<timestamp>`
- active: `~/.config/quickshell/caelestia/current`
- rollback target: `~/.config/quickshell/caelestia/previous`
- pre-migration snapshots: `~/.local/share/caerice/snapshots/`

Run `~/.local/bin/caerice-rollback` to swap `current` and `previous`. No Google
Calendar data or credentials are involved in this operation.

Package changes are reported by `caelestia/bin/check-package-updates.sh`; a
build is not promoted unless the staged validation passes. Restart the shell
with `pkill -TERM -x qs; sleep 1; qs -c ~/.config/quickshell/caelestia/current -n -d`.
