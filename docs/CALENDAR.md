# Calendar, Google Calendar y Focus/Pomodoro

Cortetsu integra calendario mensual de solo lectura, agenda diaria y Pomodoro persistente. OAuth y HTTP viven en `cortetsu/bin/cortetsu-calendar`; QML consume JSON estructurado y ejecuta acciones explícitas del helper.

## Google Calendar: solo lectura

Scopes:

```text
https://www.googleapis.com/auth/calendar.events.readonly
https://www.googleapis.com/auth/calendar.calendarlist.readonly
```

No existe ruta de escritura de eventos, calendarios, recordatorios ni invitaciones.

## OAuth

1. Habilitar Google Calendar API.
2. Crear credenciales OAuth **Desktop application**.
3. Guardar el JSON en `~/.config/cortetsu/calendar-client.json` con modo `0600`.
4. Abrir Calendar o ejecutar `cortetsu-calendar sync --force`.

El flujo usa PKCE, `state` aleatorio, callback sólo en `127.0.0.1` y timeout global de cinco minutos. El refresh token vive en Secret Service bajo `cortetsu-google-calendar`; nunca se escribe en cache, configuración o logs. La migración v2 mueve de forma silenciosa el secreto anterior sólo cuando es necesario y lo elimina después de confirmar la nueva entrada.

## Sincronización

Se solicita al abrir desde Bottom Hub, shortcut o IPC. Un cache menor de 15 minutos se reutiliza; el refresco manual fuerza consulta nueva. Se conservan 62 días anteriores y 370 futuros, paginación, recurrencias expandidas, zona horaria IANA y eventos de varios días.

```text
$XDG_CONFIG_HOME/cortetsu/calendar-selection.json
$XDG_CACHE_HOME/cortetsu/calendar-events.json
```

## Focus/Pomodoro

```text
$XDG_STATE_HOME/cortetsu/pomodoro.json
```

Ciclo predeterminado:

```text
25 min FOCUS -> 5 min BREAK
cada 4 sesiones -> 15 min LONG_BREAK
BREAK/LONG_BREAK -> FOCUS
```

Pausa, reanudación, reinicio y salto sobreviven al reinicio del shell. El cálculo por timestamps conserva el tiempo correcto tras suspensión. Locks separados protegen el singleton y las escrituras atómicas.

## Pruebas

```bash
cortetsu-calendar disconnect
bash caelestia/tests/test-calendar-readonly.sh
python3 caelestia/tests/test-calendar-credentials.py
python3 caelestia/tests/test-calendar-polish.py
python3 caelestia/tests/test-pomodoro.py
```
