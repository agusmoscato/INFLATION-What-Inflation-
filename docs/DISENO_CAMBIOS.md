# Cambios de diseño (tanda "jugabilidad clara, coleccionables y timba")

`docs/DISENO.md` no se toca. Acá se anota cada sistema nuevo. Las decisiones técnicas están en `docs/DECISIONES.md`.

## Parte A: que se entienda la jugabilidad

### A1. Objetivo siempre visible
- Una notita de tiza fija en la columna izquierda muestra el próximo objetivo con su progreso ("Tené 3 carritos: 1/3") y una barra.
- La cadena (`ObjectiveLogic`, 60+ objetivos) cubre todo el juego: carrito, primera inflación, remarcar, mejoras, cada negocio de la Era 1, sobres, Era 2, refugio, evento, raspadita, reforma, figuritas, Eras 3 a 5, plan económico, medidas y ganar. Cada texto enseña algo.
- El índice solo avanza (`obj_index`): reformar no hace retroceder la cadena.
- Si el objetivo tarda más de 60 s en alcanzarse, la notita agrega una **meta chica** ("Mientras tanto: Kiosco ($440), en unos 25 s") para que siempre haya algo a mano.

### A2. ¿Le ganás a la inflación?
- Indicador grande en el HUD: flecha verde + "LE GANÁS A LA INFLACIÓN" o flecha roja + "LA INFLACIÓN TE ESTÁ COMIENDO".
- Regla: se compara tu **ingreso real por segundo** (ingreso / nivel de precios) con el que tenías al cierre del mes anterior. Tras un aumento sin remarcar cae (rojo); se recupera remarcando o comprando negocios (verde).
- Debajo muestra los números ("Ingreso real $2,75/s (antes $0/s)").

### A3. Tooltips en todo
- Al pasar el mouse: una línea con números concretos, sin fórmulas. Ejemplos: negocio ("Te da $40/s. La inflación te come $12/s de ese valor."), mejoras (efecto en $/s), remarcar ("tus ingresos pasan de $x/s a $y/s"), plata en mano, tasa, empanada, refugios, reforma, pestañas, indicador, objetivos.
- Los tooltips usan el estilo de tiza del juego.

### A4. Desbloqueo progresivo
- Cada mecánica aparece en su momento: **Mejoras** (primer negocio), **Figuritas** (abrir el Kiosco), **Eventos, Refugios, Reforma y Timba** (Era 2), **Quiniela y timba del dólar** (Era 3; no existen en la demo).
- Al desbloquearse, un cartel de tiza animado la explica en 1 o 2 líneas y una flecha señala la pestaña.
- Las pestañas bloqueadas se ven tachadas con "PRÓXIMAMENTE" y un tooltip que dice qué hacer para abrirla. Al cargar una partida avanzada no se anuncia todo de golpe.

### A5. "¿Cómo se juega?"
- Botón en el menú: una pizarra ilustrada de una sola pantalla con el loop **vendé → invertí → remarcá → protegete → reformá** y la meta final.

### A6. Verificación de jugador nuevo
- `godot --headless --script tools/simulate.gd -- --qa-newplayer` simula los primeros 15 minutos con las acciones más obvias (clic, comprar lo que pide el objetivo, remarcar).
- Pasa si nunca hay más de 60 s sin algo alcanzable (objetivo en <= 60 s o una meta chica). Resultado: ver el final de este documento y `docs/qa_newplayer.csv`.

## Resultado del QA de jugador nuevo

```
Objetivos cumplidos: 27 | mayor espera entre objetivos cumplidos: 158 s
Segundos en los que el objetivo tardaba mas de 60 s y se mostro una 'meta chica': 268
Mayor tramo SIN nada alcanzable: 0 s (en el segundo 0)
RESULTADO: PASA (limite 60 s sin objetivo alcanzable)
```

Con la cadena de objetivos actual el jugador nuevo siempre tiene algo alcanzable: en los tramos donde el objetivo principal tarda mas de 60 s (por ejemplo el cartel gigante de $3 K en el minuto 6) la notita muestra una meta chica comprable en menos de 45 s. El detalle de tiempos de cada objetivo esta en `docs/qa_newplayer.csv`.

## Parte B: coleccionables

### B1. Álbum de figuritas del barrio
- 60 figuritas en 6 páginas de 10: **Negocios, Personajes del barrio, Billetes, Titulares, Eventos y Doradas** (`data/stickers.json`).
- Rarezas: común (borde blanco), rara (celeste) y dorada (amarilla, con brillo de tiza animado: una banda diagonal que barre la figurita y destellos que titilan).
- Todas dibujadas por código en estilo pizarra caricaturesca: negocios con los íconos de tiza, 10 personajes con cara y accesorio propios (verdulera, kiosquero, taxista, abuela, perro, gato, contador, economista, pibe del delivery y cartonero), billetes en miniatura, y 30 garabatos para titulares, eventos y doradas. Cada una tiene un chiste corto (tooltip).
- El álbum de billetes pasó a ser la página **Billetes** (10 billetes). Se llena con las reformas, como antes; las figuritas se conservan entre reformas.

### B2. Sobres
- Se compran en la pestaña Álbum una vez abierto el Kiosco: 5 figuritas por sobre. El precio es 45 s de tus ingresos (con un piso que sigue al nivel de precios), así que **sube con la inflación**.
- Abrirlos: se rasga arrastrando el mouse por el borde (con partículas de tiza y sonido de rasgado), las figuritas salen de a una dándose vuelta, el sello **¡REPE!** marca las repetidas, **¡NUEVA!** las que te faltaban y las **doradas** disparan un sonido especial, una lluvia de tiza y un temblor. "Abrir todo" salta la animación.
- Probabilidades por figurita: dorada 3 %, rara 22 %, común 75 %. Los billetes no salen de sobres.

### B3. Repetidas y chupi
- Contador "Tengo X/60 - Me falta Y - Repetidas Z".
- **Chupi:** 5 repetidas se cambian por 1 figurita faltante a elección (las doradas cuestan 15; sin eso, las 10 doradas serían demasiado fáciles de completar).

### B4. Recompensas
- Cada página completa da un bonus permanente: Negocios +10 % ingresos, Personajes -5 % inflación, Billetes +25 % ingresos (más 2 % por billete), Titulares +50 % al bono de remarcar a tiempo, Eventos +5 s para decidir y Doradas +15 % ingresos y -10 % inflación.
- Álbum completo: logro "El Gran Coleccionista" y un **final secreto** (pantalla de pizarra).
- Los bonus no afectan al simulador (el bot no colecciona), así que los tiempos de balance no cambian.

### B5. Más fuentes de figuritas
- Los eventos dejan una figurita de premio el 30 % de las veces (rareza 78 % común, 20 % rara, 2 % dorada).
- La demo regala un sobre una sola vez al abrirse el álbum.
- La timba (parte C) también da sobres y doradas.

## Parte C: timba (siempre con plata del juego)

Nunca hay dinero real ni microtransacciones; hay un cartel fijo que lo dice en la pestaña. Balance y números: [docs/balance_timba.md](balance_timba.md). La demo incluye la raspadita pero no la quiniela ni la timba del dólar.

### C1. Raspadita del kiosco (Era 2)
- Se compra por 1 %, 5 % o 10 % de tu plata actual (acotado por el tope de premios) y se **raspa con el mouse**: polvo de tiza que salta de la tarjeta, sonido de raspado, auto-revelado al 55 % raspado y reacciones según el premio (monedas, lluvia de tiza dorada, temblor de pantalla, fanfarria especial para el pozo).
- Premios: nada, x2, x10, un sobre de figuritas, una figurita dorada o el **pozo** que crece con cada raspadita.

### C2. Quiniela del mes (Era 3)
- Elegís un número del 00 al 99 y cuánto apostar. Al cerrar el mes se sortea con una animación de **bolillero** en tiza (bombo con bolillas, salen dos bolillas con la decena y la unidad). 2 cifras pagan x70 y la última cifra x7, sobre lo que juega después de la comisión del 30 % del quinielero (esa comisión es lo que mantiene el valor esperado en -7 %).

### C3. Timba del dólar (Era 3)
- Antes de cada mes apostás si el dato oficial de inflación queda arriba o abajo de la tasa de hoy (paga x1,9). El dato oficial tiene ruido; hay **pistas reales** de los eventos activos (por ejemplo, "Corrida cambiaria termina en 12 s, antes del cierre: la inflación va a bajar").

### C4. Balance
- Valor esperado -5,9 % (raspadita), -6,9 % (quiniela) y -5 % (dólar); con las 6 páginas del álbum la raspadita queda cerca de 0. Tope: ningún premio supera 10 minutos de tus ingresos. El simulador tiene el modo `--timbero`.

### C5. Rachas y estadísticas
- Tras 5 pérdidas seguidas la próxima raspadita paga seguro (x1,5). El álbum muestra ganado, perdido y mejor premio.

### C6. Logros de timba
- "Timbero" (10 raspaditas), "Raspador serial" (50), "¡El pozo!", "Me salió la quiniela", "Dólar sabio" (3 apuestas ganadas), "Lo perdí todo (y está bien)" (8 pérdidas seguidas) y "Rasqué una dorada". Más los de figuritas: primer sobre, mitad del álbum, página completa, brillo de tiza, el chupi y El Gran Coleccionista.

## Parte D: marketing

### D1. Control de calidad de los exportados
- `tools/export_all.ps1` y `.sh` abren cada `.exe` exportado con `--qa-screenshot`: menú, cómo se juega, partida nueva, negocios, álbum y timba, en español e inglés. Guarda capturas en `user://qa/` y **falla** si algún Label o botón visible muestra una clave de traducción (`ui.…`, `biz.…`). Fue la lección de los exportados que mostraban claves: ahora no se puede publicar uno así sin enterarse.

### D2. Clips automáticos
- `godot --write-movie out.avi --fixed-fps 30 -- --record-clip <nombre> --clip-size 1920x1080` graba un clip con el Movie Maker de Godot. Los guiones están en `scripts/ui/clip_director.gd`: se prepara el estado del juego, se dispara una línea de tiempo de acciones y se rotulan carteles de tiza grandes (el primero aparece a los 0,05 s: el gancho está en el primer segundo).
- Clips (10 a 16 s): `precio_empanada` (el precio de una empanada en 60 s, con inflación del 100 % mensual solo para el clip), `trillon_cafe`, `tijera` (la reforma cortando ceros), `hiperinflacion`, `sobre_dorada`, `raspadita_pozo`, `quiniela`.
- `tools/record_clips.ps1` los graba todos en horizontal (1920x1080, `_h`) y vertical (1080x1920, `_v`) en `export/clips/`. Si hay `ffmpeg` convierte a MP4 (H.264); si no, deja AVI (MJPEG) y avisa.
- **Layout vertical:** `GameScreen._apply_layout()` pasa a una columna cuando la pantalla es más alta que ancha (cabecera en 2 columnas, mascota arriba, pestañas con texto recortado, filas de negocios compactas). También sirve para jugar en pantallas verticales. El contenido escala sobre una base de 720x1280.
- **Detalles técnicos que costaron:** la pantalla del PC (1080 px de alto) recorta la ventana inicial, así que se arranca chica y el juego la agranda por código a `--clip-size`. Si la PC se traba, el motor avanza las animaciones de golpe: el director descarta esa toma (código de salida 3) y el script reintenta.

### D3. Imágenes de Steam
- `tools/steam_assets.ps1` genera todo en `export/steam_assets/` (no se commitea): 7 imágenes de cápsula/hero/logo con `tools/steam_assets.gd` (estilo pizarrón, empanada, billete de ceros, figuritas), 74 íconos de logros (256x256, desbloqueado y en gris) y los 8 screenshots 1920x1080 con el tour de capturas (`SHOT_PNG=1`). La tabla "archivo → lugar de Steamworks" está en `docs/STEAM_PAGE.md`.

### D4. Steam
- `docs/STEAM.md`: pasos de GodotSteam para 4.4.1, dónde va `steam_appid.txt`, cómo conectar el código y qué declarar en el cuestionario (apuestas simuladas sin dinero real). La lista de 37 logros en formato Steamworks está en `docs/steam_achievements.csv` (generada por `tools/make_achievements_csv.ps1`; el API name es el id del juego).

### D6. QA de web y Linux, y conversión de clips
- **QA web** (`tools/web_qa.ps1`, lo llama `export_all`): sirve el build, abre `index.html?qa=web` en Chrome headless y mira las líneas `QA_*` de la consola. Chequea (1) que ningún texto visible sea una clave sin traducir (menú → partida nueva → negocios → álbum → timba, en es y en), (2) que la **raspadita se rasque con el mouse** (arrastres reales por el protocolo de Chrome) hasta revelarse, (3) que el **sobre se rasgue con el mouse** y muestre las 5 figuritas, (4) que el **guardado persista al recargar** la página (IndexedDB): la fase 2 carga la partida y verifica los datos. Capturas en `export/qa_web/`. Pasó en `web` y en `web_demo`.
  - Las posiciones del mouse las calcula el propio juego (transformada de pantalla) y las imprime, así el QA sigue funcionando si cambia el tamaño de la ventana. Chrome headless con WebGL por software corre a pocos cuadros por segundo, por eso el modo QA desactiva la acumulación de entrada del mouse.
- **QA Linux:** `tools/export_all.sh` corre el binario con `--qa-screenshot` (con `xvfb-run` si no hay pantalla) cuando se ejecuta en Linux. **En este PC (Windows, sin WSL) no se puede correr el binario de Linux, así que ese control no se ejecutó**: el export de Linux se genera pero no se probó. En Windows el script lo saltea y lo avisa.
- **Clips a MP4:** `tools/record_clips.ps1` convierte solo (H.264 `-preset veryfast`, CRF 20, AAC; los verticales se reconvierten con CRF más alto si pasan de 50 MB) y borra el AVI; `-ConvertOnly` convierte los AVI que ya existan. La conversión vive en el script y no dentro de `--record-clip`, porque el archivo de video recién se cierra cuando el motor termina. No encontré `ffmpeg` en este PC (ni en el PATH ni en WinGet/Chocolatey/Scoop), así que los clips siguen en AVI hasta que se pase la ruta (`-Ffmpeg ruta` o variable `FFMPEG`).
