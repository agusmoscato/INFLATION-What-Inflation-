extends RefCounted


func _fresh() -> GameModel:
	return GameModel.new(42)


func run(t) -> void:
	var m: GameModel = _fresh()
	# clic: $1 al inicio
	t.near(EconomyLogic.click_value(m).to_float(), 1.0, "un clic inicial vale $1")
	for i in range(20):
		EconomyLogic.do_click(m)
	t.near(m.money.to_float(), 20.0, "20 clics = $20")
	t.eq(m.clicks, 20, "contador de clics")
	# comprar negocio
	t.eq(EconomyLogic.buy_business(m, "empanadas", 1), 1, "compra la primera empanada")
	t.near(m.money.to_float(), 5.0, "cuesta $15")
	t.eq(EconomyLogic.buy_business(m, "kiosco", 1), 0, "kiosco no alcanza")
	t.eq(EconomyLogic.buy_business(m, "banco", 1), 0, "banco bloqueado por era")
	# el costo sube 15 % por unidad
	var def: Dictionary = GameData.businesses[0]
	t.near(EconomyLogic.business_cost(m, def, 1).to_float(), 15.0 * 1.22, "segundo cuesta 15*1,15")
	# producción
	EconomyLogic.tick(m, 10.0)
	t.near(EconomyLogic.income_per_sec(m).to_float(), 0.25, "ingreso 0,25/s")
	t.check(m.money.to_float() > 5.0, "el negocio produce")
	# compra en lote y máximo
	var m2: GameModel = _fresh()
	m2.money = BigNumber.from_float(1e6)
	var n: int = EconomyLogic.max_affordable(m2, GameData.businesses[0])
	t.check(n > 20, "max_affordable razonable (%d)" % n)
	var cost_n: BigNumber = EconomyLogic.business_cost(m2, GameData.businesses[0], n)
	var cost_n1: BigNumber = EconomyLogic.business_cost(m2, GameData.businesses[0], n + 1)
	t.check(cost_n.le(m2.money) and cost_n1.gt(m2.money), "max_affordable es exacto")
	t.eq(EconomyLogic.buy_business(m2, "empanadas", -1), n, "comprar máximo")
	t.eq(m2.owned_count("empanadas"), n, "owned actualizado")
	# lote 10 = suma de 10 compras individuales
	var m3: GameModel = _fresh()
	m3.money = BigNumber.from_float(1e9)
	var expected: float = 0.0
	for i in range(10):
		expected += 15.0 * pow(1.22, i)
	t.near(EconomyLogic.business_cost(m3, GameData.businesses[0], 10).to_float(), expected, "costo de lote x10", 1e-9)
	# hitos: x2 a las 25 unidades
	t.near(EconomyLogic.milestone_mult(24), 1.0, "hito 24")
	t.near(EconomyLogic.milestone_mult(25), 2.0, "hito 25")
	t.near(EconomyLogic.milestone_mult(100), 8.0, "hito 100")
	# mejoras
	var m4: GameModel = _fresh()
	m4.money = BigNumber.from_float(1000.0)
	t.check(EconomyLogic.buy_upgrade(m4, "click1"), "compra click1")
	t.check(not EconomyLogic.buy_upgrade(m4, "click1"), "no se compra dos veces")
	t.near(EconomyLogic.click_value(m4).to_float(), 2.0, "clic x2")
	t.check(not EconomyLogic.buy_upgrade(m4, "empanadas_a"), "mejora bloqueada sin 5 negocios")
	# remarcar
	var m5: GameModel = _fresh()
	m5.money = BigNumber.from_float(1000.0)
	EconomyLogic.buy_business(m5, "empanadas", 3)
	m5.price_level = BigNumber.from_float(2.0)
	t.check(EconomyLogic.needs_remark(m5), "hay que remarcar")
	var inc_before: float = EconomyLogic.income_per_sec(m5).to_float()
	m5.remark_window = 5.0
	var bonus: BigNumber = EconomyLogic.remark(m5, true)
	t.check(bonus.to_float() > 0.0, "bono por remarcar a tiempo")
	t.near(EconomyLogic.income_per_sec(m5).to_float(), inc_before * 2.0, "remarcar duplica ingreso nominal")
	t.check(not EconomyLogic.needs_remark(m5), "ya remarcado")
	# auto-remarcado
	var m6: GameModel = _fresh()
	m6.money = BigNumber.from_float(1e5)
	EconomyLogic.buy_upgrade(m6, "auto_remark1")
	m6.price_level = BigNumber.from_float(3.0)
	EconomyLogic.tick(m6, 25.0)
	t.check(not EconomyLogic.needs_remark(m6), "auto-remarcado funciona")
	# refugios
	var m7: GameModel = _fresh()
	m7.era = 2
	m7.money = BigNumber.from_float(1000.0)
	t.check(EconomyLogic.refuge_buy(m7, "bricks", BigNumber.from_float(1000.0)), "comprar ladrillos")
	t.check(m7.money.is_zero(), "plata gastada")
	t.near(EconomyLogic.refuge_value(m7, "bricks").to_float(), 940.0, "comisión 6 %")
	t.check(EconomyLogic.refuge_sell(m7, "bricks", 1.0), "vender ladrillos")
	t.near(m7.money.to_float(), 940.0 * 0.94, "doble comisión", 1e-6)
	# cepo bloquea refugios
	m7.money = BigNumber.from_float(100.0)
	EconomyLogic.start_event(m7, "cepo")
	t.check(not EconomyLogic.refuge_buy(m7, "gold", BigNumber.from_float(50.0)), "cepo bloquea compra")
	EconomyLogic.update_events(m7, 61.0, false)
	t.check(EconomyLogic.refuge_buy(m7, "gold", BigNumber.from_float(50.0)), "cepo termina")
	# dólar protege (se desvaloriza menos que la inflación)
	var m8: GameModel = _fresh()
	m8.era = 2
	m8.money = BigNumber.from_float(1e4)
	EconomyLogic.refuge_buy(m8, "usd", BigNumber.from_float(1e4))
	var before: float = EconomyLogic.refuge_value(m8, "usd").div(m8.price_level).to_float()
	for i in range(6):
		EconomyLogic.month_end(m8)
	var after: float = EconomyLogic.refuge_value(m8, "usd").div(m8.price_level).to_float()
	t.check(after > before * 0.7, "el dólar conserva valor real (%.0f -> %.0f)" % [before, after])
	# eventos
	var m9: GameModel = _fresh()
	m9.era = 2
	m9.base_income = BigNumber.from_float(10.0)
	m9.dirty = false
	EconomyLogic.start_event(m9, "aguinaldo")
	t.near(EconomyLogic.event_income_mult(m9), 2.0, "aguinaldo duplica")
	t.eq(m9.events_seen, 1, "evento contado")
	EconomyLogic.update_events(m9, 31.0, false)
	t.near(EconomyLogic.event_income_mult(m9), 1.0, "aguinaldo expira")
	# paro: se puede negociar
	var m10: GameModel = _fresh()
	m10.era = 2
	EconomyLogic.start_event(m10, "paro")
	t.check(EconomyLogic.settle_strike(m10), "negociar paro (costo 0 sin ingresos)")
	t.check(not EconomyLogic.has_event(m10, "paro"), "paro terminado")
	# compra inteligente: arranca con clics, luego compra negocios
	var m11: GameModel = _fresh()
	m11.money = BigNumber.from_float(20.0)
	t.check(EconomyLogic.smart_buy(m11), "smart_buy compra algo")
	t.eq(m11.owned_count("empanadas"), 1, "lo primero rentable es una empanada")
