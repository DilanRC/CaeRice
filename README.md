# Cortetsu

> Dotfiles personal para CachyOS/Arch: Hyprland, Quickshell, Qt 6/QML y un escritorio rápido, reversible y visualmente coherente.

**Cortetsu** combina Cortés con *tetsu* (鉄, hierro/acero): una identidad propia inspirada en disciplina samurái, tinta sumi, acero ennegrecido, índigo y bermellón. La referencia es estética y de producto; no depende de la identidad de ningún shell upstream.

## Qué es ahora

Cortetsu ya no es sólo un patchset de shell. Es una plataforma de dotfiles con cuatro contratos independientes y verificables:

1. **shell runtime**: generaciones inmutables de Quickshell;
2. **dotfiles runtime**: generaciones inmutables para configuración de usuario;
3. **profile**: selección declarativa de capacidades y paquetes;
4. **doctor**: comprobación del sistema antes de asumir que una función existe.

Los dotfiles administrados apuntan a una única referencia estable `~/.local/share/cortetsu/dotfiles/current`. Cambiar esa referencia cambia todo el conjunto; rollback no reescribe archivos uno por uno.

## Principios

- cero escrituras sobre el runtime del paquete en `/etc`;
- generaciones de usuario inmutables con `current`, `previous` y rollback atómico;
- archivos preexistentes respaldados antes de ser adoptados;
- namespace activo exclusivamente `cortetsu-*` / `CORTETSU_*`;
- nada de `sh -c` en QML;
- paneles ocultos sin polling continuo;
- procesos y telemetría compartidos en vez de duplicados por vista;
- secretos fuera del repositorio mediante Secret Service;
- cambios críticos con staging, hashes, pruebas y verificación real;
- historial anterior preservado sólo como procedencia, nunca como dependencia activa.

## Stack confirmado

- CachyOS / Arch Linux;
- Hyprland `0.56.2`;
- Quickshell `0.3.1` o build git compatible;
- Caelestia Shell `2.4.0` como adapter temporal del shell;
- Qt 6 / QML para interfaz;
- PipeWire/WirePlumber, NetworkManager, UPower y systemd --user para integración del sistema.

La base actual de Caelestia se reconstruye desde `v2.4.0` commit `24aa15eefdb146350d2548c0a015b04eddbd1008`. Cortetsu aplica adapters y módulos sólo dentro de staging. La dirección del proyecto es reducir progresivamente esos adapters hasta que el shell sea completamente propio.

## Generaciones

```text
~/.local/share/cortetsu/builds/<build-id>
~/.config/quickshell/cortetsu/current
~/.config/quickshell/cortetsu/previous

~/.local/share/cortetsu/dotfiles/builds/<build-id>
~/.local/share/cortetsu/dotfiles/current
~/.local/share/cortetsu/dotfiles/previous
```

`/etc/xdg/quickshell/caelestia` es referencia de solo lectura.

## Perfil personal

`profiles/personal.toml` hereda de `profiles/base.toml`. El manifest `dotfiles/manifest.toml` decide qué archivos pertenecen a Cortetsu y `packages/arch.toml` describe dependencias por grupos. Nada instala paquetes automáticamente todavía: `doctor` detecta drift antes de que `bootstrap` se convierta en una operación de sistema.

## Módulos

- Bottom Hub: dock/taskbar contextual por monitor;
- Overview: ventanas y workspaces con previews;
- Clipboard: historial Clipse en QML;
- Hardware: rendimiento, procesos, sensores, energía e I/O;
- Display: topologías, preview, persistencia y rollback;
- Wallpaper: selector orbital con prefetch limitado;
- Calendar: Google Calendar de solo lectura;
- Focus/Pomodoro: ciclo persistente con descansos cortos y largos.

## CLI

```bash
cortetsu status
cortetsu plan
cortetsu apply
cortetsu doctor
cortetsu dotfiles status
cortetsu dotfiles rollback
cortetsu test
cortetsu verify
cortetsu audit
cortetsu install
```

`cortetsu install` construye primero un shell válido y luego promueve una generación de dotfiles. `cortetsu-shell.service` se instala, pero no se habilita automáticamente mientras se retira el mecanismo de autostart anterior.

## Calidad

CI valida sintaxis, Python, Bash, namespace, ausencia de shell arbitrario en QML, Calendar/Pomodoro, composición de overlays, transacciones de dotfiles y el flujo E2E `upstream exacto -> dos generaciones -> rollback`.

Los objetivos de rendimiento están en [`docs/PERFORMANCE.md`](docs/PERFORMANCE.md), el lenguaje visual en [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md) y la nueva plataforma de configuración en [`docs/DOTFILES_PLATFORM.md`](docs/DOTFILES_PLATFORM.md).

## Procedencia

Cortetsu mantiene documentación histórica y atribución explícita en [`docs/PROVENANCE.md`](docs/PROVENANCE.md) y `docs/history/`. La procedencia se conserva; el código activo no depende del namespace anterior.
