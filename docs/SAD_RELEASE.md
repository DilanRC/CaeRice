# SAD release checklist

A release is acceptable when:

1. `python3 scripts/features/validate-sad.py` reports `SAD STATUS: OK`.
2. `bash scripts/features/update-sad.sh` completes successfully on the real machine.
3. `python3 scripts/features/diagnose-sad.py` reports `SAD DIAGNOSTIC: OK` (or only understood non-blocking warnings).
4. Hardware and Display work interactively.
5. Gaming Center and CaeRice Updater remain absent from repository artifacts, live QML, helpers, wiring and IPC.

Do not reintroduce retired centers through recovery/install scripts.
