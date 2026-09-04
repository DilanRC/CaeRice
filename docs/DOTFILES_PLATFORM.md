# Cortetsu dotfiles platform

Cortetsu no trata los dotfiles como enlaces sueltos al repositorio. Los construye como generaciones inmutables, valida el contenido y cambia una única referencia `current`.

## Modelo

```text
repo
  dotfiles/manifest.toml
  profiles/*.toml
  packages/arch.toml
        |
        v
~/.local/share/cortetsu/dotfiles/builds/<id>/home/...
        |
        +-- current
        +-- previous
        |
        v
~/.config/... -> ~/.local/share/cortetsu/dotfiles/current/home/.config/...
```

Los targets administrados apuntan siempre a la ruta estable `current`. Un cambio de generación modifica todo el conjunto sin volver a escribir cada configuración.

## Seguridad

- paths absolutos y `..` son rechazados por schema;
- un archivo existente no administrado se respalda antes de adoptarlo;
- directorios completos existentes no se reemplazan automáticamente;
- cada archivo de una generación tiene SHA-256 registrado;
- `verify` valida hashes, perfil y enlaces administrados;
- `rollback` intercambia `current` y `previous` sólo después de validar ambas generaciones;
- `gc` nunca elimina `current` ni `previous`.

## Perfiles

`profiles/base.toml` contiene el contrato mínimo. `profiles/personal.toml` hereda de base y activa escenas e integraciones personales. `CORTETSU_PROFILE` permite seleccionar otro perfil sin modificar el repositorio.

## Comandos

```bash
cortetsu plan
cortetsu apply
cortetsu doctor
cortetsu dotfiles status
cortetsu dotfiles verify
cortetsu dotfiles rollback
cortetsu dotfiles gc
```

`cortetsu install` aplica los dotfiles después de construir una generación de shell válida. El servicio `cortetsu-shell.service` se instala pero no se habilita automáticamente mientras exista la posibilidad de un autostart previo.

## Dirección

Esta capa es la base para que packages, Hyprland, terminal, servicios, themes, scenes y el shell converjan en una única generación de sistema Cortetsu. Caelestia permanece temporalmente como adapter del shell, no como dueño de los dotfiles.
