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
	t.eq(ObjectiveLogic.current(m)["id"], "inflation", "luego esperar el primer aumento")
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
	# desbloqueos
	var mu: GameModel = GameModel.new(9)
	t.check(not Unlocks.has(mu, "refuges"), "refugios bloqueados al inicio")
	t.check(not Unlocks.has(mu, "timba"), "timba bloqueada al inicio")
	mu.era = 2
	var fresh: Array = Unlocks.update(mu)
	t.check(fresh.has("refuges") and fresh.has("timba") and fresh.has("reform") and fresh.has("events"), "la Era 2 desbloquea refugios, eventos, reforma y timba")
	t.check(Unlocks.update(mu).is_empty(), "no se anuncia dos veces")
	t.check(not Unlocks.has(mu, "quiniela"), "la quiniela espera a la Era 3")
	mu.era = 3
	t.check(Unlocks.has(mu, "quiniela") and Unlocks.has(mu, "dollar"), "Era 3: quiniela y timba del dólar")
	var md: GameModel = GameModel.new(9)
	md.demo_mode = true
	md.era = 3
	t.check(not Unlocks.has(md, "quiniela"), "la demo no incluye la quiniela")
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
