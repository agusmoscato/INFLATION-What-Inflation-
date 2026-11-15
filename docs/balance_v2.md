# Balance v2 (simulador)

Generado por `godot --headless --script tools/simulate.gd`. Los jugadores de prueba están descriptos en `scripts/core/bot_policy.gd`; los objetivos, en [DISENO_V2.md](DISENO_V2.md).

## Chequeos

| Jugador | Semilla | Chequeo | Valor | Objetivo | Resultado |
| --- | --- | --- | --- | --- | --- |
| activo | 1 | Máxima espera sin poder comprar ni reformar (s) | 4.0 (en el min 1.6) | <= 20 | PASA |
| activo | 1 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 9.3 (en el min 4.9) | <= 20 | PASA |
| activo | 1 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 25.3 | < 125 (1/2 de 250) | PASA |
| activo | 1 | Credibilidad mínima en una reforma | 9.0 (vuelta 1) | >= 5 | PASA |
| activo | 1 | Credibilidad de la primera reforma | 9.0 | 5–10 | PASA |
| activo | 1 | Plata de clics en el primer minuto (%) | 65.7 | >= 50 | PASA |
| activo | 1 | Primer renacimiento (min) | 4.2 | 4–6 | PASA |
| activo | 1 | Final: Estabilizar la economía (min) | 49.4 | 45–60 | PASA |
| activo | 1 | 100 %: árbol + álbum + logros (min) | 196.9 | 180–240 | PASA |
| activo | 1 | Vuelta 10 llega a la plata de la vuelta 1 (s) | 5.5 | <= 50 (1/5 de 250) | PASA |
| activo | 2 | Máxima espera sin poder comprar ni reformar (s) | 2.3 (en el min 0.6) | <= 20 | PASA |
| activo | 2 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 10.0 (en el min 6.9) | <= 20 | PASA |
| activo | 2 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 93.3 | < 125 (1/2 de 250) | PASA |
| activo | 2 | Credibilidad mínima en una reforma | 10.0 (vuelta 1) | >= 5 | PASA |
| activo | 2 | Credibilidad de la primera reforma | 10.0 | 5–10 | PASA |
| activo | 2 | Plata de clics en el primer minuto (%) | 65.7 | >= 50 | PASA |
| activo | 2 | Primer renacimiento (min) | 4.2 | 4–6 | PASA |
| activo | 2 | Final: Estabilizar la economía (min) | 52.3 | 45–60 | PASA |
| activo | 2 | 100 %: árbol + álbum + logros (min) | 208.3 | 180–240 | PASA |
| activo | 2 | Vuelta 10 llega a la plata de la vuelta 1 (s) | 6.3 | <= 50 (1/5 de 250) | PASA |
| activo | 3 | Máxima espera sin poder comprar ni reformar (s) | 2.3 (en el min 0.6) | <= 20 | PASA |
| activo | 3 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 9.3 (en el min 4.9) | <= 20 | PASA |
| activo | 3 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 26.0 | < 125 (1/2 de 250) | PASA |
| activo | 3 | Credibilidad mínima en una reforma | 10.0 (vuelta 1) | >= 5 | PASA |
| activo | 3 | Credibilidad de la primera reforma | 10.0 | 5–10 | PASA |
| activo | 3 | Plata de clics en el primer minuto (%) | 65.7 | >= 50 | PASA |
| activo | 3 | Primer renacimiento (min) | 4.2 | 4–6 | PASA |
| activo | 3 | Final: Estabilizar la economía (min) | 47.4 | 45–60 | PASA |
| activo | 3 | 100 %: árbol + álbum + logros (min) | 202.2 | 180–240 | PASA |
| activo | 3 | Vuelta 10 llega a la plata de la vuelta 1 (s) | 7.5 | <= 50 (1/5 de 250) | PASA |
| activo | 4 | Máxima espera sin poder comprar ni reformar (s) | 3.5 (en el min 1.5) | <= 20 | PASA |
| activo | 4 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 9.3 (en el min 4.9) | <= 20 | PASA |
| activo | 4 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 25.0 | < 125 (1/2 de 250) | PASA |
| activo | 4 | Credibilidad mínima en una reforma | 8.0 (vuelta 1) | >= 5 | PASA |
| activo | 4 | Credibilidad de la primera reforma | 8.0 | 5–10 | PASA |
| activo | 4 | Plata de clics en el primer minuto (%) | 65.7 | >= 50 | PASA |
| activo | 4 | Primer renacimiento (min) | 4.2 | 4–6 | PASA |
| activo | 4 | Final: Estabilizar la economía (min) | 52.2 | 45–60 | PASA |
| activo | 4 | 100 %: árbol + álbum + logros (min) | 195.9 | 180–240 | PASA |
| activo | 4 | Vuelta 10 llega a la plata de la vuelta 1 (s) | 4.8 | <= 50 (1/5 de 250) | PASA |
| pasivo | 1 | Máxima espera sin poder comprar ni reformar (s) | 11.5 (en el min 5.5) | <= 20 | PASA |
| pasivo | 1 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 12.0 (en el min 0.2) | <= 20 | PASA |
| pasivo | 1 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 140.8 | < 198 (1/2 de 395) | PASA |
| pasivo | 1 | Credibilidad mínima en una reforma | 5.0 (vuelta 1) | >= 5 | PASA |
| pasivo | 1 | Credibilidad de la primera reforma | 5.0 | 5–10 | PASA |
| pasivo | 1 | Primer renacimiento (min) | 6.6 | (informativo) | PASA |
| pasivo | 1 | Final: Estabilizar la economía (min) | 67.8 | 60–75 | PASA |
| pasivo | 2 | Máxima espera sin poder comprar ni reformar (s) | 11.3 (en el min 4.8) | <= 20 | PASA |
| pasivo | 2 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 12.0 (en el min 0.2) | <= 20 | PASA |
| pasivo | 2 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 27.8 | < 177 (1/2 de 353) | PASA |
| pasivo | 2 | Credibilidad mínima en una reforma | 5.0 (vuelta 1) | >= 5 | PASA |
| pasivo | 2 | Credibilidad de la primera reforma | 5.0 | 5–10 | PASA |
| pasivo | 2 | Primer renacimiento (min) | 5.9 | (informativo) | PASA |
| pasivo | 2 | Final: Estabilizar la economía (min) | 65.3 | 60–75 | PASA |
| pasivo | 3 | Máxima espera sin poder comprar ni reformar (s) | 11.3 (en el min 4.3) | <= 20 | PASA |
| pasivo | 3 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 12.0 (en el min 0.2) | <= 20 | PASA |
| pasivo | 3 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 150.8 | < 164 (1/2 de 328) | PASA |
| pasivo | 3 | Credibilidad mínima en una reforma | 5.0 (vuelta 1) | >= 5 | PASA |
| pasivo | 3 | Credibilidad de la primera reforma | 5.0 | 5–10 | PASA |
| pasivo | 3 | Primer renacimiento (min) | 5.5 | (informativo) | PASA |
| pasivo | 3 | Final: Estabilizar la economía (min) | 70.4 | 60–75 | PASA |
| distraido | 1 | Máxima espera sin poder comprar ni reformar (s) | 5.3 (en el min 2.5) | <= 20 | PASA |
| distraido | 1 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 9.8 (en el min 6.3) | <= 20 | PASA |
| distraido | 1 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 25.5 | < 135 (1/2 de 270) | PASA |
| distraido | 1 | Credibilidad mínima en una reforma | 6.0 (vuelta 1) | >= 5 | PASA |
| distraido | 1 | Credibilidad de la primera reforma | 6.0 | 5–10 | PASA |
| distraido | 1 | Plata de clics en el primer minuto (%) | 66.4 | >= 50 | PASA |
| distraido | 1 | Primer renacimiento (min) | 4.5 | (informativo) | PASA |
| distraido | 1 | Final: Estabilizar la economía (min) | 73.1 | 60–75 | PASA |
| distraido | 2 | Máxima espera sin poder comprar ni reformar (s) | 4.0 (en el min 2.6) | <= 20 | PASA |
| distraido | 2 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 9.8 (en el min 6.3) | <= 20 | PASA |
| distraido | 2 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 38.3 | < 135 (1/2 de 270) | PASA |
| distraido | 2 | Credibilidad mínima en una reforma | 7.0 (vuelta 1) | >= 5 | PASA |
| distraido | 2 | Credibilidad de la primera reforma | 7.0 | 5–10 | PASA |
| distraido | 2 | Plata de clics en el primer minuto (%) | 66.4 | >= 50 | PASA |
| distraido | 2 | Primer renacimiento (min) | 4.5 | (informativo) | PASA |
| distraido | 2 | Final: Estabilizar la economía (min) | 65.3 | 60–75 | PASA |
| distraido | 3 | Máxima espera sin poder comprar ni reformar (s) | 3.8 (en el min 1.4) | <= 20 | PASA |
| distraido | 3 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 4.0 (en el min 38.5) | <= 20 | PASA |
| distraido | 3 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 75.8 | < 135 (1/2 de 270) | PASA |
| distraido | 3 | Credibilidad mínima en una reforma | 8.0 (vuelta 1) | >= 5 | PASA |
| distraido | 3 | Credibilidad de la primera reforma | 8.0 | 5–10 | PASA |
| distraido | 3 | Plata de clics en el primer minuto (%) | 66.4 | >= 50 | PASA |
| distraido | 3 | Primer renacimiento (min) | 4.5 | (informativo) | PASA |
| distraido | 3 | Final: Estabilizar la economía (min) | 63.7 | 60–75 | PASA |

## Activo (clickea mucho), semilla 1

| Vuelta | Minuto | Duración | Plata máxima ganada | +Credibilidad | Nodos comprados después | Llega a la plata de la vuelta 1 en |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 4.2 | 4:10 | $137,61 K | 9 | 4 | 250 s |
| 2 | 5.1 | 0:55 | $3,04 M | 23 | 5 | 25 s |
| 3 | 7.0 | 1:57 | $6,15 M | 26 | 4 | 21 s |
| 4 | 8.0 | 0:55 | $619,69 M | 64 | 9 | 20 s |
| 5 | 9.2 | 1:17 | $1,25 B | 72 | 4 | 19 s |
| 6 | 10.4 | 1:06 | $2,59 B | 78 | 3 | 8 s |
| 7 | 11.9 | 1:35 | $17,35 B | 119 | 4 | 8 s |
| 8 | 13.7 | 1:46 | $36,61 B | 129 | 3 | 7 s |
| 9 | 15.5 | 1:45 | $173,72 B | 149 | 1 | 7 s |
| 10 | 17.8 | 2:23 | $349,19 B | 158 | 3 | 6 s |
| 11 | 19.3 | 1:25 | $1,17 T | 193 | 4 | 3 s |
| 12 | 21.3 | 2:00 | $2,34 T | 266 | 3 | 2 s |
| 13 | 21.9 | 0:40 | $5,2 T | 310 | 3 | 1 s |
| 14 | 23.6 | 1:40 | $10,5 T | 327 | 3 | 1 s |
| 15 | 24.4 | 0:50 | $40,93 T | 363 | 2 | 2 s |
| 16 | 26.9 | 2:30 | $34,66 T | 358 | 3 | 2 s |
| 17 | 29.4 | 2:29 | $51,16 T | 391 | 2 | 2 s |
| 18 | 31.9 | 2:30 | $136,6 T | 401 | 0 | 1 s |
| 19 | 34.4 | 2:30 | $207,11 T | 412 | 0 | 1 s |
| 20 | 36.9 | 2:30 | $101,56 T | 392 | 0 | 1 s |
| 21 | 39.4 | 2:30 | $43,22 T | 369 | 0 | 1 s |
| 22 | 41.9 | 2:30 | $51,45 T | 374 | 0 | 1 s |
| 23 | 44.4 | 2:30 | $162,7 T | 406 | 0 | 1 s |
| 24 | 46.9 | 2:30 | $148,65 T | 403 | 0 | 1 s |
| 25 | 49.4 | 2:30 | $47,37 T | 372 | 1 | 1 s |
| … | | | | | | |
| 92 | 192.9 | 2:30 | $75,73 Sx | 6615 | 0 | 0 s |
| 93 | 194.4 | 1:30 | $152,29 Sx | 6808 | 1 | 0 s |
| 94 | 196.9 | 2:30 | $69,74 Sx | 6593 | 1 | 0 s |

- Final (Estabilizar la economía): minuto **49.4**
- 100 %: minuto **196.9**
- Al terminar la simulación (min 197): nodos 115/115, figuritas 60/60, logros 53/53, vueltas 95

## Pasivo (casi no clickea, compra lo más barato), semilla 1

| Vuelta | Minuto | Duración | Plata máxima ganada | +Credibilidad | Nodos comprados después | Llega a la plata de la vuelta 1 en |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 6.6 | 6:35 | $18,1 K | 5 | 2 | 395 s |
| 2 | 9.8 | 3:10 | $45,44 K | 6 | 3 | 141 s |
| 3 | 11.9 | 2:10 | $161,53 K | 12 | 2 | 57 s |
| 4 | 13.0 | 1:05 | $331,21 K | 14 | 3 | 24 s |
| 5 | 13.9 | 0:55 | $709,72 K | 21 | 3 | 18 s |
| 6 | 15.2 | 1:17 | $1,42 M | 24 | 3 | 17 s |
| 7 | 16.8 | 1:33 | $2,85 M | 28 | 4 | 16 s |
| 8 | 17.6 | 0:50 | $23,43 M | 42 | 4 | 9 s |
| 9 | 18.4 | 0:50 | $139,4 M | 54 | 2 | 5 s |
| 10 | 20.9 | 2:30 | $81,92 M | 50 | 2 | 5 s |
| 11 | 23.4 | 2:30 | $37,99 M | 61 | 3 | 5 s |
| 12 | 25.9 | 2:30 | $114,97 M | 72 | 2 | 5 s |
| 13 | 27.7 | 1:45 | $295,92 M | 82 | 3 | 5 s |
| 14 | 30.2 | 2:30 | $395,81 M | 85 | 0 | 4 s |
| 15 | 32.7 | 2:30 | $320,13 M | 82 | 1 | 2 s |
| 16 | 34.7 | 2:00 | $2,52 B | 106 | 3 | 2 s |
| 17 | 35.8 | 1:05 | $6,36 B | 117 | 1 | 1 s |
| 18 | 36.9 | 1:10 | $13,09 B | 127 | 2 | 1 s |
| 19 | 37.9 | 1:00 | $29,83 B | 138 | 3 | 1 s |
| 20 | 39.1 | 1:09 | $60,9 B | 192 | 2 | 1 s |
| 21 | 40.4 | 1:16 | $121,91 B | 224 | 2 | 1 s |
| 22 | 41.9 | 1:31 | $244,47 B | 238 | 1 | 1 s |
| 23 | 43.0 | 1:07 | $487,19 B | 254 | 2 | 1 s |
| 24 | 44.1 | 1:06 | $989,56 B | 270 | 3 | 1 s |
| 25 | 45.6 | 1:32 | $2,07 T | 292 | 2 | 1 s |
| … | | | | | | |
| 57 | 122.1 | 2:30 | $22,64 Qa | 722 | 1 | 0 s |
| 58 | 124.6 | 2:30 | $50,12 Qa | 756 | 1 | 0 s |
| 59 | 126.6 | 2:01 | $90,31 Qa | 1186 | 1 | 0 s |

- Final (Estabilizar la economía): minuto **67.8**
- Al terminar la simulación (min 128): nodos 88/115, figuritas 60/60, logros 45/53, vueltas 60

## Distraído (deja de jugar 2 min a mitad de la vuelta), semilla 1

| Vuelta | Minuto | Duración | Plata máxima ganada | +Credibilidad | Nodos comprados después | Llega a la plata de la vuelta 1 en |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 4.5 | 4:30 | $32,8 K | 6 | 3 | 270 s |
| 2 | 5.4 | 0:55 | $78,4 K | 8 | 3 | 26 s |
| 3 | 6.4 | 1:00 | $2,81 M | 23 | 4 | 24 s |
| 4 | 7.4 | 0:56 | $5,67 M | 31 | 4 | 16 s |
| 5 | 8.3 | 0:55 | $167,87 M | 54 | 8 | 15 s |
| 6 | 10.0 | 1:45 | $89,34 B | 112 | 6 | 16 s |
| 7 | 12.2 | 2:10 | $610,8 B | 166 | 6 | 5 s |
| 8 | 15.3 | 3:05 | $628,31 M | 82 | 2 | 4 s |
| 9 | 18.8 | 3:32 | $1,24 B | 89 | 1 | 3 s |
| 10 | 22.6 | 3:46 | $1,54 B | 91 | 0 | 3 s |
| 11 | 26.5 | 3:53 | $4,44 B | 113 | 3 | 3 s |
| 12 | 27.5 | 1:00 | $1,26 T | 195 | 3 | 2 s |
| 13 | 29.4 | 1:53 | $2,52 T | 206 | 3 | 1 s |
| 14 | 31.9 | 2:30 | $4,67 T | 281 | 3 | 1 s |
| 15 | 33.0 | 1:08 | $9,35 T | 324 | 2 | 1 s |
| 16 | 35.1 | 2:06 | $18,74 T | 342 | 3 | 1 s |
| 17 | 36.1 | 0:58 | $37,53 T | 360 | 3 | 1 s |
| 18 | 38.6 | 2:30 | $55,49 T | 376 | 3 | 1 s |
| 19 | 41.8 | 3:15 | $8,89 T | 328 | 0 | 1 s |
| 20 | 45.5 | 3:37 | $87,95 T | 388 | 0 | 1 s |
| 21 | 49.3 | 3:48 | $63,92 T | 380 | 0 | 1 s |
| 22 | 53.2 | 3:54 | $43,14 T | 369 | 0 | 1 s |
| 23 | 57.1 | 3:57 | $137,37 T | 401 | 0 | 1 s |
| 24 | 61.1 | 3:58 | $48,54 T | 372 | 0 | 1 s |
| 25 | 65.1 | 3:59 | $121,03 T | 397 | 0 | 1 s |
| … | | | | | | |
| 45 | 124.0 | 3:10 | $4,43 Qa | 653 | 1 | 0 s |
| 46 | 127.6 | 3:35 | $21,84 Qa | 720 | 0 | 0 s |
| 47 | 131.4 | 3:47 | $20,09 Qa | 717 | 1 | 0 s |

- Final (Estabilizar la economía): minuto **73.1**
- Al terminar la simulación (min 133): nodos 85/115, figuritas 60/60, logros 45/53, vueltas 48
