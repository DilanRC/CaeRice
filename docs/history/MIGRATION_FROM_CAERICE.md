# Migración de CaeRice a Cortetsu

## Decisión

El nombre canónico del producto y del futuro repositorio es **Cortetsu**.

CaeRice pasa a ser el nombre histórico de la etapa centrada en personalizar Caelestia. Cortetsu amplía el alcance hacia un dotfiles completo para CachyOS/Arch y una plataforma de escritorio personal independiente de la identidad de cualquier upstream.

## Origen del nombre

`Cortetsu` es una marca inventada para este proyecto. Combina **Cortés**, apellido de Dilan Rodríguez Cortés, con *tetsu* (鉄), “hierro” en japonés. La referencia es estética y simbólica: un entorno personal forjado, resistente y disciplinado. No pretende ser una palabra japonesa tradicional ni presentarse como tal.

## Regla principal

El cambio de identidad no autoriza un reemplazo masivo de cadenas.

Los nombres técnicos existentes forman parte del estado instalado y se mantienen hasta disponer de una migración probada. Esto incluye:

```text
caerice-*
~/.config/caerice/
~/.local/state/caerice/
~/.local/share/caelestia-custom-system/
caerice-power-auto.service
```

También se conservan temporalmente nombres de scripts como `install-caerice.sh`, porque otros entrypoints y backups pueden referenciarlos.

## Identidad inmediata

Desde la Fase 0:

- nombre visible: `Cortetsu`;
- manifiesto: `cortetsu.toml`;
- entrada de usuario: `scripts/cortetsu`;
- nueva documentación bajo el nombre Cortetsu;
- CaeRice se usa únicamente para historia o compatibilidad.

## Identificadores canónicos futuros

Cuando las migraciones estén listas, los identificadores nuevos serán:

```text
cortetsu
cortetsu-*
~/.config/cortetsu/
~/.local/state/cortetsu/
~/.cache/cortetsu/
~/.local/share/cortetsu/
cortetsu-*.service
```

## Secuencia segura

### Paso 1 — Alias de lectura

Los nuevos helpers deben buscar primero las rutas Cortetsu y usar las rutas heredadas como fallback.

### Paso 2 — Escritura dual controlada

Sólo para datos pequeños y estructurados, una versión de transición puede escribir el nuevo formato y conservar el anterior hasta verificar equivalencia.

### Paso 3 — Copia atómica

Un migrador debe:

1. inventariar el estado existente;
2. crear un backup con timestamp;
3. validar permisos y formato;
4. copiar a una ruta temporal;
5. verificar el resultado;
6. activar la ruta nueva mediante rename atómico;
7. conservar el origen sin borrarlo.

### Paso 4 — Aliases de comandos y servicios

Los comandos `caerice-*` deben convertirse en wrappers hacia `cortetsu-*` durante al menos un ciclo estable. Los servicios systemd antiguos deben mostrar una advertencia de deprecación, pero seguir funcionando.

### Paso 5 — Retirada explícita

Los nombres heredados sólo se eliminan cuando:

- no quedan referencias activas en el repositorio;
- el instalador detecta y migra instalaciones antiguas;
- existe rollback documentado;
- los tests prueban instalación limpia y actualización;
- la máquina real pasa la validación completa.

## Renombre del repositorio

El repositorio de GitHub debe pasar de `DilanRC/CaeRice` a `DilanRC/Cortetsu` después de integrar la Fase 0. No se debe crear un repositorio nuevo ni perder el historial. La operación correcta es renombrar el repositorio existente.

Tras el renombre, los clones locales deben confirmar el remoto canónico:

```bash
git remote set-url origin https://github.com/DilanRC/Cortetsu.git
git remote -v
git fetch --prune origin
```

## Documentación histórica

No se reemplazará el nombre CaeRice dentro de reportes fechados, commits, rutas de backups antiguos ni documentos de reconciliación. Esos nombres describen hechos históricos y son útiles para diagnóstico.

Los documentos actuales deben usar:

```text
Cortetsu (anteriormente CaeRice)
```

cuando sea necesario explicar compatibilidad.

## Rollback de la Fase 0

La Fase 0 no cambia nombres de helpers, configuración, IPC, systemd ni rutas del runtime. Revertirla consiste únicamente en revertir el commit de identidad y documentación. El funcionamiento instalado permanece igual.
