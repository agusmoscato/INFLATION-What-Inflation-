# Balance v2 (simulador)

Generado por `godot --headless --script tools/simulate.gd`. Los jugadores de prueba están descriptos en `scripts/core/bot_policy.gd`; los objetivos, en [DISENO_V2.md](DISENO_V2.md).

## Chequeos

| Jugador | Semilla | Chequeo | Valor | Objetivo | Resultado |
| --- | --- | --- | --- | --- | --- |
| activo | 1 | Máxima espera sin poder comprar ni reformar (s) | 4.0 (en el min 1.6) | <= 20 | PASA |
| activo | 1 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 9.3 (en el min 4.9) | <= 20 | PASA |
| activo | 1 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 23.8 | < 125 (1/2 de 250) | PASA |
| activo | 1 | Credibilidad mínima en una reforma | 9.0 (vuelta 1) | >= 5 | PASA |
| activo | 1 | Credibilidad de la primera reforma | 9.0 | 5–10 | PASA |
| activo | 1 | Plata de clics en el primer minuto (%) | 65.7 | >= 50 | PASA |
| activo | 1 | Primer renacimiento (min) | 4.2 | 4–6 | PASA |
| activo | 1 | Final: Estabilizar la economía (min) | 57.2 | 45–60 | PASA |
| activo | 1 | 100 %: árbol + álbum + logros (min) | 207.3 | 180–240 | PASA |
| activo | 1 | Vuelta 10 llega a la plata de la vuelta 1 (s) | 3.3 | <= 50 (1/5 de 250) | PASA |
| activo | 2 | Máxima espera sin poder comprar ni reformar (s) | 2.3 (en el min 0.6) | <= 20 | PASA |
| activo | 2 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 9.8 (en el min 6.5) | <= 20 | PASA |
| activo | 2 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 71.3 | < 125 (1/2 de 250) | PASA |
| activo | 2 | Credibilidad mínima en una reforma | 10.0 (vuelta 1) | >= 5 | PASA |
| activo | 2 | Credibilidad de la primera reforma | 10.0 | 5–10 | PASA |
| activo | 2 | Plata de clics en el primer minuto (%) | 65.7 | >= 50 | PASA |
| activo | 2 | Primer renacimiento (min) | 4.2 | 4–6 | PASA |
| activo | 2 | Final: Estabilizar la economía (min) | 56.1 | 45–60 | PASA |
| activo | 2 | 100 %: árbol + álbum + logros (min) | 210.7 | 180–240 | PASA |
| activo | 2 | Vuelta 10 llega a la plata de la vuelta 1 (s) | 3.5 | <= 50 (1/5 de 250) | PASA |
| activo | 3 | Máxima espera sin poder comprar ni reformar (s) | 2.3 (en el min 0.6) | <= 20 | PASA |
| activo | 3 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 9.3 (en el min 4.9) | <= 20 | PASA |
| activo | 3 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 24.5 | < 125 (1/2 de 250) | PASA |
| activo | 3 | Credibilidad mínima en una reforma | 10.0 (vuelta 1) | >= 5 | PASA |
| activo | 3 | Credibilidad de la primera reforma | 10.0 | 5–10 | PASA |
| activo | 3 | Plata de clics en el primer minuto (%) | 65.7 | >= 50 | PASA |
| activo | 3 | Primer renacimiento (min) | 4.2 | 4–6 | PASA |
| activo | 3 | Final: Estabilizar la economía (min) | 56.0 | 45–60 | PASA |
| activo | 3 | 100 %: árbol + álbum + logros (min) | 205.9 | 180–240 | PASA |
| activo | 3 | Vuelta 10 llega a la plata de la vuelta 1 (s) | 4.3 | <= 50 (1/5 de 250) | PASA |
| pasivo | 1 | Máxima espera sin poder comprar ni reformar (s) | 11.5 (en el min 5.5) | <= 20 | PASA |
| pasivo | 1 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 12.0 (en el min 0.2) | <= 20 | PASA |
| pasivo | 1 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 106.8 | < 198 (1/2 de 395) | PASA |
| pasivo | 1 | Credibilidad mínima en una reforma | 5.0 (vuelta 1) | >= 5 | PASA |
| pasivo | 1 | Credibilidad de la primera reforma | 5.0 | 5–10 | PASA |
| pasivo | 1 | Primer renacimiento (min) | 6.6 | (informativo) | PASA |
| pasivo | 1 | Final: Estabilizar la economía (min) | 73.7 | 60–75 | PASA |
| pasivo | 2 | Máxima espera sin poder comprar ni reformar (s) | 11.3 (en el min 4.8) | <= 20 | PASA |
| pasivo | 2 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 12.0 (en el min 0.2) | <= 20 | PASA |
| pasivo | 2 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 27.0 | < 177 (1/2 de 353) | PASA |
| pasivo | 2 | Credibilidad mínima en una reforma | 5.0 (vuelta 1) | >= 5 | PASA |
| pasivo | 2 | Credibilidad de la primera reforma | 5.0 | 5–10 | PASA |
| pasivo | 2 | Primer renacimiento (min) | 5.9 | (informativo) | PASA |
| pasivo | 2 | Final: Estabilizar la economía (min) | 68.3 | 60–75 | PASA |
| pasivo | 3 | Máxima espera sin poder comprar ni reformar (s) | 11.3 (en el min 4.3) | <= 20 | PASA |
| pasivo | 3 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 12.0 (en el min 0.2) | <= 20 | PASA |
| pasivo | 3 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 116.3 | < 164 (1/2 de 328) | PASA |
| pasivo | 3 | Credibilidad mínima en una reforma | 5.0 (vuelta 1) | >= 5 | PASA |
| pasivo | 3 | Credibilidad de la primera reforma | 5.0 | 5–10 | PASA |
| pasivo | 3 | Primer renacimiento (min) | 5.5 | (informativo) | PASA |
| pasivo | 3 | Final: Estabilizar la economía (min) | 68.6 | 60–75 | PASA |
| distraido | 1 | Máxima espera sin poder comprar ni reformar (s) | 5.3 (en el min 2.5) | <= 20 | PASA |
| distraido | 1 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 9.8 (en el min 6.3) | <= 20 | PASA |
| distraido | 1 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 22.0 | < 135 (1/2 de 270) | PASA |
| distraido | 1 | Credibilidad mínima en una reforma | 5.0 (vuelta 1) | >= 5 | PASA |
| distraido | 1 | Credibilidad de la primera reforma | 5.0 | 5–10 | PASA |
| distraido | 1 | Plata de clics en el primer minuto (%) | 66.4 | >= 50 | PASA |
| distraido | 1 | Primer renacimiento (min) | 4.5 | (informativo) | PASA |
| distraido | 1 | Final: Estabilizar la economía (min) | 67.3 | 60–75 | PASA |
| distraido | 2 | Máxima espera sin poder comprar ni reformar (s) | 4.0 (en el min 2.6) | <= 20 | PASA |
| distraido | 2 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 8.8 (en el min 6.1) | <= 20 | PASA |
| distraido | 2 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 22.0 | < 135 (1/2 de 270) | PASA |
| distraido | 2 | Credibilidad mínima en una reforma | 6.0 (vuelta 1) | >= 5 | PASA |
| distraido | 2 | Credibilidad de la primera reforma | 6.0 | 5–10 | PASA |
| distraido | 2 | Plata de clics en el primer minuto (%) | 66.4 | >= 50 | PASA |
| distraido | 2 | Primer renacimiento (min) | 4.5 | (informativo) | PASA |
| distraido | 2 | Final: Estabilizar la economía (min) | 64.9 | 60–75 | PASA |
| distraido | 3 | Máxima espera sin poder comprar ni reformar (s) | 3.8 (en el min 1.4) | <= 20 | PASA |
| distraido | 3 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 4.0 (en el min 25.7) | <= 20 | PASA |
| distraido | 3 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 23.8 | < 135 (1/2 de 270) | PASA |
| distraido | 3 | Credibilidad mínima en una reforma | 7.0 (vuelta 1) | >= 5 | PASA |
| distraido | 3 | Credibilidad de la primera reforma | 7.0 | 5–10 | PASA |
| distraido | 3 | Plata de clics en el primer minuto (%) | 66.4 | >= 50 | PASA |
| distraido | 3 | Primer renacimiento (min) | 4.5 | (informativo) | PASA |
| distraido | 3 | Final: Estabilizar la economía (min) | 64.9 | 60–75 | PASA |
| autoclicker | 1 | Máxima espera sin poder comprar ni reformar (s) | 2.8 (en el min 0.8) | <= 20 | PASA |
| autoclicker | 1 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 14.8 (en el min 16.3) | <= 20 | PASA |
| autoclicker | 1 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 24.0 | < 125 (1/2 de 250) | PASA |
| autoclicker | 1 | Credibilidad mínima en una reforma | 11.0 (vuelta 1) | >= 5 | PASA |
| autoclicker | 1 | Credibilidad de la primera reforma | 11.0 | 5–15 | PASA |
| autoclicker | 1 | Plata de clics en el primer minuto (%) | 67.2 | >= 50 | PASA |
| autoclicker | 1 | Primer renacimiento (min) | 4.2 | (informativo) | PASA |
| autoclicker | 1 | Final: Estabilizar la economía (min) | 55.1 | 50–70 | PASA |
| autoclicker | 2 | Máxima espera sin poder comprar ni reformar (s) | 2.8 (en el min 0.8) | <= 20 | PASA |
| autoclicker | 2 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 10.0 (en el min 58.5) | <= 20 | PASA |
| autoclicker | 2 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 72.8 | < 125 (1/2 de 250) | PASA |
| autoclicker | 2 | Credibilidad mínima en una reforma | 11.0 (vuelta 1) | >= 5 | PASA |
| autoclicker | 2 | Credibilidad de la primera reforma | 11.0 | 5–15 | PASA |
| autoclicker | 2 | Plata de clics en el primer minuto (%) | 67.2 | >= 50 | PASA |
| autoclicker | 2 | Primer renacimiento (min) | 4.2 | (informativo) | PASA |
| autoclicker | 2 | Final: Estabilizar la economía (min) | 54.7 | 50–70 | PASA |
| autoclicker | 3 | Máxima espera sin poder comprar ni reformar (s) | 2.8 (en el min 0.8) | <= 20 | PASA |
| autoclicker | 3 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 10.3 (en el min 57.7) | <= 20 | PASA |
| autoclicker | 3 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 24.5 | < 125 (1/2 de 250) | PASA |
| autoclicker | 3 | Credibilidad mínima en una reforma | 12.0 (vuelta 1) | >= 5 | PASA |
| autoclicker | 3 | Credibilidad de la primera reforma | 12.0 | 5–15 | PASA |
| autoclicker | 3 | Plata de clics en el primer minuto (%) | 67.2 | >= 50 | PASA |
| autoclicker | 3 | Primer renacimiento (min) | 4.2 | (informativo) | PASA |
| autoclicker | 3 | Final: Estabilizar la economía (min) | 50.8 | 50–70 | PASA |

## Activo (clickea mucho), semilla 1

| Vuelta | Minuto | Duración | Plata máxima ganada | +Credibilidad | Nodos comprados después | Llega a la plata de la vuelta 1 en |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 4.2 | 4:10 | $137,61 K | 9 | 4 | 250 s |
| 2 | 5.1 | 0:55 | $7,83 M | 28 | 6 | 24 s |
| 3 | 7.1 | 2:03 | $15,86 M | 37 | 5 | 21 s |
| 4 | 8.1 | 0:55 | $2,03 B | 74 | 9 | 17 s |
| 5 | 9.5 | 1:27 | $4,07 B | 82 | 3 | 17 s |
| 6 | 10.6 | 1:06 | $8,18 B | 88 | 4 | 7 s |
| 7 | 12.9 | 2:15 | $5,74 T | 200 | 5 | 7 s |
| 8 | 15.5 | 2:40 | $2,71 T | 189 | 3 | 7 s |
| 9 | 18.0 | 2:30 | $2,5 T | 188 | 3 | 3 s |
| 10 | 20.5 | 2:30 | $3,28 T | 192 | 4 | 3 s |
| 11 | 21.6 | 1:04 | $10,84 T | 320 | 2 | 2 s |
| 12 | 24.1 | 2:30 | $19,35 T | 343 | 3 | 2 s |
| 13 | 26.6 | 2:30 | $30,22 T | 355 | 3 | 2 s |
| 14 | 29.1 | 2:30 | $32,18 T | 356 | 3 | 1 s |
| 15 | 30.0 | 0:57 | $10,46 T | 395 | 3 | 1 s |
| 16 | 32.5 | 2:30 | $33,93 T | 363 | 0 | 1 s |
| 17 | 35.0 | 2:30 | $43,42 T | 369 | 0 | 1 s |
| 18 | 37.5 | 2:30 | $126,26 T | 399 | 0 | 1 s |
| 19 | 39.7 | 2:08 | $225,37 T | 419 | 0 | 1 s |
| 20 | 42.2 | 2:30 | $138,83 T | 401 | 0 | 1 s |
| 21 | 44.7 | 2:30 | $394,37 T | 431 | 0 | 1 s |
| 22 | 47.2 | 2:30 | $690,71 T | 447 | 0 | 1 s |
| 23 | 49.7 | 2:30 | $391,47 T | 431 | 0 | 1 s |
| 24 | 52.2 | 2:30 | $442,15 T | 434 | 0 | 1 s |
| 25 | 54.7 | 2:30 | $501,52 T | 438 | 0 | 1 s |
| … | | | | | | |
| 91 | 202.3 | 2:30 | $47,25 Sx | 6487 | 0 | 0 s |
| 92 | 204.8 | 2:30 | $36,31 Sx | 6416 | 1 | 0 s |
| 93 | 207.3 | 2:30 | $22,81 Sx | 6291 | 1 | 0 s |

- Final (Estabilizar la economía): minuto **57.2**
- 100 %: minuto **207.3**
- Al terminar la simulación (min 207): nodos 115/115, figuritas 60/60, logros 53/53, vueltas 94

## Pasivo (casi no clickea, compra lo más barato), semilla 1

| Vuelta | Minuto | Duración | Plata máxima ganada | +Credibilidad | Nodos comprados después | Llega a la plata de la vuelta 1 en |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 6.6 | 6:35 | $18,1 K | 5 | 2 | 395 s |
| 2 | 9.1 | 2:30 | $49,71 K | 7 | 4 | 107 s |
| 3 | 11.4 | 2:16 | $99,48 K | 10 | 1 | 29 s |
| 4 | 12.4 | 1:00 | $12,25 M | 30 | 5 | 23 s |
| 5 | 14.9 | 2:30 | $18,86 M | 39 | 6 | 16 s |
| 6 | 17.4 | 2:30 | $27,27 M | 41 | 6 | 15 s |
| 7 | 18.2 | 0:50 | $71,28 M | 49 | 1 | 9 s |
| 8 | 19.2 | 1:03 | $142,8 M | 54 | 3 | 4 s |
| 9 | 21.7 | 2:30 | $204,22 M | 71 | 2 | 5 s |
| 10 | 24.2 | 2:30 | $219,06 M | 71 | 3 | 5 s |
| 11 | 26.7 | 2:30 | $261,59 M | 80 | 3 | 5 s |
| 12 | 29.2 | 2:30 | $83,56 M | 69 | 0 | 5 s |
| 13 | 31.7 | 2:30 | $567,64 M | 89 | 1 | 3 s |
| 14 | 34.2 | 2:30 | $559,08 M | 89 | 1 | 3 s |
| 15 | 36.7 | 2:30 | $948,85 M | 94 | 2 | 2 s |
| 16 | 37.6 | 0:55 | $2,1 B | 104 | 3 | 2 s |
| 17 | 38.4 | 0:45 | $4,31 B | 113 | 1 | 1 s |
| 18 | 39.2 | 0:50 | $8,86 B | 158 | 2 | 1 s |
| 19 | 40.2 | 0:55 | $17,96 B | 170 | 2 | 1 s |
| 20 | 41.1 | 0:59 | $35,97 B | 199 | 2 | 1 s |
| 21 | 42.2 | 1:02 | $72,77 B | 213 | 1 | 1 s |
| 22 | 42.8 | 0:35 | $184,82 B | 232 | 2 | 1 s |
| 23 | 43.8 | 1:02 | $376,52 B | 248 | 2 | 1 s |
| 24 | 45.1 | 1:15 | $6,09 T | 313 | 2 | 1 s |
| 25 | 46.9 | 1:52 | $12,27 T | 336 | 3 | 1 s |
| … | | | | | | |
| 58 | 127.9 | 2:30 | $28,88 Qa | 732 | 1 | 0 s |
| 59 | 130.4 | 2:30 | $60,3 Qa | 765 | 1 | 0 s |
| 60 | 132.9 | 2:30 | $25,34 Qa | 1087 | 1 | 0 s |

- Final (Estabilizar la economía): minuto **73.7**
- Al terminar la simulación (min 134): nodos 88/115, figuritas 60/60, logros 45/53, vueltas 61

## Distraído (deja de jugar 2 min a mitad de la vuelta), semilla 1

| Vuelta | Minuto | Duración | Plata máxima ganada | +Credibilidad | Nodos comprados después | Llega a la plata de la vuelta 1 en |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 4.5 | 4:30 | $20,14 K | 5 | 2 | 270 s |
| 2 | 5.4 | 0:55 | $258,39 K | 11 | 4 | 22 s |
| 3 | 6.4 | 1:00 | $6,58 M | 27 | 5 | 22 s |
| 4 | 7.4 | 0:59 | $13,2 M | 36 | 5 | 13 s |
| 5 | 8.3 | 0:55 | $749,6 M | 65 | 8 | 13 s |
| 6 | 10.7 | 2:25 | $7,83 B | 88 | 4 | 8 s |
| 7 | 13.9 | 3:12 | $12,38 B | 115 | 4 | 3 s |
| 8 | 16.4 | 2:30 | $5,22 B | 105 | 3 | 2 s |
| 9 | 19.7 | 3:15 | $397,01 M | 77 | 1 | 2 s |
| 10 | 21.5 | 1:50 | $27,71 B | 125 | 1 | 2 s |
| 11 | 24.0 | 2:30 | $18,54 B | 131 | 3 | 2 s |
| 12 | 24.9 | 0:55 | $558,57 B | 182 | 3 | 2 s |
| 13 | 26.0 | 1:05 | $900,35 B | 203 | 3 | 1 s |
| 14 | 28.4 | 2:23 | $4,3 T | 280 | 3 | 1 s |
| 15 | 31.6 | 3:12 | $3,22 T | 298 | 2 | 1 s |
| 16 | 32.5 | 0:50 | $39,92 T | 362 | 3 | 1 s |
| 17 | 35.0 | 2:30 | $27,65 T | 352 | 3 | 1 s |
| 18 | 38.2 | 3:15 | $11,1 T | 334 | 2 | 1 s |
| 19 | 40.7 | 2:28 | $80,51 T | 386 | 1 | 1 s |
| 20 | 43.9 | 3:14 | $97,04 T | 391 | 0 | 1 s |
| 21 | 46.4 | 2:30 | $46,24 T | 371 | 0 | 1 s |
| 22 | 49.7 | 3:15 | $13,66 T | 342 | 0 | 1 s |
| 23 | 52.2 | 2:30 | $76,69 T | 385 | 0 | 1 s |
| 24 | 55.4 | 3:15 | $33,69 T | 362 | 0 | 1 s |
| 25 | 57.9 | 2:30 | $178,57 T | 408 | 0 | 1 s |
| … | | | | | | |
| 49 | 119.9 | 2:30 | $106,88 Qa | 790 | 1 | 0 s |
| 50 | 123.2 | 3:15 | $12,19 Qa | 695 | 0 | 0 s |
| 51 | 125.7 | 2:30 | $94,85 Qa | 784 | 1 | 0 s |

- Final (Estabilizar la economía): minuto **67.3**
- Al terminar la simulación (min 127): nodos 86/115, figuritas 60/60, logros 45/53, vueltas 52

## autoclicker, semilla 1

| Vuelta | Minuto | Duración | Plata máxima ganada | +Credibilidad | Nodos comprados después | Llega a la plata de la vuelta 1 en |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 4.2 | 4:10 | $294,66 K | 11 | 5 | 250 s |
| 2 | 5.1 | 0:55 | $19,37 M | 32 | 6 | 24 s |
| 3 | 7.5 | 2:22 | $38,82 M | 43 | 6 | 26 s |
| 4 | 8.4 | 0:55 | $84,92 M | 49 | 7 | 18 s |
| 5 | 9.3 | 0:55 | $1,81 B | 75 | 3 | 16 s |
| 6 | 10.7 | 1:25 | $3,63 B | 81 | 3 | 9 s |
| 7 | 13.4 | 2:40 | $931,51 B | 173 | 6 | 8 s |
| 8 | 16.3 | 2:55 | $38,15 T | 232 | 2 | 7 s |
| 9 | 19.2 | 2:55 | $777,76 T | 286 | 5 | 4 s |
| 10 | 21.7 | 2:30 | $89,08 T | 247 | 4 | 2 s |
| 11 | 24.2 | 2:30 | $50,58 T | 368 | 3 | 2 s |
| 12 | 26.7 | 2:30 | $45,77 T | 366 | 3 | 2 s |
| 13 | 29.2 | 2:30 | $159,8 T | 400 | 3 | 2 s |
| 14 | 31.7 | 2:30 | $281,19 T | 421 | 3 | 2 s |
| 15 | 34.2 | 2:30 | $280,18 T | 421 | 1 | 1 s |
| 16 | 36.7 | 2:30 | $266,13 T | 420 | 0 | 1 s |
| 17 | 39.2 | 2:30 | $479,55 T | 437 | 0 | 1 s |
| 18 | 41.7 | 2:30 | $179,94 T | 408 | 0 | 1 s |
| 19 | 44.2 | 2:30 | $160,15 T | 405 | 0 | 1 s |
| 20 | 46.7 | 2:30 | $848,49 T | 453 | 0 | 1 s |
| 21 | 47.6 | 0:54 | $289,79 T | 482 | 0 | 1 s |
| 22 | 50.1 | 2:30 | $239,07 T | 416 | 0 | 1 s |
| 23 | 52.6 | 2:30 | $292,36 T | 422 | 0 | 1 s |
| 24 | 55.1 | 2:30 | $629,75 T | 445 | 1 | 1 s |
| 25 | 57.6 | 2:30 | $970,9 T | 457 | 2 | 1 s |
| … | | | | | | |
| 49 | 109.5 | 1:02 | $1,04 Qi | 1343 | 1 | 0 s |
| 50 | 111.6 | 2:04 | $2,16 Qi | 1395 | 1 | 0 s |
| 51 | 114.1 | 2:30 | $1,77 Qi | 1379 | 1 | 0 s |

- Final (Estabilizar la economía): minuto **55.1**
- Al terminar la simulación (min 115): nodos 92/115, figuritas 60/60, logros 46/53, vueltas 52
