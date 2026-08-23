# Bottom Hub

## Objetivo

Reemplazar el dock y la barra lateral por una barra inferior completa y coherente para Caelestia/CaeRice.

La barra inferior vive en `modules/BottomHub.qml`. Usa superficies translúcidas de `Colours.tPalette`, iconos Material y estados de los servicios nativos de Caelestia. Conserva la lógica útil del antiguo `CustomDock.qml`: favoritas, agrupación por aplicación, ventanas por monitor, clic para lanzar/enfocar, rueda para recorrer ventanas, clic central para cerrar y clic derecho para fijar/quitar favoritas.

El contenido nativo de notificaciones, Utilities y los popouts se conserva, pero sus wrappers laterales se retiran. `SUPER+N` abre el centro de notificaciones inferior y `SUPER+I` abre Quick Settings. No queda barra visual, hotspot ni activación por hover en el borde izquierdo o derecho.

## Geometría

- Bottom Hub: superficie de 60 px con segmentos funcionales de 52 px.
- margen inferior: 2 px.
- popouts, notificaciones y Quick Settings: borde inferior unido a la parte superior del hub, alineados con el segmento de sistema.
- barra nativa: adaptador no visual de ancho cero, sin loader, input ni zona exclusiva.
- launcher nativo: `dockOffset = 72`.
- segmento de aplicaciones: ancho según su contenido, limitado por el espacio simétrico disponible y centrado en la pantalla.
- bandeja: isla adaptativa independiente entre aplicaciones y sistema.

## Archivos propios

- `caelestia/modules-owned/modules/BottomHub.qml`
- `caelestia/modules-owned/modules/HubButton.qml`

## Patches nativos implicados

- `shell.qml.patch`: carga `BottomHub` en vez de `CustomDock`.
- `modules__sidebar__Wrapper.qml.patch`: convierte el contenido de notificaciones en un centro inferior acotado.
- `modules__bar__BarWrapper.qml.patch`: desactiva por completo la barra lateral visual nativa.
- `modules__bar__popouts__*.qml.patch`: añade el modo inferior unido para los popouts nativos.
- `modules__drawers__Interactions.qml.patch`: conserva el popup mientras el puntero pasa del icono al contenido y elimina el Quick Toggles por hover.
- `modules__utilities__Wrapper.qml.patch`: desacopla Quick Settings del sidebar y lo coloca encima del hub.
- `modules__drawers__Panels.qml.patch`: centra el launcher y ancla las superficies inferiores a la derecha.
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
3. El logo CachyOS abre el launcher nativo encima del hub.
4. Las esferas cambian al workspace seleccionado y permiten cambiar con clic.
5. Favoritas y aplicaciones abiertas aparecen centradas y el segmento se contrae cuando hay pocas.
6. Clic en app: lanza o enfoca.
7. Rueda sobre una app con varias ventanas: recorre ventanas.
8. Clic central: cierra la ventana activa de esa app.
9. Clic derecho: fija/quita de favoritas.
10. Hover sobre volumen, output, Wifi, Bluetooth o batería abre su popup unido a la barra y permite entrar en él sin que se cierre.
11. Clic en volumen alterna mute y la rueda ajusta el nivel; output, Wifi y Bluetooth abren su configuración nativa.
12. Batería muestra el estado real y abre su popup.
13. La bandeja es una isla separada, prioriza el icono SNI real y abre sus menús nativos por hover.
14. Clic en fecha/hora abre y cierra Quick Toggles; pasar el mouse por una zona vacía no lo activa.
15. El botón de notificaciones y `SUPER+N` abren el nuevo centro inferior.
16. La fecha y `SUPER+I` abren el mismo Quick Settings; launcher, notificaciones y ajustes son excluyentes.
17. En dos monitores, cada barra muestra solo las ventanas de su monitor.
18. No existe barra vertical, hotspot lateral, fondo de media pantalla ni animación horizontal de popups.

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

No fusionar `feature/bottom-hub` a `main` hasta comprobar interacción, multimonitor, launcher, notificaciones y touchpad en el runtime real.
