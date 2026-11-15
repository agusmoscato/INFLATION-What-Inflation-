# INFLATION? What Inflation?

Un **clicker casual con renacimientos** para Steam: tocás la empanada, abrís negocios y le ganás a la inflación hasta que los precios explotan; entonces hacés la reforma monetaria, gastás la Credibilidad en un árbol de 115 nodos y volvés a empezar, más rápido. **1 hora para el final, 3–4 horas para el 100 %.** Hecho con **Godot 4.4 (GDScript)**; todo lo visual y sonoro está generado por código.

> Rama `rediseno-clicker`. Diseño v2: [docs/DISENO_V2.md](docs/DISENO_V2.md) · balance medido: [docs/balance_v2.md](docs/balance_v2.md) · página de Steam: [docs/STEAM_PAGE.md](docs/STEAM_PAGE.md). El diseño anterior (tycoon de eras) queda en [docs/DISENO.md](docs/DISENO.md).

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
godot --headless --script tests/run_tests.gd   # BigNumber, economía, árbol, guardado, figuritas, contenido y traducciones
godot --headless res://tests/SmokeUI.tscn      # prueba de humo de la interfaz (cualquier "SCRIPT ERROR" es un fallo)
```

El runner propio (`tests/run_tests.gd`) no tiene dependencias y devuelve código de salida 1 si algo falla.

Nota: los scripts que usan los autoloads (`GameState`, `Economy`...) no compilan con `--script`; por eso la lógica vive en clases puras (`GameModel`, `EconomyLogic`, `TreeLogic`, `GameData`, `SaveIO`, `BotPolicy`) y la prueba de la interfaz corre como escena.

## Simulador de balance y QA de duración

```
godot --headless --script tools/simulate.gd -- --seeds=1,2,3,4 --qa      # código 1 si algún chequeo falla
powershell -File tools/qa_newplayer.ps1 -Profile pasivo -Seconds 600     # 10 min con la interfaz real + hoja de contacto
powershell -File tools/qa_newplayer.ps1 -Profile activo -Seconds 3600    # 60 min (hojas 0–10 y 10–60 min)
```

Tres jugadores de prueba (`scripts/core/bot_policy.gd`, los mismos en el simulador y en el QA del juego real):
**activo** (7 clics/s, atrapa casi todos los billetes, compra lo de mejor repago), **pasivo** (1 clic/s, compra siempre
lo más barato) y **distraído** (4 clics/s y deja de jugar 2 minutos a mitad de las vueltas largas). Los tres reforman
cuando el juego lo aconseja (el botón de reforma late). El simulador escribe `docs/balance_v2.md`.

Chequeos para los tres (falla si no se cumplen): nunca más de 20 s sin poder comprar ni reformar, la vuelta 2 llega a
la plata de la vuelta 1 en menos de la mitad del tiempo, ninguna reforma da menos de 5 de Credibilidad (la primera,
entre 5 y 10) y, salvo el pasivo, los clics son la fuente principal de plata en el primer minuto. Duración (activo):
primera reforma entre los minutos 4 y 6, final entre 45 y 60 (pasivo y distraído: entre 60 y 75), 100 % entre 3 y 4 horas, nunca más de 20 s sin una mejora a tiro en la primera hora, y la vuelta 10 llega a la plata
de la vuelta 1 en un quinto del tiempo.

`tools/qa_newplayer.ps1` arma `docs/qa/v2_0_a_10_min_<perfil>.jpg` (una captura cada 30 s) y
`docs/qa/v2_10_a_60_min_<perfil>.jpg` (cada 2,5 min).

## Estructura

```
project.godot, export_presets.cfg
scenes/Main.tscn              única escena; todo lo demás se construye por código
scripts/core/                 BigNumber, GameData, GameModel, EconomyLogic, TreeLogic, StickerLogic, GambleLogic (raspadita),
                              BotPolicy, SaveIO, I18n, Settings + autoloads: EventBus, GameState, Economy, SaveSystem
scripts/ui/                   menú, juego (GameScreen), árbol (SkillTreeView), billete volador, íconos de mejoras, álbum,
                              raspadita, sobres, sonido generado, juice
scripts/platform/             interfaz de logros (local + esqueleto de Steam)
data/*.json                   negocios, mejoras, árbol, noticias, capas visuales, billetes, figuritas, logros, titulares
i18n/                         CSV de traducciones (es/en), cargados en runtime (v2.txt tiene todo lo del diseño nuevo)
tests/, tools/                tests, prueba de humo, simulador y QA
```

## Decisiones principales (v2)

- Inflación como pared: la tasa crece sola en cada vuelta (r = 0,2 %/s · e^(t/78 s), se duplica cada ~54 s); todo cuesta × P y la producción no sube con P. Remarcar congela P unos segundos.
- Credibilidad por vuelta = (log10(plata máxima ganada) − 4)², con multiplicadores del árbol; para cobrarla entera hay que acercarse a la mejor vuelta (a 2 ceros o menos), así no conviene reformar cada 20 s. La primera reforma se habilita cuando la economía colapsa.
- El árbol (115 nodos) es lo que acelera cada vuelta; los costos por anillo (3, 10, 30, 80, 250, 1.500, 8.000, 22.000; final 3.000) están calibrados con el simulador.
- Se eliminaron el plan económico, los refugios, la quiniela, la timba del dólar, el panel de objetivos y las órdenes de compra. Las partidas de la versión 1 no se convierten (se empieza de cero con un aviso).
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
- **Demo**: las primeras 3 vueltas y los anillos 1–3 del árbol; después de la tercera reforma muestra "¡Esto fue la demo!". Guarda aparte del juego completo. `DemoMode.STEAM_URL` (vacía) se completa cuando haya AppID. En el editor se puede probar con el argumento `--demo`.
- Las traducciones viven en `i18n/*.txt` (formato CSV con extensión `.txt` para que Godot las exporte crudas) y los datos en `data/*.json`; los presets los incluyen con `include_filter`.
- El ícono se genera con `godot --rendering-driver opengl3 res://tools/IconMaker.tscn` (`icon.png` + `icon.ico`).
- **Pendiente:** el build de Linux no se probó en esta máquina. No hay integración con Steam todavía (falta el AppID).

## Opciones de rendimiento

Opciones > "Calidad de tiza" (Alta / Media / Baja) baja el efecto de pantalla, las partículas y los manchones. Si los FPS caen por debajo de 45 durante 5 s, el juego sugiere bajarla.

## Tutorial y noticias

El tutorial dura solo la primera vuelta (unos 4 minutos) y son 4 notitas que se van solas: tocá la empanada → comprá un carrito → remarcá → reformá. Después solo hay avisos chicos de cosas nuevas (desbloqueos, mejoras, hitos, logros) que desaparecen en 3 s. Las noticias (eventos con 2 opciones y 10 s para elegir) se desbloquean en la rama INFLACIÓN del árbol.
