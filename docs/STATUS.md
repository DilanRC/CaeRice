# Estado estable — 2026-08-16

## Terminado

- Dock personalizado: estable.
- Launcher integrado al Dock: estable.
- Overview `Super+Tab`: estable, con previews vivos y workspaces por monitor.
- Sistema de workspaces: eDP 1–10, HDMI 11–20.
- Limpieza de keybinds: `Super+V` liberado para Clipboard QML; eliminados los accesos redundantes acordados.
- Sistema de recuperación: migrado de copias completas a patches + módulos propios.
- Base de patches: Caelestia `v2.3.0`, commit `94d5eb9e6fe9c6b1f69e663d9ed410a441e2d67f`.
- Docker Desktop retirado; Docker Engine nativo se usa on-demand.

## Próximo módulo

Clipboard QML en `Super+V`.

## Regla de desarrollo

No usar un `PanelWindow` independiente para overlays interactivos. Integrar Clipboard en el árbol nativo de `ContentWindow.qml`, siguiendo la arquitectura que funciona con Overview.
