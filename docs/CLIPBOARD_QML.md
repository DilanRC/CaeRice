# Clipboard QML — `Super+V`

## Objetivo

Reemplazar la apertura de Clipse con un drawer nativo de CaeRice integrado en el mismo árbol de interacción que el Overview.

## Requisitos iniciales

- `Super+V` abre/cierra el Clipboard.
- `Esc` cierra.
- `↑/↓` navegan.
- `Enter` copia/activa la entrada seleccionada.
- `Delete` elimina una entrada.
- búsqueda incremental.
- mouse/touchpad funcionales.
- historial persistente.
- deduplicación.
- soporte de texto y URLs desde la primera versión estable.
- arquitectura preparada para previews de imágenes y pin/unpin.

## Arquitectura

El overlay se integra en `modules/drawers/ContentWindow.qml`; no se crea un `PanelWindow` separado.

Módulos propios previstos:

```text
modules/ClipboardController.qml
modules/clipboard/Wrapper.qml
modules/clipboard/Content.qml
modules/clipboard/ClipboardItem.qml
```

Integraciones upstream previstas:

- `shell.qml`: instanciar `ClipboardController` si hace falta a nivel raíz.
- `modules/drawers/ContentWindow.qml`: región/panel del clipboard y focus grab.
- `modules/drawers/Regions.qml` / `Panels.qml`: solo si el diseño actual lo requiere.
- `modules/Shortcuts.qml` o IPC: exponer `caelestia:clipboard`.
- `hypr-user.lua`: `Super+V -> caelestia:clipboard` cuando el endpoint exista.

## Backend

No desinstalar `clipse` ni `cliphist` al iniciar el desarrollo. Primero detectar el backend de clipboard ya activo y construir el UI sobre una interfaz desacoplada. Cuando el módulo funcione de punta a punta, decidir cuál dependencia queda.

## Criterio de terminado

El módulo se considera estable cuando funciona con teclado y touchpad, conserva historial entre reinicios, no roba foco después de cerrar, no rompe Overview/Dock/Launcher, y `verify-patches.sh` reporta el estado esperado.
