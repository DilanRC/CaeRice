# Regional/clima: formato de hora, unidad de temperatura y ubicación

Cortetsu reemplaza `GlobalConfig.services.{useTwelveHourClock, useFahrenheit, weatherLocation}` por `CortetsuRegional`, un singleton first-party bajo `cortetsu/modules/`. Las preferencias mismas no se duplican: siguen viviendo en `CortetsuConfig` (`~/.config/cortetsu/preferences.json`), la única fuente de verdad. `CortetsuRegional` sólo re-expone esas tres preferencias bajo un nombre orientado a "regional" y centraliza la lógica pura de formateo/URLs/parseo que antes vivía duplicada e inline dentro de tres archivos upstream parcheados.

## Componentes

- `cortetsu/modules/CortetsuRegional.js` (`.pragma library`): funciones puras y deterministas -- sin llamadas de red, sin globals de Qt. Construye URLs (Open-Meteo forecast/geocoding, Nominatim reverse-geocode, ip-api.com), parsea sus respuestas JSON, decide patrones de hora (`h:mm A` / `h:mm`, `ha` / `hh:00`), convierte y formatea temperatura, corrige diacríticos de nombres de ciudad, calcula el backoff de rate-limit de ip-api.com.
- `cortetsu/modules/CortetsuRegional.qml` (`pragma Singleton`): expone `useTwelveHourClock`, `useFahrenheit`, `weatherLocation` como bindings de sólo lectura hacia `CortetsuConfig`, más las funciones anteriores para quien las necesite (`Weather.qml`, `DesktopClock.qml`, `Forecast.qml`).
- `caelestia/patches/services__RegionalConfig.qml.patch`: sigue existiendo porque `services/Weather.qml`, `modules/background/DesktopClock.qml` y `modules/lock/weather/Forecast.qml` son archivos upstream de caelestia-shell que también dependen de `Caelestia`/`Caelestia.Config` para tokens de diseño (Colours, Tokens, StyledText, Icons) -- una capacidad distinta, fuera de este alcance. El patch quedó reducido a delegar en `CortetsuRegional` en cada punto donde antes leía config regional inline; ya no reconstruye URLs, parsea JSON de clima, ni mantiene la tabla de diacríticos -- eso vive únicamente en `CortetsuRegional.js`.

## Por qué el patch no desaparece (y por qué `grep GlobalConfig` no baja)

Un patch unificado tiene que conservar, en sus líneas `-`, el contenido exacto del archivo pristino que reemplaza -- si no, `patch` no puede verificar el contexto ni aplicarse. Como el archivo upstream original sí usa `GlobalConfig.services.*` en esos ocho puntos, esas ocho líneas seguirán apareciendo (como líneas removidas) mientras el patch exista, sin importar qué tan first-party sea el reemplazo. La señal real de progreso no es ese grep contra el `.patch` (que el propio `scripts/audit-zero-caelestia.py` ignora a propósito), sino:

1. Cero referencias a `GlobalConfig`/`Caelestia.Config` en código operativo no-patch (`cortetsu/modules`, `cortetsu/bin`, `core`, `scripts`, `config`) -- ya cumplido.
2. Cero líneas **añadidas** (`+`) por el patch que reintroduzcan `GlobalConfig` -- verificado en `cortetsu/tests/test-regional.py`.
3. Toda la lógica no trivial (URLs, parseo JSON, diacríticos, rate-limit) vive en un módulo first-party testeable, no inline en el archivo parcheado.

## API de clima usada (documentado, no inventado)

Extraído directamente del `Weather.qml` de caelestia-shell v2.4.0 (upstream real, vía `git archive` del tag fijado en `caelestia/compatibility.json`):

- Pronóstico: `https://api.open-meteo.com/v1/forecast` (sin API key).
- Geocoding directo (nombre de ciudad -> coordenadas): `https://geocoding-api.open-meteo.com/v1/search`.
- Geocoding inverso (coordenadas -> ciudad): `https://nominatim.openstreetmap.org/reverse`.
- Fallback de ubicación por IP: `http://ip-api.com/json` (con manejo de rate-limit 429 / header `x-rl` agotado).

## Tests

`cortetsu/tests/test-regional.py` ejecuta `cortetsu/tests/test-regional.node.js` bajo Node real contra fixtures JSON hechas a mano que imitan las cuatro respuestas anteriores -- **nunca hay una llamada de red real**, ni en el test ni en CI. Además verifica estáticamente que `CortetsuRegional` no duplica las preferencias y que el patch delega correctamente en cada punto.
