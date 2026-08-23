# Bottom Hub QA

Fecha: 2026-08-23

## Alcance

Validación funcional y visual sobre una reconstrucción completa en
`/tmp/caerice-qa-shell`, levantada como una segunda instancia de Quickshell.
La prueba usa la configuración y servicios reales del usuario sin escribir en
`/etc/xdg`.

## Resultado

| Flujo | Resultado | Evidencia |
| --- | --- | --- |
| Carga de shell | PASS | `Configuration Loaded`, sin errores QML del Bottom Hub ni Keybinds |
| `SUPER+N` | PASS | `sidebar=1`, `utilities=1`; ambos paneles aparecen juntos y adyacentes |
| Centro de notificaciones con `sidebar.enabled=false` | PASS | El wrapper depende de `screenState.sidebar`, no de la barra lateral retirada |
| Quick Tools independiente | PASS | Abre y cierra `utilities` sin activar notificaciones |
| `SUPER+I` | PASS | Bind activo y Nexus conserva su destino original |
| `SUPER+H` | PASS | Bind activo; Hardware abre y cierra por IPC |
| Launcher | PASS | Abre/cierra y el mismo control puede alternarlo |
| Overview | PASS | Abre/cierra; corregido `Icons is not defined` en las tarjetas |
| Clipboard | PASS | Abre/cierra por controlador nativo |
| Display Manager | PASS | Abre/cierra por controlador nativo |
| Session y Dashboard | PASS | Ambos drawers alternan de `0` a `1` y vuelven a `0` |
| Islas center / tray / system | PASS | Contrato v4 y evaluación visual 17/17 |
| Popups de volumen, red, Bluetooth y batería | PASS | Anclaje por centro del icono y movimiento lateral retirado |
| Tray SNI | PASS | Isla separada y prioridad del icono nativo verificadas por gate |
| Editor: lectura | PASS | 98 atajos reales cargados |
| Editor: reasignación | PASS | Escritura atómica, detección de colisión, reload y rollback |
| Editor: creación de app | PASS | Guarda nombre, desktop id y comando; vuelve a listarlos |
| Editor: borrado | PASS | Confirmación doble, snapshot, eliminación y rollback probado |
| Editor: nombres e iconos | PASS | Brave Origin, Dolphin, Kitty y Volume Control resueltos visualmente |
| Esquema de color | PASS | Superficies e iconos usan `Colours.palette`/`Colours.tPalette` |

## Fallos encontrados y corregidos

1. El centro de notificaciones estaba bloqueado por
   `Config.sidebar.enabled=false`, aunque `SUPER+N` activaba su estado. El
   contenido inferior ahora es independiente de la barra lateral retirada.
2. El backend no exponía comando ni desktop id y la UI mostraba “Caelestia” en
   todas las filas. Ahora expone metadata y resuelve la entrada instalada.
3. No existía operación de borrado. Se añadió borrado de variables y binds de
   usuario, con snapshot y restauración automática.
4. Overview usaba `Icons.getAppIcon` sin importar `qs.utils`. El import faltante
   quedó añadido y cubierto por gate.

## Observación del equipo

`codium` figura como editor en `~/.config/hypr/variables.lua`, pero no existe un
ejecutable ni una entrada `.desktop` instalados. La fila conserva el nombre y
comando configurados con icono genérico; no se inventa una aplicación distinta.

## Comandos de regresión

```bash
python3 scripts/features/test-keybinds.py
python3 scripts/features/eval-keybind-editor.py
python3 scripts/features/test-bottom-hub-target.py
python3 scripts/features/test-bottom-hub-v3.py
python3 scripts/features/test-bottom-hub-v4.py
python3 scripts/features/test-retained-overlay-wiring.py
python3 scripts/features/eval-bottom-hub-design.py
```
