# INFLATION? What Inflation? — Diseño v2: clicker casual con renacimientos

> Rama `rediseno-clicker`. Reemplaza al diseño "tycoon" de [DISENO.md](DISENO.md) (que queda como historia).
> Se mantienen el arte de pizarra, la empanada, el tema de la inflación, el humor, las figuritas y lo técnico
> (BigNumber, guardado, QA, exports). Todos los números de este documento viven en `data/*.json` y los valida el
> simulador (`tools/simulate.gd`, reporte en [balance_v2.md](balance_v2.md)).

## 1. Objetivos de duración (los mide el simulador; el QA falla si no se cumplen)

| Hito | Objetivo |
| --- | --- |
| Primer renacimiento (reforma) | minuto 4–6 |
| Final: nodo "Estabilizar la economía" | minuto 50–70 |
| 100 % (árbol + álbum + logros) | 3 h – 4 h, nunca más |
| Aceleración | la vuelta 10 llega a la plata máxima de la vuelta 1 en ≤ 1/5 del tiempo |
| Siempre estás mejorando | en la primera hora, nunca más de 20 s sin algo comprable (mejora, negocio o nodo) |

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
| 1 | Carrito de empanadas | 15 | 0,5 | siempre |
| 2 | Kiosco | 130 | 4 | siempre |
| 3 | Choripanería | 1.400 | 32 | siempre |
| 4 | Lavadero | 16.000 | 260 | siempre |
| 5 | Panadería | 200.000 | 2.100 | siempre |
| 6 | Almacén | 2,6 M | 18.000 | siempre |
| 7 | Remisería | 35 M | 160.000 | nodo "Negocios avanzados" |
| 8 | Fábrica | 500 M | 1,5 M | nodo "Negocios avanzados" |
| 9 | Imprenta de billetes | 8 B | 15 M | capstone NEGOCIOS |
| 10 | Holding de ceros | 140 B | 160 M | capstone NEGOCIOS |

### 2.3 Mejoras (fila de íconos, estilo Cookie Clicker)
Aparecen como íconos de tiza en una fila sobre la tienda, ordenadas por precio. Se pierden al reformar.
Costo × P, igual que los negocios.
- **Por negocio** (40): al tener 1 / 5 / 15 / 40 unidades → ese negocio ×2 cada una; cuestan
  10 / 60 / 600 / 20.000 × costo base.
- **De clic** (6): con 15 / 80 / 250 / 600 / 1.200 / 2.500 clics en la vuelta → clic ×2, ×2, +1 % de $/s por clic,
  ×3, +1 % de $/s, ×3. Cuestan 50 / 1.000 / 30.000 / 1 M / 50 M / 5 B.
- **Sinergias** (5): carrito↔kiosco, kiosco↔choripán, lavadero↔panadería, panadería↔almacén, remisería↔fábrica:
  el primero gana +2 % por cada unidad del segundo (requiere 10 de cada uno). Cuestan 50 × el costo base del segundo.
- **Globales** (4): "Precios de lista" ×1,5, "Delivery" ×1,5, "Tarjeta en 12 cuotas" ×2, "Pago con QR" ×2,
  con 20 / 60 / 120 / 200 negocios en total. Cuestan 5 K / 500 K / 50 M / 5 B.
Total: 55 mejoras. Como cada vuelta tiene muchas, casi siempre hay un ícono cerca de poder comprarse.

### 2.4 La inflación como pared
- La tasa crece sola con el tiempo de la vuelta t: **r(t) = 0,2 %/s × e^(t/78 s) × velocidad** (se duplica cada ~54 s;
  el árbol baja la velocidad). El nivel de precios acumula **P = e^∫r** salvo con precios congelados:
  P ≈ 1,8 al minuto 2, 4 al minuto 3, 25 al minuto 4, 1.250 al minuto 5, 6 millones al minuto 6.
  Todo lo que se compra cuesta × P; la producción NO sube con P → los precios se disparan.
- Se muestra como **inflación mensual** (1 "mes" = 10 s): 2 % al empezar, 22 % al minuto 3, 155 % al minuto 5.
- **Remarcar** (botón): congela P **5 s**; recarga **30 s** (el árbol lo lleva a 9 s / 20 s). Como la tasa sigue
  creciendo con el tiempo real, remarcar ayuda sin romper la pared.
- Capas visuales (los nombres de las viejas eras): 1 "El puesto" → 2 "El barrio" ($100 K ganados en la vuelta) →
  3 "La ciudad" ($100 M) → 4 "Las finanzas" ($100 B) → 5 "¡Hiperinflación!" (inflación mensual ≥ 100 %: tinte rojo).
- **Colapso**: cuando P ≥ 100 y el negocio más barato cuesta más de 60 s de producción, aparece el cartel
  "¡La economía colapsó! Hacé la reforma" (y el botón de reforma late). **La primera reforma se habilita recién ahí**
  (≈ minuto 4,5); desde la segunda, cuando el jugador quiera.

### 2.5 Billete volador (el "golden cookie")
- Primero a los 40 s de la partida; después cada **30–90 s** (al azar). Cruza la pantalla en 12 s.
- Premio al azar: **Frenesí** ×7 producción por 15 s (40 %), **Plata** = 60 s de producción (mínimo 50 clics) (35 %),
  **Precios congelados** 15 s (15 %), **Figurita** (10 %, con el álbum; si no, Plata).

## 3. Renacer: Reforma monetaria
- Botón "Reforma" con vista previa: **"Vas a ganar X Credibilidad"** y confirmación.
- **Credibilidad = ⌊ (log10(plata máxima ganada en la vuelta) − 4)² × multiplicadores + extras ⌋** (logarítmica: ganar
  1.000 veces más da unos puntos más, no 1.000 veces más). $1 M → 4, $1 B → 25, $1 T → 64, $1 Qa → 121.
- **Contra la reforma "de 20 segundos"**: la vuelta cuenta completa si iguala o supera tu mejor vuelta y no cuenta nada
  si queda 2 ceros o más abajo (en el medio, proporcional). Así cada vuelta tiene que llegar lejos.
- Se reinicia la vuelta (plata, negocios, mejoras, P) y se conserva todo lo demás (árbol, álbum, logros, Credibilidad no
  gastada). La tijera corta los ceros (animación existente, al menos uno por reforma).
- Resumen al renacer: "Vuelta 7: llegaste a $4,2 B en 3:12 — +18 Credibilidad", con flechas contra la vuelta anterior.
- Cada reforma agrega un billete al álbum (página Billetes, 10 billetes).
- *Balance*: se probaron raíz de lo ganado por vuelta (explota), raíz cúbica acumulada estilo Cookie Clicker (explota o
  se estanca según el árbol, sin punto medio) y logaritmo acumulado (se estanca a la mitad). El logaritmo al cuadrado
  por vuelta con la regla de la mejor vuelta fue el único estable en todas las semillas del simulador.

## 4. Árbol de habilidades (el corazón del juego)
- **115 nodos** dibujados con tiza en una pizarra que se arrastra y se hace zoom (rueda / pellizco / botones + −).
- El centro es **ESTABILIZAR LA ECONOMÍA** (el final), visible desde el principio como meta.
  Alrededor nacen 6 ramas, una cada 60°. Anillo r a 150 px × r del centro.
- Un nodo se ve cuando su padre está comprado; los vecinos del borde se ven como niebla con "?"; el resto no se dibuja.
- Se compran con Credibilidad, en cualquier momento (también a mitad de vuelta).
- **Costos por anillo**: 3, 10, 30, 80, 250, 1.500, 8.000, 22.000 (×1,15 si es lateral; puentes 2.700). Final:
  **3.000** y requiere los 6 **sellos** (el nodo del anillo 4 de cada rama). En la primera hora cada reforma alcanza
  para 2–5 nodos; los anillos 6 a 8 son el "después del final" (del minuto ~60 al 100 %).

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
- Avisos chicos arriba a la derecha (desbloqueos, mejoras nuevas, hitos, logros); se van solos en 3 s.
- Plata grande y brillante con ticker "+$/s" bien visible; números que "saltan" al cambiar.
- Cada compra: "pop" visual (escala) y sonoro. Nodos del árbol: chispazo de tiza al comprar.

## 8. Logros
- **53 logros** (8 secretos, con chistes), alcanzables en 3–4 h. Menú: **% de completado** =
  (nodos + figuritas + logros) / (115 + 60 + 53).

## 9. Simulador y QA
- Bot (`scripts/core/bot_policy.gd`, el mismo en el simulador y en el QA del juego real): 5 clics/s con combo, toca el
  85 % de los billetes, remarca cuando puede, compra lo de mejor repago, reforma cuando la Credibilidad que suma por
  minuto (últimos 30 s) cae debajo del promedio de la vuelta, compra nodos por prioridad (sellos y final primero;
  después el más barato, con preferencia NEGOCIOS > EMPANADA > RENACER > INFLACIÓN > FIGURITAS > SUERTE), abre sobres,
  hace chupi y juega raspaditas mientras falten figuritas.
- Reporte `docs/balance_v2.md`: minuto de cada reforma, duración de cada vuelta, minuto del final y del 100 %,
  máxima espera sin nada comprable en la primera hora.
- `tools/simulate.gd -- --seeds=1,2,3,4 --qa` termina con código 1 si no se cumple algún objetivo de la sección 1.
- Hojas de contacto del juego real: 0–10 min (una captura cada 30 s) y 10–60 min (cada 2,5 min).

## 10. Demo
Las primeras 3 vueltas y los anillos 1–3 del árbol. Después de la tercera reforma: pantalla "¡Esto fue la demo!".

## 11. Precio sugerido
Juego corto ("1 hora para el final, 3–4 h para el 100 %"): **USD 2,99–3,99** (recomendado USD 3,99 con 20 % de
descuento de lanzamiento).
