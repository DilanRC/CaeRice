# CaeRice

Repositorio fuente de las personalizaciones de Caelestia/Hyprland usadas en CachyOS.

## Objetivo

CaeRice guarda el código, patches, configuración y scripts necesarios para reconstruir las personalizaciones sin depender de copias manuales en `/etc/xdg/quickshell/caelestia`.

Estado base actual:

- `caelestia-shell 2.3.0-3`
- upstream `v2.3.0`
- upstream commit `94d5eb9e6fe9c6b1f69e663d9ed410a441e2d67f`
- Dock personalizado integrado
- Launcher integrado al Dock
- Overview `Super+Tab` con previews vivos
- workspaces 1–10 en eDP y 11–20 en HDMI
- `Super+V` reservado para Clipboard QML

## Estructura

- `current/`: seed legible de los módulos propios más recientes disponibles.
- `caelestia/`: snapshot exacto del sistema patch-based de la máquina; se llena con `scripts/sync-live-to-repo.fish`.
- `config/`: configuración de usuario versionada.
- `scripts/`: mantenimiento, migración y sincronización.
- `docs/`: arquitectura y planes de módulos.
- `archive/`: artefactos históricos de recuperación.

## Fuente de verdad

Una vez ejecutado `scripts/sync-live-to-repo.fish` desde la máquina, `caelestia/` pasa a ser la fuente exacta del estado instalado. Los directorios locales `legacy/`, `snapshots/`, `reinstall-backups/` y el clon `upstream-git/` no se versionan porque Git ya conserva el historial y esos datos se pueden regenerar.

## Flujo de trabajo

1. Sincronizar el estado estable a `main`.
2. Crear una rama `feature/<modulo>` para cada módulo nuevo.
3. Probar el módulo en el shell real.
4. Sincronizar los módulos/patches finales.
5. Integrar la rama a `main`.

El siguiente módulo planificado es `feature/clipboard-qml` para `Super+V`.

## Wallpaper Manager Orbital V2.1

El manager usa una órbita flotante sobre el wallpaper real, con scrim ligero y superficies dinámicas solo para categorías y acciones. La entrada espera el hero y siete thumbnails esenciales; una ventana de prefetch de hasta 18 imágenes a 128 px alimenta la cache compartida sin cargar la colección completa.

Verificación dirigida:

```bash
python3 scripts/features/test-wallpaper-manager.py
python3 scripts/features/eval-wallpaper-manager.py
python3 scripts/features/validate-wallpaper-manager.py
qmltestrunner -input caelestia/modules-owned/modules/wallpaper/tests -import caelestia/modules-owned -import /home/dilan/.local/share/caelestia-custom-system/upstream-git
```

El instalador atómico existente conserva el rollback; V2.1 no cambia servicios, preview, Apply, Random ni la política de overlays.
