# Balance v2 (simulador)

Generado por `godot --headless --script tools/simulate.gd`. Los jugadores de prueba están descriptos en `scripts/core/bot_policy.gd`; los objetivos, en [DISENO_V2.md](DISENO_V2.md).

## Chequeos

| Jugador | Semilla | Chequeo | Valor | Objetivo | Resultado |
| --- | --- | --- | --- | --- | --- |
| activo | 1 | Máxima espera sin poder comprar ni reformar (s) | 4.0 (en el min 1.7) | <= 20 | PASA |
| activo | 1 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 9.3 (en el min 2.4) | <= 20 | PASA |
| activo | 1 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 22.8 | < 125 (1/2 de 250) | PASA |
| activo | 1 | Credibilidad mínima en una reforma | 10.0 (vuelta 1) | >= 5 | PASA |
| activo | 1 | Credibilidad de la primera reforma | 10.0 | 5–10 | PASA |
| activo | 1 | Plata de clics en el primer minuto (%) | 65.7 | >= 50 | PASA |
| activo | 1 | Nodos comprados por reforma (mediana) | 2.0 (mín 1, máx 6) | >= 2 | PASA |
| activo | 1 | Reformas que no compran ningún nodo | 0.0 | 0 | PASA |
| activo | 1 | Duración de las vueltas, mediana (min) | 4.0 | 2–4 | PASA |
| activo | 1 | Primer renacimiento (min) | 4.2 | 4–6 | PASA |
| activo | 1 | Vuelta 10 llega a la plata de la vuelta 1 (s) | 1.0 | <= 50 (1/5 de 250) | PASA |
| activo | 1 | 100 %: árbol + álbum + logros (min) | 150.1 | 150–210 | PASA |
| activo | 1 | Final: Estabilizar la economía (min) | 56.8 | 50–70 | PASA |
| activo | 1 | Reformas hasta el final | 17.0 | 15–20 | PASA |
| activo | 2 | Máxima espera sin poder comprar ni reformar (s) | 2.8 (en el min 105.0) | <= 20 | PASA |
| activo | 2 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 9.3 (en el min 3.2) | <= 20 | PASA |
| activo | 2 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 28.5 | < 125 (1/2 de 250) | PASA |
| activo | 2 | Credibilidad mínima en una reforma | 10.0 (vuelta 1) | >= 5 | PASA |
| activo | 2 | Credibilidad de la primera reforma | 10.0 | 5–10 | PASA |
| activo | 2 | Plata de clics en el primer minuto (%) | 65.7 | >= 50 | PASA |
| activo | 2 | Nodos comprados por reforma (mediana) | 2.0 (mín 1, máx 6) | >= 2 | PASA |
| activo | 2 | Reformas que no compran ningún nodo | 0.0 | 0 | PASA |
| activo | 2 | Duración de las vueltas, mediana (min) | 4.0 | 2–4 | PASA |
| activo | 2 | Primer renacimiento (min) | 4.2 | 4–6 | PASA |
| activo | 2 | Vuelta 10 llega a la plata de la vuelta 1 (s) | 1.3 | <= 50 (1/5 de 250) | PASA |
| activo | 2 | 100 %: árbol + álbum + logros (min) | 153.1 | 150–210 | PASA |
| activo | 2 | Final: Estabilizar la economía (min) | 54.6 | 50–70 | PASA |
| activo | 2 | Reformas hasta el final | 16.0 | 15–20 | PASA |
| activo | 3 | Máxima espera sin poder comprar ni reformar (s) | 2.3 (en el min 0.6) | <= 20 | PASA |
| activo | 3 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 12.8 (en el min 19.3) | <= 20 | PASA |
| activo | 3 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 23.0 | < 125 (1/2 de 250) | PASA |
| activo | 3 | Credibilidad mínima en una reforma | 10.0 (vuelta 1) | >= 5 | PASA |
| activo | 3 | Credibilidad de la primera reforma | 10.0 | 5–10 | PASA |
| activo | 3 | Plata de clics en el primer minuto (%) | 65.7 | >= 50 | PASA |
| activo | 3 | Nodos comprados por reforma (mediana) | 3.0 (mín 1, máx 7) | >= 2 | PASA |
| activo | 3 | Reformas que no compran ningún nodo | 0.0 | 0 | PASA |
| activo | 3 | Duración de las vueltas, mediana (min) | 4.0 | 2–4 | PASA |
| activo | 3 | Primer renacimiento (min) | 4.2 | 4–6 | PASA |
| activo | 3 | Vuelta 10 llega a la plata de la vuelta 1 (s) | 1.0 | <= 50 (1/5 de 250) | PASA |
| activo | 3 | 100 %: árbol + álbum + logros (min) | 152.3 | 150–210 | PASA |
| activo | 3 | Final: Estabilizar la economía (min) | 58.5 | 50–70 | PASA |
| activo | 3 | Reformas hasta el final | 16.0 | 15–20 | PASA |
| pasivo | 1 | Máxima espera sin poder comprar ni reformar (s) | 11.3 (en el min 1.5) | <= 20 | PASA |
| pasivo | 1 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 12.0 (en el min 0.2) | <= 20 | PASA |
| pasivo | 1 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 70.3 | < 185 (1/2 de 369) | PASA |
| pasivo | 1 | Credibilidad mínima en una reforma | 5.0 (vuelta 1) | >= 5 | PASA |
| pasivo | 1 | Credibilidad de la primera reforma | 5.0 | 5–10 | PASA |
| pasivo | 1 | Nodos comprados por reforma (mediana) | 3.0 (mín 1, máx 6) | >= 2 | PASA |
| pasivo | 1 | Reformas que no compran ningún nodo | 0.0 | 0 | PASA |
| pasivo | 1 | Duración de las vueltas, mediana (min) | 3.8 | 2–4 | PASA |
| pasivo | 1 | Primer renacimiento (min) | 6.2 | (informativo) | PASA |
| pasivo | 1 | Final: Estabilizar la economía (min) | 63.8 | <= 80 | PASA |
| pasivo | 1 | Reformas hasta el final | 18.0 | (informativo) | PASA |
| pasivo | 2 | Máxima espera sin poder comprar ni reformar (s) | 10.5 (en el min 5.3) | <= 20 | PASA |
| pasivo | 2 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 12.0 (en el min 0.2) | <= 20 | PASA |
| pasivo | 2 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 80.0 | < 164 (1/2 de 329) | PASA |
| pasivo | 2 | Credibilidad mínima en una reforma | 5.0 (vuelta 1) | >= 5 | PASA |
| pasivo | 2 | Credibilidad de la primera reforma | 5.0 | 5–10 | PASA |
| pasivo | 2 | Nodos comprados por reforma (mediana) | 3.0 (mín 1, máx 6) | >= 2 | PASA |
| pasivo | 2 | Reformas que no compran ningún nodo | 0.0 | 0 | PASA |
| pasivo | 2 | Duración de las vueltas, mediana (min) | 3.8 | 2–4 | PASA |
| pasivo | 2 | Primer renacimiento (min) | 5.5 | (informativo) | PASA |
| pasivo | 2 | Final: Estabilizar la economía (min) | 64.0 | <= 80 | PASA |
| pasivo | 2 | Reformas hasta el final | 18.0 | (informativo) | PASA |
| pasivo | 3 | Máxima espera sin poder comprar ni reformar (s) | 11.3 (en el min 5.0) | <= 20 | PASA |
| pasivo | 3 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 12.0 (en el min 0.2) | <= 20 | PASA |
| pasivo | 3 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 81.8 | < 152 (1/2 de 304) | PASA |
| pasivo | 3 | Credibilidad mínima en una reforma | 5.0 (vuelta 1) | >= 5 | PASA |
| pasivo | 3 | Credibilidad de la primera reforma | 5.0 | 5–10 | PASA |
| pasivo | 3 | Nodos comprados por reforma (mediana) | 3.0 (mín 1, máx 6) | >= 2 | PASA |
| pasivo | 3 | Reformas que no compran ningún nodo | 0.0 | 0 | PASA |
| pasivo | 3 | Duración de las vueltas, mediana (min) | 3.8 | 2–4 | PASA |
| pasivo | 3 | Primer renacimiento (min) | 5.1 | (informativo) | PASA |
| pasivo | 3 | Final: Estabilizar la economía (min) | 65.3 | <= 80 | PASA |
| pasivo | 3 | Reformas hasta el final | 19.0 | (informativo) | PASA |
| distraido | 1 | Máxima espera sin poder comprar ni reformar (s) | 4.8 (en el min 2.6) | <= 20 | PASA |
| distraido | 1 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 12.8 (en el min 23.9) | <= 20 | PASA |
| distraido | 1 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 22.0 | < 135 (1/2 de 270) | PASA |
| distraido | 1 | Credibilidad mínima en una reforma | 5.0 (vuelta 1) | >= 5 | PASA |
| distraido | 1 | Credibilidad de la primera reforma | 5.0 | 5–10 | PASA |
| distraido | 1 | Plata de clics en el primer minuto (%) | 66.4 | >= 50 | PASA |
| distraido | 1 | Nodos comprados por reforma (mediana) | 3.0 (mín 1, máx 7) | >= 2 | PASA |
| distraido | 1 | Reformas que no compran ningún nodo | 0.0 | 0 | PASA |
| distraido | 1 | Duración de las vueltas, mediana (min) | 4.0 | 2–4 | PASA |
| distraido | 1 | Primer renacimiento (min) | 4.5 | (informativo) | PASA |
| distraido | 1 | Final: Estabilizar la economía (min) | 64.5 | <= 80 | PASA |
| distraido | 1 | Reformas hasta el final | 17.0 | (informativo) | PASA |
| distraido | 2 | Máxima espera sin poder comprar ni reformar (s) | 3.8 (en el min 1.6) | <= 20 | PASA |
| distraido | 2 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 9.8 (en el min 9.3) | <= 20 | PASA |
| distraido | 2 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 22.0 | < 135 (1/2 de 270) | PASA |
| distraido | 2 | Credibilidad mínima en una reforma | 6.0 (vuelta 1) | >= 5 | PASA |
| distraido | 2 | Credibilidad de la primera reforma | 6.0 | 5–10 | PASA |
| distraido | 2 | Plata de clics en el primer minuto (%) | 66.4 | >= 50 | PASA |
| distraido | 2 | Nodos comprados por reforma (mediana) | 3.0 (mín 1, máx 7) | >= 2 | PASA |
| distraido | 2 | Reformas que no compran ningún nodo | 0.0 | 0 | PASA |
| distraido | 2 | Duración de las vueltas, mediana (min) | 3.8 | 2–4 | PASA |
| distraido | 2 | Primer renacimiento (min) | 4.5 | (informativo) | PASA |
| distraido | 2 | Final: Estabilizar la economía (min) | 66.7 | <= 80 | PASA |
| distraido | 2 | Reformas hasta el final | 18.0 | (informativo) | PASA |
| distraido | 3 | Máxima espera sin poder comprar ni reformar (s) | 3.8 (en el min 1.6) | <= 20 | PASA |
| distraido | 3 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 9.8 (en el min 9.8) | <= 20 | PASA |
| distraido | 3 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 22.0 | < 135 (1/2 de 270) | PASA |
| distraido | 3 | Credibilidad mínima en una reforma | 8.0 (vuelta 1) | >= 5 | PASA |
| distraido | 3 | Credibilidad de la primera reforma | 8.0 | 5–10 | PASA |
| distraido | 3 | Plata de clics en el primer minuto (%) | 66.4 | >= 50 | PASA |
| distraido | 3 | Nodos comprados por reforma (mediana) | 3.0 (mín 1, máx 7) | >= 2 | PASA |
| distraido | 3 | Reformas que no compran ningún nodo | 0.0 | 0 | PASA |
| distraido | 3 | Duración de las vueltas, mediana (min) | 4.0 | 2–4 | PASA |
| distraido | 3 | Primer renacimiento (min) | 4.5 | (informativo) | PASA |
| distraido | 3 | Final: Estabilizar la economía (min) | 63.3 | <= 80 | PASA |
| distraido | 3 | Reformas hasta el final | 17.0 | (informativo) | PASA |
| autoclicker | 1 | Máxima espera sin poder comprar ni reformar (s) | 3.3 (en el min 1.4) | <= 20 | PASA |
| autoclicker | 1 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 9.3 (en el min 3.4) | <= 20 | PASA |
| autoclicker | 1 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 22.3 | < 125 (1/2 de 250) | PASA |
| autoclicker | 1 | Credibilidad mínima en una reforma | 10.0 (vuelta 1) | >= 5 | PASA |
| autoclicker | 1 | Credibilidad de la primera reforma | 10.0 | 5–15 | PASA |
| autoclicker | 1 | Plata de clics en el primer minuto (%) | 66.8 | >= 50 | PASA |
| autoclicker | 1 | Nodos comprados por reforma (mediana) | 3.0 (mín 2, máx 6) | >= 2 | PASA |
| autoclicker | 1 | Reformas que no compran ningún nodo | 0.0 | 0 | PASA |
| autoclicker | 1 | Duración de las vueltas, mediana (min) | 3.7 | 2–4 | PASA |
| autoclicker | 1 | Primer renacimiento (min) | 4.2 | (informativo) | PASA |
| autoclicker | 1 | Final: Estabilizar la economía (min) | 55.4 | 50–70 | PASA |
| autoclicker | 1 | Reformas hasta el final | 16.0 | 15–20 | PASA |
| autoclicker | 2 | Máxima espera sin poder comprar ni reformar (s) | 3.0 (en el min 1.0) | <= 20 | PASA |
| autoclicker | 2 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 13.8 (en el min 19.3) | <= 20 | PASA |
| autoclicker | 2 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 22.0 | < 125 (1/2 de 250) | PASA |
| autoclicker | 2 | Credibilidad mínima en una reforma | 9.0 (vuelta 1) | >= 5 | PASA |
| autoclicker | 2 | Credibilidad de la primera reforma | 9.0 | 5–15 | PASA |
| autoclicker | 2 | Plata de clics en el primer minuto (%) | 66.8 | >= 50 | PASA |
| autoclicker | 2 | Nodos comprados por reforma (mediana) | 3.0 (mín 1, máx 7) | >= 2 | PASA |
| autoclicker | 2 | Reformas que no compran ningún nodo | 0.0 | 0 | PASA |
| autoclicker | 2 | Duración de las vueltas, mediana (min) | 3.7 | 2–4 | PASA |
| autoclicker | 2 | Primer renacimiento (min) | 4.2 | (informativo) | PASA |
| autoclicker | 2 | Final: Estabilizar la economía (min) | 57.1 | 50–70 | PASA |
| autoclicker | 2 | Reformas hasta el final | 16.0 | 15–20 | PASA |
| autoclicker | 3 | Máxima espera sin poder comprar ni reformar (s) | 3.0 (en el min 1.0) | <= 20 | PASA |
| autoclicker | 3 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 11.5 (en el min 19.7) | <= 20 | PASA |
| autoclicker | 3 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 21.0 | < 125 (1/2 de 250) | PASA |
| autoclicker | 3 | Credibilidad mínima en una reforma | 9.0 (vuelta 1) | >= 5 | PASA |
| autoclicker | 3 | Credibilidad de la primera reforma | 9.0 | 5–15 | PASA |
| autoclicker | 3 | Plata de clics en el primer minuto (%) | 66.8 | >= 50 | PASA |
| autoclicker | 3 | Nodos comprados por reforma (mediana) | 3.0 (mín 1, máx 6) | >= 2 | PASA |
| autoclicker | 3 | Reformas que no compran ningún nodo | 0.0 | 0 | PASA |
| autoclicker | 3 | Duración de las vueltas, mediana (min) | 3.7 | 2–4 | PASA |
| autoclicker | 3 | Primer renacimiento (min) | 4.2 | (informativo) | PASA |
| autoclicker | 3 | Final: Estabilizar la economía (min) | 59.4 | 50–70 | PASA |
| autoclicker | 3 | Reformas hasta el final | 17.0 | 15–20 | PASA |
| gastador | 1 | Máxima espera sin poder comprar ni reformar (s) | 3.5 (en el min 1.4) | <= 20 | PASA |
| gastador | 1 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 12.0 (en el min 22.2) | <= 20 | PASA |
| gastador | 1 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 25.5 | < 125 (1/2 de 250) | PASA |
| gastador | 1 | Credibilidad mínima en una reforma | 10.0 (vuelta 1) | >= 5 | PASA |
| gastador | 1 | Credibilidad de la primera reforma | 10.0 | 5–15 | PASA |
| gastador | 1 | Plata de clics en el primer minuto (%) | 67.3 | >= 50 | PASA |
| gastador | 1 | Nodos comprados por reforma (mediana) | 3.0 (mín 2, máx 7) | >= 2 | PASA |
| gastador | 1 | Reformas que no compran ningún nodo | 0.0 | 0 | PASA |
| gastador | 1 | Duración de las vueltas, mediana (min) | 3.8 | 2–4 | PASA |
| gastador | 1 | Primer renacimiento (min) | 4.2 | (informativo) | PASA |
| gastador | 1 | Final: Estabilizar la economía (min) | 63.3 | 50–70 | PASA |
| gastador | 1 | Reformas hasta el final | 18.0 | 15–20 | PASA |
| gastador | 2 | Máxima espera sin poder comprar ni reformar (s) | 3.0 (en el min 0.9) | <= 20 | PASA |
| gastador | 2 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 13.3 (en el min 46.4) | <= 20 | PASA |
| gastador | 2 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 21.5 | < 125 (1/2 de 250) | PASA |
| gastador | 2 | Credibilidad mínima en una reforma | 9.0 (vuelta 1) | >= 5 | PASA |
| gastador | 2 | Credibilidad de la primera reforma | 9.0 | 5–15 | PASA |
| gastador | 2 | Plata de clics en el primer minuto (%) | 67.3 | >= 50 | PASA |
| gastador | 2 | Nodos comprados por reforma (mediana) | 3.0 (mín 2, máx 7) | >= 2 | PASA |
| gastador | 2 | Reformas que no compran ningún nodo | 0.0 | 0 | PASA |
| gastador | 2 | Duración de las vueltas, mediana (min) | 4.0 | 2–4 | PASA |
| gastador | 2 | Primer renacimiento (min) | 4.2 | (informativo) | PASA |
| gastador | 2 | Final: Estabilizar la economía (min) | 62.0 | 50–70 | PASA |
| gastador | 2 | Reformas hasta el final | 17.0 | 15–20 | PASA |
| gastador | 3 | Máxima espera sin poder comprar ni reformar (s) | 3.0 (en el min 0.9) | <= 20 | PASA |
| gastador | 3 | Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s) | 10.5 (en el min 22.3) | <= 20 | PASA |
| gastador | 3 | Vuelta 2 llega a la plata de la vuelta 1 (s) | 25.5 | < 125 (1/2 de 250) | PASA |
| gastador | 3 | Credibilidad mínima en una reforma | 9.0 (vuelta 1) | >= 5 | PASA |
| gastador | 3 | Credibilidad de la primera reforma | 9.0 | 5–15 | PASA |
| gastador | 3 | Plata de clics en el primer minuto (%) | 67.3 | >= 50 | PASA |
| gastador | 3 | Nodos comprados por reforma (mediana) | 3.0 (mín 2, máx 7) | >= 2 | PASA |
| gastador | 3 | Reformas que no compran ningún nodo | 0.0 | 0 | PASA |
| gastador | 3 | Duración de las vueltas, mediana (min) | 3.7 | 2–4 | PASA |
| gastador | 3 | Primer renacimiento (min) | 4.2 | (informativo) | PASA |
| gastador | 3 | Final: Estabilizar la economía (min) | 63.0 | 50–70 | PASA |
| gastador | 3 | Reformas hasta el final | 18.0 | 15–20 | PASA |

## Activo (clickea mucho), semilla 1

| Reforma | Minuto | Duración de la vuelta | Plata ganada | +Credibilidad | Nodos comprados con ella | Nodos en total |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 4.2 | 4:10 | $214,57 K | 10 | 5 | 5 |
| 2 | 7.2 | 3:00 | $534,97 M | 35 | 4 | 9 |
| 3 | 10.2 | 3:00 | $4,58 B | 43 | 4 | 13 |
| 4 | 13.2 | 3:00 | $1,18 T | 77 | 6 | 19 |
| 5 | 16.2 | 3:00 | $9,44 T | 88 | 6 | 25 |
| 6 | 19.8 | 3:35 | $18,96 T | 94 | 2 | 27 |
| 7 | 22.8 | 3:00 | $178,51 T | 106 | 2 | 29 |
| 8 | 25.8 | 3:01 | $358,81 T | 137 | 2 | 31 |
| 9 | 28.8 | 3:02 | $716,83 T | 142 | 2 | 33 |
| 10 | 31.9 | 3:07 | $1,49 Qa | 147 | 2 | 35 |
| 11 | 34.9 | 3:00 | $3 Qa | 236 | 4 | 39 |
| 12 | 38.1 | 3:08 | $6,2 Qa | 244 | 6 | 45 |
| 13 | 41.2 | 3:07 | $12,98 Qa | 253 | 4 | 49 |
| 14 | 44.2 | 3:00 | $48,07 Qa | 268 | 3 | 52 |
| 15 | 47.4 | 3:08 | $98,06 Qa | 276 | 2 | 54 |
| 16 | 50.4 | 3:00 | $206,97 Qa | 285 | 3 | 57 |
| 17 | 53.8 | 3:24 | $409,61 Qa | 298 | 3 | 60 |
| 18 | 56.8 | 3:00 | $1,38 Qi | 313 | 2 | 62 |
| 19 | 60.8 | 4:00 | $48,91 Qi | 358 | 2 | 64 |
| 20 | 64.8 | 4:00 | $859,44 Qi | 395 | 2 | 66 |
| 21 | 68.8 | 4:00 | $2,82 Sx | 411 | 2 | 68 |
| 22 | 72.8 | 4:00 | $23,05 Sx | 440 | 3 | 71 |
| 23 | 76.8 | 4:00 | $84,52 Sx | 594 | 3 | 74 |
| 24 | 80.8 | 4:00 | $870,26 Sx | 636 | 3 | 77 |
| 25 | 84.8 | 4:00 | $6,1 Sp | 673 | 3 | 80 |
| 26 | 88.8 | 4:00 | $261,96 Sp | 745 | 3 | 83 |
| 27 | 92.8 | 4:00 | $2,85 Oc | 792 | 2 | 85 |
| 28 | 96.8 | 4:00 | $7,96 Oc | 1055 | 2 | 87 |
| 29 | 100.8 | 4:00 | $604,06 Oc | 1171 | 2 | 89 |
| 30 | 104.8 | 4:00 | $9,83 No | 1248 | 2 | 91 |
| 31 | 108.8 | 4:00 | $30,41 No | 1280 | 2 | 93 |
| 32 | 112.8 | 4:00 | $2,4 Dc | 2103 | 3 | 96 |
| 33 | 116.8 | 4:00 | $118,13 Dc | 2273 | 4 | 100 |
| 34 | 120.8 | 4:00 | $1,61e37 | 2495 | 3 | 103 |
| 35 | 124.8 | 4:00 | $5,19e39 | 2766 | 2 | 105 |
| 36 | 128.8 | 4:00 | $2,1e41 | 2943 | 2 | 107 |
| 37 | 132.8 | 4:00 | $4,85e42 | 4642 | 2 | 109 |
| 38 | 136.8 | 4:00 | $2,46e45 | 5111 | 1 | 110 |
| 39 | 140.8 | 4:00 | $1,85e46 | 5266 | 2 | 112 |
| 40 | 144.8 | 4:00 | $1,26e48 | 5595 | 1 | 113 |
| 41 | 148.8 | 4:00 | $3,78e49 | 8794 | 2 | 115 |
| 42+ | 150.0 | | | | (árbol completo) | 115 |

- Final (Estabilizar la economía): minuto **56.8**
- 100 %: minuto **150.1**
- Al terminar la simulación (min 150): nodos 115/115, figuritas 60/60, logros 53/53, vueltas 43

## Pasivo (casi no clickea, compra lo más barato), semilla 1

| Reforma | Minuto | Duración de la vuelta | Plata ganada | +Credibilidad | Nodos comprados con ella | Nodos en total |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 6.2 | 6:09 | $10,91 K | 5 | 2 | 2 |
| 2 | 9.2 | 3:00 | $126,61 K | 9 | 4 | 6 |
| 3 | 12.2 | 3:00 | $10,05 M | 23 | 2 | 8 |
| 4 | 15.2 | 3:00 | $5,68 B | 44 | 4 | 12 |
| 5 | 18.2 | 3:00 | $87,78 B | 65 | 6 | 18 |
| 6 | 21.2 | 3:00 | $373,37 B | 72 | 6 | 24 |
| 7 | 24.2 | 3:00 | $856,1 B | 78 | 2 | 26 |
| 8 | 27.2 | 3:00 | $139,96 T | 104 | 2 | 28 |
| 9 | 31.0 | 3:50 | $84,68 T | 127 | 1 | 29 |
| 10 | 34.8 | 3:50 | $133,83 T | 130 | 2 | 31 |
| 11 | 37.8 | 3:00 | $998,79 T | 158 | 3 | 34 |
| 12 | 41.7 | 3:50 | $1,19 Qa | 207 | 4 | 38 |
| 13 | 45.3 | 3:39 | $2,39 Qa | 233 | 5 | 43 |
| 14 | 48.3 | 3:00 | $12,11 Qa | 251 | 5 | 48 |
| 15 | 51.3 | 3:00 | $65,5 Qa | 271 | 3 | 51 |
| 16 | 54.3 | 3:00 | $134,33 Qa | 280 | 2 | 53 |
| 17 | 57.4 | 3:03 | $269,03 Qa | 288 | 3 | 56 |
| 18 | 60.8 | 3:23 | $539,97 Qa | 301 | 3 | 59 |
| 19 | 63.8 | 3:00 | $1,44 Qi | 313 | 3 | 62 |
| 20 | 67.8 | 4:00 | $31,76 Qi | 352 | 2 | 64 |
| 21 | 71.8 | 4:00 | $400,37 Qi | 385 | 2 | 66 |
| 22 | 75.8 | 4:00 | $4,45 Sx | 417 | 2 | 68 |
| 23 | 79.8 | 4:00 | $16,07 Sx | 435 | 2 | 70 |
| 24 | 83.9 | 4:09 | $32,41 Sx | 576 | 3 | 73 |
| 25 | 87.9 | 4:00 | $282,87 Sx | 615 | 4 | 77 |
| 26 | 91.9 | 4:00 | $10,73 Sp | 683 | 3 | 80 |
| 27 | 95.9 | 4:00 | $105,23 Sp | 727 | 2 | 82 |
| 28 | 99.9 | 4:00 | $2,89 Oc | 793 | 3 | 85 |
| 29 | 103.9 | 4:00 | $13,92 Oc | 1070 | 2 | 87 |
| 30 | 107.9 | 4:00 | $653,69 Oc | 1173 | 2 | 89 |
| 31 | 111.9 | 4:00 | $10,55 No | 1250 | 2 | 91 |
| 32 | 115.9 | 4:00 | $199,39 No | 1332 | 2 | 93 |
| 33 | 119.9 | 4:00 | $6,26 Dc | 2144 | 3 | 96 |

- Final (Estabilizar la economía): minuto **63.8**
- Al terminar la simulación (min 124): nodos 96/115, figuritas 60/60, logros 45/53, vueltas 34

## Distraído (deja de jugar 2 min a mitad de la vuelta), semilla 1

| Reforma | Minuto | Duración de la vuelta | Plata ganada | +Credibilidad | Nodos comprados con ella | Nodos en total |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 4.5 | 4:30 | $20,56 K | 5 | 2 | 2 |
| 2 | 7.8 | 3:15 | $1,13 M | 13 | 4 | 6 |
| 3 | 10.8 | 3:00 | $187,86 M | 32 | 3 | 9 |
| 4 | 14.3 | 3:30 | $48,86 B | 52 | 5 | 14 |
| 5 | 17.3 | 3:00 | $1,8 T | 79 | 7 | 21 |
| 6 | 21.1 | 3:50 | $447,28 B | 75 | 4 | 25 |
| 7 | 24.1 | 3:00 | $10,16 T | 90 | 2 | 27 |
| 8 | 27.8 | 3:41 | $20,65 T | 94 | 1 | 28 |
| 9 | 30.8 | 3:00 | $573,59 T | 140 | 3 | 31 |
| 10 | 35.0 | 4:15 | $3,73 Qa | 153 | 2 | 33 |
| 11 | 38.9 | 3:50 | $1,3 Qa | 160 | 2 | 35 |
| 12 | 42.3 | 3:29 | $5,72 Qa | 247 | 5 | 40 |
| 13 | 46.2 | 3:50 | $710,95 T | 220 | 5 | 45 |
| 14 | 49.7 | 3:30 | $16,25 Qa | 255 | 4 | 49 |
| 15 | 53.5 | 3:50 | $4,22 Qa | 240 | 2 | 51 |
| 16 | 56.5 | 3:00 | $226,53 Qa | 286 | 3 | 54 |
| 17 | 60.7 | 4:10 | $1,42 Qi | 308 | 3 | 57 |
| 18 | 64.5 | 3:50 | $2,1 Qi | 318 | 4 | 61 |
| 19 | 68.5 | 4:00 | $18,58 Qi | 346 | 2 | 63 |
| 20 | 72.7 | 4:10 | $18,89 Qi | 346 | 1 | 64 |
| 21 | 76.7 | 4:00 | $268,52 Qi | 380 | 2 | 66 |
| 22 | 80.7 | 4:00 | $5,07 Sx | 419 | 3 | 69 |
| 23 | 84.7 | 4:00 | $27 Sx | 573 | 3 | 72 |
| 24 | 88.7 | 4:00 | $3,53 Sp | 662 | 3 | 75 |
| 25 | 92.7 | 4:02 | $6,58 Sp | 689 | 4 | 79 |
| 26 | 96.7 | 4:00 | $252,81 Sp | 744 | 2 | 81 |
| 27 | 100.7 | 4:00 | $1,19 Oc | 775 | 3 | 84 |
| 28 | 104.7 | 4:00 | $27,84 Oc | 1088 | 2 | 86 |
| 29 | 108.7 | 4:00 | $229,94 Oc | 1145 | 2 | 88 |
| 30 | 112.7 | 4:00 | $43,03 No | 1289 | 2 | 90 |
| 31 | 116.9 | 4:10 | $69,29 No | 1303 | 2 | 92 |
| 32 | 120.9 | 4:00 | $1,81 Dc | 1395 | 3 | 95 |

- Final (Estabilizar la economía): minuto **64.5**
- Al terminar la simulación (min 125): nodos 95/115, figuritas 60/60, logros 45/53, vueltas 33

## Autoclicker (17 clics/s, compra lo más rentable), semilla 1

| Reforma | Minuto | Duración de la vuelta | Plata ganada | +Credibilidad | Nodos comprados con ella | Nodos en total |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 4.2 | 4:10 | $276,21 K | 10 | 5 | 5 |
| 2 | 7.2 | 3:00 | $778,31 M | 36 | 4 | 9 |
| 3 | 10.2 | 3:00 | $4,79 B | 43 | 4 | 13 |
| 4 | 13.2 | 3:00 | $1,38 T | 78 | 6 | 19 |
| 5 | 16.2 | 3:00 | $14,19 T | 90 | 6 | 25 |
| 6 | 19.4 | 3:16 | $28,8 T | 96 | 2 | 27 |
| 7 | 22.4 | 3:00 | $267,18 T | 108 | 2 | 29 |
| 8 | 25.8 | 3:20 | $534,12 T | 139 | 2 | 31 |
| 9 | 29.0 | 3:11 | $1,08 Qa | 144 | 2 | 33 |
| 10 | 32.4 | 3:23 | $2,18 Qa | 149 | 2 | 35 |
| 11 | 35.6 | 3:16 | $4,41 Qa | 240 | 5 | 40 |
| 12 | 38.8 | 3:13 | $8,98 Qa | 248 | 6 | 46 |
| 13 | 42.0 | 3:07 | $18,14 Qa | 256 | 3 | 49 |
| 14 | 45.3 | 3:19 | $35,17 Qa | 264 | 3 | 52 |
| 15 | 48.3 | 3:00 | $359,29 Qa | 291 | 3 | 55 |
| 16 | 51.9 | 3:39 | $712,05 Qa | 300 | 3 | 58 |
| 17 | 55.4 | 3:28 | $1,17 Qi | 339 | 3 | 61 |
| 18 | 59.6 | 4:10 | $12,78 Qi | 341 | 2 | 63 |
| 19 | 63.6 | 4:00 | $411,72 Qi | 385 | 2 | 65 |
| 20 | 67.6 | 4:00 | $1,47 Sx | 402 | 2 | 67 |
| 21 | 71.6 | 4:00 | $10,82 Sx | 429 | 2 | 69 |
| 22 | 75.6 | 4:00 | $47,82 Sx | 583 | 3 | 72 |
| 23 | 79.6 | 4:00 | $103,66 Sx | 597 | 4 | 76 |
| 24 | 83.6 | 4:00 | $5,73 Sp | 672 | 3 | 79 |
| 25 | 87.6 | 4:00 | $76 Sp | 721 | 2 | 81 |
| 26 | 91.6 | 4:00 | $262,97 Sp | 745 | 3 | 84 |
| 27 | 95.6 | 4:00 | $12,67 Oc | 1068 | 2 | 86 |
| 28 | 99.8 | 4:10 | $24,76 Oc | 1085 | 2 | 88 |
| 29 | 103.8 | 4:00 | $733,77 Oc | 1176 | 2 | 90 |
| 30 | 107.8 | 4:00 | $14,54 No | 1259 | 2 | 92 |
| 31 | 111.8 | 4:00 | $905,86 No | 1376 | 2 | 94 |

- Final (Estabilizar la economía): minuto **55.4**
- Al terminar la simulación (min 115): nodos 94/115, figuritas 60/60, logros 45/53, vueltas 32

## Gastador (autoclicker que en el árbol compra apenas puede el nodo más barato, sin ahorrar), semilla 1

| Reforma | Minuto | Duración de la vuelta | Plata ganada | +Credibilidad | Nodos comprados con ella | Nodos en total |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 4.2 | 4:10 | $210,62 K | 10 | 5 | 5 |
| 2 | 7.2 | 3:00 | $8,81 M | 18 | 2 | 7 |
| 3 | 10.2 | 3:00 | $32,64 M | 26 | 3 | 10 |
| 4 | 13.2 | 3:00 | $342,79 B | 59 | 5 | 15 |
| 5 | 16.2 | 3:00 | $2,08 T | 80 | 7 | 22 |
| 6 | 19.2 | 3:00 | $4,71 T | 84 | 3 | 25 |
| 7 | 22.2 | 3:04 | $9,5 T | 90 | 3 | 28 |
| 8 | 25.2 | 3:00 | $522,21 T | 112 | 3 | 31 |
| 9 | 28.7 | 3:28 | $1,09 Qa | 144 | 3 | 34 |
| 10 | 32.1 | 3:26 | $2,21 Qa | 149 | 4 | 38 |
| 11 | 35.4 | 3:15 | $6,4 Qa | 173 | 4 | 42 |
| 12 | 38.8 | 3:23 | $12,84 Qa | 178 | 2 | 44 |
| 13 | 42.0 | 3:13 | $26,01 Qa | 184 | 2 | 46 |
| 14 | 45.5 | 3:26 | $51,66 Qa | 190 | 2 | 48 |
| 15 | 49.3 | 3:50 | $103,07 Qa | 277 | 3 | 51 |
| 16 | 52.3 | 3:00 | $348,1 Qa | 291 | 3 | 54 |
| 17 | 56.0 | 3:42 | $692 Qa | 300 | 2 | 56 |
| 18 | 59.5 | 3:29 | $1,4 Qi | 309 | 3 | 59 |
| 19 | 63.3 | 3:50 | $1,57 Qi | 310 | 3 | 62 |
| 20 | 67.3 | 4:00 | $285,95 Qi | 381 | 2 | 64 |
| 21 | 71.3 | 4:00 | $582,73 Qi | 390 | 2 | 66 |
| 22 | 75.3 | 4:00 | $5,55 Sx | 420 | 3 | 69 |
| 23 | 79.3 | 4:00 | $50,33 Sx | 584 | 3 | 72 |
| 24 | 83.3 | 4:00 | $291,89 Sx | 616 | 3 | 75 |
| 25 | 87.3 | 4:00 | $1,41 Sp | 645 | 3 | 78 |
| 26 | 91.3 | 4:00 | $38,7 Sp | 708 | 3 | 81 |
| 27 | 95.3 | 4:00 | $1,67 Oc | 782 | 2 | 83 |
| 28 | 99.5 | 4:10 | $2,55 Oc | 791 | 2 | 85 |
| 29 | 103.5 | 4:00 | $11,72 Oc | 1065 | 2 | 87 |
| 30 | 107.5 | 4:00 | $284,78 Oc | 1151 | 2 | 89 |
| 31 | 111.5 | 4:00 | $3,95 No | 1222 | 3 | 92 |
| 32 | 115.5 | 4:00 | $752,85 No | 2052 | 3 | 95 |
| 33 | 119.5 | 4:00 | $57,73 Dc | 2243 | 3 | 98 |

- Final (Estabilizar la economía): minuto **63.3**
- Al terminar la simulación (min 123): nodos 98/115, figuritas 60/60, logros 46/53, vueltas 34
