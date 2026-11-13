# INFLATION? What Inflation?

Un incremental para Steam donde la plata pierde valor mientras jugás: para ganar tenés que crecer más rápido que la inflación. Hecho con **Godot 4.4 (GDScript)**; todo lo visual y sonoro está generado por código.

Diseño completo: [docs/DISENO.md](docs/DISENO.md). Decisiones tomadas durante el desarrollo: [docs/DECISIONES.md](docs/DECISIONES.md).

> El nombre del juego es igual en español y en inglés. Para archivos y ejecutables se usa `InflationWhatInflation`.

## Primera vez en una PC nueva

Después de clonar, un solo comando instala todo lo que hace falta (Windows; no pide nada y se puede correr de nuevo sin romper nada):

```
powershell -File tools/setup.ps1
```

Instala Godot 4.4.1 (editor y consola) en `tools\godot_bin\`, las export templates 4.4.1 de Windows, Web y Linux en `%APPDATA%\Godot\export_templates\4.4.1.stable\`, rcedit en `tools\` (configurado en el editor), ffmpeg con winget si no está, y usa Chrome o el Edge de Windows para el QA web. Al final muestra un resumen ✔/✘ con la ruta de cada herramienta.

Después:

```
powershell -File tools/export_all.ps1                            # exporta todo con QA (Windows, demo, Web, demo web y Linux)
powershell -File tools/export_all.ps1 -Targets windows,web_demo  # solo algunos destinos
powershell -File tools/record_clips.ps1                          # graba los 14 clips de marketing en MP4 (export\clips\)
```

`export_all.ps1` y `record_clips.ps1` llaman solos a `setup.ps1` si falta algo. `tools\godot_bin\` y `tools\rcedit*` están en `.gitignore`.

## Cómo correrlo

1. `powershell -File tools/setup.ps1` (o instalar Godot 4.4.1 a mano). El editor queda en `tools\godot_bin\Godot_v4.4.1-stable_win64.exe` y la consola en `tools\godot_bin\Godot_v4.4.1-stable_win64_console.exe` (en los comandos de abajo, `godot` es esa consola).
2. Primera vez (genera el caché de clases): `godot --headless --import`
3. Abrir el proyecto en el editor y presionar F5, o `godot --path .`

Controles: clic en la empanada (o barra espaciadora), botones de la interfaz.

## Tests

```
godot --headless --import                      # solo la primera vez
godot --headless --script tests/run_tests.gd   # BigNumber, economía, inflación, guardado, prestige, contenido y traducciones
godot --headless res://tests/SmokeUI.tscn      # prueba de humo de la interfaz (cualquier "SCRIPT ERROR" es un fallo)
```

El runner propio (`tests/run_tests.gd`) no tiene dependencias y devuelve código de salida 1 si algo falla. Estado actual: **1229 chequeos OK, 0 fallos**.

Nota: los scripts que usan los autoloads (`GameState`, `Economy`...) no compilan con `--script`; por eso la lógica vive en clases puras (`GameModel`, `EconomyLogic`, `GameData`, `SaveIO`) y la prueba de la interfaz corre como escena.

## Simulador de balance

```
godot --headless --script tools/simulate.gd [-- --hours=10 --seed=1 --noprestige]
```

Juega hasta 10 horas con un bot simple y escribe `docs/balance.csv` (minuto en que se llega a cada era, reforma, plan y a la victoria). Resultado actual:

Dos estrategias del bot (3 semillas, minutos de juego). Detalle en [docs/balance_refugios.md](docs/balance_refugios.md):

| Hito | Objetivo (diseño) | Sin refugios | Con refugios |
| --- | --- | --- | --- |
| Era 2 | 30 min | 27 | 27 |
| Era 3 | 120 min | 113-118 | 99-110 |
| Era 4 | 240 min | 216-218 | 179-206 |
| Era 5 | 420 min | 440-443 | 371-390 |
| Victoria (inflación 0) | 7-10 h | 523-531 (8,8 h) | 463-477 (7,8 h) |

Los refugios (cartera diversificada, +15 % de ingresos por refugio con ahorros >= 2 min de ingresos) aceleran ~12 % en promedio (no son obligatorios). Todas las eras quedan a ±25 % de la tabla. Opciones del simulador: `--norefuges`, `--nopark`, `--noevents`, `--noprestige`.

## Estructura

```
project.godot, export_presets.cfg
scenes/Main.tscn              única escena; todo lo demás se construye por código
scripts/core/                 BigNumber, GameData, GameModel, EconomyLogic, SaveIO, I18n, Settings
                              + autoloads: EventBus, GameState, Economy, SaveSystem
scripts/ui/                   pantallas (menú, juego, opciones, créditos), sonido generado, juice
scripts/platform/             interfaz de logros (local + esqueleto de Steam)
data/*.json                   negocios, mejoras, eventos, eras, refugios, planes, billetes, logros, titulares
i18n/                         CSV de traducciones (es/en), cargados en runtime
tests/, tools/                tests, prueba de humo y simulador
```

## Estado de las fases

| Fase | Estado |
| --- | --- |
| 1. Base (proyecto, autoloads, BigNumber, test runner) | Completa |
| 2. Prototipo jugable (clic, negocios, inflación, HUD, guardado, offline) | Completa |
| 3. Sistemas (remarcar, refugios, eventos, reforma, álbum) | Completa |
| 4. Contenido (5 eras, plan económico, final, créditos) | Completa |
| 5. Balance con el simulador | Completa (ver tabla); el bot no usa refugios, así que su valor real no está medido |
| 6. Juice (billetes, temblor, sacudida, tijera, titulares, tinte rojo, sonidos) | Completa |
| 7. Pulido (menú, opciones, logros, inglés, export presets) | Completa; falta probar exports reales |

## Qué falta / TODO

- **Exports**: `export_presets.cfg` define Windows, Linux y Web. No hay export templates instaladas en esta máquina, así que no se exportó. Listo para cuando las instales: `tools/export_all.sh --install-templates` (o `tools/export_all.sh` si ya las tenés; `--check` solo verifica). Deja los builds en `export/` y comprueba que el build web tenga `index.html/js/wasm/pck`.
- **Steam**: `scripts/platform/achievements.gd` es la interfaz; hoy se usa `LocalAchievements` (logros en el save). `achievements_steam.gd` deja anotado dónde conectar GodotSteam (no instalado). Falta crear los logros en Steamworks con los ids de `data/achievements.json`.
- **Arte y sonido**: todo es placeholder generado por código (formas, tweens, partículas, tonos sintetizados). La música es un loop corto que se acelera con la inflación.
- **Balance**: hay que validarlo con jugadores reales; los refugios y los eventos casi no pesan en el simulador. Las tasas por era, el costo de las medidas finales y los umbrales de era están en `data/`.
- **Pruebas visuales**: se revisó el layout a 1280x720; falta probar otras resoluciones y pantalla completa.
- Revisión de los textos en inglés por un nativo y prueba del humor con jugadores de afuera de Latinoamérica (riesgo del diseño).

## Decisiones principales

- Refugios: cartera diversificada (+15 % de ingresos por refugio con ahorros >= 2 min de ingresos).
- Costos de negocios crecen x1,22 por unidad; ingresos escalan con tus precios (M), costos con el nivel de precios (P); remarcar pone M al día.
- Era según ganancia real histórica (independiente de la inflación). Credibilidad por ganancia real de cada vuelta, con exponente 0,3.
- Cada plan económico se usa una sola vez; la cruzada final son 5 medidas que bajan la tasa un 20 % cada una.
- La inflación corre también offline (tope 12 h); sin auto-remarcado el ingreso real se licua.
- Nada de políticos, partidos ni billetes reales: billetes, empresas y titulares son ficticios.

## Repositorio

https://github.com/agusmoscato/INFLATION-What-Inflation-.git (rama `main`). Se hace push después de cada commit de fase.

## Estilo visual

Pizarra de kiosco caricaturesca: todo dibujado con tiza (ver [docs/rediseno.md](docs/rediseno.md), con el antes y después). Tipografías Cabin Sketch y Caveat Brush (SIL OFL, licencias en `assets/fonts/`). Íconos propios opcionales en `assets/icons/<id>.png`.

## Capturas por resolución

```
TOUR_RES=1920x1080 SHOT_DIR=docs/screenshots godot --rendering-driver opengl3 res://tests/ScreenshotTour.tscn
```

Genera 13 capturas (JPG) (menú, juego en Era 1 y 3, las 6 pestañas, hiperinflación, tijera de la reforma, opciones, créditos) renderizando fuera de pantalla a tamaño exacto, emulando el escalado del proyecto. Revisadas en 1920x1080, 1280x800 (Steam Deck) y 2560x1440: ver `docs/screenshots/`. Los avisos ("¡Logro!") se apilan sobre la empanada; es cosmético.

## Página de Steam

Borrador en español e inglés (descripción corta y larga, features y etiquetas): [docs/STEAM_PAGE.md](docs/STEAM_PAGE.md).

## Builds y exportación

Presets en `export_presets.cfg`: **Windows Desktop**, **Linux**, **Web**, **Windows Demo** y **Web Demo** (los dos últimos con el feature tag `demo`). Requieren las export templates 4.4.1 (en Windows las instala `tools/setup.ps1`; en Linux/macOS `tools/export_all.sh --install-templates`). `export/` está en `.gitignore`. En Windows, `powershell -File tools/export_all.ps1` hace todo esto, con QA, y deja los zips para itch.io en `export\web\InflationWhatInflation_web.zip` y `export\web_demo\InflationWhatInflation_web_demo.zip`.

```
godot --headless --import
godot --headless --export-release "Windows Desktop" export/windows/InflationWhatInflation.exe
godot --headless --export-release "Windows Demo"    export/windows_demo/InflationWhatInflationDemo.exe
godot --headless --export-release "Web"             export/web/index.html
godot --headless --export-release "Web Demo"        export/web_demo/index.html
```

- **Windows**: un solo `.exe` portable (PCK embebido), con el ícono de la empanada (rcedit) y la versión/nombre del producto incrustados. Sin firmar: SmartScreen puede advertir la primera vez.
- **Web**: GL Compatibility / WebGL 2, sin threads. Guardado en IndexedDB. Instrucciones de itch.io en [docs/ITCH.md](docs/ITCH.md).
- **Demo**: Era 1, Era 2 y la primera reforma; después muestra la pantalla "¡Esto fue la demo!". Guarda aparte del juego completo. `DemoMode.STEAM_URL` (vacía) se completa cuando haya AppID. En el editor se puede probar con el argumento `--demo`.
- Las traducciones viven en `i18n/*.txt` (formato CSV con extensión `.txt` para que Godot las exporte crudas) y los datos en `data/*.json`; los presets los incluyen con `include_filter`.
- El ícono se genera con `godot --rendering-driver opengl3 res://tools/IconMaker.tscn` (`icon.png` + `icon.ico`).
- **Pendiente:** el build de Linux no se probó en esta máquina. No hay integración con Steam todavía (falta el AppID).

## Opciones de rendimiento

Opciones > "Calidad de tiza" (Alta / Media / Baja) baja el efecto de pantalla, las partículas y los manchones. Si los FPS caen por debajo de 45 durante 5 s, el juego sugiere bajarla.

## Tutorial y eventos

Los primeros 2 minutos tienen un tutorial de tiza (clic → carrito → inflación → remarcar) que se puede saltear y no vuelve a aparecer. Los eventos plantean una decisión de 2 opciones con 10 s para elegir (ver [docs/balance_eventos.md](docs/balance_eventos.md)).
