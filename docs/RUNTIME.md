# Runtime versionado de Cortetsu

Cortetsu nunca escribe `/etc/xdg/quickshell/caelestia`; ese árbol pertenece al paquete y se usa sólo como referencia. El constructor toma la revisión upstream exacta, aplica adapters y módulos en staging, ejecuta gates y sólo entonces promueve una generación.

```text
~/.local/share/cortetsu/builds/<build-id>
~/.config/quickshell/cortetsu/current
~/.config/quickshell/cortetsu/previous
~/.config/quickshell/cortetsu/legacy-previous   # sólo snapshot pre-v2, si existe
```

Variables canónicas:

```text
CORTETSU_DATA_ROOT
CORTETSU_RUNTIME_ROOT
CORTETSU_UPSTREAM_SOURCE
```

No existen fallbacks activos a variables CaeRice.

El flujo verifica que `v2.4.0` resuelva al commit `24aa15eefdb146350d2548c0a015b04eddbd1008`, construye en `.staging-*`, genera `BUILD.json`, convierte la salida en una ruta inmutable y conmuta `current` mediante symlink temporal + `mv -T`.

## Generaciones

`current` y `previous` sólo son válidos cuando contienen `BUILD_ID`, `BUILD.json`, `compatibility.json`, `composition.json` y módulos esenciales. El rollback rechaza cualquier destino que no cumpla ese contrato.

Durante la migración única a v2, un runtime pretransaccional puede conservarse en `legacy-previous`. Es un snapshot archivado para diagnóstico y nunca participa en rollback automático.

## Rollback

```bash
cortetsu-rollback
```

El rollback comparte el lock del constructor y conmuta enlaces atómicamente. El instalador coloca únicamente helpers `cortetsu-*`, la CLI, el wrapper de Caelestia, configuración Hyprland, bridge de temas y unidades systemd de usuario.

## Reinicio

```bash
pkill -TERM -x qs
sleep 1
qs -p ~/.config/quickshell/cortetsu/current -n -d
```

## Migración v2

`scripts/migrate-cortetsu-v2.sh` es idempotente. Antes de retirar nombres instalados antiguos crea un backup timestamped en `~/.local/share/cortetsu/migrations/`, migra Calendar/Pomodoro al namespace XDG de Cortetsu, migra el secreto de Calendar sin imprimirlo y conserva el opt-in del servicio de energía.
