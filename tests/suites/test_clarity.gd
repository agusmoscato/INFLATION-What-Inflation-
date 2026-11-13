extends RefCounted
## Claridad de jugabilidad: la acción recomendada, el objetivo accionable y el offline más justo.


func run(t) -> void:
	# --- Advisor: lo primero que se destaca es la empanada ---
	var m: GameModel = GameModel.new(3)
	t.eq(Advisor.recommend(m)["kind"], "click", "al empezar se destaca la empanada")
	for i in range(10):
		EconomyLogic.do_click(m)
	ObjectiveLogic.update(m)
	# con plata para el carrito, se destaca comprarlo
	m.money = BigNumber.from_float(100.0)
	var rec: Dictionary = Advisor.recommend(m)
	t.eq(rec["kind"], "buy", "con plata se destaca comprar")
	t.eq(rec["id"], "empanadas", "el carrito")
	# con el primer negocio y sin plata, el objetivo manda: se señala la nota, no otra compra
	var mb: GameModel = GameModel.new(3)
	for i in range(10):
		EconomyLogic.do_click(mb)
	mb.money = BigNumber.from_float(100.0)
	EconomyLogic.buy_business(mb, "empanadas", 1)
	ObjectiveLogic.update(mb)
	mb.money = BigNumber.from_float(5.0)
	var rb: Dictionary = Advisor.recommend(mb)
	t.eq(rb["kind"], "objective", "ahorrando para el objetivo, la flecha va al objetivo")
	mb.money = BigNumber.from_float(500.0)
	t.check(Advisor.recommend(mb)["kind"] != "objective", "con plata, la flecha va a la compra del objetivo")
	# sin ningún negocio y sin plata, tocar la empanada
	m.money = BigNumber.zero()
	t.eq(Advisor.recommend(m)["kind"], "click", "sin plata: tocar la empanada")
	# una decisión de evento gana a todo
	m.pending_choice = {"id": "corrida", "remaining": 10.0}
	t.eq(Advisor.recommend(m)["kind"], "decision", "el evento pendiente se destaca primero")
	m.pending_choice = {}
	# precios muy viejos: remarcar
	var mr: GameModel = GameModel.new(3)
	for i in range(3):
		EconomyLogic.do_click(mr)
	mr.money = BigNumber.from_float(100.0)
	EconomyLogic.buy_business(mr, "empanadas", 1)
	mr.price_level = mr.price_level.mul_f(2.0)
	mr.unlocked["inflation"] = 100.0
	mr.unlocked["remark"] = 200.0
	t.eq(Advisor.recommend(mr)["kind"], "remark", "con los precios al 50 % se destaca remarcar")
	t.check(Advisor.lag(mr) > 0.4, "atraso medido")
	# mecánica nueva sin abrir: se destaca la pestaña hasta abrirla
	var mt: GameModel = GameModel.new(3)
	for i in range(3):
		EconomyLogic.do_click(mt)
	mt.money = BigNumber.zero()
	mt.unlocked["upgrades"] = 100.0      # recién desbloqueada y todavía sin abrir
	var rt: Dictionary = Advisor.recommend(mt, [])
	t.eq(rt["kind"], "tab", "pestaña nueva destacada")
	var rt2: Dictionary = Advisor.recommend(mt, [1])
	t.check(rt2["kind"] != "tab", "ya abiertas, deja de destacarse")

	# --- objetivo accionable ---
	var mo: GameModel = GameModel.new(3)
	var st0: Dictionary = ObjectiveLogic.status(mo, ObjectiveLogic.LIST[0])
	t.eq(st0["need"], "count", "los clics son una cuenta")
	t.eq(st0["n"], 10, "faltan 10 clics")
	t.eq(st0["go"]["kind"], "click", "ir = tocar la empanada")
	var cart: Dictionary = ObjectiveLogic.LIST[1]
	t.eq(cart["id"], "cart", "segundo objetivo: carrito")
	var st1: Dictionary = ObjectiveLogic.status(mo, cart)
	t.check(not st1["ready"] and st1["need"] == "money", "sin plata: falta plata")
	t.near((st1["money"] as BigNumber).to_float(), 15.0, "faltan $15")
	mo.money = BigNumber.from_float(20.0)
	var st2: Dictionary = ObjectiveLogic.status(mo, cart)
	t.check(st2["ready"], "con plata: ¡YA PODÉS!")
	t.eq(st2["go"]["id"], "empanadas", "ir = comprar el carrito")
	# todos los objetivos tienen estado calculable
	var mz: GameModel = GameModel.new(3)
	for o in ObjectiveLogic.LIST:
		var s: Dictionary = ObjectiveLogic.status(mz, o)
		t.check(s.has("ready") and s.has("need") and s.has("go"), "estado del objetivo " + str(o["id"]))

	# --- offline más justo: inflación al 50 % de velocidad y tope de 12 meses ---
	var m7: GameModel = GameModel.new(1)
	m7.money = BigNumber.from_float(50.0)
	var rep: Dictionary = EconomyLogic.simulate_offline(m7, 300.0)
	t.eq(rep["months"], 5, "5 min offline = 5 meses (mitad de velocidad)")
	var m8: GameModel = GameModel.new(1)
	var rep2: Dictionary = EconomyLogic.simulate_offline(m8, 3.0 * 3600.0)
	t.eq(rep2["months"], 12, "tope de 12 meses de inflación por ausencia")
	t.check(rep2.has("price_before") and rep2.has("price_after"), "el informe trae los precios")
	t.check((rep2["price_after"] as BigNumber).gt(rep2["price_before"]), "los precios subieron")
	# después del tope el ingreso sigue entrando (no se pierde el tiempo ausente)
	var m9: GameModel = GameModel.new(1)
	m9.money = BigNumber.from_float(100.0)
	EconomyLogic.buy_business(m9, "empanadas", 3)
	var before: BigNumber = m9.money
	var rep3: Dictionary = EconomyLogic.simulate_offline(m9, 2.0 * 3600.0)
	t.check(m9.money.gt(before), "el ingreso sigue después del tope de meses")
	t.eq(rep3["months"], 12, "12 meses aunque pasen 2 h")

	# --- ritmo inicial: sin inflación hasta el cartel "¡La inflación!" ---
	var mg: GameModel = GameModel.new(5)
	mg.intro_grace = true
	t.near(EconomyLogic.inflation_rate(mg), 0.0, "sin inflación al empezar")
	var p0: BigNumber = mg.price_level
	EconomyLogic.month_end(mg)
	t.check(mg.price_level.approx_eq(p0), "los precios no suben antes de la inflación")
	t.check(mg.remark_window <= 0.0, "y tampoco hay ventana de remarcar")
	mg.unlocked["inflation"] = 120.0
	t.check(EconomyLogic.inflation_rate(mg) > 0.0, "con el cartel arranca la inflación")
	EconomyLogic.month_end(mg)
	t.check(mg.price_level.gt(p0), "y ahí sí suben los precios")
	# primer carrito rápido y kiosco accesible
	var mq: GameModel = GameModel.new(5)
	t.near(EconomyLogic.business_cost(mq, GameData.businesses[0], 1).to_float(), 15.0, "el primer carrito cuesta $15 (15 clics, unos 5 s)")
	t.near(EconomyLogic.business_cost(mq, GameData.businesses[1], 1).to_float(), 60.0, "el kiosco cuesta $60")
	# la acción destacada y el objetivo apuntan siempre a lo mismo: con la plata del objetivo, la flecha va a ese negocio
	var mo2: GameModel = GameModel.new(5)
	mo2.money = BigNumber.from_float(1000.0)
	for i in range(10):
		EconomyLogic.do_click(mo2)
	ObjectiveLogic.update(mo2)
	var pick: Dictionary = Advisor.recommend(mo2)
	var want: Dictionary = ObjectiveLogic.status(mo2, ObjectiveLogic.LIST[mo2.obj_index])["go"]
	t.eq(pick["kind"], want["kind"], "la flecha va a lo que dice el objetivo")
	t.eq(pick["id"], want["id"], "y al mismo negocio")

	# --- tensión: la inflación sube por tramos entre los minutos 5 y 15 (solo en la primera vuelta) ---
	var mt2: GameModel = GameModel.new(5)
	mt2.intro_grace = true
	mt2.unlocked["inflation"] = 120.0
	mt2.time_played = 200.0
	t.near(EconomyLogic.inflation_rate(mt2), 0.03, "antes del minuto 6: 3 %")
	mt2.time_played = 400.0
	t.near(EconomyLogic.inflation_rate(mt2), 0.05, "tramo 1 (minutos 6 a 9): 5 %")
	mt2.time_played = 560.0
	t.near(EconomyLogic.inflation_rate(mt2), 0.03, "entre tramos: 3 %")
	mt2.time_played = 650.0
	t.near(EconomyLogic.inflation_rate(mt2), 0.08, "tramo 2 (minutos 10 a 13): 8 %")
	mt2.time_played = 900.0
	t.near(EconomyLogic.inflation_rate(mt2), 0.03, "después vuelve al 3 %")
	mt2.reforms = 1
	mt2.time_played = 650.0
	t.check(EconomyLogic.inflation_rate(mt2) < 0.08, "después de la primera reforma ya no hay tramos")
	mt2.reforms = 0
	var seen_before: int = mt2.tension_seen
	EconomyLogic.month_end(mt2)
	t.check(mt2.tension_seen > seen_before, "se anuncia el tramo con un aviso")
	# el semáforo se pone rojo si no se remarca ni se compra, y vuelve a verde al remarcar
	var ms2: GameModel = GameModel.new(5)
	ms2.intro_grace = true
	ms2.unlocked["inflation"] = 120.0
	ms2.unlocked["remark"] = 240.0
	ms2.time_played = 400.0
	ms2.money = BigNumber.from_float(1000.0)
	EconomyLogic.buy_business(ms2, "kiosco", 5)
	EconomyLogic.month_end(ms2)
	EconomyLogic.month_end(ms2)
	t.check(not EconomyLogic.race(ms2)["winning"], "sin remarcar, con 5 % por mes: semáforo en rojo")
	ms2.remark_window = 5.0
	EconomyLogic.remark(ms2, true)
	t.check(EconomyLogic.race(ms2)["winning"], "al remarcar vuelve al verde")
