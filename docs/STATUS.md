# Estado estable — 2026-08-30

## Terminado

- Wallpaper Manager orbital V2.1: acceso `Super+Shift+W`, apertura neutral y debounce V2 preservados; órbita flotante sin panel opaco, scrim ligero, surfaces dinámicas locales, estado Current/Preview, gate de apertura y prefetch acotado a 18 imágenes. Validado en runtime en eDP y HDMI, navegación rápida sin thumbnails vacíos, 40 aperturas con 0 fallos y RSS -9,128 KiB, logs QML limpios y video `/home/dilan/Vídeos/v2.1.mp4`.

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
