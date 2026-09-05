# Clipboard QML — `Super+V`

## Objetivo

Reemplazar la apertura de Clipse con un drawer nativo de Cortetsu integrado en el mismo árbol de interacción que Overview, con nivel visual equivalente o superior al Dock y al launcher personalizado.

## Interacción

- `Super+V` abre/cierra el Clipboard.
- `Esc` cierra.
- `↑/↓` navegan.
- `Enter` copia/activa la entrada seleccionada y cierra.
- `Delete` elimina una entrada.
- `P` fija/desfija la entrada seleccionada.
- `Ctrl+F` enfoca la búsqueda.
- clic selecciona.
- doble clic copia.
- clic medio elimina.
- clic derecho fija/desfija.
- botones por tarjeta: pin, copiar y eliminar.

## Arquitectura

El overlay se integra en `modules/drawers/ContentWindow.qml`; no se crea un `PanelWindow` separado.

Módulos propios:

```text
modules/ClipboardController.qml
modules/clipboard/Wrapper.qml
modules/clipboard/Content.qml
modules/clipboard/ClipboardItem.qml
```

Integraciones upstream:

- `shell.qml`: instancia `ClipboardController`.
- `components/ScreenState.qml`: estado `clipboard` por pantalla.
- `modules/drawers/ContentWindow.qml`: focus/input y scrim del drawer.
- `modules/drawers/Panels.qml`: integra `Clipboard.Wrapper` en el árbol nativo.
- `hypr-user.lua`: `Super+V -> caelestia:clipboard`.

## Backend

Clipse sigue siendo el backend de captura de historial mediante `clipse -listen` y sus procesos `wl-paste --watch`. El QML reemplaza únicamente la interfaz TUI. El historial se consume desde `~/.config/clipse/clipboard_history.json` mediante `FileView` con vigilancia de cambios y escrituras atómicas.

Al cerrar el drawer, `Wrapper.qml` destruye el `Loader` del contenido pesado. `FileView`, `ListView`, previews y delegates dejan de existir mientras el Clipboard está cerrado; no se mata el proceso completo de Quickshell porque ese proceso aloja todo Caelestia.

## Diseño Cortetsu

La interfaz sigue el mismo sistema visual que Dock/Launcher:

- ningún color principal está hardcodeado;
- superficies, texto, bordes y acentos provienen de `Colours.palette` / `Colours.tPalette`;
- tamaños, radios y tipografía usan `Tokens`;
- el acento seleccionado usa `m3primary` y `m3secondaryContainer` del esquema activo;
- el panel usa capas tonales en vez de una caja negra fija, por lo que cambia correctamente con el esquema de Caelestia;
- header con icono, contador, filtros `All/Pinned` y `Clear`;
- buscador visual con shortcut `Ctrl+F`;
- tarjetas compactas con icono contextual para texto, comando, URL o imagen;
- preview real para imágenes;
- acciones independientes por tarjeta;
- selección, hover y foco con transiciones cortas coherentes con el Dock;
- footer con keycaps para las acciones principales.

La referencia visual es el mock-up premium generado durante el desarrollo, pero la implementación no copia colores fijos del mock-up: traduce la jerarquía, espaciado, tarjetas, controles y acento al esquema Material activo.

## Criterio de terminado

El módulo se considera estable cuando funciona con teclado y touchpad, conserva historial entre reinicios, no roba foco después de cerrar, descarga el contenido pesado al cerrarse, no rompe Overview/Dock/Launcher, responde correctamente al IPC del runtime Cortetsu y `cortetsu verify` reporta el estado esperado.
