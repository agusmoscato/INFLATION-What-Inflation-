# Balance de la timba

La timba usa SIEMPRE plata del juego. No hay dinero real ni microtransacciones: nada de lo que se gana o se pierde sale de, ni va a, plata de verdad.

## Valor esperado (por cada $1 apostado)

| Juego | Reglas | Valor esperado | Cómo se calculó |
| --- | --- | --- | --- |
| Raspadita | 76,5 % nada, 17 % x2, 2,5 % x10, 3,5 % sobre (vale 3x), 0,45 % dorada (vale 20x), 0,05 % pozo (10 % de cada raspadita lo alimenta); tras 5 pérdidas seguidas paga x1,5 seguro | **0,941** (-5,9 %) | simulación de 1.000.000 de raspaditas con racha y pozo (`GambleLogic.scratch_expected_value`) |
| Raspadita con las 6 páginas del álbum | los premios en plata suben +7,5 % | **~0,99** (cerca de 0, sin ser positivo) | ídem con suerte 0,075 |
| Quiniela | el quinielero se queda el 30 %; 2 cifras x70 (1 %), última cifra x7 (9 %) | **0,931** (-6,9 %) | exacto por enumeración: (0,01 x 70 + 0,09 x 7) x 0,7 |
| Timba del dólar | apostás arriba/abajo de la tasa de hoy; paga x1,9; dato oficial con ruido (sigma 25 %) | **~0,95** (-5 %) | 50 % de acierto x 1,9 (test con 20.000 apuestas) |

Los tests (`tests/suites/test_gamble.gd`) fijan estos rangos: la raspadita sin bonus queda entre -10 % y -5 %; con el álbum completo se acerca a 0 sin superarlo.
La timba del dólar usa pistas reales de los eventos activos (por ejemplo, una corrida que termina antes del cierre baja la inflación): da algo de habilidad, pero el umbral ya incluye los eventos de hoy, así que la ventaja es chica.

## Topes
- Ningún premio supera **10 minutos de tus ingresos actuales** (con un piso al inicio del juego de 50 niveles de precios). Para que eso se cumpla siempre, la apuesta máxima es tope/10 en la raspadita, tope/49 en la quiniela y tope/1,9 en la timba del dólar.
- Los premios de la timba **no cuentan como ganancia real** del juego: no aceleran las eras ni suman Credibilidad.

## Rachas y mala suerte
- Tras 5 pérdidas seguidas (en cualquier juego de timba), la próxima raspadita tiene premio asegurado (x1,5).
- El álbum muestra ganado, perdido y mejor premio (en pesos de hoy).

## Efecto en los tiempos del simulador
`godot --headless --script tools/simulate.gd -- --timbero --seed=N`: el bot apuesta el 5 % de su plata cada 30 s a la raspadita, y a la quiniela y al dólar cuando se abren (sin coleccionar a propósito).

| Semilla | Victoria sin timba (min) | Victoria timbero (min) | Diferencia |
| --- | --- | --- | --- |
| 1 | 451 | 441 | -2 % |
| 2 | 430 | 411 | -4 % |
| 3 | 432 | 403 | -7 % |

El bot sin timba termina en 7,2-7,5 h (dentro de las 7-10 h del diseño), así que **ignorar la timba no rompe los tiempos**. El timbero no termina más lento: pierde plata apostando, pero los sobres y doradas que cobra en la raspadita completan páginas del álbum y los bonus permanentes (+10 % ingresos, -5 % inflación, etc.) compensan de sobra. Si la timba se quisiera volver pura pérdida, habría que sacar los sobres de la raspadita o achicar los bonus de las páginas.
