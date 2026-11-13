# Steam: qué falta y cómo se conecta

Estado: **la integración con Steam todavía NO está hecha** a propósito: hace falta el AppID. El juego funciona completo sin Steam (logros locales en el save). Este documento tiene los pasos exactos para conectarlo apenas haya AppID.

## 1. GodotSteam para Godot 4.4.1

Hay dos caminos. Recomendado: **plantillas precompiladas** (no hay que compilar Godot).

1. Bajá de <https://godotsteam.com/> (sección *Downloads → Pre-compiled*) el paquete **GodotSteam 4.x para Godot 4.4** (GDExtension). Ojo con la versión: el release tiene que decir 4.4 y el SDK de Steamworks que trae (1.6x) tiene que ser el de ese release.
2. Descomprimilo y copiá la carpeta `godotsteam/` dentro de `addons/` del proyecto (`res://addons/godotsteam/`). Incluye `godotsteam.gdextension` y las DLL (`libgodotsteam.windows.*.dll`, `steam_api64.dll`) para Windows/Linux.
3. Abrí el proyecto una vez en el editor para que registre la extensión (`godot --headless --import`).
4. Verificá: `Engine.has_singleton("Steam")` devuelve `true` con el cliente de Steam abierto.

Alternativa: compilar el módulo (godot-steam) dentro del motor. Solo si hace falta una función que la GDExtension no tenga; implica reexportar templates propias.

**Importante:** los exportados que se suben a Steam deben incluir `steam_api64.dll` al lado del `.exe` (el preset de Windows ya está en modo "no embeber pck", se copia a mano o con *export → Resources → filters*).

## 2. Dónde va `steam_appid.txt`

- **Para probar en desarrollo** (juego lanzado fuera de Steam): archivo de texto con solo el AppID (ej. `480` para el Spacewar de pruebas) en la **misma carpeta que el `.exe`** (en el editor: junto a `project.godot`).
- **No se sube a Steam**: Steam ya sabe el AppID cuando lo lanza el cliente. Está en `.gitignore`; no lo commitees ni lo metas en el depot.
- En el depot de Steam solo van: `InflationWhatInflation.exe`, `.pck` (si no está embebido) y `steam_api64.dll`.

## 3. Cómo conectar el código (cuando haya AppID)

El juego ya está preparado: `scripts/platform/achievements.gd` define la interfaz `Achievements`; `LocalAchievements` guarda en el save; `SteamAchievements` (`achievements_steam.gd`) es el esqueleto. `GameState.adopt()` tiene un `TODO(steam)`.

1. Autoload nuevo `scripts/platform/steam_boot.gd` (**no existe todavía**):
   ```gdscript
   extends Node
   const APP_ID: int = 0   # <- poné el AppID real
   var ok: bool = false
   func _ready() -> void:
       if not Engine.has_singleton("Steam") or DemoMode.is_demo():
           return
       var steam = Engine.get_singleton("Steam")
       var r: Dictionary = steam.steamInitEx(APP_ID)   # status 0 = OK
       ok = int(r.get("status", 1)) == 0
   func _process(_d: float) -> void:
       if ok: Engine.get_singleton("Steam").run_callbacks()
   ```
2. En `GameState` (`new_game()` y `adopt()`): si `SteamBoot.ok` usar `SteamAchievements.new(m.achievements)`; si no, `LocalAchievements`.
3. En `SteamAchievements.unlock(id)`: descomentar `setAchievement(id)` + `storeStats()` (ya está escrito en el esqueleto).
4. Al iniciar (después de cargar el save), sincronizar: por cada id desbloqueado en el save que Steam todavía no tiene, llamar `setAchievement`. Así un jugador que ya jugaba recupera todo.
5. **La demo no usa Steam** (`DemoMode.is_demo()`), tiene su propio AppID/página: se conecta aparte (solo el botón de wishlist con `DemoMode.STEAM_URL`).
6. Botón "Lista de deseos" en el menú de la demo y en la pantalla de fin de demo: poné la URL de la página en `DemoMode.STEAM_URL` (hoy está vacía y el botón no aparece).

## 4. Mapeo de logros

**Los API names de Steamworks son exactamente los ids de `data/achievements.json`** (por ejemplo `first_sale`, `era_3`, `pozo`). No hay tabla de conversión.

La lista completa en el formato para cargar en Steamworks está en [`steam_achievements.csv`](steam_achievements.csv) (generada con `tools/make_achievements_csv.ps1` desde `data/achievements.json` + `i18n/*.txt`, así que no se desincroniza con el juego). 37 logros. Columnas: API name, nombre y descripción en español e inglés, ícono desbloqueado, ícono bloqueado, oculto.

| Dónde en Steamworks | Qué cargar |
|---|---|
| *Stats & Achievements → Achievements* | Un logro por fila del CSV. API name = columna `api_name`. |
| Nombre / descripción | Columnas `nombre_es`/`descripcion_es` (spanish) y `name_en`/`description_en` (english). Hay que cargar **los dos idiomas** en *Localization*. |
| Íconos | `export/steam_assets/achievements/<id>.png` (desbloqueado, 256×256) y `<id>_locked.png` (gris). Se generan con `tools/steam_assets.ps1` (ver `STEAM_PAGE.md`). |
| Ocultos | `album_60` (final secreto del álbum), `lost_all` y `win` (spoilers). El resto, visibles. |

Los 37 logros, para tener a mano (id → nombre en español):

| API name | Nombre | Descripción | Oculto |
|---|---|---|---|
| `first_sale` | Primera venta | Hacé clic en la empanada. | no |
| `clicks_500` | Callos en el dedo | Hacé 500 clics. | no |
| `first_remark` | Cartel recién pintado | Remarcá precios por primera vez. | no |
| `remarks_100` | Marcador compulsivo | Remarcá 100 veces. | no |
| `million_nothing` | Millón de nada | Tené un millón que no alcanza ni para un café. | no |
| `googol` | Googol de nada | Llegá a 1e100 en la mano. | no |
| `buildings_50` | Emprendedor serial | Tené 50 negocios a la vez. | no |
| `buildings_500` | Monopolio de barrio | Tené 500 negocios a la vez. | no |
| `upgrades_30` | Mejoras de todo tipo | Comprá 30 mejoras en una misma vuelta. | no |
| `era_2` | Bienvenido al barrio | Llegá a la Era 2. | no |
| `era_3` | Ciudad grande, precios grandes | Llegá a la Era 3. | no |
| `era_4` | Traje y corbata | Llegá a la Era 4. | no |
| `era_5` | Cero a la izquierda | Llegá a la Era 5. | no |
| `first_event` | Titular del día | Vivé tu primer evento. | no |
| `events_25` | Siempre pasa algo | Vivé 25 eventos. | no |
| `first_refuge` | Del colchón al ladrillo | Guardá plata en un refugio. | no |
| `hyper` | Hiperinflación (ver para creer) | Vivir una tasa mensual de 100 % o más. | no |
| `first_reform` | Tijeretazo | Hacé tu primera reforma monetaria. | no |
| `reforms_5` | Cirujano de ceros | Hacé 5 reformas monetarias. | no |
| `album_full` | Coleccionista | Completá el álbum de billetes. | no |
| `first_plan` | Plan platita | Ejecutá tu primer plan económico. | no |
| `marathon` | Maratón de la plata | Jugá 10 horas en total. | no |
| `zero_cut_30` | Treinta ceros menos | Cortá 30 ceros en total. | no |
| `first_pack` | Primer sobre | Rasgá y abrí un sobre de figuritas. | no |
| `stickers_30` | Mitad del álbum | Juntá 30 figuritas distintas. | no |
| `page_1` | Página completa | Completá una página del álbum. | no |
| `golden_first` | Brillo de tiza | Conseguí una figurita dorada. | no |
| `trade_1` | El chupi | Cambiá repetidas por una figurita faltante. | no |
| `album_60` | El Gran Coleccionista | Completá el álbum de 60 figuritas. | sí |
| `timbero` | Timbero | Raspá 10 raspaditas (con plata del juego). | no |
| `scratch_50` | Raspador serial | Raspá 50 raspaditas. | no |
| `pozo` | ¡El pozo! | Ganá el pozo de la raspadita. | no |
| `quiniela_hit` | Me salió la quiniela | Ganá la quiniela con las 2 cifras. | no |
| `dollar_3` | Dólar sabio | Ganá 3 apuestas de la timba del dólar. | no |
| `lost_all` | Lo perdí todo (y está bien) | Perdé 8 apuestas seguidas. Solo era plata del juego. | sí |
| `gold_scratch` | Rasqué una dorada | Ganá una figurita dorada en una raspadita. | no |
| `win` | ¿Inflación? ¿Qué inflación? | Bajá la inflación a cero. | sí |

## 5. Cuestionario de contenido (Steamworks → Store Page → Content Survey)

Este juego **simula apuestas**: raspadita, quiniela y apuesta al dólar, con plata ficticia del juego. No hay dinero real, no hay compras dentro del juego, no se puede cobrar nada. Aun así, en el cuestionario de contenido hay que declararlo:

- En *Gambling* / *Juegos de apuestas*: marcar **"El juego incluye apuestas simuladas / mecánicas de casino SIN dinero real y sin forma de ganar dinero real o items con valor real"** (Simulated gambling).
- Texto sugerido para el campo de descripción del contenido:
  > El juego incluye minijuegos de azar con moneda ficticia del propio juego (raspadita, quiniela y apuesta a la cotización del dólar). No se usa dinero real, no hay microtransacciones ni cajas con valor real, y los premios son solo monedas y figuritas del juego. Las probabilidades están balanceadas para que, en promedio, apostar sea una pérdida chica, y hay una pantalla de estadísticas que lo muestra.
- Marcar también *Humor / sátira* y, si Steam lo pide, *Contenido de apuestas: sí, simulado*. Esto puede sumar una **calificación de edad (PEGI/ESRB/USK) más alta**; hay que completar el cuestionario IARC con la misma respuesta.
- No marcar "loot boxes" con valor real: los sobres de figuritas se compran **solo con plata ficticia del juego**.

## 6. Checklist antes de subir

1. Tener AppID de juego y de demo, pagar la tarifa de Steamworks.
2. Cargar los 37 logros del CSV + íconos.
3. Completar `APP_ID` en `steam_boot.gd` y `DemoMode.STEAM_URL`.
4. `tools/export_all.ps1` (hace el control de calidad de textos sin traducir), subir `export/windows/` con SteamPipe.
5. Probar con el cliente de Steam abierto: se desbloquea `first_sale` al primer clic y aparece el overlay.
6. Cargar las imágenes de `export/steam_assets/` según [`STEAM_PAGE.md`](STEAM_PAGE.md).
