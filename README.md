# Cortetsu

> Dotfiles personal para CachyOS/Arch, Hyprland y un escritorio Quickshell profundamente integrado. Anteriormente conocido como **CaeRice**.

**Cortetsu** fusiona mi apellido, **Cortés**, con *tetsu* (鉄, hierro/acero). El nombre representa un entorno personal forjado con disciplina: estética inspirada en el Japón feudal y el samurái, pero sin depender de la identidad de Caelestia ni de otro proyecto.

Cortetsu no pretende ser una colección de archivos para copiar a ciegas. Su objetivo es reconstruir un escritorio completo, coherente y verificable: shell, compositor, temas, servicios de usuario, aplicaciones, perfiles de máquina y recuperación.

## Estado de la transición

La identidad canónica del proyecto pasa a ser **Cortetsu**. Durante la migración se conservan temporalmente nombres técnicos heredados como `caerice-*`, `~/.config/caerice` y `~/.local/share/caelestia-custom-system`. Renombrarlos de golpe rompería helpers, servicios systemd, rutas de estado e instalaciones existentes.

Esos identificadores se retirarán únicamente mediante migraciones idempotentes, con backup, validación y compatibilidad hacia atrás. Los documentos históricos pueden seguir usando el nombre CaeRice cuando describen estados anteriores.

## Base confirmada

- distribución objetivo: CachyOS y Arch Linux;
- compositor: Hyprland;
- shell base actual: Caelestia sobre Quickshell;
- paquete integrado: `caelestia-shell 2.4.0-1`;
- upstream: `v2.4.0`;
- commit upstream: `24aa15eefdb146350d2548c0a015b04eddbd1008`;
- runtime actual: `/etc/xdg/quickshell/caelestia`.

Caelestia es una dependencia de la implementación actual, no la identidad ni el límite futuro del proyecto.

## Capacidades actuales

- Bottom Hub con dock, taskbar por monitor y launcher integrado;
- Overview con previews vivos y workspaces por monitor;
- Clipboard QML respaldado por Clipse;
- Hardware Center con rendimiento, procesos, sensores, I/O, energía y keybinds;
- Display Manager con preview, confirmación, persistencia y rollback;
- Wallpaper Manager orbital con prefetch limitado y protección contra previews obsoletos;
- temas y esquemas coordinados con el shell;
- patches mínimos, módulos propios, preflight, backups y validadores semánticos.

Gaming Center y el antiguo CaeRice Updater permanecen retirados del runtime.

## Dirección del producto

Cortetsu crecerá como un dotfiles completo mediante capas independientes:

1. inventario y paquetes;
2. configuración de usuario;
3. adaptación del shell;
4. módulos QML propios;
5. servicios systemd de usuario;
6. temas y adaptadores de aplicaciones;
7. perfiles por máquina;
8. generaciones reproducibles y rollback;
9. escenas transaccionales para trabajo, estudio, batería, presentación y gaming.

La arquitectura objetivo y sus fases están documentadas en [`docs/CORTETSU_ARCHITECTURE.md`](docs/CORTETSU_ARCHITECTURE.md). La política de compatibilidad está en [`docs/MIGRATION_FROM_CAERICE.md`](docs/MIGRATION_FROM_CAERICE.md).

## Entrada unificada

```bash
./scripts/cortetsu status
./scripts/cortetsu test
./scripts/cortetsu verify
./scripts/cortetsu audit
./scripts/cortetsu install
```

`install` conserva por ahora el instalador interno probado de CaeRice. Antes de modificar el runtime ejecuta pruebas, preflight y backups.

## Estructura actual

- `caelestia/`: módulos propios, patches, helpers, pruebas y datos de la integración actual;
- `config/`: configuración de usuario versionada;
- `scripts/`: instalación, mantenimiento, migración y validación;
- `docs/`: arquitectura, decisiones, QA e historial;
- `cortetsu.toml`: identidad, compatibilidad y contrato de alto nivel del proyecto.

La estructura futura incorporará `dotfiles/`, `profiles/`, `packages/`, `themes/`, `modules/` y `generations/` cuando cada capa pueda migrarse sin perder el estado probado actual.

## Reglas de desarrollo

- `main` representa únicamente estados estables y probados;
- cada cambio funcional nace en una rama dedicada;
- no se reemplazan árboles completos de una versión nueva del shell con copias antiguas;
- las integraciones sobre upstream deben ser mínimas y verificables;
- toda escritura crítica requiere staging, backup y validación posterior;
- las capacidades se detectan; no se asume hardware inexistente;
- secretos, tokens y datos privados nunca se versionan;
- la verificación real en CachyOS/Arch tiene prioridad sobre validaciones puramente estáticas;
- los portes desde otros proyectos se reescriben conforme a la arquitectura de Cortetsu y conservan atribución.

## Procedencia

Caelestia es la base actual del shell. `uthman_dotfiles` sirvió como fuente de ideas y prototipos para algunos componentes, especialmente Status Pill, Clipboard y monitorización. Cortetsu conserva un registro explícito de procedencia en [`docs/PROVENANCE.md`](docs/PROVENANCE.md).
