# Comparación del simulador: sin refugios vs con refugios

Comando: `godot --headless --script tools/simulate.gd -- [--norefuges] --seed=N`

**Bot "sin refugios"**: compra por menor repago, remarca a tiempo, reforma y juega los planes. No toca los refugios ni responde a eventos.

**Bot "con refugios"**: lo mismo, más:
- arma una *cartera diversificada* (cada refugio con ahorros >= 2 min de ingresos da +15 % de ingresos); ahorra para armarla solo cuando lo mejor que puede comprar repaga en más de 10 min;
- responde a eventos: cepo (espera, no puede mover nada), corrida cambiaria (vende el dólar que saltó), paro (negocia si sale barato), aguinaldo (no ahorra mientras dura).

Minutos de juego hasta cada hito (semillas 1 / 2 / 3):

| Hito | Objetivo del diseño | Sin refugios | Con refugios | Diferencia |
| --- | --- | --- | --- | --- |
| Era 2 | 30 | 27 / 27 / 27 | 27 / 27 / 27 | 0 % |
| Era 3 | 120 | 113 / 118 / 115 | 100 / 110 / 99 | -12 % / -7 % / -14 % |
| Era 4 | 240 | 216 / 216 / 218 | 179 / 206 / 181 | -17 % / -5 % / -17 % |
| Era 5 | 420 | 443 / 442 / 440 | 372 / 390 / 371 | -16 % / -12 % / -16 % |
| Victoria | 420-600 | 531 / 523 / 524 | 463 / 477 / 463 | -13 % / -9 % / -12 % |

Promedio de las diferencias (Eras 3-5 y victoria, 3 semillas): **-12 %**, dentro del 10-25 % pedido. Ambas estrategias terminan en el rango de 7-10 h del diseño y las eras quedan a ±25 % de la tabla.

## Qué da la ventaja
- La cartera diversificada es lo que mueve la aguja. Con la versión anterior (solo estacionar plata y arrastrar 50 % a la reforma) la ventaja era ~0 % o, peor, exagerada: el arrastre en la reforma le regalaba al bot un capital que salteaba el inicio de cada vuelta.
- Estacionar plata durante las esperas casi no pesa: el bot compra en cuanto puede, así que rara vez tiene efectivo expuesto a la inflación.
- Responder a eventos es ruido dentro de la variación entre semillas (con y sin respuesta a eventos la diferencia es de ±3 %). Los eventos hoy son más sabor que decisión; si querés que importen, hay que darles efectos más grandes.

## No es obligatorio
Sin refugios el bot igual llega al final en ~8,8 h; con ellos, en ~7,8 h. Para un jugador humano la cartera cuesta ~2 min de ingresos por refugio y se mantiene sola (los refugios no se gastan; solo hay que reponer el aumento del ingreso).

Archivos: `balance_sin_refugios.csv`, `balance_con_refugios.csv` (semilla 1). `balance.csv` es la última corrida.
