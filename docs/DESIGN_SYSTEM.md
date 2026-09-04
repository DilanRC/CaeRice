# Cortetsu visual system

La estética samurái de Cortetsu es contenida: precisión, contraste, espacio y materiales; no decoración temática literal.

## Lenguaje

- **sumi**: fondos casi negros y superficies carbón;
- **tetsu**: bordes y elevaciones como acero ennegrecido;
- **ai**: índigo para foco y acciones primarias;
- **shu**: bermellón reservado para estados importantes;
- **washi**: texto principal ligeramente cálido;
- **ma**: espacio negativo deliberado para reducir ruido visual.

Cortetsu usa la paleta Material 3 generada por el stack actual como fuente adaptable, pero la jerarquía y el motion son propios.

## Motion

- hover: rápido y discreto;
- toggles: feedback inmediato;
- popovers: entrada breve, sin rebote ornamental;
- paneles: transición espacial clara;
- animación infinita: sólo para estados activos que realmente lo justifican.

Los componentes deben preferir `Tokens.anim` del runtime sobre duraciones mágicas. El Bottom Hub usa escala contenida para evitar el efecto de dock elástico exagerado.

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
