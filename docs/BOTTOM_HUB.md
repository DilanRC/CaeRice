# Bottom Hub — rediseño visual (2026-08-22)

## Qué es

`BottomHub.qml` es la barra inferior flotante (dock + launcher + overview +
notificaciones + quick toggles + reloj + sesión), reemplazo de `CustomDock`.
Vive en `modules-owned/modules/BottomHub.qml` + `HubButton.qml`, y su
IPC target sigue siendo `bottomHub` (con `customDock` como alias de
compatibilidad para el binding `SUPER+D` existente).

## Problema que resuelve este cambio

La barra se veía grande y el panel de notificaciones dejaba una "huella"
visual incluso cerrado. Causa raíz, en orden de impacto:

1. **`modules/drawers/Panels.qml` tenía un hunk sin aplicar.** El patch de
   `modules/sidebar/Wrapper.qml` ya asumía que el panel de notificaciones
   sería reanclado (`anchors.horizontalCenter` + `anchors.bottom: parent.bottom`),
   pero en el sistema real seguía anclado como columna derecha
   (`anchors.top: notifications.bottom; anchors.bottom: utilities.top; anchors.right: parent.right`).
   Con top **y** bottom anclados a la vez, el alto real del panel dejaba de
   depender de `implicitHeight` y pasaba a depender del hueco entre
   `notifications.bottom` y `utilities.top` — casi toda la pantalla. De ahí
   el bloque enorme y deformado del screenshot.
2. **`modules/utilities/Wrapper.qml` nunca se parcheó.** Seguía 100% upstream:
   ancho atado a `sidebar.width * sidebar.offsetScale * horizontalStretch`, y
   visible cuando `screenState.sidebar || screenState.utilities` — es decir,
   abrir notificaciones abría también Quick Toggles y lo estiraba al ancho
   de notificaciones ("attached to sidebar", el merge visual de Caelestia
   upstream). Por eso ambos aparecían fusionados en una sola masa.
3. **Fondo compartido (`PanelBg`/blob) sin aislar.** `sidebarBg`/`utilsBg` en
   `ContentWindow.qml` tenían `exclude`/`bottomLeftRadius`/`topLeftRadius`
   cruzados para fingir que eran un solo panel — vestigio del merge de (2).
4. **Región de input fantasma en Quick Toggles.** `Regions.qml` fijaba
   `y: root.win.height - height` para `utilities`, ignorando su posición
   real; con el panel cerrado quedaba una tira de pocos px pegada al borde
   inferior, capturando clics, en vez de seguir al panel fuera de pantalla.

## Diseño actual

- **Notificaciones** (`modules/sidebar`): popover flotante, centrado
  horizontalmente, anclado por abajo (`anchors.bottom: parent.bottom`),
  clearance fijo de 72px sobre el hub. Cerrado, se desliza completo bajo el
  borde de pantalla (no shrink-to-zero, mismo patrón que `session`/`osd`).
- **Quick Toggles** (`modules/utilities`): ahora es un popover **independiente**,
  desacoplado de `sidebar` (se eliminó `horizontalStretch`, `sidebarLerp`, el
  estado `attachedToSidebar` y la property `sidebar`). Se activa solo con
  `screenState.utilities`. Sigue anclado abajo-derecha (no compite
  visualmente con el popover de notificaciones, centrado).
- **BottomHub.qml**: pastilla compacta (52px de alto, antes 64), padding y
  separadores más ajustados, iconos de dock más chicos (42×44, antes 48×50).
  Nuevo botón "Quick Toggles" (icono `tune`) — antes no existía forma de
  abrir Quick Toggles sin abrir notificaciones.
- Cerrar cualquier popover del hub (`closeAllPopovers()`) cierra los tres
  (launcher, sidebar, utilities) para mantener "un solo drawer abierto a la
  vez", igual que antes.
- Click fuera del panel de Quick Toggles ahora lo cierra
  (`HyprlandFocusGrab` en `ContentWindow.qml` incluye `s.utilities`), igual
  que ya pasaba con notificaciones.

## Status Pill transitorio (2026-08-31)

`modules-owned/modules/StatusPill.qml` aparece entre los controles del sistema
y el reloj, solo mientras existe alguno de estos estados compartidos:

1. `Recorder.running` — `REC`, primero, y al hacer click llama `Recorder.stop()`.
2. `Notifs.dnd` — `DND`, segundo, y al hacer click alterna el DND de Caelestia.
3. `IdleInhibitor.enabled` — `Awake`, tercero, y al hacer click alterna el
   inhibidor Wayland de Caelestia.

No crea servicios, scripts ni timers. Cada instancia del Bottom Hub se enlaza
a esos mismos singletons, por lo que los dos monitores muestran el mismo estado
sin duplicar procesos. La anchura se anima a cero al desaparecer el último
estado; no queda una región visual reservada.

El instalador existente `scripts/install-cortetsu.sh` aplica los módulos propios
con preflight y backup. Wallpaper Manager queda fuera de este cambio. Para
revertir, restaura el backup que el instalador deja en
`~/.local/share/cortetsu/upstream/reinstall-backups/` y reinicia
Caelestia.

## Archivos tocados

- `modules-owned/modules/BottomHub.qml` — rediseño + botón Quick Toggles.
- `modules-owned/modules/HubButton.qml` — tamaño por defecto 40×44 (antes 48×50).
- `patches/modules__drawers__Panels.qml.patch` — aplica de verdad el reanclaje
  de `sidebar`; quita `sidebar:` de `Utilities.Wrapper`; toasts ya no
  dependen de `sidebar.top`.
- `patches/modules__drawers__ContentWindow.qml.patch` — `utilities` entra al
  focus-grab; se borra el binding muerto `utilities.horizontalStretch`; se
  simplifican `sidebarBg`/`utilsBg` (sin exclude cruzado).
- `patches/modules__drawers__Regions.qml.patch` — la región de `utilities`
  sigue su `y` real en vez de fijarse al borde de pantalla.
- `patches/modules__utilities__Wrapper.qml.patch` — **nuevo**. Desacopla
  Quick Toggles de `sidebar`, mismo patrón de popover flotante que
  `sidebar/Wrapper.qml`.
- `patches/MANIFEST.tsv` — registra el patch nuevo de arriba.

## Riesgo conocido, no corregido en este cambio

`modules/drawers/Interactions.qml` (sin parchear, upstream) todavía calcula
el gesto de "arrastrar desde el borde derecho para revelar notificaciones"
asumiendo que `sidebar` es una columna anclada a la derecha
(`panels.sidebar.x`, `inRightPanel`, umbral de threshold horizontal). Con
notificaciones ahora centradas abajo, ese gesto queda desalineado con el
panel real. No estaba en el alcance pedido y no rompe nada que ya
funcionara (el gesto de swipe-desde-el-borde ya era el remanente de un
diseño de sidebar-lateral que la BottomHub abandonó antes de este cambio).
Seguimiento sugerido: decidir si se remapea a swipe-desde-abajo o se
retira.
