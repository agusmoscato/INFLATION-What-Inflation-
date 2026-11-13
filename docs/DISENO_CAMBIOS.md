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
