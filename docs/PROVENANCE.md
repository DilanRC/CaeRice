# Procedencia y atribución

Cortetsu combina trabajo propio, adaptación del shell base e ideas estudiadas en otros dotfiles. Este registro evita perder la procedencia durante refactors y migraciones.

## Identidad Cortetsu

- autor y propietario: Dilan Rodríguez Cortés;
- nombre: marca inventada a partir de `Cortés` + *tetsu* (鉄, hierro);
- función: identidad independiente para el dotfiles y la plataforma de escritorio;
- relación con upstreams: técnica, no nominal.

## Caelestia

- repositorio: `caelestia-dots/shell`;
- función: base actual del shell, componentes, servicios, tokens visuales y contratos de integración;
- modelo de uso actual: módulos propios de Cortetsu más cambios mínimos sobre archivos upstream;
- base integrada al iniciar la transición: tag `v2.4.0`, commit `24aa15eefdb146350d2548c0a015b04eddbd1008`.

Los archivos de Caelestia no deben presentarse como código original de Cortetsu. Los patches deben conservar contexto suficiente para distinguir upstream y modificación local.

## uthman_dotfiles

- repositorio: `codetesla51/uthman_dotfiles`;
- función: referencia de producto y prototipos Quickshell;
- componentes estudiados o usados como inspiración:
  - `StatusPill.qml`;
  - `ClipboardPanel.qml`;
  - `SystemMonitor.qml`;
  - `BatteryPanel.qml`;
  - `KeybindsPanel.qml`;
  - patrón de temas dinámicos y panel de control.

### Estado de los portes

| Familia Cortetsu | Fuente conceptual | Tipo de adaptación |
|---|---|---|
| Status Pill | `StatusPill.qml` | reescritura para servicios, tokens e iconos del shell base |
| Clipboard | `ClipboardPanel.qml` | flujo funcional reescrito sobre Clipse, FileView y ContentWindow |
| Hardware Center | `SystemMonitor.qml`, `BatteryPanel.qml`, `KeybindsPanel.qml` | inspiración y expansión en subsistema multipágina |
| futuro Control Center | panel web y módulos de Uthman | referencia de alcance; no porte directo |

Los nuevos portes deben registrar el commit fuente exacto antes de copiar o adaptar código sustancial.

## Reglas para futuras incorporaciones

Cada incorporación debe documentar:

```text
source_repository
source_commit
source_path
license_observed
files_or_behaviour_adapted
destination_paths
adaptation_type
```

Tipos permitidos:

- `idea`: sólo se adopta el concepto;
- `behaviour`: se reproduce el comportamiento con implementación propia;
- `adaptation`: se transforma código identificable;
- `vendor`: se conserva código externo casi intacto.

Las adaptaciones y vendors requieren revisar la licencia de la revisión exacta y conservar los avisos aplicables. Ante una licencia ausente o ambigua, no se debe copiar código nuevo hasta resolver la procedencia.

## Código propio

Se consideran áreas desarrolladas específicamente para el proyecto, sin perjuicio de las APIs y componentes base usados:

- infraestructura de patches, preflight, normalizadores y validadores semánticos;
- Display Manager transaccional;
- Wallpaper Manager orbital y su modelo determinístico;
- integración multipantalla del Bottom Hub;
- helpers de telemetría, energía y persistencia;
- reconciliación y recuperación del runtime;
- futura capa de perfiles, generaciones, acciones y escenas de Cortetsu.

Este documento no sustituye los avisos de licencia de cada dependencia ni concede por sí mismo una licencia al repositorio.
