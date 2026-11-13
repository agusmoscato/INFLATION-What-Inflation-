# Inflación Idle — Documento de diseño

Nov 13, 2026 · @Agustin

## Pitch

Un incremental donde la plata pierde valor mientras jugás: para ganar tenés que crecer más rápido que la inflación. Arrancás vendiendo empanadas a $1 y terminás manejando una economía con precios de 100 dígitos.

| Campo | Definición |
| --- | --- |
| Gancho (3 segundos) | Un contador de inflación que se dispara y un billete al que le van creciendo los ceros |
| Diferencial | La inflación es el enemigo: ninguna moneda es segura y los números grandes son el chiste |
| Público | Fans de incrementales en Steam (Cookie Clicker, Revolution Idle) y de humor sobre economía |
| Precio | USD 4,99, con 10% de descuento de lanzamiento |
| Duración | 6–10 horas hasta el final, completable al 100% |
| Plataformas | Steam (Windows y Linux) y demo web en itch.io |
| Idiomas | Español e inglés desde el primer día |
| Referencias | Cookie Clicker (humor y números), Bills Must Be Paid (sensación al tocar), MMO98 (gancho temático) |

Tono: sátira de la inflación en general, sin políticos ni partidos reales. Así se entiende en cualquier país y no espanta a nadie.

## Loop principal

La tensión central: tus ingresos crecen en pesos, pero los costos suben con la inflación. El puntaje real es tu **poder adquisitivo**, no la cantidad de pesos.

1. **Segundo a segundo:** hacés clic en la empanada, vendés y vuelan billetes. Cada pocos segundos aparece un cartel de "¡Aumento!" y los precios suben.
2. **Minuto a minuto:** comprás negocios que producen solos, remarcás precios para no quedarte atrás y pasás plata a refugios (dólar, ladrillos, oro) antes de que se licue.
3. **Hora a hora:** cuando los números se vuelven inmanejables, hacés una reforma monetaria (prestige): le sacás ceros a la moneda y ganás multiplicadores permanentes.

El juego funciona dejado en segundo plano: el progreso offline se calcula al volver, pero la inflación también corre mientras no estás.

## Sistemas

La inflación toca todos los sistemas: cada uno es una forma de defenderte de ella o de aprovecharla.

| Sistema | Cómo funciona | Se desbloquea |
| --- | --- | --- |
| Inflación | Un "mes" de juego dura 30 s. Cada mes los costos suben según la tasa actual. Eventos y decisiones la aceleran o la frenan | Desde el inicio |
| Negocios | Generadores automáticos: kiosco, almacén, remisería, fábrica, cadena, banco. Cada uno con niveles y mejoras | Era 1 en adelante |
| Remarcar | Botón para actualizar precios: da ingreso extra si lo hacés a tiempo. Una mejora lo automatiza | Era 1 |
| Refugios | Pasás pesos a dólar, ladrillos, oro o cripto. Protegen valor, pero cobran comisión y cripto es volátil | Era 2 |
| Reforma monetaria (prestige 1) | Sacás ceros a la moneda y empezás de nuevo con puntos de Credibilidad, que dan multiplicadores permanentes | Primera vez a los \~45 min |
| Plan económico (prestige 2) | Elegís un plan con reglas distintas para la siguiente vuelta: Estabilización, Convertibilidad o Emisión | Era 4 |
| Eventos | Feriado largo, aguinaldo (ingreso doble), corrida cambiaria, cepo (bloquea refugios 60 s), paro | Era 2 |
| Colección de billetes | Cada reforma agrega un billete ficticio a tu álbum. Completarlo da bonus | Primera reforma |
| Logros | Integrados con Steam. Ejemplo: "Millón de nada", llegar a un millón que no alcanza para un café | Siempre |

## Progresión por eras

Cinco eras llevan al jugador de un puesto callejero a la hiperinflación. El final llega cuando logra estabilizar la economía.

| Era | Tiempo de juego | Negocios clave | Qué se desbloquea | Escala de precios |
| --- | --- | --- | --- | --- |
| 1. El puesto | 0–30 min | Empanadas, kiosco | Remarcar, primeras mejoras | $1 a $10.000 |
| 2. El barrio | 30 min–2 h | Almacén, remisería, verdulería | Refugios, eventos, primera reforma | Hasta millones |
| 3. La ciudad | 2–4 h | Fábrica, cadena de locales | Empleados, automatización total | Hasta billones |
| 4. Las finanzas | 4–7 h | Banco, bolsa, cripto | Plan económico (prestige 2) | Hasta 1e30 |
| 5. Hiperinflación | 7–10 h | Todo a la vez | Desafío final: bajar la tasa a cero | Hasta 1e100 y más |

## Estilo visual, sonido y humor

Arte 2D plano y simple, para que lo pueda producir una sola persona. Lo que vende es el juice, no el detalle.

- **Visual:** billetes ficticios que van sumando ceros hasta no entrar en pantalla, números que tiemblan cuando la inflación sube y la pantalla que se tiñe de rojo en la hiperinflación.
- **Juice:** billetes volando en cada venta, sacudida de cámara en los aumentos y animación de tijera cortándole ceros al billete en cada reforma.
- **Sonido:** caja registradora, monedas y una música que se acelera con la tasa de inflación.
- **Humor:** una cinta de titulares de diario ficticios ("Empanada supera al dólar como refugio de valor"), nombres de mejoras con chiste y logros absurdos.
- **Límite:** nada de políticos, partidos ni billetes reales.

## Marketing

Objetivo: llegar al Next Fest con más de 10.000 wishlists. Como referencia, Bills Must Be Paid entró con 15.623 y vendió 330.000 copias en 20 días ([fuente](https://howtomarketagame.com/?p=6779)).

- **Videos cortos todos los días (10–15 min de trabajo):** "El precio de una empanada después de 10 minutos de juego", "Pasé de $1 a un millón y no me alcanza para un café", el billete que se queda sin espacio para los ceros. Es lo mismo que le funcionó a Sir, We Have an Orc Problem ([fuente](https://howtomarketagame.com/2026/08/18/the-week-of-the-golden-age)).
- **Página de Steam:** abrirla en la semana 4 con un GIF del contador de inflación disparado. La cápsula muestra un billete gigante lleno de ceros.
- **Demo:** gratis en itch.io (versión web) y en Steam, que cubra la Era 1 y la primera reforma.
- **Comunidad:** posteos en r/incremental\_games y Discord propio desde la primera demo.
- **Next Fest:** el primero que llegue con al menos dos meses de página publicada.

## Plan técnico y roadmap

Godot 4 con GDScript, unas 14 semanas hasta el lanzamiento. Después arranca Plastiquito.

**Arquitectura**

- **Números grandes:** una clase propia BigNumber (mantisa + exponente). Los float normales se rompen alrededor de 1e308 y la hiperinflación los va a superar.
- **Autoloads:** GameState (estado), Economy (tick e inflación), SaveSystem (guardado en JSON y progreso offline) y EventBus (señales).
- **Datos aparte del código:** negocios, mejoras y eventos en archivos de recursos, para balancear sin tocar lógica.
- **Simulador sin interfaz:** un script que juega 10 horas en segundos y genera la curva de progreso, para balancear con datos.
- **Steam:** GodotSteam para logros. Exportar a Windows, Linux y web (demo de itch.io).
- **Con Claude Code:** repo en git, un CLAUDE.md con las reglas de este documento y una tarea chica por sesión.

**Roadmap**

1. Semanas 1–2, prototipo: clic, 5 negocios, inflación, BigNumber y guardado. La meta es saber si 20 minutos de juego enganchan.
2. Semanas 3–4, sistemas: remarcar, refugios, eventos y primera reforma. Abrir la página de Steam.
3. Semanas 5–6, contenido: Eras 1 a 3 y primer balance con el simulador.
4. Semanas 7–8, arte, sonido y juice. Eras 4 y 5 y el final.
5. Semanas 9–10, demo, tráiler y empezar con los videos cortos diarios.
6. Semanas 11–14, pulido, logros de Steam, traducción al inglés, beta cerrada y lanzamiento.

## Riesgos y preguntas abiertas

El riesgo principal es que el humor sea demasiado local. Se mitiga probando la demo con jugadores de afuera de Latinoamérica antes de la semana 6.

| Riesgo | Mitigación |
| --- | --- |
| El chiste no se entiende fuera de Argentina | Inflación universal, textos en inglés revisados por nativos y prueba temprana con extranjeros |
| Lectura política | Sátira sin políticos, partidos ni hechos reales |
| Parecerse a otro clon más del género | La inflación como enemigo tiene que verse en el primer segundo del tráiler |
| Balance con números enormes | BigNumber desde el día 1 y simulador de 10 horas |

- [ ] ¿Nombre final? Opciones: "Inflación Idle", "Inflation Idle", "Remarcando".
- [ ] ¿Arte propio o contratado?
- [ ] ¿USD 4,99 o USD 2,99?

## Fuentes

- [AppMagic: juegos idle en Steam 2024–2026](https://appmagic.rocks/blog/idle-steam-games-2026)
- [How To Market A Game: best sellers de julio 2026](https://howtomarketagame.com/2026/08/18/the-week-of-the-golden-age)
- [How To Market A Game: Bills Must Be Paid](https://howtomarketagame.com/?p=6779)
- [GameDev.net: Incremental Games Have a Creativity Problem](https://gamedev.net/news/3928-incremental-games-have-a-creativity-problem/)
