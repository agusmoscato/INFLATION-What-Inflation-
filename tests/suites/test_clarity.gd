extends RefCounted
## Claridad de jugabilidad: la acción recomendada, el objetivo accionable y el offline más justo.


func run(t) -> void:
	# --- Advisor: lo primero que se destaca es la empanada ---
	var m: GameModel = GameModel.new(3)
	t.eq(Advisor.recommend(m)["kind"], "click", "al empezar se destaca la empanada")
	for i in range(3):
		EconomyLogic.do_click(m)
	# con plata para el carrito, se destaca comprarlo
	m.money = BigNumber.from_float(100.0)
	var rec: Dictionary = Advisor.recommend(m)
	t.eq(rec["kind"], "buy", "con plata se destaca comprar")
	t.eq(rec["id"], "empanadas", "el carrito")
	# sin plata, seguir tocando (era 1)
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
	t.eq(Advisor.recommend(mr)["kind"], "remark", "con los precios al 50 % se destaca remarcar")
	t.check(Advisor.lag(mr) > 0.4, "atraso medido")
	# mecánica nueva sin abrir: se destaca la pestaña hasta abrirla
	var mt: GameModel = GameModel.new(3)
	for i in range(3):
		EconomyLogic.do_click(mt)
	mt.money = BigNumber.zero()
	mt.era = 2
	Unlocks.update(mt)
	var rt: Dictionary = Advisor.recommend(mt, [])
	t.eq(rt["kind"], "tab", "pestaña nueva destacada")
	var rt2: Dictionary = Advisor.recommend(mt, [1, 2, 3, 4, 5])
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
