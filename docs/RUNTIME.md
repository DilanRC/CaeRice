# Runtime versionado de Cortetsu

Cortetsu no escribe `/etc/xdg/quickshell/caelestia`. Ese árbol pertenece al
paquete. El constructor toma la revisión upstream exacta, aplica patches y
módulos en staging, ejecuta validadores y sólo entonces promueve una generación.

```text
~/.local/share/cortetsu/builds/<build-id>
~/.config/quickshell/cortetsu/current
~/.config/quickshell/cortetsu/previous
~/.config/quickshell/cortetsu/legacy-previous
```

Variables canónicas:

```text
CORTETSU_DATA_ROOT
CORTETSU_RUNTIME_ROOT
CORTETSU_UPSTREAM_SOURCE
```

Las variables `CORTETSU_*` equivalentes siguen como fallback temporal.

El flujo verifica que `v2.4.0` resuelva al commit
`24aa15eefdb146350d2548c0a015b04eddbd1008`, construye en `.staging-*`, genera
`BUILD.json`, mueve el resultado a una ruta inmutable y cambia `current` con un
symlink temporal más `mv -T`.

## Generaciones y migración heredada

`current` siempre debe ser una generación administrada por Cortetsu y contener
`BUILD_ID`, `BUILD.json`, `compatibility.json`, `composition.json` y los módulos
esenciales. `previous` sólo se usa como destino de rollback cuando cumple el
mismo contrato.

Las instalaciones anteriores podían dejar `previous` apuntando a un runtime que
tenía `shell.qml`, pero no `BUILD.json`. Esa generación no se borra: durante la
siguiente promoción se mueve a `legacy-previous`, queda visible para inspección
y se excluye del rollback automático. La generación `current` administrada
anterior pasa entonces a `previous`.

`cortetsu verify` valida `current` estrictamente. Si detecta un `previous`
heredado, emite una advertencia pero no declara inválida la generación actual.
`cortetsu-rollback` sí rechaza cualquier destino que no tenga metadatos
completos, evitando volver accidentalmente a un runtime pretransaccional.

## Rollback

```bash
cortetsu-rollback
```

El rollback valida ambas generaciones, usa el mismo lock y conmuta los enlaces
de forma atómica. El instalador copia todos los helpers `cortetsu-*` requeridos,
crea aliases `cortetsu-*`, instala la configuración de Hyprland, el puente de
temas y las unidades systemd de usuario.

Reinicio:

```bash
pkill -TERM -x qs
sleep 1
qs -p ~/.config/quickshell/cortetsu/current -n -d
```
