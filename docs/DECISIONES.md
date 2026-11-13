# Decisiones de diseño y técnicas

Registro de decisiones tomadas de forma autónoma (más reciente al final).

## Entorno
- Godot 4.4.1 estable (Windows, consola) descargado en `tools/godot_bin/` (ignorado por git). El sistema de la sesión es Windows, no Linux.
- Lógica de juego en clases puras (`GameModel`, `EconomyLogic`, `GameData`, `SaveIO`) sin nodos ni autoloads, para poder testear y simular en headless. Los autoloads (`EventBus`, `GameState`, `Economy`, `SaveSystem`) son envoltorios finos.
- Traducciones: CSV en `i18n/` cargado en runtime con `TranslationServer` (no depende del import del editor); la UI usa `tr()`.

## Cambio de nombre y repositorio (2026-11-13)
- Nombre oficial: **INFLATION? What Inflation?** (igual en español e inglés, no se traduce). Se usa en `project.godot`, título de ventana, menú, README y export presets.
- Para archivos, ejecutables y carpetas: `InflationWhatInflation`.
- La carpeta local del proyecto sigue llamándose "Inflación Idle" porque es el espacio de trabajo abierto; renombrarla queda para el usuario.
- Repo: https://github.com/agusmoscato/INFLATION-What-Inflation-.git (rama `main`). Push después de cada commit de fase.
- `docs/DISENO.md` no se toca (lo actualiza el usuario).
