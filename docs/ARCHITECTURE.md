# Arquitectura de CaeRice

## Principio principal

CaeRice no debe reemplazar archivos completos de una versión nueva de Caelestia con copias viejas. Las modificaciones se dividen en dos categorías:

1. **Módulos propios**: archivos completos que pertenecen a CaeRice, por ejemplo `CustomDock.qml`, `OverviewController.qml` y `modules/overview/*`.
2. **Integraciones sobre upstream**: cambios mínimos sobre archivos nativos de Caelestia, almacenados como patches.

## Base upstream actual

- paquete instalado: `caelestia-shell 2.3.0-3`
- tag: `v2.3.0`
- commit: `94d5eb9e6fe9c6b1f69e663d9ed410a441e2d67f`

## Runtime

El shell real continúa instalado bajo:

`/etc/xdg/quickshell/caelestia`

CaeRice es la fuente versionada. El runtime se valida/aplica mediante los scripts guardados en `caelestia/bin` después de sincronizar el estado real.

## Overlays interactivos

Dock, Overview y futuros overlays interactivos deben integrarse en el árbol nativo de `modules/drawers/ContentWindow.qml` cuando necesitan foco/teclado/input mask. No se deben crear `PanelWindow` independientes para estos overlays: esa arquitectura produjo fallos de interacción con touchpad.

## Actualizaciones

Después de actualizar Caelestia:

```bash
bash ~/.local/share/caelestia-custom-system/bin/verify-patches.sh
```

- `APPLIED`: modificación presente.
- `MISSING`: patch compatible pero no aplicado.
- `CONFLICT`: upstream cambió; adaptar el patch antes de tocar el runtime.

`install-patches.sh` hace preflight y aborta antes de modificar nada si hay un conflicto.

## Git

`main` representa el estado estable probado. Cada módulo nuevo debe desarrollarse en una rama `feature/*` y fusionarse solo cuando funcione en el shell real.
