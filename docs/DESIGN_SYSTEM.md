# Cortetsu visual system

La estética samurái de Cortetsu es contenida: precisión, contraste, espacio y materiales; no decoración temática literal.

## Lenguaje

- **sumi**: fondos casi negros y superficies carbón;
- **tetsu**: bordes y elevaciones como acero ennegrecido;
- **ai**: índigo para foco y acciones primarias;
- **shu**: bermellón reservado para estados importantes;
- **washi**: texto principal ligeramente cálido;
- **ma**: espacio negativo deliberado para reducir ruido visual.

La paleta puede seguir adaptándose al wallpaper durante la etapa de adapter, pero jerarquía, interacción y motion pertenecen a Cortetsu.

## Fuente declarativa

`~/.config/cortetsu/ui.toml` es el contrato de producto. Vive dentro de las generaciones de dotfiles y define identidad, spacing, radios y presupuesto de motion. La UI irá migrando progresivamente de tokens del adapter a tokens Cortetsu compilados desde ese contrato.

El primer token activo propio vive en `modules/CortetsuDesign.js`: el Bottom Hub ya usa `hoverScale=1.04` y `motionFastMs=100` en lugar de codificar su carácter de interacción mediante el runtime upstream.

## Motion

- hover: 100 ms, escala contenida;
- toggles: feedback inmediato;
- popovers: entrada breve, sin rebote ornamental;
- paneles: transición espacial clara;
- animación infinita: sólo para estados activos que realmente lo justifican.

El objetivo no es añadir animación, sino eliminar latencia percibida sin mantener trabajo cuando la interfaz está quieta.

## Jerarquía

Una superficie debe mostrar primero el estado y la acción probable. Métricas avanzadas permanecen disponibles, pero no compiten con la información primaria.

Ejemplo Hardware:

```text
System health
CPU      17% · 52 C
GPU      11% · 59 C
Memory   8.2 / 32 GB

Advanced metrics ->
```

## Reglas

- una familia de radios, spacing y tipografía;
- ningún color hardcoded cuando existe token semántico;
- estados de hover/focus/pressed consistentes;
- contraste legible en light/dark y fondos derivados del wallpaper;
- iconografía funcional, no ornamental;
- el contenido manda sobre el chrome;
- overlays con exclusividad y foco predecibles;
- 144 Hz deben sentirse fluidos sin mantener trabajo continuo cuando la UI está quieta.
