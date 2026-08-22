# Bottom Hub

## Objetivo

Reemplazar la sidebar lateral y el dock independiente por una interfaz inferior coherente para Caelestia/CaeRice.

La barra inferior vive en `modules/BottomHub.qml`. Conserva la lógica útil del antiguo `CustomDock.qml`: favoritas, agrupación por aplicación, ventanas por monitor, clic para lanzar/enfocar, rueda para recorrer ventanas, clic central para cerrar y clic derecho para fijar/quitar favoritas.

La sidebar nativa de Caelestia **no se reimplementa**. `modules/sidebar/Wrapper.qml` se parchea para abrir desde abajo, encima del Bottom Hub. Así `NotifDock`, acciones, scroll y demás interacción permanecen dentro del `drawers/ContentWindow` nativo y de su máscara Wayland.

## Geometría

- Bottom Hub: 64 px.
- margen inferior: 2 px.
- separación de launcher/sidebar: hasta 72 px desde el borde inferior.
- sidebar inferior: ancho máximo 520 px y alto máximo 430 px o 55 % de la pantalla.
- launcher nativo: `dockOffset = 72`.

## Archivos propios

- `caelestia/modules-owned/modules/BottomHub.qml`
- `caelestia/modules-owned/modules/HubButton.qml`

## Patches nativos implicados

- `shell.qml.patch`: carga `BottomHub` en vez de `CustomDock`.
- `modules__sidebar__Wrapper.qml.patch`: cambia la sidebar de derecha a abajo.
- `modules__drawers__Panels.qml.patch`: recompone anclajes de sidebar, OSD, sesión y toasts.
- `modules__drawers__Regions.qml.patch`: actualiza la máscara de input Wayland.
- `modules__launcher__Wrapper.qml.patch`: mantiene el launcher encima del hub.

## Compatibilidad

`BottomHub.qml` conserva dos targets IPC:

- `bottomHub`
- `customDock`

El segundo existe para que el binding actual `SUPER+D` y scripts antiguos sigan funcionando durante la migración.

## Aplicación de prueba

No modificar archivos de `/etc/xdg/quickshell/caelestia` manualmente.

Desde el checkout de la rama:

```bash
git switch feature/bottom-hub
bash scripts/install-caerice.sh
```

El instalador ejecuta preflight con `patch --dry-run` antes de modificar el runtime. Si algún patch no corresponde a la versión instalada, aborta con `CONFLICT` sin aplicar cambios.

Después:

```bash
pkill -TERM -f 'qs -c caelestia'
sleep 1
caelestia shell -d
```

## Verificación manual

1. Bottom Hub visible en la parte inferior de cada monitor.
2. `SUPER+D` oculta/muestra el hub.
3. Botón Apps abre el launcher nativo encima del hub.
4. Botón Overview abre/cierra Overview.
5. Favoritas y aplicaciones abiertas aparecen en el centro.
6. Clic en app: lanza o enfoca.
7. Rueda sobre una app con varias ventanas: recorre ventanas.
8. Clic central: cierra la ventana activa de esa app.
9. Clic derecho: fija/quita de favoritas.
10. Botón de notificaciones abre la antigua sidebar como panel inferior.
11. El panel de notificaciones acepta scroll del touchpad y acciones.
12. El launcher y la sidebar no quedan abiertos simultáneamente.
13. En dos monitores, cada dock muestra solo las ventanas de su monitor.
14. OSD, sesión y toasts no se desplazan lateralmente al abrir notificaciones.

## Diagnóstico

Para observar errores QML:

```bash
journalctl --user -f | grep -Ei 'caelestia|quickshell|qml'
```

También puede ejecutarse el shell desde terminal:

```bash
caelestia shell -d
```

## Rollback

La rama estable sigue siendo `main`. Si la prueba falla, volver al estado estable del repositorio y reinstalar:

```bash
git switch main
bash scripts/install-caerice.sh
pkill -TERM -f 'qs -c caelestia'
sleep 1
caelestia shell -d
```

`install-patches.sh` crea además un backup previo en:

```text
~/.local/share/caelestia-custom-system/reinstall-backups/
```

No fusionar `feature/bottom-hub` a `main` hasta comprobar interacción, multimonitor, launcher, sidebar y touchpad en el runtime real.
