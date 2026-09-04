# Calendar, Google Calendar y Pomodoro

Cortetsu integra un calendario mensual de solo lectura, agenda diaria y un
Pomodoro persistente. OAuth y HTTP viven en `caelestia/bin/cortetsu-calendar`;
QML consume JSON estructurado y ejecuta acciones del helper.

El prefijo `cortetsu-*` se conserva por compatibilidad. El instalador crea los
aliases canónicos `cortetsu-calendar` y `cortetsu-pomodoro`.

## Google Calendar: solo lectura

El helper sólo llama a `CalendarList.list` y `Events.list`, con estos scopes:

```text
https://www.googleapis.com/auth/calendar.events.readonly
https://www.googleapis.com/auth/calendar.calendarlist.readonly
```

No existe una ruta de escritura: Cortetsu no cambia eventos, calendarios,
recordatorios ni invitaciones.

## OAuth

1. Habilitar Google Calendar API en Google Cloud.
2. Crear credenciales OAuth de tipo **Desktop application**.
3. Guardar el JSON en `~/.config/caelestia/calendar-client.json` con modo `0600`.
4. Abrir el panel o ejecutar `cortetsu-calendar sync --force`.

El flujo usa PKCE, valida un `state` aleatorio, escucha sólo en `127.0.0.1` y
expira a los cinco minutos. El refresh token se guarda con Secret Service
(`secret-tool`), nunca en configuración, cache o logs. La entrada heredada
`cortetsu-google-calendar` se reconoce para migración compatible.

## Sincronización

El panel solicita sincronización cada vez que se abre, tanto desde Bottom Hub
como por shortcut o IPC. Un cache de menos de 15 minutos se reutiliza; el botón
de refresco fuerza una consulta nueva. Se conservan 62 días anteriores y 370
días futuros, con paginación, eventos recurrentes expandidos y zona horaria
IANA. Los eventos de varios días aparecen en cada fecha que abarcan.

Archivos locales:

```text
$XDG_CONFIG_HOME/caelestia/calendar-selection.json
$XDG_CACHE_HOME/caelestia/calendar-events.json
```

Cambiar un chip de calendario actualiza la selección y fuerza un nuevo sync.

## Pomodoro

Estado:

```text
$XDG_STATE_HOME/caelestia/pomodoro.json
```

Flujo predeterminado:

```text
25 min FOCUS -> 5 min BREAK
cada 4 sesiones -> 15 min LONG_BREAK
BREAK/LONG_BREAK -> FOCUS
```

Pausa, reanudación, reinicio y salto de descanso sobreviven al reinicio del
shell. Timestamps mantienen el tiempo correcto tras suspensión. Locks separan
el daemon singleton de las escrituras de estado, y las transiciones producen
un toast local.

## Desconectar y probar

```bash
cortetsu-calendar disconnect
bash caelestia/tests/test-calendar-readonly.sh
python3 caelestia/tests/test-calendar-credentials.py
python3 caelestia/tests/test-calendar-polish.py
python3 caelestia/tests/test-pomodoro.py
```
