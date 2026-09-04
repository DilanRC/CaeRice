# Cortetsu

> Dotfiles personal para CachyOS/Arch: Hyprland, Quickshell, Qt 6/QML y un shell de escritorio rápido, reversible y visualmente coherente.

**Cortetsu** combina Cortés con *tetsu* (鉄, hierro/acero): una identidad propia inspirada en disciplina samurái, tinta sumi, acero ennegrecido, índigo y bermellón. La referencia es estética y de producto; no depende de la identidad de ningún shell upstream.

## Principios

- cero escrituras sobre el runtime del paquete en `/etc`;
- generaciones de usuario inmutables con `current`, `previous` y rollback atómico;
- namespace activo exclusivamente `cortetsu-*` / `CORTETSU_*`;
- nada de `sh -c` en QML;
- paneles ocultos sin polling continuo;
- procesos y telemetría compartidos en vez de duplicados por vista;
- secretos fuera del repositorio mediante Secret Service;
- cambios críticos con staging, pruebas y verificación real;
- historial de la etapa anterior preservado sólo como procedencia, nunca como dependencia activa.

## Stack confirmado

- CachyOS / Arch Linux;
- Hyprland `0.56.2`;
- Quickshell `0.3.1` o build git compatible;
- Caelestia Shell `2.4.0` como base upstream temporal;
- Qt 6 / QML para interfaz;
- PipeWire/WirePlumber, NetworkManager, UPower y systemd --user para integración del sistema.

La base actual de Caelestia se reconstruye desde `v2.4.0` commit `24aa15eefdb146350d2548c0a015b04eddbd1008`. Cortetsu aplica sus adapters y módulos sólo dentro de staging. La dirección del proyecto es reducir progresivamente esos adapters hasta que el shell sea completamente propio.

## Runtime

```text
~/.local/share/cortetsu/builds/<build-id>
~/.config/quickshell/cortetsu/current
~/.config/quickshell/cortetsu/previous
```

`/etc/xdg/quickshell/caelestia` es referencia de solo lectura.

## Módulos

- Bottom Hub: dock/taskbar contextual por monitor;
- Overview: ventanas y workspaces con previews;
- Clipboard: historial Clipse en QML;
- Hardware: rendimiento, procesos, sensores, energía e I/O;
- Display: topologías, preview, persistencia y rollback;
- Wallpaper: selector orbital con prefetch limitado;
- Calendar: Google Calendar de solo lectura;
- Focus/Pomodoro: ciclo persistente con descansos cortos y largos.

Los módulos retirados (Gaming Center y Updater) no forman parte del runtime.

## CLI

```bash
./scripts/cortetsu status
./scripts/cortetsu test
./scripts/cortetsu verify
./scripts/cortetsu audit
./scripts/cortetsu install
```

La primera instalación de Cortetsu v2 ejecuta una migración idempotente: respalda el estado antiguo, mueve únicamente datos propiedad de Cortetsu al namespace nuevo, retira comandos antiguos administrados y conserva configuración de Caelestia que el upstream todavía necesita.

## Calidad

CI valida sintaxis, Python, Bash, namespace, ausencia de shell arbitrario en QML, Calendar/Pomodoro, composición de overlays y el flujo E2E `upstream exacto -> dos generaciones -> rollback`.

Los objetivos de rendimiento están en [`docs/PERFORMANCE.md`](docs/PERFORMANCE.md) y el lenguaje visual en [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md). La arquitectura general está en [`docs/CORTETSU_ARCHITECTURE.md`](docs/CORTETSU_ARCHITECTURE.md).

## Procedencia

Cortetsu mantiene documentación histórica y atribución explícita en [`docs/PROVENANCE.md`](docs/PROVENANCE.md) y `docs/history/`. La procedencia se conserva; el código activo no depende del namespace anterior.
