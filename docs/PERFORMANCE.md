# Cortetsu performance contract

Cortetsu optimiza experiencia percibida y trabajo real, no números aislados.

## Presupuestos

- shell idle: sin subprocesses recurrentes de alta frecuencia;
- módulos cerrados: sin polling periódico salvo servicios compartidos del upstream;
- apertura de overlay: objetivo < 120 ms hasta primer frame útil en hardware objetivo;
- hover/toggle: respuesta visual inmediata, animación breve;
- imágenes: carga asíncrona, tamaños de decodificación acotados y prefetch limitado;
- telemetría: una fuente compartida por métrica siempre que exista API nativa;
- QML: ningún `sh -c`; acciones externas explícitas y auditables;
- runtime: promoción y rollback atómicos.

## Política de timers

Un `Timer` repetitivo debe cumplir al menos una condición:

1. sólo corre mientras la superficie que consume el dato está visible;
2. representa tiempo real visible al usuario (por ejemplo Pomodoro activo);
3. no existe una señal/evento nativo equivalente.

Debounce y timers one-shot no se consideran polling.

## Prioridad de backends

1. señales/modelos nativos de Caelestia/Qt ya disponibles;
2. D-Bus/IPC/eventos del sistema;
3. helpers Cortetsu especializados;
4. polling únicamente como fallback medido.

Caelestia 2.4 ya ofrece servicios C++ para CPU, memoria, GPU, red, PipeWire y sensores. Cortetsu debe reutilizarlos antes de duplicar telemetría.

## Medición

Antes de una release mayor se registran:

- tiempo de arranque del shell;
- RSS estable tras idle;
- CPU idle;
- latencia de apertura/cierre de Bottom Hub y overlays;
- número de procesos externos lanzados durante 60 s de idle;
- errores/warnings QML;
- 40 ciclos consecutivos de apertura/cierre para superficies críticas.

Una optimización no se acepta si reduce un benchmark pero empeora interacción, estabilidad o mantenibilidad.
