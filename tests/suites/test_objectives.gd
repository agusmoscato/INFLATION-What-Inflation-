extends RefCounted


func run(t) -> void:
	var m: GameModel = GameModel.new(9)
	t.eq(ObjectiveLogic.current(m)["id"], "click10", "el primer objetivo es hacer clics")
	for i in range(10):
		EconomyLogic.do_click(m)
	ObjectiveLogic.update(m)
	t.eq(ObjectiveLogic.current(m)["id"], "cart", "luego juntar para el carrito")
	var p: Dictionary = ObjectiveLogic.current(m)
	t.check(p["frac"] > 0.5, "progreso del carrito: 10/15")
	m.money = BigNumber.from_float(50.0)
	EconomyLogic.buy_business(m, "empanadas", 1)
	ObjectiveLogic.update(m)
	t.eq(ObjectiveLogic.current(m)["id"], "cart3", "luego tres carritos")
	# el índice solo avanza: reformar no hace retroceder la cadena
	var idx: int = m.obj_index
	m.owned = {}
	ObjectiveLogic.update(m)
	t.check(m.obj_index >= idx, "la cadena no retrocede")
	# la cadena cubre todo el juego y cada objetivo tiene texto en los dos idiomas
	t.check(ObjectiveLogic.count() >= 30, "al menos 30 objetivos")
	var ids: Dictionary = {}
	for o in ObjectiveLogic.LIST:
		t.check(not ids.has(o["id"]), "id único " + str(o["id"]))
		ids[o["id"]] = true
		t.check(I18n.has_key("obj." + str(o["id"]), "es") and I18n.has_key("obj." + str(o["id"]), "en"), "texto del objetivo " + str(o["id"]))
	var last: Dictionary = ObjectiveLogic.LIST[ObjectiveLogic.count() - 1]
	t.eq(last["kind"], "won", "el último objetivo es ganar")
	# desbloqueos: una mecánica nueva cada 2 o 3 minutos, solo cuando se usó la anterior
	var mu: GameModel = GameModel.new(9)
	t.check(not Unlocks.has(mu, "inflation"), "la inflación no está al empezar")
	t.check(not Unlocks.has(mu, "refuges"), "refugios bloqueados al inicio")
	t.check(not Unlocks.has(mu, "timba"), "timba bloqueada al inicio")
	mu.time_played = 125.0
	t.check(Unlocks.update(mu).is_empty(), "sin ningún negocio no se desbloquea la inflación")
	mu.owned["kiosco"] = 1
	t.eq(Unlocks.update(mu), ["inflation"], "minuto 2 con un negocio: inflación")
	mu.time_played = 235.0
	t.check(Unlocks.update(mu).is_empty(), "remarcar espera al minuto 4")
	mu.time_played = 245.0
	t.eq(Unlocks.update(mu), ["remark"], "minuto 4: remarcar")
	mu.time_played = 355.0
	t.check(Unlocks.update(mu).is_empty(), "mejoras esperan al minuto 6")
	mu.remarks = 1
	mu.time_played = 365.0
	t.eq(Unlocks.update(mu), ["upgrades"], "minuto 6: mejoras (después de remarcar)")
	mu.time_played = 530.0
	t.check(Unlocks.update(mu).is_empty(), "figuritas esperan al minuto 9")
	mu.upgrades["click1"] = true
	mu.time_played = 545.0
	t.eq(Unlocks.update(mu), ["album"], "minuto 9: figuritas (después de comprar una mejora)")
	# si el jugador no usa la mecánica anterior, igual se destraba pasado un rato (nadie se queda trabado)
	var mf: GameModel = GameModel.new(9)
	mf.unlocked["inflation"] = 100.0
	mf.unlocked["remark"] = 200.0
	mf.time_played = 330.0
	t.check(not Unlocks.used(mf, "remark"), "sin remarcar todavía no se usó")
	mf.time_played = 360.0
	t.check(Unlocks.used(mf, "remark"), "pasados 150 s se considera usada (no traba a nadie)")
	mu.era = 2
	mu.time_played = 600.0
	t.check(Unlocks.update(mu).is_empty(), "ni siquiera en Era 2 se desbloquea todo junto")
	var order: Array = []
	var clock: float = 700.0
	while order.size() < 4 and clock < 3000.0:
		mu.time_played = clock
		for f in Unlocks.update(mu):
			order.append([f, clock])
		clock += 10.0
	t.eq(str(order.map(func(p: Array) -> String: return p[0])), str(["refuges", "events", "timba", "reform"]), "Era 2: refugios, eventos, timba y reforma, de a uno")
	for i in range(1, order.size()):
		t.check(float(order[i][1]) - float(order[i - 1][1]) >= 150.0, "separación mínima entre %s y %s" % [order[i - 1][0], order[i][0]])
	t.check(not Unlocks.has(mu, "quiniela"), "la quiniela espera a la Era 3")
	mu.era = 3
	mu.time_played = clock + 200.0
	Unlocks.update(mu)
	mu.time_played += 200.0
	Unlocks.update(mu)
	t.check(Unlocks.has(mu, "quiniela") and Unlocks.has(mu, "dollar"), "Era 3: quiniela y timba del dólar")
	var md: GameModel = GameModel.new(9)
	md.demo_mode = true
	md.era = 3
	Unlocks.sync_silent(md)
	t.check(not Unlocks.has(md, "quiniela"), "la demo no incluye la quiniela")
	# una partida vieja (Era 2) lo tiene todo desbloqueado de entrada
	var mold: GameModel = GameModel.new(9)
	mold.era = 3
	Unlocks.sync_silent(mold)
	t.check(Unlocks.has(mold, "upgrades") and Unlocks.has(mold, "album") and Unlocks.has(mold, "reform") and Unlocks.has(mold, "quiniela"), "partida vieja: todo desbloqueado")
	# ¿le ganás a la inflación?
	var mr: GameModel = GameModel.new(9)
	mr.money = BigNumber.from_float(500.0)
	EconomyLogic.buy_business(mr, "empanadas", 5)
	EconomyLogic.month_end(mr)
	var r: Dictionary = EconomyLogic.race(mr)
	t.check(not r["winning"], "tras el aumento sin remarcar: la inflación te come")
	t.check(not (r["lost_ps"] as BigNumber).is_zero(), "se calcula cuánto te come")
	EconomyLogic.remark(mr, true)
	t.check(EconomyLogic.race(mr)["winning"], "remarcando le volvés a ganar")
	# tiempo estimado y meta chica
	var me: GameModel = GameModel.new(9)
	var first_eta: float = ObjectiveLogic.eta(me, ObjectiveLogic.LIST[0])
	t.near(first_eta, 10.0, "10 clics tardan ~10 s")
	t.check(ObjectiveLogic.reachable(me), "al inicio hay algo alcanzable")
	me.money = BigNumber.from_float(100.0)
	var micro: Dictionary = ObjectiveLogic.micro(me)
	t.check(not micro.is_empty(), "con $100 hay una meta chica")
	t.check(float(micro["eta"]) <= ObjectiveLogic.MICRO_MAX_ETA, "la meta chica es alcanzable rápido")
