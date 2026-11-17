# Clips de marketing de INFLATION

Este juego es parte del estudio moscode.games: para todo lo visual y los clips, seguir ../../../_estudio/brand/MARCA.md.

Este repo aporta solo la **grabación cruda**; la edición de marca (caja de gancho, cierre, EN/ES, hoja de contacto)
la hace `_estudio/tools/clip_tool.py`, desde la carpeta del estudio con `/clips inflation`.

## Grabar
```
powershell -File tools/clips/grabar.ps1                          # los 8 guiones, en y es, 1080x1920
powershell -File tools/clips/grabar.ps1 -Clips tijera -Langs en  # uno solo
powershell -File tools/clips/grabar.ps1 -Size 1920x1080          # horizontal (tráiler del canal)
powershell -File tools/clips/grabar.ps1 -Listar                  # guiones disponibles
```
Salida: `export/clips_crudos/<guion>_<idioma>.mp4` (30 fps, CRF 16, con sonido; `export/` no se versiona).
Con otro `-Size` el nombre lleva el tamaño: `<guion>_<idioma>_1920x1080.mp4`.
Basado en `tools/record_clips.ps1` (que sigue igual): mismo Movie Maker, mismos reintentos si la PC se traba.
Abre una ventana de Godot siempre arriba mientras graba: no la tapes ni la minimices.

Flags del juego que usa (en `scripts/ui/main.gd` y `scripts/ui/clip_director.gd`; sin ellos todo sigue igual):
- `--clip-lang en|es`: idioma de la interfaz en el clip (antes era siempre español).
- `--clip-sin-carteles`: no dibuja los carteles de tiza del director, porque el gancho va en la caja de marca.

## Guiones (`scripts/ui/clip_director.gd`)
| guion | dura | qué muestra |
|---|---|---|
| `precio_empanada` | 16 s | el precio de un carrito en un minuto de inflación |
| `trillon_cafe` | 14 s | de $1 a un trillón y el carrito igual no alcanza |
| `tijera` | 13 s | la reforma monetaria: la tijera le corta los ceros al billete |
| `hiperinflacion` | 14 s | hiperinflación con la empanada en pánico y números que no entran |
| `sobre_dorada` | 14 s | abrir un sobre de figuritas y que salga una dorada |
| `raspadita` | 14 s | la raspadita que paga x10 |
| `billete` | 14 s | el billete volador y el frenesí |
| `arbol` | 14 s | el árbol de 115 nodos comprándose solo |

Guiones del estudio (23,5 s de acción real cada uno, sin carteles; el bot juega con las llamadas de `Economy`, sin
adelantar el tiempo; grabar con `-Size 1920x1080`):

| guion | qué muestra |
|---|---|
| `remarcar` | inflación ~50 % mensual ("HYPERINFLATION!"), los precios suben solos y el bot remarca a los 7 s (precios congelados 9 s) |
| `imprenta` | compra la imprenta de billetes: ingreso x3,6, vuelan billetes, precios x2 en 23 s (la imprenta no cambia la inflación en el juego) |
| `tijera_larga` | final de vuelta → reforma (tijera) → resumen → 6 compras en el árbol |
| `sobres` | tres sobres seguidos; el último trae la dorada (~19 s) |
| `raspaditas` | nada, nada, x10 |
| `clics` | 15 clics/s a la empanada durante 22 s (330 clics), combo y críticos |
| `billetes` | tres billetes voladores con frenesí x7 y clics |
| `diez_negocios` | compra los 10 negocios, del carrito al holding (la lista baja sola) |
| `noticias` | turistas, corrida y tarifazo, con elección |
| `compras` | compra todo de a 10: precios tachados, hitos x2 y logros |

Sesiones largas para montar (clips que atrapan; el bot del juego, `BotPolicy`, juega de verdad con la interfaz;
cada momento se registra como `BEAT <segundo> <qué>` en `export/clips_crudos/<sesión>_es_1920x1080.log`):

| sesión | qué graba |
|---|---|
| `sesion_vuelta1` | la vuelta 1 real desde $0 (290 s) |
| `sesion_casi_pierdo` | vuelta 4 (partida jugada sin pantalla hasta ahí): tarifazo → "colgarse del poste" y corrida → "aguantar" (opciones reales que suben la inflación) → hiperinflación 23–26 % → remarca y agarra billetes (300 s) |
| `sesion_progresion` | vuelta ~36 con la imprenta y el holding desbloqueados (el bot prioriza la rama de negocios del árbol): de 3 a 10 negocios en 11 s |
| `sesion_imprenta` | la misma altura de partida, comprando imprentas sin parar: 500 imprentas en 146 s |
| `sesion_vuelta10` | vuelta 10 real (60 s): arranca con $42 K y al minuto tiene más de $1 T |
| `sesion_sobres` | 6 sobres con rarezas reales (el 6.º trae la dorada) y el álbum (34/60) |
| `sesion_billetes_perdidos` | deja pasar 3 billetes (vuelan 12 s y se van) y agarra el 4.º y el 5.º con frenesí |
| `sesion_lluvia` | vuelta 8, un billete cada 8 s agarrado con frenesí y el bot comprando todo |
| `sesion_corrida_remarcar` | igual que `sesion_casi_pierdo` pero en la corrida elige "remarcar" (a los 150 s: $306 B contra $56 B) |
| `sesion_raspaditas` | 5 raspaditas reales: nada, x2, nada, nada, x10 |

Datos medidos (para saber qué se puede mostrar): la imprenta y el holding se desbloquean recién en la vuelta ~36
(~2 h de juego, árbol con 105 de 115 nodos); el remarcar automático aparece en la vuelta 14 (desde ahí no hay
hiperinflación); en la vuelta 1 el bot "activo" solo compra carrito y kiosco en los primeros 5 minutos.

Para un momento nuevo, se suma un `_clip_<nombre>()` al director (y a su `match`).

## Recomendaciones para editar
- **Grabar siempre en horizontal (`-Size 1920x1080`)**: el formato vertical del estudio es "blur fill" (la pantalla
  entera en el medio sobre el mismo video desenfocado; ver MARCA.md). En vertical nativo la interfaz sale chiquita.
- Zooms que funcionan (en px de la grabación 1920x1080, `"zoom": {"factor", "centro", "desde", "dur"}`):
  billete viejo de la reforma 1,5× en `[960, 540]`; figuritas del sobre 1,4× en `[1000, 590]`; billete volador
  1,5× en `[1180, 560]`; empanada 1,8× en `[533, 505]` (deja afuera la barra de plata y "Reform: once you earn…").
- La barra de arriba (plata, inflación del mes) ocupa y 0–200; "Reform: once you earn…" está cerca de y 900.
- **`precio_empanada` e `hiperinflacion` no muestran precios disparándose en el v2**: el freno (`brake_s`) no deja
  que el negocio más barato cueste más de 12 s de producción y corrige con deflación el adelanto del director (el
  carrito baja de $22,8 a $21). Los guiones son del diseño anterior; hasta que se rehagan, no los uses para "inflación".
- Los guiones duran 13–16 s: con `"duracion": 15` o más, la herramienta congela el último cuadro. Mejor que el
  momento fuerte esté en el segundo 0 (`"inicio"` > 0 si tarda en arrancar) y no estirar más de 2 s.
- Título para la caja: `INFLATION?`. Llamado a la acción: "Free demo on itch.io" / "Demo gratis en itch.io".
