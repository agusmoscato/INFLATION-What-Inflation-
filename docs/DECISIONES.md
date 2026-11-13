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

## Economía (Fases 2-5, núcleo)
- Modelo: ingresos = base_real × M (tus precios); costos = base_real × P (nivel de precios). P sube cada "mes" (30 s) según la tasa de la era; M solo se pone al día al **remarcar** (manual con bono "a tiempo" en los 10 s posteriores al aumento, o automático con mejoras). Sin remarcar, el ingreso real se licua.
- La era depende de la **ganancia real histórica** (`lifetime_real`), no del tiempo, para que sea independiente de la inflación. Los umbrales están en `data/eras.json` y se calibraron con el simulador.
- Reforma monetaria: Credibilidad = (ganancia real de la vuelta / 1e6)^0.3. Cada punto da +3 % de ingreso y baja la inflación 1 % (mínimo -50 %). Resetea negocios, mejoras, P y M; los refugios arrastran 50 %. Agrega un billete al álbum (12 en total; completo = +25 %).
- Plan económico (prestige 2): desde la Era 4, con Credibilidad mínima 15/60/240. Cada plan (Estabilización, Convertibilidad, Emisión) se puede usar **una sola vez**. Convierte 50 % de la Credibilidad en bono permanente ("legado") y da x1,6 permanente.
- Final: en la Era 5 hay 5 medidas antiinflacionarias que bajan la tasa 20 % de la base cada una; con tasa 0 al cierre de un mes se gana (se puede seguir jugando).
- Costo de negocios: crece x1,22 por unidad (con 1,15 los multiplicadores de mejoras hacían trivial todo).
- Offline: tope de 12 h; la inflación corre, no hay clics ni eventos, y sin auto-remarcado el ingreso real decae.
- Simulador: el bot hace 1 clic/s, remarca a tiempo, compra por menor tiempo de repago, reforma cada ≥40 min cuando duplica su Credibilidad y ahorra para las medidas finales. No usa refugios (solo el arrastre).
- Resultado del simulador (semilla 1): Era 2 a los 27 min (objetivo 30), Era 3 a 112 (120), Era 4 a 208 (240), Era 5 a 393 (420), victoria a 583 (7-10 h). Primera reforma a los 40 min (~45).
