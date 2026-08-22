# Arquitectura de CaeRice

## Principio principal

CaeRice no debe reemplazar archivos completos de una versión nueva de Caelestia con copias viejas. Las modificaciones se dividen en dos categorías:

1. **Módulos propios**: archivos completos que pertenecen a CaeRice, por ejemplo `BottomHub.qml`, `HubButton.qml`, `OverviewController.qml` y `modules/overview/*`.
2. **Integraciones sobre upstream**: cambios mínimos sobre archivos nativos de Caelestia, almacenados como patches.

## Base upstream actual

- paquete instalado: `caelestia-shell 2.3.0-3`
- tag: `v2.3.0`
- commit: `94d5eb9e6fe9c6b1f69e663d9ed410a441e2d67f`

## Runtime

El shell real continúa instalado bajo:

`/etc/xdg/quickshell/caelestia`

CaeRice es la fuente versionada. El runtime se valida/aplica mediante los scripts guardados en `caelestia/bin` después de sincronizar el estado real.

## Superficies e input

El Bottom Hub usa un `PanelWindow` propio únicamente para la barra inferior: botones, iconos de aplicaciones, rueda, clics y acciones simples.

Los overlays interactivos que necesitan scroll complejo, foco, teclado o una máscara de input coordinada deben permanecer en el árbol nativo de `modules/drawers/ContentWindow.qml`. Por eso la nueva sidebar inferior reutiliza `modules/sidebar/NotifDock.qml` y solo modifica su `Wrapper.qml`, `Panels.qml` y `Regions.qml`; no se dibuja una segunda sidebar dentro del `PanelWindow` del hub.

`ContentWindow.qml` es una superficie de integración compartida, no un archivo exclusivo del patch de Overview. Clipboard, Hardware Center y Display Manager extienden las mismas cadenas de layer, keyboard focus, input mask, focus grab y cierre. El preflight de Bottom Hub debe preservar esos miembros y validar el estado semántico compuesto; no debe exigir que el archivo vuelva a ser byte por byte el resultado del patch base.

El launcher también continúa siendo el launcher nativo de Caelestia y se desplaza 72 px para aparecer visualmente unido al Bottom Hub.

## Actualizaciones

Después de actualizar Caelestia:

```bash
bash ~/.local/share/caelestia-custom-system/bin/verify-patches.sh
```

- `APPLIED`: el patch literal está presente.
- `TARGET`: el archivo contiene el estado funcional objetivo, pero fue extendido por otras integraciones CaeRice y ya no coincide byte por byte con el patch base.
- `MISSING`: patch compatible pero no aplicado.
- `CONFLICT`: upstream o una integración cambió de forma que no satisface ni el patch ni las invariantes semánticas; adaptar antes de tocar el runtime.

`install-patches.sh` hace preflight y aborta antes de modificar nada si hay un conflicto. Para Bottom Hub, el instalador ejecuta además `test-bottom-hub-target.py` antes de iniciar la instalación, de modo que el propio checker semántico se valide antes de usarse sobre `/etc/xdg`.

## Git

`main` representa el estado estable probado. Cada módulo nuevo debe desarrollarse en una rama `feature/*` y fusionarse solo cuando funcione en el shell real.

El desarrollo de la interfaz inferior vive en `feature/bottom-hub` hasta completar las pruebas descritas en `docs/BOTTOM-HUB.md`.
