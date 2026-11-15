# Genera i18n/v2.txt (CSV: keys, es, en) con todos los textos del diseño v2. Uso: python tools/gen_i18n_v2.py i18n/v2.txt
import csv, sys

out = sys.argv[1]
rows = []
def k(key, es, en):
    rows.append((key, es, en))

# ---------------- interfaz ----------------
k("ui.remark", "REMARCAR", "REPRICE")
k("ui.remark_cd", "Remarcar (%d s)", "Reprice (%d s)")
k("ui.remarked", "¡REMARCADO! Precios congelados %d s", "REPRICED! Prices frozen for %d s")
k("ui.cred", "Credibilidad", "Credibility")
k("ui.upgrades", "Mejoras", "Upgrades")
k("ui.upgrades_none", "Mejoras: comprá negocios y tocá la empanada para que aparezcan", "Upgrades: buy businesses and poke the empanada to unlock them")
k("ui.businesses", "Negocios", "Businesses")
k("ui.nav.tree", "Árbol", "Tree")
k("ui.nav.tree_can", "¡Podés comprar %d cosas!", "You can buy %d things!")
k("ui.nav.tree_can1", "¡Podés comprar 1 cosa!", "You can buy 1 thing!")
k("ui.nav.album", "Álbum", "Album")
k("ui.nav.scratch", "Raspadita (5 %)", "Scratch card (5%)")
k("ui.nav.ach", "Logros", "Achievements")
k("ui.close", "Cerrar", "Close")
k("ui.cancel", "Cancelar", "Cancel")
k("ui.ips", "+$%s/s", "+$%s/s")
k("ui.frenzy_on", "¡FRENESÍ! %d s", "FRENZY! %d s")
k("ui.frozen", "PRECIOS CONGELADOS (%d s)", "PRICES FROZEN (%d s)")
k("ui.rate", "Inflación: %s %% mensual", "Inflation: %s%% a month")
k("ui.prices", "Precios x%s desde que empezó la vuelta", "Prices x%s since this run started")
k("ui.per_click", "+$%s por clic", "+$%s per click")
k("ui.combo", "COMBO %s", "COMBO %s")
k("ui.crit", "CRÍTICO", "CRITICAL")
k("ui.collapse", "Los precios se te escaparon. ¡Hacé la reforma y empezá más fuerte!", "Prices got away from you. Do the reform and start stronger!")
k("ui.reform.btn", "Reformar ahora: +%d Credibilidad", "Reform now: +%d Credibility")
k("ui.reform.btn_at", "Reforma: cuando ganes %s en la vuelta (te falta %s)", "Reform: once you earn %s this run (%s to go)")
k("ui.reform.stuck", "Los precios se te escaparon. ¡Hacé la reforma y empezá más fuerte!", "Prices got away from you. Do the reform and start stronger!")
k("ui.reform.advice", "Buen momento para reformar: seguir en esta vuelta rinde cada vez menos.", "Good time to reform: staying in this run pays less and less.")
k("ui.reform.what", "¿Qué es la reforma monetaria?", "What is the monetary reform?")
k("ui.reform.what.1", "1. Le cortás ceros a la moneda: los precios vuelven a la normalidad.", "1. You cut zeros off the currency: prices go back to normal.")
k("ui.reform.what.2", "2. Empezás de nuevo: la plata, los negocios y las mejoras se reinician.", "2. You start over: money, businesses and upgrades reset.")
k("ui.reform.what.3", "3. Ganás Credibilidad para comprar mejoras permanentes en el árbol.", "3. You earn Credibility to buy permanent upgrades in the tree.")
k("ui.reform.what.4", "4. Con el árbol, la próxima vuelta va mucho más rápido.", "4. With the tree, the next run goes much faster.")
k("ui.summary.first", "¡Primera reforma! Ahora andá al árbol: con lo que compres ahí, la próxima vuelta va a ser mucho más rápida.", "First reform! Now go to the tree: what you buy there makes your next run much faster.")
k("ui.tree.recommend", "Comprá esto: tu próxima vuelta va a ser mucho más rápida", "Buy this: your next run will be much faster")
k("ui.remark.line", "Congela los precios %d s", "Freezes prices for %d s")
k("ui.rate_braked", "Inflación frenada (venía a %s %% mensual)", "Inflation held back (was heading to %s%% a month)")
k("ui.upgrades_next", "Próximas:", "Coming up:")
k("joke.0", "¡Aumentó el colectivo!", "The bus fare went up!")
k("joke.1", "El kiosquero remarcó los alfajores. Otra vez.", "The corner shop repriced the alfajores. Again.")
k("joke.2", "¡Subió la nafta! El carrito ahora empuja a pedal.", "Gas went up! The cart is now pedal-powered.")
k("joke.3", "Tu tía dice que antes con un peso comprabas todo.", "Your aunt says a peso used to buy everything.")
k("joke.4", "El almacenero ya escribe los precios en lápiz.", "The grocer now writes prices in pencil.")
k("joke.5", "¡Aumentó el boleto! Los clientes vienen caminando.", "Fares went up! Customers are walking now.")
k("joke.6", "El café cuesta lo mismo que una casa. La casa también.", "Coffee costs as much as a house. So does the house.")
k("joke.7", "La empanada de carne ahora es de carne de oro.", "The beef empanada is now gold-beef.")
k("joke.8", "Se agotaron las etiquetas para remarcar.", "The repricing stickers sold out.")
k("joke.9", "El vuelto ahora te lo dan en figuritas.", "Your change now comes in stickers.")
k("joke.10", "¡Aumentó la yerba! Esto ya es personal.", "Yerba mate went up! Now it's personal.")
k("joke.11", "Un economista en la tele pide calma. Aumentó la calma.", "An economist on TV asks for calm. Calm went up.")
k("joke.12", "El chori sale lo mismo que el auto que lo trae.", "The chori costs as much as the car delivering it.")
k("joke.13", "Los precios suben por la escalera... y por el ascensor.", "Prices take the stairs... and the elevator.")
k("ui.biz.more", "hay más abajo", "more below")
k("ui.biz.mystery", "Un negocio nuevo... ¿qué será?", "A new business... what could it be?")
k("ui.biz.locked_tree", "Se desbloquea en el árbol", "Unlocks in the tree")
k("ui.upg.locked", "Todavía está lejos: se habilita cuando cueste menos de 10 minutos de lo que ganás.", "Still far away: it unlocks when it costs less than 10 minutes of what you earn.")
k("ui.upg.missing", "te faltan %s", "%s to go")
k("ui.toast.fresh", "¡Moneda nueva, confianza nueva! Producción x10 los primeros 30 s.", "New currency, new trust! Production x10 for the first 30 s.")
k("ui.reform.btn_off", "Reforma monetaria (todavía no)", "Monetary reform (not yet)")
k("ui.reform.need", "La reforma corta los ceros y te da Credibilidad para el árbol: cuanto más lejos llegues, más te da.", "The reform cuts the zeros and gives you Credibility for the tree: the further you get, the more it gives.")
k("ui.reform.best", "Para ganar todo, igualá tu mejor vuelta (%s).", "To earn it all, match your best run (%s).")
k("ui.reform.hint", "Cuanto más lejos llegues en la vuelta, más Credibilidad te da la reforma.", "The further you get this run, the more Credibility the reform gives.")
k("ui.reform.demo", "La demo llega hasta la tercera reforma.", "The demo ends at the third reform.")
k("ui.reform.title", "Reforma monetaria", "Monetary reform")
k("ui.reform.gain", "Vas a ganar %d Credibilidad", "You will earn %d Credibility")
k("ui.reform.desc", "Llegaste a %s en %s. Se reinician la plata, los negocios, las mejoras y los precios. Se quedan el árbol, el álbum y los logros.", "You reached %s in %s. Money, businesses, upgrades and prices reset. The tree, the album and the achievements stay.")
k("ui.reform.confirm", "¡Cortar los ceros!", "Cut the zeros!")
k("ui.biz.each", "$%s/s cada uno", "$%s/s each")
k("ui.biz.next_ms", "x2 a los %d", "x2 at %d")
k("ui.upg.cost", "Cuesta %s", "Costs %s")
k("ui.toast.milestone", "¡Hito! %d de %s: producción x2", "Milestone! %d %s: production x2")
k("ui.toast.unlock", "¡Nuevo! %s", "New! %s")
k("ui.toast.upgrade", "Mejora nueva: %s (%s)", "New upgrade: %s (%s)")
k("ui.toast.page", "¡Página completa: %s!", "Page complete: %s!")
k("ui.toast.sticker", "Figurita: %s", "Sticker: %s")
k("ui.toast.auto_scratch", "Raspadita automática: %s", "Auto scratch card: %s")
k("ui.toast.ach", "¡Logro! %s", "Achievement! %s")
k("ui.toast.node", "Árbol: %s", "Tree: %s")
k("ui.old_save", "Tu partida era de la versión anterior (el tycoon). Empezás de cero en el clicker.", "Your save was from the previous version (the tycoon). You start fresh in the clicker.")
k("ui.tree.title", "Árbol de la Credibilidad", "Credibility tree")
k("ui.tree.help", "Arrastrá para moverte, rueda o +/- para el zoom. Comprar un nodo revela a sus vecinos. Los 6 sellos abren el centro: ESTABILIZAR LA ECONOMÍA.", "Drag to move, wheel or +/- to zoom. Buying a node reveals its neighbors. The 6 seals open the center: STABILIZE THE ECONOMY.")
k("ui.tree.center", "Centrar", "Center")
k("ui.tree.cred", "Credibilidad: %d", "Credibility: %d")
k("ui.tree.cost", "%d cred.", "%d cred.")
k("ui.ach.done", "LOGRADO:", "DONE:")
k("ui.tree.seal", "SELLO", "SEAL")
k("ui.tree.cap", "CAPSTONE", "CAPSTONE")
k("ui.tree.fog", "Todavía no se sabe qué hay acá. Comprá el nodo de al lado.", "Nobody knows what is here yet. Buy the node next to it.")
k("ui.tree.owned", "¡Comprado!", "Bought!")
k("ui.tree.buy", "Comprar (%d de Credibilidad)", "Buy (%d Credibility)")
k("ui.tree.full_game", "Juego completo", "Full game")
k("ui.tree.needs", "Necesita: %s", "Needs: %s")
k("ui.tree.missing", "Te faltan %d de Credibilidad", "You need %d more Credibility")
k("ui.branch.emp", "Rama EMPANADA", "EMPANADA branch")
k("ui.branch.neg", "Rama NEGOCIOS", "BUSINESS branch")
k("ui.branch.inf", "Rama INFLACIÓN", "INFLATION branch")
k("ui.branch.sue", "Rama SUERTE Y TIMBA", "LUCK & GAMBLING branch")
k("ui.branch.fig", "Rama FIGURITAS", "STICKERS branch")
k("ui.branch.ren", "Rama RENACER", "REBIRTH branch")
k("ui.branch.bridge", "Puente entre ramas", "Bridge between branches")
k("ui.branch.final", "El centro del árbol", "The center of the tree")
k("ui.ach.completion", "Completado: %s %%  ·  Árbol %d/%d  ·  Álbum %d/%d  ·  Logros %d/%d", "Completion: %s%%  ·  Tree %d/%d  ·  Album %d/%d  ·  Achievements %d/%d")
k("ui.ach.secret", "Logro secreto", "Secret achievement")
k("ui.ach.secret_d", "???", "???")
k("ui.summary.line", "Vuelta %d: llegaste a %s en %s - +%d Credibilidad", "Run %d: you reached %s in %s - +%d Credibility")
k("ui.summary.cmp", "Vuelta anterior: %s · %s · +%d", "Previous run: %s · %s · +%d")
k("ui.summary.note", "¡Billete nuevo para el álbum!", "New banknote for the album!")
k("ui.summary.tree", "Ir al árbol", "Go to the tree")
k("ui.summary.play", "Seguir jugando", "Keep playing")
k("ui.offline.away", "Estuviste afuera %s.", "You were away for %s.")
k("ui.offline.gain", "Tus negocios ganaron %s", "Your businesses earned %s")
k("ui.offline.note", "Sin vos la producción rinde un %d %% y la inflación no avanza.", "Without you production runs at %d%% and inflation stands still.")
k("ui.pack.free", "Abrir sobre de regalo (%d)", "Open gift pack (%d)")
k("ui.album.howto", "Figuritas: de los billetes voladores, las raspaditas, las noticias y los sobres (comprados o de regalo en cada reforma). Los billetes salen de las reformas. Cada página completa da un bonus permanente.", "Stickers: from flying banknotes, scratch cards, news and packs (bought or gifted on every reform). Banknotes come from reforms. Every complete page gives a permanent bonus.")
k("ui.credits.stats", "Tiempo: %s  -  Reformas: %d  -  Nodos: %d  -  Ceros cortados: %d", "Time: %s  -  Reforms: %d  -  Nodes: %d  -  Zeros cut: %d")
k("ui.credits.win", "¡ECONOMÍA ESTABILIZADA!", "ECONOMY STABILIZED!")
k("ui.menu.completion", "Completado: %s %%", "Completion: %s%%")
k("demo.stats", "Jugaste %s y le cortaste %d ceros a la moneda. El juego completo tiene el árbol entero, el final y el 100 %%.", "You played %s and cut %d zeros off the currency. The full game has the whole tree, the ending and the 100%%.")

# tutorial (solo la primera vuelta)
k("tut.v2.0", "¡Tocá la empanada! Cada clic es una venta (y si tocás rápido, combo).", "Poke the empanada! Every click is a sale (tap fast for a combo).")
k("tut.v2.1", "Comprá un carrito: vende solo.", "Buy a cart: it sells by itself.")
k("tut.v2.2", "¡Los precios suben solos! Remarcá para congelarlos un rato.", "Prices go up by themselves! Reprice to freeze them for a while.")
k("tut.v2.3", "¡Buen momento para la reforma monetaria! Tocá el botón que late.", "Good time for the monetary reform! Press the glowing button.")

# cómo se juega
k("howto.1", "TOCÁ", "TAP")
k("howto.1d", "Tocá la empanada (o la barra espaciadora). Rápido = combo.", "Poke the empanada (or press space). Fast = combo.")
k("howto.2", "COMPRÁ", "BUY")
k("howto.2d", "Negocios que venden solos y mejoras baratas en la fila de íconos.", "Businesses that sell by themselves and cheap upgrades in the icon row.")
k("howto.3", "REMARCÁ", "REPRICE")
k("howto.3d", "La inflación sube sola en cada vuelta. Remarcar congela los precios un rato.", "Inflation climbs by itself every run. Repricing freezes prices for a while.")
k("howto.4", "REFORMÁ", "REFORM")
k("howto.4d", "Cuando todo cuesta demasiado, cortá los ceros y ganá Credibilidad.", "When everything costs too much, cut the zeros and earn Credibility.")
k("howto.5", "CRECÉ", "GROW")
k("howto.5d", "Gastala en el árbol: cada vuelta va más rápido que la anterior.", "Spend it on the tree: every run goes faster than the last.")
k("howto.goal", "Meta: comprar el centro del árbol, ESTABILIZAR LA ECONOMÍA (más o menos 1 hora). El 100 %, en 3 o 4.", "Goal: buy the center of the tree, STABILIZE THE ECONOMY (about 1 hour). 100% takes 3 to 4.")

# capas visuales (las viejas eras)
k("era.1", "El puesto", "The stand")
k("era.2", "El barrio", "The neighborhood")
k("era.3", "La ciudad", "The city")
k("era.4", "Las finanzas", "High finance")
k("era.5", "¡HIPERINFLACIÓN!", "HYPERINFLATION!")

# billete volador
k("bill.money", "¡Billete! +%s", "Banknote! +%s")
k("bill.frenzy", "¡FRENESÍ!", "FRENZY!")
k("bill.frenzy.d", "producción x%d por %d s", "production x%d for %d s")
k("bill.freeze", "¡Precios congelados %d s!", "Prices frozen for %d s!")
k("bill.clickfrenzy", "¡CLIC FRENÉTICO! clics x30 por %d s", "CLICK FRENZY! clicks x30 for %d s")
k("bill.sticker", "¡Una figurita! %s", "A sticker! %s")
k("timba.frenzy", "producción x7 un rato", "production x7 for a while")
for o, es, en in [("nothing", "nada", "nothing"), ("x2", "x2", "x2"), ("x10", "¡x10!", "x10!"), ("pity", "x1,5 (consuelo)", "x1.5 (consolation)"), ("pack", "un sobre", "a pack"), ("golden", "¡una dorada!", "a golden one!"), ("frenzy", "¡frenesí!", "frenzy!")]:
    k("timba.res." + o, es, en)

# desbloqueos
for f, es, en in [("crit", "Clics críticos", "Critical clicks"), ("adv_biz", "Negocios avanzados: remisería y fábrica", "Advanced businesses: cab company and factory"),
                  ("manager", "El encargado compra negocios solo", "The manager buys businesses by himself"), ("excl_biz", "Negocios exclusivos: imprenta y holding", "Exclusive businesses: printing press and holding"),
                  ("events", "Noticias de último momento", "Breaking news"), ("auto_remark", "Remarcado automático", "Automatic repricing"),
                  ("infl_pays", "La inflación te paga", "Inflation pays you"), ("scratch", "Raspadita del kiosco", "Corner-shop scratch card"),
                  ("clickfrenzy", "Premio nuevo en los billetes: clic frenético", "New banknote prize: click frenzy"), ("auto_scratch", "Raspadita automática", "Automatic scratch card"),
                  ("album", "Álbum de figuritas (¡y un sobre de regalo!)", "Sticker album (and a gift pack!)"), ("autoclick", "Autoclicker de empanadas", "Empanada autoclicker")]:
    k("unlock." + f, es, en)

# mejoras
for i, (es, en) in enumerate([("Delantal", "Apron"), ("Cartel luminoso", "Neon sign"), ("Sucursal", "Branch office"), ("Franquicia", "Franchise")], 1):
    k("upg.short.biz_%d" % i, es, en)
k("upg.fx.biz", "%s x%s", "%s x%s")
k("upg.fx.click", "Clic x%s", "Click x%s")
k("upg.fx.click_pct", "Clic +%d %% de $/s", "Click +%d%% of $/s")
k("upg.fx.all", "Todo x%s", "Everything x%s")
k("upg.fx.syn", "%s +%d %% por %s", "%s +%d%% per %s")
for bid, pl, plen, sh, shen in [("empanadas", "Carritos", "Carts", "carrito", "cart"), ("kiosco", "Kioscos", "Shops", "kiosco", "shop"),
                                ("choripan", "Choris", "Choris", "chori", "chori"), ("lavadero", "Lavaderos", "Car washes", "lavadero", "car wash"),
                                ("panaderia", "Panaderías", "Bakeries", "panadería", "bakery"), ("almacen", "Almacenes", "Groceries", "almacén", "grocery"),
                                ("remiseria", "Remiserías", "Taxi cos.", "remisería", "taxi co."), ("fabrica", "Fábricas", "Factories", "fábrica", "factory"),
                                ("imprenta", "Imprentas", "Presses", "imprenta", "press"), ("holding", "Holdings", "Holdings", "holding", "holding")]:
    k("biz.%s.pl" % bid, pl, plen)
    k("biz.%s.sh" % bid, sh, shen)
for i, (es, en) in enumerate([("%s con delantal", "%s with an apron"), ("%s con cartel luminoso", "%s with a neon sign"), ("%s con sucursal", "%s with a branch office"), ("%s de franquicia", "%s franchise")], 1):
    k("upg.biz_%d" % i, es, en)
k("upg.biz.d", "%s produce %s.", "%s produces %s.")
for i, (es, en, ses, sen) in enumerate([
        ("%s a la calle", "%s on the high street", "Local a la calle", "Street front"), ("Cadena de %s", "%s chain", "Cadena", "Chain"),
        ("%s con marca registrada", "Trademarked %s", "Marca registrada", "Trademark"), ("%s de exportación", "Export-grade %s", "Exportación", "Export"),
        ("%s multinacional", "Multinational %s", "Multinacional", "Multinational"), ("Monopolio de %s", "%s monopoly", "Monopolio", "Monopoly"),
        ("Imperio de %s", "%s empire", "Imperio", "Empire"), ("%s de leyenda", "Legendary %s", "Leyenda", "Legend")], 5):
    k("upg.biz_%d" % i, es, en)
    k("upg.short.biz_%d" % i, ses, sen)
for cid, es, en, des, den in [
    ("clickt_1", "Callo en el dedo", "Finger callus", "Clic x2.", "Click x2."),
    ("clickt_2", "Billetera virtual", "Digital wallet", "Cada clic suma el 1 % de tu producción por segundo.", "Every click adds 1% of your production per second."),
    ("clickt_3", "Dedo de acero", "Steel finger", "Clic x2.", "Click x2."),
    ("clickt_4", "Cobro con QR", "QR checkout", "Cada clic suma otro 1 % de tu producción por segundo.", "Every click adds another 1% of your production per second."),
    ("clickt_5", "Mano biónica", "Bionic hand", "Clic x3.", "Click x3."),
    ("clickt_6", "Posnet de oro", "Golden card reader", "Cada clic suma un 2 % más de tu producción por segundo.", "Every click adds 2% more of your production per second."),
    ("clickt_7", "El dedo de Dios", "The finger of God", "Clic x3. Más polémico todavía.", "Click x3. Even more controversial.")]:
    k("upg." + cid, es, en); k("upg.%s.d" % cid, des, den)
for sid, es, en in [("syn_6", "El kiosco vende choripán", "The corner shop sells choripán"), ("syn_7", "Empanada y chori", "Empanada and chori"),
                    ("syn_8", "Chori para los que lavan", "Chori for the car washers"), ("syn_9", "Facturas en el kiosco", "Pastries at the corner shop"),
                    ("syn_10", "Lavado y mandados", "Wash and errands"), ("syn_11", "Remís al almacén", "Cab to the grocery"),
                    ("syn_12", "Pan industrial", "Industrial bread"), ("syn_13", "Billetes de fábrica", "Factory-made banknotes"),
                    ("syn_14", "Remises offshore", "Offshore cabs"), ("syn_15", "Imprenta del holding", "The holding's printing press")]:
    k("upg." + sid, es, en)
for i, (es, en) in enumerate([("Volanteada", "Flyers"), ("Aviso en la radio", "Radio ad"), ("Cartel en la ruta", "Highway billboard"),
                              ("Influencer del barrio", "Neighborhood influencer"), ("Promo 2x1", "2-for-1 deal"), ("Jingle pegadizo", "Catchy jingle"),
                              ("Spot en el entretiempo", "Halftime commercial"), ("Globo aerostático", "Hot-air balloon")]):
    k("upg.promo_%d" % i, es, en)
k("upg.promo.d", "Todos los negocios producen x1,03. Siempre hay otra campaña (cada una cuesta un poco más).", "All businesses produce x1.03. There is always another campaign (each costs a bit more).")
k("ui.upg.cond_biz", "a los %d %s", "at %d %s")
k("ui.upg.cond_clicks", "a los %d clics", "at %d clicks")
k("ui.upg.cond_clicks_total", "a los %d clics en total", "at %d total clicks")
k("ui.upg.locked_cond", "Se desbloquea %s.", "Unlocks %s.")

k("upg.syn.d", "%s produce +%d %% por cada %s.", "%s produces +%d%% per %s.")
k("upg.glob.d", "Todos los negocios producen %s.", "All businesses produce %s.")
for cid, es, en, des, den in [
    ("click_1", "Dedo índice", "Index finger", "Clic x2.", "Click x2."),
    ("click_2", "Dedo mayor", "Middle finger", "Clic x2 (sin mala intención).", "Click x2 (no offense meant)."),
    ("click_3", "Tarjeta de débito", "Debit card", "Cada clic suma también el 1 % de tu producción por segundo.", "Every click also adds 1% of your production per second."),
    ("click_4", "Muñeca de acero", "Steel wrist", "Clic x3.", "Click x3."),
    ("click_5", "Posnet portátil", "Portable card reader", "Cada clic suma otro 1 % de tu producción por segundo.", "Every click adds another 1% of your production per second."),
    ("click_6", "Mano de Dios", "Hand of God", "Clic x3. Polémico.", "Click x3. Controversial.")]:
    k("upg." + cid, es, en); k("upg.%s.d" % cid, des, den)
for sid, es, en in [("syn_1", "Empanadas en el kiosco", "Empanadas at the corner shop"), ("syn_2", "Choripán con gaseosa", "Choripán with soda"),
                    ("syn_3", "Pan recién lavado", "Freshly laundered bread"), ("syn_4", "Facturas al por mayor", "Pastries wholesale"), ("syn_5", "Remises de fábrica", "Factory cabs")]:
    k("upg." + sid, es, en)
for gid, es, en in [("glob_1", "Precios de lista", "List prices"), ("glob_2", "Delivery", "Delivery"), ("glob_3", "Tarjeta en 12 cuotas", "12 interest-free installments"), ("glob_4", "Pago con QR", "QR payments")]:
    k("upg." + gid, es, en)

# noticias
ev = [
 ("feriado", "¡FERIADO PUENTE! ¿Abrís igual?", "LONG WEEKEND! Do you open anyway?", "open", "Abrir: clics x5, negocios al 70 % (30 s)", "Open: clicks x5, businesses at 70% (30 s)", "rest", "Descansar: +45 s de producción", "Rest: +45 s of production"),
 ("aguinaldo", "¡Cobraste el aguinaldo!", "You got your year-end bonus!", "cash", "Gastarlo: +60 s de producción", "Spend it: +60 s of production", "invest", "Invertirlo: producción x2 por 60 s", "Invest it: production x2 for 60 s"),
 ("corrida", "¡CORRIDA CAMBIARIA! Todos al dólar", "CURRENCY RUN! Everyone to the dollar", "remark", "Remarcar todo: precios congelados 10 s, producción al 80 %", "Reprice everything: prices frozen 10 s, production at 80%", "hold", "Aguantar: inflación x2 y producción x1,5 por 20 s", "Hold on: inflation x2 and production x1.5 for 20 s"),
 ("paro", "PARO GENERAL: no vino nadie", "GENERAL STRIKE: nobody showed up", "overtime", "Pagar horas extra (20 s de producción)", "Pay overtime (20 s of production)", "close", "Cerrar 15 s (la inflación también para un poco)", "Close for 15 s (inflation slows down too)"),
 ("tarifazo", "¡TARIFAZO! Llegó la boleta de la luz", "UTILITY HIKE! The electricity bill arrived", "pay", "Pagarla (25 s de producción)", "Pay it (25 s of production)", "hook", "Colgarse del poste: producción x1,3, inflación x1,5 (40 s)", "Steal power: production x1.3, inflation x1.5 (40 s)"),
 ("turistas", "¡Llegó un micro de turistas!", "A tourist bus arrived!", "tourist", "Precio turista: producción x2 por 30 s", "Tourist price: production x2 for 30 s", "friend", "Precio amigo: una figurita y +20 s de producción", "Friendly price: a sticker and +20 s of production"),
]
for eid, q_es, q_en, a, a_es, a_en, b, b_es, b_en in ev:
    k("ev." + eid, q_es, q_en)
    k("ev.%s.%s" % (eid, a), a_es, a_en)
    k("ev.%s.%s" % (eid, b), b_es, b_en)
k("hl.ev.tarifazo", "Aumenta la luz: \"es para que la uses menos\", explicaron", "Electricity goes up: \"so you use less of it\", they explained")
k("hl.ev.turistas", "Turistas felices: \"¡todo es baratísimo!\" (por ahora)", "Happy tourists: \"everything is so cheap!\" (for now)")

# ---------------- árbol ----------------
N = []
def n(nid, es, en, des, den):
    k("node." + nid, es, en); k("node.%s.d" % nid, des, den)
n("final", "ESTABILIZAR LA ECONOMÍA", "STABILIZE THE ECONOMY", "El final. Inflación de un dígito, gente que ahorra en pesos y producción x2. Pide los 6 sellos. Después se puede seguir hasta el 100 %.", "The ending. Single-digit inflation, people saving in pesos and production x2. Needs the 6 seals. You can keep going to 100% afterwards.")
# EMPANADA
n("emp_1", "Empanada de horno", "Oven-baked empanada", "Clic x2.", "Click x2.")
n("emp_2a", "Dedo rápido", "Quick finger", "El combo llega a 30 (más multiplicador).", "The combo goes up to 30 (more multiplier).")
n("emp_2", "Repulgue firme", "Firm crimp", "Clic x2.", "Click x2.")
n("emp_2b", "Sabor a gloria", "Taste of glory", "Cada clic suma el 1 % de tu producción por segundo.", "Every click adds 1% of your production per second.")
n("emp_3a", "Racha", "Streak", "Cada punto de combo vale 50 % más.", "Each combo point is worth 50% more.")
n("emp_3", "Clic crítico", "Critical click", "5 % de chance de que un clic valga x5.", "5% chance for a click to be worth x5.")
n("emp_3b", "Masa madre", "Sourdough", "Clic x2.", "Click x2.")
n("emp_4a", "Combo paciente", "Patient combo", "El combo aguanta medio segundo más sin clics.", "The combo survives half a second longer without clicks.")
n("emp_4", "Empanada de oro", "Golden empanada", "SELLO. Clic x3.", "SEAL. Click x3.")
n("emp_4b", "Relleno extra", "Extra filling", "Cada clic suma otro 2 % de tu producción por segundo.", "Every click adds another 2% of your production per second.")
n("emp_5a", "Ojo de halcón", "Hawk eye", "+5 % de chance de crítico.", "+5% critical chance.")
n("emp_5", "Golpe maestro", "Master strike", "Los críticos valen el doble (x10).", "Criticals are worth double (x10).")
n("emp_5b", "Docena de 13", "Baker's dozen", "Clic x5.", "Click x5.")
n("emp_6a", "Combo eterno", "Eternal combo", "El combo llega a 50.", "The combo goes up to 50.")
n("emp_6", "Mano de horno", "Oven hand", "Cada clic suma otro 5 % de tu producción por segundo.", "Every click adds another 5% of your production per second.")
n("emp_6b", "Crítico en cadena", "Chain critical", "+10 % de chance de crítico.", "+10% critical chance.")
n("emp_7", "Autoclicker de empanadas", "Empanada autoclicker", "CAPSTONE. Una abuela toca la empanada 10 veces por segundo, para siempre.", "CAPSTONE. A grandma pokes the empanada 10 times a second, forever.")
n("emp_8", "Empanada infinita", "Infinite empanada", "Clic x5 y la abuela trae a una amiga (+10 clics/s).", "Click x5 and grandma brings a friend (+10 clicks/s).")
# NEGOCIOS
n("neg_1", "Socio del barrio", "Neighborhood partner", "Empezás cada vuelta con 5 carritos y producís x2.", "Start every run with 5 carts and produce x2.")
n("neg_2a", "Proveedor amigo", "Friendly supplier", "Los negocios cuestan 10 % menos.", "Businesses cost 10% less.")
n("neg_2", "Horario corrido", "Open all day", "Producción x1,5.", "Production x1.5.")
n("neg_2b", "Apertura con carrito", "Opening with a cart", "Cada vuelta empieza con 15 carritos y 5 kioscos.", "Every run starts with 15 carts and 5 corner shops.")
n("neg_3a", "Mayorista", "Wholesaler", "Los negocios cuestan otro 10 % menos.", "Businesses cost another 10% less.")
n("neg_3", "Negocios avanzados", "Advanced businesses", "Desbloquea la remisería y la fábrica.", "Unlocks the cab company and the factory.")
n("neg_3b", "Llave en mano", "Turnkey", "Cada vuelta empieza con 25 carritos, 12 kioscos y 5 choripanerías.", "Every run starts with 25 carts, 12 corner shops and 5 choripán stands.")
n("neg_4a", "Hitos triples", "Triple milestones", "Los hitos de 10/25/50/100 dan x2,5 en vez de x2.", "The 10/25/50/100 milestones give x2.5 instead of x2.")
n("neg_4", "Cadena de locales", "Chain of stores", "SELLO. Producción x2.", "SEAL. Production x2.")
n("neg_4b", "Sinergias", "Synergies", "Las mejoras de sinergia rinden el doble.", "Synergy upgrades are twice as good.")
n("neg_5a", "Precio de fábrica", "Factory price", "Los negocios cuestan 15 % menos.", "Businesses cost 15% less.")
n("neg_5", "Franquicias", "Franchises", "Producción x2,5.", "Production x2.5.")
n("neg_5b", "Inauguración", "Grand opening", "Cada vuelta empieza con 25 carritos, 15 kioscos y 10 choripanerías.", "Every run starts with 25 carts, 15 corner shops and 10 choripán stands.")
n("neg_6a", "Encargado", "Manager", "Un encargado compra el mejor negocio cada 2 segundos.", "A manager buys the best business every 2 seconds.")
n("neg_6", "Monopolio de barrio", "Neighborhood monopoly", "Producción x3.", "Production x3.")
n("neg_6b", "Producción en serie", "Mass production", "+0,1 % de producción por cada negocio que tengas.", "+0.1% production per business you own.")
n("neg_7", "Negocios exclusivos", "Exclusive businesses", "CAPSTONE. Desbloquea la imprenta de billetes y el holding de ceros.", "CAPSTONE. Unlocks the banknote printing press and the zeros holding.")
n("neg_8", "Holding multinacional", "Multinational holding", "Producción x4.", "Production x4.")
# INFLACIÓN
n("inf_1", "Precios cuidados", "Price watch", "Inflación -20 %.", "Inflation -20%.")
n("inf_2a", "Etiquetadora", "Label gun", "Remarcar congela 2 s más.", "Repricing freezes 2 s longer.")
n("inf_2", "Remarcador veloz", "Speedy repricer", "Remarcar recarga 5 s más rápido.", "Repricing recharges 5 s faster.")
n("inf_2b", "Noticias", "News", "Desbloquea las noticias de último momento: decisiones con premio.", "Unlocks breaking news: decisions with rewards.")
n("inf_3a", "Congelamiento largo", "Long freeze", "El premio \"precios congelados\" dura 10 s más.", "The \"prices frozen\" prize lasts 10 s longer.")
n("inf_3", "Ancla nominal", "Nominal anchor", "La inflación sube 10 % más despacio.", "Inflation climbs 10% slower.")
n("inf_3b", "Lectura del diario", "Reading the paper", "Las noticias buenas rinden 50 % más.", "Good news pays 50% more.")
n("inf_4a", "Remarcado automático", "Automatic repricing", "Remarca solo cada vez que se puede.", "Reprices by itself whenever it can.")
n("inf_4", "Banco central independiente", "Independent central bank", "SELLO. La inflación sube 10 % más despacio.", "SEAL. Inflation climbs 10% slower.")
n("inf_4b", "Indexación", "Indexation", "Con inflación de más del 50 % mensual, producción x1,5.", "With inflation above 50% a month, production x1.5.")
n("inf_5a", "Precios máximos", "Price caps", "Remarcar congela otros 2 s.", "Repricing freezes another 2 s.")
n("inf_5", "Metas de inflación", "Inflation targeting", "La inflación sube 10 % más despacio.", "Inflation climbs 10% slower.")
n("inf_5b", "Tablita", "Crawling peg", "Los precios suben solo el 90 % de lo que sube la inflación.", "Prices only rise 90% as much as inflation does.")
n("inf_6a", "Remarcador eléctrico", "Electric repricer", "Remarcar recarga otros 5 s más rápido.", "Repricing recharges another 5 s faster.")
n("inf_6", "Desinflación", "Disinflation", "La inflación sube 12 % más despacio.", "Inflation climbs 12% slower.")
n("inf_6b", "Convertibilidad de juguete", "Toy convertibility", "Los precios suben otro 10 % menos que la inflación.", "Prices rise another 10% less than inflation.")
n("inf_7", "La inflación te paga", "Inflation pays you", "CAPSTONE. +50 % de producción por cada cero que tengan los precios. Por fin.", "CAPSTONE. +50% production for every zero prices have. Finally.")
n("inf_8", "Moneda dura", "Hard currency", "La inflación sube 15 % más despacio.", "Inflation climbs 15% slower.")
# SUERTE
n("sue_1", "Billetes al viento", "Bills in the wind", "Los billetes voladores aparecen 15 % más seguido.", "Flying banknotes show up 15% more often.")
n("sue_2a", "Frenesí largo", "Long frenzy", "El frenesí dura 5 s más.", "Frenzy lasts 5 s longer.")
n("sue_2", "Raspadita del kiosco", "Corner-shop scratch card", "Desbloquea la raspadita: 5 % de tu plata por premios x2, x10, sobres o frenesí.", "Unlocks the scratch card: 5% of your money for x2, x10, packs or frenzy.")
n("sue_2b", "Viento a favor", "Tailwind", "Los billetes de plata dan el doble.", "Money banknotes pay double.")
n("sue_3a", "Billete doble", "Double banknote", "15 % de chance de que vengan dos billetes juntos.", "15% chance that two banknotes come together.")
n("sue_3", "Cábala", "Lucky charm", "Premios de la raspadita 50 % más probables.", "Scratch card prizes 50% more likely.")
n("sue_3b", "Clic frenético", "Click frenzy", "Premio nuevo en los billetes: clics x30 por 10 s.", "New banknote prize: clicks x30 for 10 s.")
n("sue_4a", "Frenesí x10", "Frenzy x10", "El frenesí multiplica x10 en vez de x7.", "Frenzy multiplies x10 instead of x7.")
n("sue_4", "Trébol de cuatro hojas", "Four-leaf clover", "SELLO. Los billetes aparecen 20 % más seguido.", "SEAL. Banknotes show up 20% more often.")
n("sue_4b", "Racha de suerte", "Lucky streak", "Después de 3 raspaditas perdidas, la próxima paga seguro.", "After 3 losing scratch cards, the next one always pays.")
n("sue_5a", "Billete lento", "Slow banknote", "Los billetes tardan 50 % más en cruzar.", "Banknotes take 50% longer to cross.")
n("sue_5", "Premio doble", "Double prize", "Billetes de plata x2 y frenesí 5 s más largo.", "Money banknotes x2 and frenzy 5 s longer.")
n("sue_5b", "Dorada a la vista", "Golden in sight", "Doble chance de dorada en la raspadita.", "Double golden chance on scratch cards.")
n("sue_6a", "Frenesí eterno", "Eternal frenzy", "El frenesí dura otros 5 s más.", "Frenzy lasts another 5 s longer.")
n("sue_6", "Suerte de campeón", "Champion's luck", "Los billetes aparecen 20 % más seguido.", "Banknotes show up 20% more often.")
n("sue_6b", "Número de la suerte", "Lucky number", "Premios de la raspadita otro 50 % más probables.", "Scratch card prizes another 50% more likely.")
n("sue_7", "Raspadita automática", "Automatic scratch card", "CAPSTONE. Cada 30 s se rasca sola una raspadita gratis.", "CAPSTONE. A free scratch card scratches itself every 30 s.")
n("sue_8", "Lluvia de billetes", "Raining money", "Billetes de plata x3 y más seguidos.", "Money banknotes x3 and more frequent.")
# FIGURITAS
n("fig_1", "Álbum de figuritas", "Sticker album", "Desbloquea el álbum (60 figuritas) y te regala un sobre.", "Unlocks the album (60 stickers) and gives you a pack.")
n("fig_2a", "Kiosquero amigo", "Friendly shopkeeper", "Los sobres cuestan la mitad.", "Packs cost half.")
n("fig_2", "Sobre de regalo", "Gift pack", "Cada reforma te regala un sobre.", "Every reform gives you a pack.")
n("fig_2b", "Figuritas al viento", "Stickers in the wind", "Los billetes voladores traen figuritas más seguido.", "Flying banknotes bring stickers more often.")
n("fig_3a", "Chupi barato", "Cheap swap", "El chupi cuesta 3 repetidas en vez de 5.", "Swapping costs 3 duplicates instead of 5.")
n("fig_3", "Pegatina brillante", "Shiny sticker", "Doble chance de figurita dorada.", "Double chance of a golden sticker.")
n("fig_3b", "Colección", "Collection", "+2 % de producción por cada figurita distinta.", "+2% production per different sticker.")
n("fig_4a", "Sobre de 6", "Pack of 6", "Los sobres traen 6 figuritas.", "Packs bring 6 stickers.")
n("fig_4", "Álbum lleno de vida", "Album full of life", "SELLO. Los bonus de página valen el doble.", "SEAL. Page bonuses are worth double.")
n("fig_4b", "Dos sobres", "Two packs", "Cada reforma regala otro sobre.", "Every reform gives another pack.")
n("fig_5a", "Sobre en oferta", "Pack on sale", "Los sobres cuestan la mitad otra vez.", "Packs cost half again.")
n("fig_5", "Figuritas doradas", "Golden stickers", "Otra vez el doble de chance de dorada.", "Double golden chance again.")
n("fig_5b", "Brillo", "Shine", "+5 % de producción por cada dorada.", "+5% production per golden sticker.")
n("fig_6a", "Chupi experto", "Expert swapper", "El chupi cuesta 2 repetidas.", "Swapping costs 2 duplicates.")
n("fig_6", "Coleccionista", "Collector", "+5 % de producción por cada figurita distinta.", "+5% production per different sticker.")
n("fig_6b", "Tres sobres", "Three packs", "Cada reforma regala un tercer sobre.", "Every reform gives a third pack.")
n("fig_7", "Edición especial", "Special edition", "CAPSTONE. Cada página completa multiplica la producción x1,5.", "CAPSTONE. Every complete page multiplies production x1.5.")
n("fig_8", "Museo del barrio", "Neighborhood museum", "+8 % de producción por cada figurita distinta.", "+8% production per different sticker.")
# RENACER
n("ren_1", "Memoria colectiva", "Collective memory", "+25 % de Credibilidad por reforma.", "+25% Credibility per reform.")
n("ren_2a", "Ahorro en el colchón", "Savings under the mattress", "Cada vuelta empieza con $25.000.", "Every run starts with $25,000.")
n("ren_2", "Discurso de cadena nacional", "National broadcast speech", "+20 % de Credibilidad.", "+20% Credibility.")
n("ren_2b", "Discurso convincente", "Convincing speech", "+2 de Credibilidad en cada reforma.", "+2 Credibility on every reform.")
n("ren_3a", "Primera venta", "First sale", "Los primeros 40 s de cada vuelta la producción va x10.", "For the first 40 s of every run production goes x10.")
n("ren_3", "Confianza", "Trust", "+25 % de Credibilidad.", "+25% Credibility.")
n("ren_3b", "Plazo fijo", "Fixed-term deposit", "Cada vuelta empieza con $50.000 más.", "Every run starts with $50,000 more.")
n("ren_4a", "Memoria de mejoras", "Upgrade memory", "Las mejoras de clic que compraste se conservan al reformar.", "The click upgrades you bought survive the reform.")
n("ren_4", "Prestigio", "Prestige", "SELLO. +30 % de Credibilidad.", "SEAL. +30% Credibility.")
n("ren_4b", "Promesa de campaña", "Campaign promise", "+5 de Credibilidad en cada reforma.", "+5 Credibility on every reform.")
n("ren_5a", "Herencia", "Inheritance", "Cada vuelta empieza con $50 M más.", "Every run starts with $50 M more.")
n("ren_5", "Reputación", "Reputation", "+30 % de Credibilidad.", "+30% Credibility.")
n("ren_5b", "Arranque rápido", "Quick start", "La producción x10 del arranque dura 30 s más.", "The x10 start-up production lasts 30 s longer.")
n("ren_6a", "Fondo anticíclico", "Countercyclical fund", "Cada vuelta empieza con $50 B más.", "Every run starts with $50 B more.")
n("ren_6", "Leyenda", "Legend", "+50 % de Credibilidad.", "+50% Credibility.")
n("ren_6b", "Siesta productiva", "Productive nap", "Sin jugar, la producción rinde 25 % en vez de 10 %.", "While away, production runs at 25% instead of 10%.")
n("ren_7", "Reforma perpetua", "Perpetual reform", "CAPSTONE. +50 % de Credibilidad. Ya reformás con los ojos cerrados.", "CAPSTONE. +50% Credibility. You reform with your eyes closed.")
n("ren_8", "Prócer en el billete", "National hero on the bill", "+50 % de Credibilidad. Tu cara en el billete de mil millones.", "+50% Credibility. Your face on the billion-peso bill.")
# PUENTES
n("br_1", "Empanada S.A.", "Empanada Inc.", "Puente EMPANADA-NEGOCIOS: +1 % al clic por cada negocio.", "EMPANADA-BUSINESS bridge: +1% click per business.")
n("br_2", "Precios de mayorista", "Wholesale prices", "Puente NEGOCIOS-INFLACIÓN: los negocios cuestan 30 % menos.", "BUSINESS-INFLATION bridge: businesses cost 30% less.")
n("br_3", "Timba cambiaria", "Currency gambling", "Puente INFLACIÓN-SUERTE: durante el frenesí los precios quedan congelados.", "INFLATION-LUCK bridge: prices stay frozen during frenzy.")
n("br_4", "Sobre sorpresa", "Surprise pack", "Puente SUERTE-FIGURITAS: los billetes traen todavía más figuritas.", "LUCK-STICKERS bridge: banknotes bring even more stickers.")
n("br_5", "Billete de colección", "Collector's banknote", "Puente FIGURITAS-RENACER: +5 % de Credibilidad por página completa.", "STICKERS-REBIRTH bridge: +5% Credibility per complete page.")
n("br_6", "Memoria muscular", "Muscle memory", "Puente RENACER-EMPANADA: 3 clics automáticos por segundo.", "REBIRTH-EMPANADA bridge: 3 automatic clicks per second.")

# ---------------- logros ----------------
A = [
("first_sale", "Primera venta", "First sale", "Tocá la empanada.", "Poke the empanada."),
("clicks_1000", "Tendinitis", "Tendinitis", "1.000 clics.", "1,000 clicks."),
("clicks_10000", "Dedo de acero", "Steel finger", "10.000 clics.", "10,000 clicks."),
("combo_20", "Combo de barrio", "Neighborhood combo", "Llegá a un combo de 20.", "Reach a 20 combo."),
("combo_40", "Combo eterno", "Eternal combo", "Llegá a un combo de 40.", "Reach a 40 combo."),
("first_crit", "¡Crítico!", "Critical!", "Hacé un clic crítico.", "Land a critical click."),
("crits_500", "Golpe de suerte serial", "Serial lucky strike", "500 clics críticos.", "500 critical clicks."),
("first_biz", "Emprendedor", "Entrepreneur", "Comprá tu primer negocio.", "Buy your first business."),
("biz_50", "PyME", "Small business", "50 negocios en una vuelta.", "50 businesses in one run."),
("biz_200", "Grupo empresario", "Business group", "200 negocios en una vuelta.", "200 businesses in one run."),
("carts_100", "Carritocracia", "Cartocracy", "100 carritos de empanadas a la vez.", "100 empanada carts at once."),
("adv_biz", "Remisero de confianza", "Trusted cab driver", "Abrí una remisería.", "Open a cab company."),
("excl_biz", "Imprimiendo billetes", "Printing money", "Abrí la imprenta de billetes.", "Open the banknote printing press."),
("holding", "Holding de ceros", "Zeros holding", "Abrí el holding de ceros.", "Open the zeros holding."),
("upg_20", "Mejora continua", "Continuous improvement", "20 mejoras en una vuelta.", "20 upgrades in one run."),
("upg_40", "Todo con mejoras", "Upgraded everything", "40 mejoras en una vuelta.", "40 upgrades in one run."),
("first_remark", "Remarcador", "Repricer", "Remarcá por primera vez.", "Reprice for the first time."),
("remarks_100", "Etiquetadora humana", "Human label gun", "Remarcá 100 veces.", "Reprice 100 times."),
("paranoid", "Paranoico", "Paranoid", "Remarcá antes de los 10 s de una vuelta, por las dudas.", "Reprice in the first 10 s of a run, just in case."),
("hyper", "Hiperinflación", "Hyperinflation", "Ver una inflación de 20 % mensual.", "See 20% monthly inflation."),
("hyper_1000", "¿Inflación? ¿Qué inflación?", "Inflation? What inflation?", "Tené $1.000 millones con la inflación frenada a cero.", "Hold $1 billion with inflation slowed down to zero."),
("million_nothing", "Millonario de nada", "Millionaire of nothing", "Tené un millón con la inflación arriba del 15 % mensual.", "Hold a million with inflation above 15% a month."),
("first_bill", "¡Un billete!", "A banknote!", "Atrapá un billete volador.", "Catch a flying banknote."),
("bills_50", "Cazador de billetes", "Banknote hunter", "Atrapá 50 billetes voladores.", "Catch 50 flying banknotes."),
("bill_missed", "Se voló", "Gone with the wind", "Dejá escapar un billete. Suele pasar.", "Let a banknote fly away. It happens."),
("frenzy_10", "Frenético", "Frantic", "10 frenesíes.", "10 frenzies."),
("first_reform", "Primera reforma", "First reform", "Cortale los ceros a la moneda.", "Cut the zeros off the currency."),
("reforms_10", "Cortador de ceros", "Zero cutter", "10 reformas.", "10 reforms."),
("reforms_25", "Reformista serial", "Serial reformer", "25 reformas.", "25 reforms."),
("fast_run", "Vuelta relámpago", "Lightning run", "Reformá en menos de 90 s ganando 10 o más de Credibilidad.", "Reform in under 90 s earning 10+ Credibility."),
("no_hands", "Manos en los bolsillos", "Hands in pockets", "Reformá habiendo tocado la empanada 10 veces o menos en la vuelta.", "Reform after poking the empanada 10 times or fewer in the run."),
("zeros_100", "Tijera de oro", "Golden scissors", "Cortá 100 ceros en total.", "Cut 100 zeros in total."),
("cred_100", "Creíble", "Credible", "Ganá 100 de Credibilidad en total.", "Earn 100 Credibility in total."),
("cred_10000", "Palabra santa", "Word of honor", "Ganá 10.000 de Credibilidad en total.", "Earn 10,000 Credibility in total."),
("nodes_10", "Ramitas", "Twigs", "10 nodos del árbol.", "10 tree nodes."),
("nodes_50", "Árbol frondoso", "Leafy tree", "50 nodos del árbol.", "50 tree nodes."),
("nodes_all", "Bosque nativo", "Native forest", "El árbol completo.", "The whole tree."),
("first_cap", "Cambio de juego", "Game changer", "Comprá un capstone.", "Buy a capstone."),
("all_caps", "Seis copas", "Six cups", "Los 6 capstones.", "All 6 capstones."),
("final", "Economía estable", "Stable economy", "Estabilizá la economía. ¿Quién lo hubiera dicho?", "Stabilize the economy. Who would have thought?"),
("first_pack", "Primer sobre", "First pack", "Abrí un sobre de figuritas.", "Open a sticker pack."),
("golden_1", "Brilla, brilla", "Shine bright", "Conseguí una figurita dorada.", "Get a golden sticker."),
("page_1", "Página completa", "Page complete", "Completá una página del álbum.", "Complete an album page."),
("album_full", "Álbum completo", "Album complete", "Las 60 figuritas.", "All 60 stickers."),
("first_trade", "¿Me la cambiás?", "Swap you?", "Hacé un chupi.", "Make a swap."),
("first_scratch", "Raspá y ganá", "Scratch and win", "Jugá una raspadita.", "Play a scratch card."),
("scratch_x10", "Diez veces", "Ten times", "Sacá x10 en la raspadita.", "Hit x10 on a scratch card."),
("bad_luck", "Mufa", "Jinxed", "Perdé 3 raspaditas seguidas.", "Lose 3 scratch cards in a row."),
("first_event", "Último momento", "Breaking news", "Leé tu primera noticia.", "Read your first news."),
("events_20", "Lector del diario", "Newspaper reader", "20 noticias.", "20 news."),
("billion_run", "Mil millones", "A billion", "Ganá $1.000 millones en una vuelta.", "Earn $1 billion in one run."),
("trillion_run", "Billonario", "Trillionaire", "Ganá $1 billón (un millón de millones) en una vuelta.", "Earn $1 trillion in one run."),
("two_hours", "Dos horitas nomás", "Just two hours", "Jugá 2 horas.", "Play for 2 hours."),
]
for aid, es, en, des, den in A:
    k("ach." + aid, es, en); k("ach.%s.d" % aid, des, den)

with open(out, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, quoting=csv.QUOTE_ALL, lineterminator="\n")
    w.writerow(["keys", "es", "en"])
    seen = set()
    for r in rows:
        assert r[0] not in seen, r[0]
        seen.add(r[0])
        w.writerow(r)
print(len(rows), "claves")
