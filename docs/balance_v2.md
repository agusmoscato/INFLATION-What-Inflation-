# Balance v2 (simulador)

Generado por `godot --headless --script tools/simulate.gd`. Los jugadores de prueba están descriptos en `scripts/core/bot_policy.gd`; los objetivos, en [DISENO_V2.md](DISENO_V2.md).

## Chequeos

| Jugador | Semilla | Chequeo | Valor | Objetivo | Resultado |
| --- | --- | --- | --- | --- | --- |
| activo | 1 | Máxima espera sin poder comprar ni reformar (s) | 4.3 (en el min 1.4) | <= 20 | PASA |
| activo | 1 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 24.0 | < 125 (1/2 de 250) | PASA |
| activo | 1 | Credibilidad mínima en una reforma | 9.0 (vuelta 1) | >= 5 | PASA |
| activo | 1 | Credibilidad de la primera reforma | 9.0 | 5–10 | PASA |
| activo | 1 | Plata de clics en el primer minuto (%) | 67.0 | >= 50 | PASA |
| activo | 1 | Primer renacimiento (min) | 4.2 | 4–6 | PASA |
| activo | 1 | Final: Estabilizar la economía (min) | 59.4 | 50–70 | PASA |
| activo | 1 | 100 %: árbol + álbum + logros (min) | 226.8 | 180–240 | PASA |
| activo | 1 | Vuelta 10 llega a la plata de la vuelta 1 (s) | 4.5 | <= 50 (1/5 de 250) | PASA |
| activo | 2 | Máxima espera sin poder comprar ni reformar (s) | 3.0 (en el min 0.7) | <= 20 | PASA |
| activo | 2 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 97.3 | < 125 (1/2 de 250) | PASA |
| activo | 2 | Credibilidad mínima en una reforma | 10.0 (vuelta 1) | >= 5 | PASA |
| activo | 2 | Credibilidad de la primera reforma | 10.0 | 5–10 | PASA |
| activo | 2 | Plata de clics en el primer minuto (%) | 67.0 | >= 50 | PASA |
| activo | 2 | Primer renacimiento (min) | 4.2 | 4–6 | PASA |
| activo | 2 | Final: Estabilizar la economía (min) | 60.1 | 50–70 | PASA |
| activo | 2 | 100 %: árbol + álbum + logros (min) | 229.0 | 180–240 | PASA |
| activo | 2 | Vuelta 10 llega a la plata de la vuelta 1 (s) | 4.5 | <= 50 (1/5 de 250) | PASA |
| activo | 3 | Máxima espera sin poder comprar ni reformar (s) | 3.0 (en el min 0.7) | <= 20 | PASA |
| activo | 3 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 24.8 | < 125 (1/2 de 250) | PASA |
| activo | 3 | Credibilidad mínima en una reforma | 10.0 (vuelta 1) | >= 5 | PASA |
| activo | 3 | Credibilidad de la primera reforma | 10.0 | 5–10 | PASA |
| activo | 3 | Plata de clics en el primer minuto (%) | 67.0 | >= 50 | PASA |
| activo | 3 | Primer renacimiento (min) | 4.2 | 4–6 | PASA |
| activo | 3 | Final: Estabilizar la economía (min) | 56.7 | 50–70 | PASA |
| activo | 3 | 100 %: árbol + álbum + logros (min) | 225.4 | 180–240 | PASA |
| activo | 3 | Vuelta 10 llega a la plata de la vuelta 1 (s) | 6.0 | <= 50 (1/5 de 250) | PASA |
| activo | 4 | Máxima espera sin poder comprar ni reformar (s) | 3.8 (en el min 1.5) | <= 20 | PASA |
| activo | 4 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 23.5 | < 125 (1/2 de 250) | PASA |
| activo | 4 | Credibilidad mínima en una reforma | 8.0 (vuelta 1) | >= 5 | PASA |
| activo | 4 | Credibilidad de la primera reforma | 8.0 | 5–10 | PASA |
| activo | 4 | Plata de clics en el primer minuto (%) | 67.0 | >= 50 | PASA |
| activo | 4 | Primer renacimiento (min) | 4.2 | 4–6 | PASA |
| activo | 4 | Final: Estabilizar la economía (min) | 65.9 | 50–70 | PASA |
| activo | 4 | 100 %: árbol + álbum + logros (min) | 231.0 | 180–240 | PASA |
| activo | 4 | Vuelta 10 llega a la plata de la vuelta 1 (s) | 3.8 | <= 50 (1/5 de 250) | PASA |
| pasivo | 1 | Máxima espera sin poder comprar ni reformar (s) | 11.3 (en el min 1.5) | <= 20 | PASA |
| pasivo | 1 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 103.5 | < 188 (1/2 de 375) | PASA |
| pasivo | 1 | Credibilidad mínima en una reforma | 5.0 (vuelta 1) | >= 5 | PASA |
| pasivo | 1 | Credibilidad de la primera reforma | 5.0 | 5–10 | PASA |
| pasivo | 1 | Primer renacimiento (min) | 6.3 | (informativo) | PASA |
| pasivo | 1 | Final: Estabilizar la economía (min) | 92.0 | (informativo) | PASA |
| distraido | 1 | Máxima espera sin poder comprar ni reformar (s) | 5.5 (en el min 2.3) | <= 20 | PASA |
| distraido | 1 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 22.0 | < 135 (1/2 de 270) | PASA |
| distraido | 1 | Credibilidad mínima en una reforma | 5.0 (vuelta 1) | >= 5 | PASA |
| distraido | 1 | Credibilidad de la primera reforma | 5.0 | 5–10 | PASA |
| distraido | 1 | Plata de clics en el primer minuto (%) | 67.6 | >= 50 | PASA |
| distraido | 1 | Primer renacimiento (min) | 4.5 | (informativo) | PASA |
| distraido | 1 | Final: Estabilizar la economía (min) | 85.8 | (informativo) | PASA |

## Activo (clickea mucho), semilla 1

| Vuelta | Minuto | Duración | Plata máxima ganada | +Credibilidad | Nodos comprados después | Llega a la plata de la vuelta 1 en |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 4.2 | 4:10 | $135,99 K | 9 | 4 | 250 s |
| 2 | 5.1 | 0:55 | $5,13 M | 26 | 5 | 24 s |
| 3 | 7.1 | 1:59 | $10,4 M | 29 | 5 | 21 s |
| 4 | 8.0 | 0:55 | $2,39 B | 75 | 10 | 16 s |
| 5 | 9.3 | 1:16 | $5,12 B | 84 | 2 | 15 s |
| 6 | 10.5 | 1:11 | $10,55 B | 91 | 3 | 7 s |
| 7 | 11.7 | 1:12 | $9,9 B | 125 | 1 | 8 s |
| 8 | 13.3 | 1:38 | $56,85 B | 134 | 1 | 7 s |
| 9 | 15.8 | 2:30 | $5,51 B | 105 | 1 | 8 s |
| 10 | 17.7 | 1:55 | $2,9 T | 190 | 5 | 5 s |
| 11 | 19.9 | 2:09 | $5,82 T | 221 | 3 | 4 s |
| 12 | 22.0 | 2:07 | $11,79 T | 303 | 4 | 3 s |
| 13 | 23.5 | 1:30 | $24,01 T | 349 | 5 | 3 s |
| 14 | 25.3 | 1:50 | $48,43 T | 367 | 3 | 2 s |
| 15 | 26.8 | 1:28 | $96,85 T | 386 | 2 | 2 s |
| 16 | 28.3 | 1:30 | $157,02 T | 424 | 3 | 2 s |
| 17 | 29.8 | 1:30 | $752,8 T | 451 | 3 | 2 s |
| 18 | 32.3 | 2:30 | $481,15 T | 437 | 1 | 1 s |
| 19 | 34.8 | 2:30 | $700,83 T | 448 | 1 | 1 s |
| 20 | 36.5 | 1:38 | $1,54 Qa | 471 | 1 | 1 s |
| 21 | 38.0 | 1:29 | $1,53 Qa | 519 | 1 | 1 s |
| 22 | 39.4 | 1:25 | $13,76 Qa | 544 | 0 | 1 s |
| 23 | 41.9 | 2:30 | $23,11 Qa | 557 | 0 | 1 s |
| 24 | 44.4 | 2:30 | $45,6 Qa | 580 | 0 | 1 s |
| 25 | 46.9 | 2:30 | $19,2 Qa | 551 | 0 | 1 s |
| … | | | | | | |
| 100 | 222.8 | 2:30 | $78,75 Sx | 6626 | 0 | 0 s |
| 101 | 225.3 | 2:30 | $197,78 Sx | 6881 | 1 | 0 s |
| 102 | 226.8 | 1:29 | $858,15 Sx | 7297 | 1 | 0 s |

- Final (Estabilizar la economía): minuto **59.4**
- 100 %: minuto **226.8**
- Al terminar la simulación (min 227): nodos 115/115, figuritas 60/60, logros 53/53, vueltas 103

## Pasivo (casi no clickea, compra lo más barato), semilla 1

| Vuelta | Minuto | Duración | Plata máxima ganada | +Credibilidad | Nodos comprados después | Llega a la plata de la vuelta 1 en |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 6.3 | 6:15 | $18,12 K | 5 | 2 | 375 s |
| 2 | 8.5 | 2:17 | $36,27 K | 6 | 3 | 104 s |
| 3 | 10.3 | 1:42 | $72,73 K | 9 | 2 | 27 s |
| 4 | 11.3 | 1:00 | $7,14 M | 27 | 4 | 23 s |
| 5 | 13.8 | 2:30 | $4,81 M | 30 | 5 | 17 s |
| 6 | 16.3 | 2:30 | $5,95 M | 32 | 4 | 18 s |
| 7 | 17.5 | 1:14 | $14,33 M | 39 | 4 | 9 s |
| 8 | 18.8 | 1:18 | $28,76 M | 43 | 1 | 5 s |
| 9 | 20.0 | 1:12 | $25,74 M | 49 | 2 | 5 s |
| 10 | 22.5 | 2:30 | $94,88 M | 51 | 1 | 5 s |
| 11 | 24.6 | 2:06 | $189,64 M | 77 | 2 | 4 s |
| 12 | 25.4 | 0:50 | $414,26 M | 85 | 0 | 4 s |
| 13 | 27.3 | 1:48 | $828,95 M | 93 | 1 | 4 s |
| 14 | 29.8 | 2:30 | $138,3 M | 74 | 1 | 4 s |
| 15 | 31.8 | 2:02 | $1,66 B | 101 | 1 | 3 s |
| 16 | 34.3 | 2:30 | $3 B | 108 | 3 | 3 s |
| 17 | 36.8 | 2:30 | $2,73 B | 107 | 2 | 2 s |
| 18 | 39.3 | 2:30 | $1,33 B | 98 | 1 | 2 s |
| 19 | 41.8 | 2:30 | $1,27 B | 98 | 2 | 2 s |
| 20 | 42.7 | 0:55 | $9,53 B | 159 | 2 | 2 s |
| 21 | 44.2 | 1:30 | $8,44 T | 322 | 5 | 2 s |
| 22 | 45.8 | 1:38 | $17 T | 339 | 2 | 1 s |
| 23 | 47.7 | 1:51 | $34,06 T | 358 | 3 | 1 s |
| 24 | 49.5 | 1:50 | $2,61 Qa | 482 | 4 | 1 s |
| 25 | 52.0 | 2:30 | $280,82 T | 421 | 3 | 1 s |
| … | | | | | | |
| 64 | 146.4 | 2:30 | $1,09 Qi | 898 | 1 | 0 s |
| 65 | 148.9 | 2:30 | $427,69 Qa | 1277 | 0 | 0 s |
| 66 | 151.4 | 2:30 | $517,28 Qa | 1290 | 1 | 0 s |

- Final (Estabilizar la economía): minuto **92.0**
- Al terminar la simulación (min 152): nodos 88/115, figuritas 60/60, logros 45/53, vueltas 67

## Distraído (deja de jugar 2 min a mitad de la vuelta), semilla 1

| Vuelta | Minuto | Duración | Plata máxima ganada | +Credibilidad | Nodos comprados después | Llega a la plata de la vuelta 1 en |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 4.5 | 4:30 | $19,77 K | 5 | 2 | 270 s |
| 2 | 5.4 | 0:55 | $243,83 K | 10 | 4 | 22 s |
| 3 | 6.4 | 1:00 | $4,18 M | 25 | 4 | 22 s |
| 4 | 7.3 | 0:50 | $8,37 M | 34 | 5 | 15 s |
| 5 | 8.2 | 0:55 | $378,03 M | 60 | 9 | 13 s |
| 6 | 9.9 | 1:45 | $151,95 B | 118 | 3 | 14 s |
| 7 | 12.4 | 2:30 | $254,08 B | 123 | 3 | 4 s |
| 8 | 15.7 | 3:15 | $1,34 B | 90 | 1 | 4 s |
| 9 | 19.3 | 3:37 | $670,92 M | 82 | 0 | 4 s |
| 10 | 23.1 | 3:48 | $12,14 B | 115 | 1 | 4 s |
| 11 | 27.0 | 3:54 | $66,83 B | 149 | 3 | 2 s |
| 12 | 28.9 | 1:50 | $694,88 B | 185 | 4 | 2 s |
| 13 | 30.9 | 2:00 | $13,96 T | 236 | 3 | 2 s |
| 14 | 33.9 | 3:00 | $742,18 B | 241 | 4 | 2 s |
| 15 | 35.0 | 1:10 | $28,03 T | 353 | 4 | 1 s |
| 16 | 36.5 | 1:26 | $55,84 T | 371 | 2 | 1 s |
| 17 | 38.0 | 1:35 | $112,76 T | 390 | 3 | 1 s |
| 18 | 39.4 | 1:23 | $229,61 T | 411 | 3 | 1 s |
| 19 | 40.8 | 1:20 | $89,97 T | 473 | 2 | 1 s |
| 20 | 43.3 | 2:30 | $2,67 Qa | 488 | 1 | 1 s |
| 21 | 46.5 | 3:15 | $256,62 T | 418 | 1 | 1 s |
| 22 | 50.2 | 3:37 | $1,62 Qa | 473 | 1 | 0 s |
| 23 | 54.0 | 3:48 | $7,25 Qa | 520 | 0 | 0 s |
| 24 | 57.9 | 3:54 | $5,21 Qa | 509 | 0 | 0 s |
| 25 | 61.8 | 3:57 | $3,91 Qa | 500 | 0 | 0 s |
| … | | | | | | |
| 48 | 136.4 | 3:54 | $1,5 Qi | 913 | 0 | 0 s |
| 49 | 140.3 | 3:57 | $336,15 Qa | 842 | 1 | 0 s |
| 50 | 144.3 | 3:58 | $2 Qi | 927 | 0 | 0 s |

- Final (Estabilizar la economía): minuto **85.8**
- Al terminar la simulación (min 146): nodos 83/115, figuritas 60/60, logros 45/53, vueltas 51
