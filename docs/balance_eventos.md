# Eventos con decisión: cuánto vale jugarlos bien

Cada evento abre una notita de tiza con 2 opciones y 10 s para elegir; si no elegís, se aplica la opción por defecto.

| Evento | Opción A | Opción B | Por defecto |
| --- | --- | --- | --- |
| Feriado largo | Abrir igual: ingresos x0,7 y clics x4 (40 s) | Liquidar: +30 s de ingresos ya, pero ingresos x0,4 (40 s) | A |
| Aguinaldo | Cobrarlo ya: +90 s de ingresos | Invertirlo: ingresos x2 durante 2 min | A |
| Corrida cambiaria | Vender los refugios con +15 % (perdés la cartera) | Aguantar: refugios x1,4 o x0,7 (50 %) | B |
| Cepo | Dólar blue: refugios habilitados con +40 puntos de comisión (60 s) | Pesos: refugios bloqueados 60 s, sin costo | B |
| Paro | Cerrar: sin ingresos 40 s, inflación x0,4 durante 60 s | Horas extra: pagás 25 s de ingresos | A |

Bot "bien jugado" (`simulate.gd`): feriado liquida cuando los clics ya no valen nada frente a los ingresos; aguinaldo siempre se invierte; corrida aguanta si hay cartera diversificada (si no, vende); cepo se queda en pesos; paro paga horas extra si le alcanza.
Bot "por defecto" (`--defaultevents`): siempre la opción por defecto, como si nunca contestara.

Minutos de juego (bot con refugios, semillas 1 / 2 / 3):

| Hito | Por defecto | Bien jugado | Diferencia |
| --- | --- | --- | --- |
| Era 3 | 104 / 110 / 110 | 74 / 108 / 100 | -29 % / -2 % / -9 % |
| Era 4 | 188 / 196 / 210 | 169 / 184 / 183 | -10 % / -6 % / -13 % |
| Era 5 | 384 / 403 / 397 | 352 / 371 / 367 | -8 % / -8 % / -8 % |
| Victoria | 457 / 484 / 481 | 435 / 438 / 450 | -5 % / -9 % / -6 % |

Promedio hasta la victoria: **-6,8 %**, dentro del 5-15 % pedido. Sin refugios (semilla 1): 549 min por defecto vs 480 bien jugado (-12,6 %). Jugar todo bien (refugios + eventos) frente a no tocar nada ronda el -20 %.

Con el bot "por defecto" los tiempos quedan parecidos a los de la tanda anterior (457-484 min con refugios), así que los umbrales de era no hicieron falta moverlos.
El aguinaldo invertido es lo que más pesa (+30 s de ingresos por evento frente a cobrarlo); el cepo no tiene mejor opción en general (por eso el dólar blue es una trampa a propósito).
