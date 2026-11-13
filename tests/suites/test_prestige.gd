extends RefCounted


func run(t) -> void:
	var m: GameModel = GameModel.new(3)
	t.check(not EconomyLogic.can_reform(m), "no se puede reformar al inicio")
	m.era = 2
	m.run_real = BigNumber.from_float(1e12)
	t.eq(EconomyLogic.credibility_possible(m), 63, "(1e12/1e6)^0.3 = 63")
	t.check(EconomyLogic.can_reform(m), "puede reformar en Era 2 con ganancias")
	m.money = BigNumber.from_float(5e6)
	m.price_level = BigNumber.from_string("1e4")
	m.owned["empanadas"] = 12
	m.upgrades["click1"] = true
	EconomyLogic.refuge_buy(m, "gold", BigNumber.from_float(1e6))
	var gold_before: BigNumber = m.refuge_units["gold"]
	var life: BigNumber = m.lifetime_real
	t.check(EconomyLogic.do_reform(m), "reforma")
	t.eq(m.credibility, 63, "gana 63 de Credibilidad")
	t.eq(m.reforms, 1, "1 reforma")
	t.check(m.money.is_zero(), "plata a cero")
	t.near(m.price_level.to_float(), 1.0, "P vuelve a 1")
	t.near(m.my_prices.to_float(), 1.0, "M vuelve a 1")
	t.eq(m.owned_count("empanadas"), 0, "negocios reseteados")
	t.check(m.upgrades.is_empty(), "mejoras reseteadas")
	t.eq(m.zeros_cut, 4, "se cortaron 4 ceros")
	t.eq(m.album.size(), 1, "billete en el álbum")
	t.check(m.lifetime_real.eq(life), "la ganancia histórica se conserva")
	t.check(m.refuge_units["gold"].approx_eq(gold_before.mul_f(0.5)), "refugios arrastran 50 %")
	t.eq(m.era, 2, "la era no baja")
	t.check(not EconomyLogic.can_reform(m), "sin ganancias nuevas no hay otra reforma")
	t.eq(EconomyLogic.reform_gain(m), 0, "ganancia 0")
	# el multiplicador de Credibilidad mejora el ingreso
	var m2: GameModel = GameModel.new(3)
	m2.money = BigNumber.from_float(100.0)
	EconomyLogic.buy_business(m2, "empanadas", 1)
	var base: float = EconomyLogic.income_per_sec(m2).to_float()
	m2.credibility = 100
	m2.dirty = true
	t.near(EconomyLogic.income_per_sec(m2).to_float(), base * 4.0, "100 de Credibilidad = x4")
	# más ganancias => más credibilidad
	m.run_real = BigNumber.from_float(1e15)
	t.eq(EconomyLogic.reform_gain(m), 501, "(1e15/1e6)^0.3 = 501")
	# álbum completo da bonus
	var m3: GameModel = GameModel.new(3)
	for i in range(12):
		m3.album.append(i)
	t.near(EconomyLogic.album_bonus(m3), 12 * 0.02 + 0.25, "bonus del álbum completo")
	# ingresos reales -> eras
	var m4: GameModel = GameModel.new(3)
	EconomyLogic.earn(m4, BigNumber.from_float(6e7))
	EconomyLogic.tick(m4, 0.1)
	t.eq(m4.era, 2, "la Era 2 llega con ganancias reales")
	# plan económico
	var m5: GameModel = GameModel.new(3)
	m5.era = 3
	m5.credibility = 30
	t.check(not EconomyLogic.can_plan(m5), "plan requiere Era 4")
	m5.era = 4
	t.check(EconomyLogic.can_plan(m5), "plan en Era 4")
	t.check(not EconomyLogic.do_plan(m5, "no_existe"), "plan inválido")
	t.check(EconomyLogic.do_plan(m5, "stabilization"), "hace el plan")
	t.eq(m5.plans_done, 1, "1 plan")
	t.eq(m5.credibility, 0, "credibilidad se reinicia")
	t.near(m5.legacy_cred, 15.0, "legado = 50 %")
	t.eq(m5.plan_id, "stabilization", "plan activo")
	t.near(EconomyLogic.inflation_rate(m5), 0.30 * 0.5 * (1.0 / (1.0 + 0.01 * 15.0)), "Estabilización baja la tasa")
	m5.money = BigNumber.from_float(100.0)
	EconomyLogic.buy_business(m5, "empanadas", 1)
	t.near(EconomyLogic.income_per_sec(m5).to_float(), 0.25 * (1.0 + 0.03 * 15.0) * 1.6 * 0.7, "ingreso con plan y legado")
	# Convertibilidad: shock periódico
	var m6: GameModel = GameModel.new(3)
	m6.era = 4
	m6.credibility = 30
	EconomyLogic.do_plan(m6, "convertibility")
	m6.month_count = 15
	var p0: float = m6.price_level.to_float()
	EconomyLogic.month_end(m6)
	t.check(m6.price_level.to_float() > p0 * 2.9, "salida de la convertibilidad: P x3")
	# cruzada: medidas
	var m7: GameModel = GameModel.new(3)
	m7.era = 4
	t.check(not EconomyLogic.buy_measure(m7), "medidas solo en Era 5")
	m7.era = 5
	m7.money = BigNumber.from_string("1e40")
	t.check(EconomyLogic.buy_measure(m7), "compra medida")
	t.eq(m7.measures, 1, "1 medida")
	# modo demo: límite en Era 2 y fin tras la primera reforma
	var md: GameModel = GameModel.new(3)
	md.demo_mode = true
	EconomyLogic.earn(md, BigNumber.from_string("1e30"))
	EconomyLogic.tick(md, 0.1)
	t.eq(md.era, 2, "demo: la era no pasa de 2 aunque haya ganancias de Era 5")
	t.check(not md.demo_finished, "demo: todavía no terminó")
	t.check(EconomyLogic.can_reform(md), "demo: se puede hacer la primera reforma")
	EconomyLogic.do_reform(md)
	t.check(md.demo_finished, "demo: terminó tras la primera reforma")
	var has_end: bool = false
	for n in md.notifications:
		if n["sig"] == "demo_end":
			has_end = true
	t.check(has_end, "demo: avisa el fin de la demo")
	var md2: GameModel = GameModel.new(3)
	md2.from_dict(md.to_dict())
	t.check(md2.demo_finished, "demo: el fin se guarda")
	var mfull: GameModel = GameModel.new(3)
	EconomyLogic.earn(mfull, BigNumber.from_string("1e30"))
	EconomyLogic.tick(mfull, 0.1)
	t.eq(mfull.era, 5, "juego completo: sin límite de era")
	t.check(DemoMode.STEAM_URL == "", "la URL de Steam queda vacía hasta tener el AppID")
