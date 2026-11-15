# INFLATION? What Inflation? — Diseño v2: clicker casual con renacimientos

> Versión oficial (en `main`). Reemplaza al diseño "tycoon" de [DISENO.md](DISENO.md) (que queda como historia).
> Se mantienen el arte de pizarra, la empanada, el tema de la inflación, el humor, las figuritas y lo técnico
> (BigNumber, guardado, QA, exports). Todos los números de este documento viven en `data/*.json` y los valida el
> simulador (`tools/simulate.gd`, reporte en [balance_v2.md](balance_v2.md)).

## 1. Objetivos (los mide el simulador; el QA falla si no se cumplen)

**Regla de oro: el jugador nunca puede quedar trabado, y cada vuelta se siente mejor que la anterior.**

| Hito | Objetivo | Quién |
| --- | --- | --- |
| Primer renacimiento (reforma) | minuto 4–6, entre 5 y 10 de Credibilidad | jugador activo |
| Final: nodo "Estabilizar la economía" | minuto 50–70 | jugador activo |
| 100 % (árbol + álbum + logros) | 3 h – 4 h, nunca más | jugador activo |
| Aceleración | la vuelta 10 llega a la plata máxima de la vuelta 1 en ≤ 1/5 del tiempo | jugador activo |
| Cada vuelta mejor | la vuelta 2 llega a la plata de la vuelta 1 en menos de la mitad del tiempo | los tres |
| Nunca trabado | nunca más de 20 s sin poder comprar nada ni reformar | los tres |
| Reformas que valen la pena | ninguna reforma da menos de 5 de Credibilidad | los tres |
| Los clics importan | en el primer minuto de la vuelta 1, los clics son la fuente principal de plata | activo y distraído |

Los tres jugadores de prueba están en la sección 9.

## 2. El loop de una vuelta (2–6 minutos)

### 2.1 La empanada (botón principal)
- Clic base: **$1**. Feedback: squash & stretch, migas de tiza, "+$" flotante y medidor de combo.
- **Combo**: cada clic a menos de 1,0 s del anterior suma 1 (tope 20). Multiplicador del clic = 1 + 0,05 × combo
  (máximo ×2). Sin clics durante 1,0 s, el combo se cae.
- Clics críticos (se desbloquean en el árbol): 5 % de chance, ×5.
- Barra espaciadora = clic.

### 2.2 Negocios (10, producen solos)
Costo del n-ésimo = base × 1,15ⁿ × P (P = nivel de precios de la vuelta, ver 2.4).
**Hitos ×2** por negocio al llegar a **10 / 25 / 50 / 100** unidades (como Cookie Clicker).

| # | Negocio | Costo base | $/s | Disponible |
| --- | --- | --- | --- | --- |
| 1 | Carrito de empanadas | 15 | 0,25 | siempre |
| 2 | Kiosco | 130 | 2 | siempre |
| 3 | Choripanería | 1.400 | 16 | siempre |
| 4 | Lavadero | 16.000 | 130 | siempre |
| 5 | Panadería | 200.000 | 1.050 | siempre |
| 6 | Almacén | 2,6 M | 9.000 | siempre |
| 7 | Remisería | 35 M | 80.000 | nodo "Negocios avanzados" |
| 8 | Fábrica | 500 M | 750.000 | nodo "Negocios avanzados" |
| 9 | Imprenta de billetes | 8 B | 7,5 M | capstone NEGOCIOS |
| 10 | Holding de ceros | 140 B | 80 M | capstone NEGOCIOS |

Los ingresos son la mitad que en la primera versión del clicker: la vuelta 1 va más tranquila y en el primer minuto
la plata sale sobre todo de los clics (≈ 67 % con un jugador activo).

### 2.3 Mejoras (tarjetas que se entienden de un vistazo)
Cada mejora es una **tarjeta** que muestra, sin hacer clic ni pasar el mouse: ícono, nombre corto ("Delantal"),
efecto ("Carritos x2", "Clic x2", "Todo x1,5", "Kioscos +2 % por carrito") y **precio**. Si te alcanza: borde verde que
late; si no: precio en rojo y una barrita hacia el precio. Al pasar el mouse aparece **al instante** el detalle (qué
hace, cuánto cuesta y cuánto te falta). Se compran con un clic. Se pierden al reformar. Costo × P.
- **Al alcance**: solo aparecen las que cuestan como mucho **10 minutos** de ingreso (producción + 3 clics/s) o lo que
  ya tenés. Las demás desbloqueadas se ven en **"Próximas"**, apagadas y con candado (hasta 4).
- **De a una**: en las primeras 3 vueltas aparece como mucho **una mejora nueva cada 20 s** (aviso "Mejora nueva:
  Delantal (Carritos x2)"); después, cada 2 s.
- **Por negocio** (40): al tener 1 / 5 / 15 / 40 unidades → ese negocio ×2; cuestan **6 / 40 / 400 / 15.000 × costo
  base** (la primera ronda: Delantal del carrito $90, Dedo índice $50, Cartel del carrito $600, Delantal del kiosco $780).
- **De clic** (6): con 15 / 80 / 250 / 600 / 1.200 / 2.500 clics en la vuelta → clic ×2, ×2, +1 % de $/s por clic,
  ×3, +1 % de $/s, ×3. Cuestan 50 / 1.000 / 30.000 / 1 M / 50 M / 5 B.
- **Sinergias** (5) y **globales** (4) como antes (sinergia: +2 % por cada unidad del otro negocio; globales ×1,5 /
  ×1,5 / ×2 / ×2 con 20 / 60 / 120 / 200 negocios).

### 2.4 La inflación: atada al progreso, con freno y tope
- **No depende del reloj**: la tasa sube con el **progreso de la vuelta** φ = ceros ganados en la vuelta / (ceros de tu
  mejor vuelta + 1,5) (en la vuelta 1, sobre 4,5 ceros): **r = 0,15 %/s × velocidad × suavidad × e^(3·φ)**. Si no
  avanzás, no se acelera; y como cada vuelta llega más rápido al mismo progreso, cada vuelta acumula menos inflación.
  La pared queda un poco más allá de tu récord: cada vuelta puede superar a la anterior.
- **Suavidad** de las primeras vueltas: ×0,4 (vuelta 1), ×0,45, ×0,6, ×0,8 y ×1 desde la quinta.
- **Tope por vuelta**: los precios no pasan de x10^(0,7 + 0,3 × reformas) (x5 en la vuelta 1), como mucho x10^8.
- **Freno (la garantía)**: el negocio más barato nunca cuesta más que **12 s de lo que ganás produciendo más 1 clic por
  segundo** (más estricto que "30 s de ingreso + 30 clics"). Si la inflación se va a pasar, se frena sola: la tasa se
  apaga al acercarse y, si hace falta (después de los 2 primeros minutos de la vuelta), los precios bajan (deflación,
  hasta x1/1000). El cartel lo dice: "Inflación frenada (venía a X % mensual)".
- Se muestra como **inflación mensual** (1 "mes" = 10 s).
- **Remarcar**: congela P **5 s** (el árbol lo lleva a 9 s); recarga 30 s (20 s con el árbol). Debajo del botón hay una
  línea fija: **"Congela los precios 5 s"**.
- Capas visuales: 1 "El puesto" → 2 "El barrio" ($100 K) → 3 "La ciudad" ($100 M) → 4 "Las finanzas" ($100 B) →
  5 "¡Hiperinflación!" (inflación mensual ≥ 20 %).

### 2.5 Billete volador (el "golden cookie")
- Primero al minuto de la partida (el primer minuto es de la empanada); después cada **30–90 s** (al azar). Cruza la pantalla en 12 s.
- Premio al azar: **Frenesí** ×7 producción por 15 s (40 %), **Plata** = 60 s de producción (mínimo 50 clics) (35 %),
  **Precios congelados** 15 s (15 %), **Figurita** (10 %, con el álbum; si no, Plata).

## 3. Renacer: Reforma monetaria (siempre disponible y explicada)
- **Botón siempre visible**: "Reformar ahora: +X Credibilidad" (en vivo) o "Reforma: disponible al llegar a $Y (te
  falta $Z)". Debajo, una línea que explica qué conviene.
- **Credibilidad = ⌊ 0,9 × (log10(plata máxima ganada en la vuelta) − 1,9)² × multiplicadores + extras ⌋**, cobrada
  **completa** (no hace falta igualar la mejor vuelta). $10 K → 3, $20 K → 5, $100 K → 8, $1 M → 15, $1 B → 45,
  $1 T → 91, $1 Qa → 154.
- **Cuándo se habilita**: cuando da 5 o más (≈ $20 K en la vuelta 1). Desde la vuelta 2, durante los primeros 2 minutos
  también hay que llegar a medio cero de tu mejor vuelta (así no conviene reformar a los 5 segundos una y otra vez);
  pasados esos 2 minutos esa regla nunca bloquea.
- **El juego aconseja** (el botón late en amarillo y aparece "Buen momento para reformar…"): en la vuelta 1, a los
  ~4 min (tutorial); después, cuando lo que sumás por minuto cae debajo del promedio de la vuelta y ya duplicaste tu
  mejor vuelta (o la vuelta pasa los 2,5 min).
- **Detector de traba**: si pasan 15 s sin poder comprar nada (comprar algo reinicia la cuenta), el botón late y
  aparece "Los precios se te escaparon. ¡Hacé la reforma y empezá más fuerte!". Con el freno casi nunca pasa.
- **La primera vez**: el diálogo explica en tiza qué es la reforma (cortás ceros, empezás de nuevo, ganás Credibilidad
  para el árbol, la próxima vuelta va más rápido). Después de la primera reforma, el resumen lleva al árbol y una
  **flecha** señala el nodo recomendado: "Comprá esto: tu próxima vuelta va a ser mucho más rápida" (primeras 3
  reformas).
- **Moneda nueva, confianza nueva**: cada vuelta después de una reforma arranca con producción **x10 durante 30 s**.
- Se reinicia la vuelta (plata, negocios, mejoras, P) y se conserva el resto. La tijera corta tantos ceros como ceros
  tenía la plata ganada menos 3.
- *Balance*: se probaron la fórmula acumulativa estilo Cookie Clicker (muy linda al principio, pero un récord de suerte
  deja todas las vueltas siguientes sin premio) y la de la versión anterior (castigaba no igualar la mejor vuelta). La
  cuadrática por vuelta con la ventana de 2 minutos fue la única que cumplió todo con los tres jugadores.

## 4. Árbol de habilidades (el corazón del juego)
- **115 nodos** dibujados con tiza en una pizarra que se arrastra y se hace zoom (rueda / pellizco / botones + −).
- El centro es **ESTABILIZAR LA ECONOMÍA** (el final), visible desde el principio como meta.
  Alrededor nacen 6 ramas, una cada 60°. Anillo r a 150 px × r del centro.
- Un nodo se ve cuando su padre está comprado; los vecinos del borde se ven como niebla con "?"; el resto no se dibuja.
- Se compran con Credibilidad, en cualquier momento (también a mitad de vuelta).
- **Costos por anillo**: **2, 6**, 35, 120, 400, 1.500, 5.000, 11.000 (×1,15 si es lateral; puentes 3.500). Final:
  **5.000** y requiere los 6 **sellos** (el nodo del anillo 4 de cada rama). En la primera hora cada reforma alcanza
  para 2–6 nodos; los anillos 6 a 8 son el "después del final" (del minuto ~60 al 100 %).
- **Los primeros nodos se notan enseguida** (cuestan 2): Empanada de horno **clic x2**, Socio del barrio **empezás con
  5 carritos y producís x2**, Precios cuidados **inflación −20 %**, Memoria colectiva **+25 % de Credibilidad**,
  Billetes al viento y Álbum de figuritas.

| Rama | Identidad | Capstone (anillo 7) |
| --- | --- | --- |
| EMPANADA (arriba) | clic, combos, críticos | **Autoclicker**: 10 clics/s automáticos |
| NEGOCIOS | producción, negocios más baratos, empezar con negocios | **Negocios exclusivos**: Imprenta y Holding |
| INFLACIÓN | inflación más lenta, remarcar más fuerte, congelados más largos | **La inflación te paga**: +50 % de producción por cada cero de P |
| SUERTE Y TIMBA (abajo) | billetes más seguidos, mejores premios, raspaditas | **Raspadita automática** cada 30 s |
| FIGURITAS | sobres gratis, más doradas, bonus por página | **Edición especial**: cada página completa ×1,5 |
| RENACER | más Credibilidad, arrancar con plata y negocios, arranque x10 | **Reforma perpetua**: +50 % de Credibilidad |

- **Nodos de desbloqueo** (el juego se revela por el árbol): Raspadita (SUERTE, anillo 2), Álbum (FIGURITAS, anillo 1),
  Noticias/eventos (INFLACIÓN, anillo 2), Negocios avanzados (NEGOCIOS, anillo 3), Encargado (compra automática,
  NEGOCIOS, anillo 6), Remarcado automático (INFLACIÓN, anillo 4).
- **6 puentes** (anillo 5, entre dos ramas vecinas; requieren el nodo de anillo 4 de ambas): mezclan identidades
  (p. ej. "Empanada S.A.": +1 % de clic por cada negocio).
- **Anillo 8** (6 nodos, 22.000): para después del final; completan el árbol.
- Detalle de los 115 nodos: `data/tree.json` (efectos) e `i18n/v2.txt` (nombres y descripciones); costos en
  `data/balance.json`.

## 5. Sistemas que se desbloquean en el árbol
- **Raspadita** (timba principal): cuesta 5 % de tu plata; premios ×2 (17 %), ×10 (2,5 %), sobre (3,5 %),
  frenesí (5 %), nada (resto). Racha de 5 pérdidas → la próxima paga seguro. Siempre con plata del juego.
- **Álbum**: 60 figuritas en 6 páginas (se mantiene). Sobre = 60 s de producción (con piso × P). Chupi: 5 repetidas
  por una faltante. Bonus por página: Negocios +10 % producción, Personajes −5 % velocidad de inflación, Billetes
  +10 % Credibilidad, Titulares +3 s de remarcar, Eventos noticias ×1,25, Doradas +15 % producción.
- **Noticias** (eventos): cada 90–150 s, una noticia con 2 opciones y 10 s para elegir (efectos temporales).

## 6. Qué se sacó o simplificó
- Las 5 eras largas → capas visuales de la vuelta (2.4). Plan económico (prestige 2), refugios y cartera → eliminados
  (algunas ideas viven como nodos). Quiniela y timba del dólar → eliminadas; queda la raspadita.
- Panel de objetivos, órdenes de compra y flecha → eliminados. Tutorial: solo la primera vuelta (≈ 4 min), con 4
  notitas que se van solas (clic → primer carrito → remarcar → reforma). Después solo avisos de cosas nuevas.
- Partidas viejas (versión 1 del guardado): se empieza de cero con un aviso.

## 7. Dinamismo y sensación
- Avisos chicos arriba a la izquierda (desbloqueos, mejoras nuevas, hitos, logros); se van solos en 3 s. **En las
  primeras 3 vueltas** salen de a uno (2,2 s entre avisos) y duran 5,5 s, y las mejoras aparecen de a una cada 20 s:
  da tiempo a leer y a cliquear.
- Plata grande y brillante con ticker "+$/s" bien visible; números que "saltan" al cambiar.
- Cada compra: "pop" visual (escala) y sonoro. Nodos del árbol: chispazo de tiza al comprar.

## 8. Logros
- **53 logros** (8 secretos, con chistes), alcanzables en 3–4 h. Con la inflación nueva cambiaron tres:
  "Hiperinflación" (ver una inflación de 20 % mensual), "Millonario de nada" (un millón con la inflación arriba del
  15 %) y el secreto "¿Inflación? ¿Qué inflación?" (tener $1.000 millones con la inflación frenada a cero). Menú: **% de completado** =
  (nodos + figuritas + logros) / (115 + 60 + 53).

## 9. Simulador y QA
- Tres jugadores de prueba (`scripts/core/bot_policy.gd`, los mismos en el simulador y en el QA del juego real):
  - **activo**: 7 clics/s con combo, toca el 90 % de los billetes al segundo, remarca con la inflación arriba del 4 %
    y compra lo de mejor repago (entre lo que puede pagar en 45 s) una vez por segundo;
  - **pasivo**: 1 clic/s, toca el 30 % de los billetes (tarde), casi no remarca y compra siempre lo más barato;
  - **distraído**: 4 clics/s y en las vueltas largas deja de jugar 2 minutos a mitad de la vuelta.
  Los tres reforman cuando el juego lo aconseja (sección 3) y compran el nodo que el juego recomienda (sellos y final
  primero; después el más barato, con preferencia NEGOCIOS = EMPANADA > INFLACIÓN > RENACER > FIGURITAS > SUERTE).
- Reporte `docs/balance_v2.md`: chequeos por jugador y semilla, y la tabla de reformas de cada jugador.
- `tools/simulate.gd -- --seeds=1,2,3,4 --qa` termina con código 1 si falla algún chequeo de la sección 1.
- Hojas de contacto del juego real (`tools/qa_newplayer.ps1`): 0–10 min con el jugador pasivo
  (`docs/qa/v2_0_a_10_min_pasivo.jpg`) y 0–10 / 10–60 min con el activo (`docs/qa/v2_0_a_10_min_activo.jpg`,
  `docs/qa/v2_10_a_60_min_activo.jpg`). El QA del juego real falla con los mismos chequeos.

## 10. Demo
Las primeras 3 vueltas y los anillos 1–3 del árbol. Después de la tercera reforma: pantalla "¡Esto fue la demo!".

## 11. Precio sugerido
Juego corto ("1 hora para el final, 3–4 h para el 100 %"): **USD 2,99–3,99** (recomendado USD 3,99 con 20 % de
descuento de lanzamiento).
