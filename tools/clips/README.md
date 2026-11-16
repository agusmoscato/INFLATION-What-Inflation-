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

Para un momento nuevo, se suma un `_clip_<nombre>()` al director (y a su `match`).

## Recomendaciones para editar
- **Grabar en horizontal (`-Size 1920x1080`) y recortar**, también para los clips verticales: en vertical la interfaz
  sale chiquita, arriba, y el resto es pizarrón vacío. Recortes que funcionan (en px de la grabación 1920x1080):
  billete viejo de la reforma `[480, 60, 960, 720]`, pantalla principal `[0, 0, 1440, 1080]`, figuritas del sobre
  `[240, 240, 1440, 720]`, plata + empanada `[0, 0, 960, 720]`; con `"layout": "cuadrado"`.
- **`precio_empanada` e `hiperinflacion` no muestran precios disparándose en el v2**: el freno (`brake_s`) no deja
  que el negocio más barato cueste más de 12 s de producción y corrige con deflación el adelanto del director (el
  carrito baja de $22,8 a $21). Los guiones son del diseño anterior; hasta que se rehagan, no los uses para "inflación".
- Los guiones duran 13–16 s: con `"duracion": 15` o más, la herramienta congela el último cuadro. Mejor que el
  momento fuerte esté en el segundo 0 (`"inicio"` > 0 si tarda en arrancar) y no estirar más de 2 s.
- Título para la caja: `INFLATION?`. Llamado a la acción: "Free demo on itch.io" / "Demo gratis en itch.io".
