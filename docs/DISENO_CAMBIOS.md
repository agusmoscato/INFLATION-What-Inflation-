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
