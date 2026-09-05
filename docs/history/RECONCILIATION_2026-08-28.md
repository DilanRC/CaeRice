# Reconciliación de máquina, 2026-08-28

## Alcance y resultado

La comparación fue de solo lectura. No se modificó `/etc/xdg`, `~/.config`, el
staging de `~/.local/share/caelestia-custom-system`, `main` ni ninguna rama
existente. La rama `reconcile/machine-2026-08-28` parte de `origin/main`, integra
el historial probado de `origin/feature/bottom-hub` y captura únicamente la
configuración activa posterior a ese historial.

Base comprobada:

- paquete: `caelestia-shell 2.3.0-3`;
- upstream: tag `v2.3.0`, commit `94d5eb9e6fe9c6b1f69e663d9ed410a441e2d67f`;
- runtime: `/etc/xdg/quickshell/caelestia`;
- fuente objetivo: `DilanRC/CaeRice`, `origin/main` en `6554451` al auditar;
- rama instalada y probada: `origin/feature/bottom-hub` en `9c85df2`.

## Clasificación

### UPSTREAM

Los archivos no listados abajo permanecen gestionados por
`caelestia-shell`. `pacman -Qkk caelestia-shell` reportó 411 archivos, 17 con
algún atributo alterado. `services/Wallpapers.qml` solo difiere en mtime, no en
contenido, por lo que sigue siendo `UPSTREAM`.

### PATCH

Estos archivos son propiedad del paquete, pero CaeRice gestiona su diferencia
mediante `caelestia/patches/MANIFEST.tsv`:

- `shell.qml` (`TARGET` semántico compuesto);
- `components/ScreenState.qml` (`TARGET`);
- `services/Hypr.qml`;
- `utils/NetworkConnection.qml`;
- `modules/Shortcuts.qml`;
- `modules/launcher/{AppList,Content,ContentList,Wrapper}.qml`;
- `modules/sidebar/Wrapper.qml`;
- `modules/bar/BarWrapper.qml`;
- `modules/bar/popouts/{Wrapper,ClipWrapper}.qml`;
- `modules/drawers/Interactions.qml`;
- `modules/utilities/Wrapper.qml`;
- `modules/drawers/Regions.qml` (`TARGET`);
- `modules/drawers/Panels.qml`;
- `modules/drawers/ContentWindow.qml` (`TARGET`).

Todos aceptan reversión literal del patch o pasan el checker semántico del
estado compuesto. No se encontró `PATCH/CONFLICT`.

### OWNED

Los 33 archivos bajo `caelestia/modules-owned/modules/` coinciden byte por byte
con el runtime. Incluyen Bottom Hub, Clipboard, Hardware, Display y Overview.

También coinciden con el repo:

- 11 helpers `caerice-*` instalados en `~/.local/bin`;
- `~/.config/systemd/user/caerice-power-auto.service`;
- `~/.config/caelestia/templates/kitty-caerice.conf`.

`cortetsu/bin/caerice-scheme-posthook` está versionado pero no instalado. Se
clasifica `OWNED/MISSING`; instalarlo solo corresponde si se activa ese flujo.

`~/.config/caelestia/shell.json`, `cli.json` y `~/.config/kitty/kitty.conf` son
estado mutable mantenido por Caelestia y sus integraciones. No se capturan como
copias completas.

### DRIFT

- `/etc/xdg/quickshell/caelestia/modules/Shortcuts.qml.orig`;
- `/etc/xdg/quickshell/caelestia/modules/launcher/Content.qml.save`.

Son residuos no gestionados, no pertenecen al paquete ni a `modules-owned`.
No se eliminaron. Deben revisarse y respaldarse antes de retirarlos.

El staging `~/.local/share/caelestia-custom-system` también está atrasado frente
al repo en scripts y `user-config/.config/caelestia/hypr-user.lua`. Sus patches y
módulos propios sí coinciden. No debe usarse `scripts/sync-live-to-repo.fish`
para corregirlo: el script reemplaza árboles completos, exige `main`, crea un
commit y hace push automáticamente.

## Cambios locales capturados

`~/.config/caelestia/hypr-user.lua`, modificado después de `9c85df2`, añadió:

- integración de Clipboard y Display Manager ausente en la copia de staging;
- `Super+Shift+Print` para captura de inventario de Warframe;
- reglas que aparcan únicamente el dock vacío y la ventana exclusive-mode de
  Overwolf;
- atajos del editor para The Witcher 3 y ChatGPT;
- eliminación del atajo anterior `Super+O` para Spotify.

`config/hypr-user.lua` y
`caelestia/user-config/.config/caelestia/hypr-user.lua` ahora son idénticos al
archivo activo. El snapshot previo está en
`/tmp/caerice-reconcile-20260828/hypr-user.lua`, SHA-256
`0d54edd51c7acfac21e745ee9f37fca8fdde370cf47c1c9c8eea1d1ebb27f7ff`.

## Riesgos

1. Copiar `origin/main` directamente al runtime quitaría módulos y wiring que
   ya están activos. La reconciliación debe validarse antes de fusionarse.
2. Ejecutar el sync histórico desde `main` puede reemplazar el repo con el
   staging atrasado y hacer push sin revisión.
3. Reinstalar `caelestia-shell` restaura archivos `PATCH` del paquete. Después de
   una actualización se debe ejecutar el preflight antes de reinstalar patches.
4. Las reglas de Overwolf dependen de la clase y títulos actuales de sus ventanas.
   Si Overwolf los cambia, dejarán de coincidir sin afectar otras ventanas.

## Rollback

- Repo: abandonar `reconcile/machine-2026-08-28`; `main` no cambió.
- Configuración propuesta: restaurar el snapshot de `/tmp` solo después de crear
  un respaldo nuevo del archivo activo.
- Runtime: usar el backup específico creado por `install-patches.sh` bajo
  `~/.local/share/caelestia-custom-system/reinstall-backups/`; no restaurar una
  copia de paquete completa sobre una versión distinta.
- Residuos `.orig` y `.save`: no eliminarlos hasta verificar que no son la única
  copia de un cambio manual.

## Verificación antes de fusionar

```bash
git switch reconcile/machine-2026-08-28
git diff --check origin/main...HEAD
python3 scripts/features/test-bottom-hub-target.py
python3 scripts/features/test-bottom-hub-v4.py
python3 scripts/features/test-keybinds.py
python3 scripts/features/test-retained-overlay-wiring.py
python3 scripts/features/eval-bottom-hub-design.py
python3 scripts/features/eval-keybind-editor.py
```

Verificación de runtime, sin instalar:

```bash
pacman -Qkk caelestia-shell
cmp config/hypr-user.lua ~/.config/caelestia/hypr-user.lua
```

No ejecutar instaladores ni eliminar los dos residuos hasta validar la rama y
decidir explícitamente el despliegue.
