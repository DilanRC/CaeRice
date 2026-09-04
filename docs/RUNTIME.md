# Runtime versionado de Cortetsu

Cortetsu no escribe `/etc/xdg/quickshell/caelestia`. Ese árbol pertenece al
paquete. El constructor toma la revisión upstream exacta, aplica patches y
módulos en staging, ejecuta validadores y sólo entonces promueve una generación.

```text
~/.local/share/cortetsu/builds/<build-id>
~/.config/quickshell/caelestia/current
~/.config/quickshell/caelestia/previous
```

Variables canónicas:

```text
CORTETSU_DATA_ROOT
CORTETSU_RUNTIME_ROOT
CORTETSU_UPSTREAM_SOURCE
```

Las variables `CAERICE_*` equivalentes siguen como fallback temporal.

El flujo verifica que `v2.4.0` resuelva al commit
`24aa15eefdb146350d2548c0a015b04eddbd1008`, construye en `.staging-*`, genera
`BUILD.json`, mueve el resultado a una ruta inmutable y cambia `current` con un
symlink temporal más `mv -T`. La generación anterior queda en `previous`.

Rollback:

```bash
cortetsu-rollback
```

El rollback valida ambas generaciones, usa el mismo lock y conmuta los enlaces
de forma atómica. El instalador copia todos los helpers `caerice-*` requeridos,
crea aliases `cortetsu-*`, instala la configuración de Hyprland, el puente de
temas y las unidades systemd de usuario.

Reinicio:

```bash
pkill -TERM -x qs
sleep 1
qs -p ~/.config/quickshell/caelestia/current -n -d
```
