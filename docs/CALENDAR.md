# Calendar Panel, Google Calendar y Pomodoro

## Estado de implementación

La integración usa un helper local (`caelestia/bin/caerice-calendar`) y no
coloca OAuth ni HTTP en QML. El helper solo llama a:

- `GET https://www.googleapis.com/calendar/v3/users/me/calendarList`
- `GET https://www.googleapis.com/calendar/v3/calendars/{calendarId}/events`

Scopes exactos:

```text
https://www.googleapis.com/auth/calendar.events.readonly
https://www.googleapis.com/auth/calendar.calendarlist.readonly
```

No existe ni debe existir una ruta de escritura. CaeRice no cambia calendarios,
eventos, colores, visibilidad, recordatorios ni invitaciones. Para modificar un
evento se debe usar Google Calendar web o móvil.

## Preparación OAuth

1. Crear o seleccionar un proyecto en Google Cloud Console.
2. Habilitar únicamente Google Calendar API.
3. Configurar OAuth consent screen como aplicación de escritorio en pruebas.
4. Crear credenciales OAuth de tipo Desktop application.
5. Guardar el JSON descargado en:
   `~/.config/caelestia/calendar-client.json`, con permisos `0600`.
6. Ejecutar `~/.local/bin/caerice-calendar sync` y completar la autorización en
   el navegador.

El refresh token se almacena con Secret Service mediante `secret-tool`, nunca en
el cache de eventos, argumentos de proceso o logs. El cache está en
`$XDG_CACHE_HOME/caelestia/calendar-events.json`; la selección local está en
`$XDG_CONFIG_HOME/caelestia/calendar-selection.json`.

## Sincronización y selección

La primera sincronización habilita los calendarios que Google marca como
seleccionados y siempre incluye el primario. Las siguientes sincronizaciones
solo consultan los calendarios habilitados localmente. Cada evento conserva la
identidad compuesta `calendarId + eventId`, además de nombre y color.

El rango inicial es ahora a 30 días, con `singleEvents=true`, `showDeleted=false`,
`orderBy=startTime`, paginación por `nextPageToken` y zona horaria local.
El umbral previsto de refresco es 15 minutos, al abrir el panel.

## Desconectar

```bash
~/.local/bin/caerice-calendar disconnect
```

Esto elimina la autorización local de Secret Service y no modifica Google
Calendar. Para revocar completamente el acceso, retirar también CaeRice desde
la página de seguridad de la cuenta Google.

## Instalación y rollback

La instalación debe ejecutarse mediante `scripts/install-caerice.sh`; no copiar
QML manualmente a `/etc/xdg`. El instalador conserva backups en
`~/.local/share/caelestia-custom-system/reinstall-backups/`. Para volver atrás,
usar la rama `main` y reinstalar con el mismo instalador.

## Gate permanente

`caelestia/tests/test-calendar-readonly.sh` verifica los scopes exactos y falla
si aparecen scopes amplios o métodos Calendar de mutación.
