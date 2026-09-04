# Bottom Hub — nota histórica

Este archivo describía el rediseño visual del **22 de agosto de 2026** y conserva valor únicamente como contexto histórico del proceso que eliminó el sidebar/barra heredados.

La arquitectura activa ya no es la descrita aquí. En particular:

- `BottomHub.qml` ya no contiene la presentación monolítica;
- App Rail, tray, status, modo y workspaces son componentes first-party Cortetsu;
- los componentes visuales no importan los servicios de Caelestia/Hyprland;
- `native-bottom-hub.py` fue retirado;
- el único despliegue soportado es mediante generaciones inmutables con `cortetsu install`;
- no se editan archivos bajo `/etc/xdg/quickshell/caelestia`.

La documentación canónica actual es:

- [`BOTTOM-HUB.md`](BOTTOM-HUB.md)
- [`CORTETSU_ARCHITECTURE.md`](CORTETSU_ARCHITECTURE.md)

Para historia adicional del proyecto, usar `docs/history/` y `PROVENANCE.md`; no usar este documento como procedimiento de instalación o diagnóstico.
