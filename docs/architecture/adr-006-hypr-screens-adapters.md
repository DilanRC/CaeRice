# ADR-006: First-party Hyprland and screen adapters

## Status

Accepted

## Context

Cortetsu-owned modules directly imported the upstream `Hypr` and `Screens`
singletons. That made backend replacement unsafe because every consumer knew
the Caelestia service names and object layout.

## Decision

Expose `CortetsuHypr` and `CortetsuScreens` as first-party singleton contracts
under `modules-owned/modules`. They proxy the current upstream services while
the migration is in progress. Consumers use only the Cortetsu names for
toplevels, workspaces, monitors, active focus, screen enumeration and dispatch.

## Trade-offs

The current implementation still has an upstream backend, so it does not yet
remove the Hyprland dependency. In exchange, backend replacement is now
isolated to two adapters and can be tested without changing every consumer.

## Consequences

- New consumers must use `CortetsuHypr` and `CortetsuScreens`.
- The adapter API stays limited to data access, screen mapping, taskbar
  filtering and dispatch. Geometry and overlay state remain elsewhere.
- The static gate rejects direct retained backend singleton usage in owned
  modules outside the adapters.
