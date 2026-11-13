extends RefCounted


func run(t) -> void:
	var m: GameModel = GameModel.new(7)
	t.near(m.price_level.to_float(), 1.0, "P inicial = 1")
	t.near(EconomyLogic.inflation_rate(m), 0.03, "tasa Era 1 = 3 %")
	# un mes = 30 s
	EconomyLogic.tick(m, 29.0)
	t.near(m.price_level.to_float(), 1.0, "antes de los 30 s no hay aumento")
	EconomyLogic.tick(m, 1.5)
	t.near(m.price_level.to_float(), 1.03, "a los 30 s sube 3 %")
	t.eq(m.month_count, 1, "un mes")
	# los costos suben con P
	var def: Dictionary = GameData.businesses[0]
	t.near(EconomyLogic.business_cost(m, def, 1).to_float(), 15.0 * 1.03, "costo sigue a P")
	# la plata pierde poder adquisitivo
	m.money = BigNumber.from_float(100.0)
	var pa: float = EconomyLogic.purchasing_power(m).to_float()
	for i in range(10):
		EconomyLogic.month_end(m)
	t.check(EconomyLogic.purchasing_power(m).to_float() < pa * 0.8, "el poder adquisitivo cae")
	# sin remarcar el ingreso real cae
	var m2: GameModel = GameModel.new(7)
	m2.money = BigNumber.from_float(100.0)
	EconomyLogic.buy_business(m2, "empanadas", 1)
	var real_before: float = EconomyLogic.income_per_sec(m2).div(m2.price_level).to_float()
	for i in range(20):
		EconomyLogic.month_end(m2)
	var real_after: float = EconomyLogic.income_per_sec(m2).div(m2.price_level).to_float()
	t.check(real_after < real_before * 0.6, "sin remarcar, el ingreso real se licua")
	EconomyLogic.remark(m2, true)
	t.near(EconomyLogic.income_per_sec(m2).div(m2.price_level).to_float(), real_before, "remarcar lo recupera")
	# eras cambian la tasa
	var m3: GameModel = GameModel.new(1)
	m3.era = 3
	t.near(EconomyLogic.inflation_rate(m3), 0.15, "tasa Era 3")
	m3.era = 5
	t.near(EconomyLogic.inflation_rate(m3), 1.0, "tasa Era 5 (hiperinflación)")
	# evento corrida duplica la tasa
	EconomyLogic.start_event(m3, "corrida")
	t.near(EconomyLogic.inflation_rate(m3), 2.0, "corrida x2")
	# la Credibilidad baja la inflación
	var m4: GameModel = GameModel.new(1)
	m4.credibility = 20
	t.check(EconomyLogic.inflation_rate(m4) < 0.03, "credibilidad baja la tasa")
	# medidas antiinflacionarias: tasa cero en Era 5 = victoria
	var m5: GameModel = GameModel.new(1)
	m5.era = 5
	m5.measures = 5
	t.near(EconomyLogic.inflation_rate(m5), 0.0, "5 medidas = tasa 0")
	EconomyLogic.month_end(m5)
	t.check(m5.won, "tasa cero en Era 5 gana")
	var m6: GameModel = GameModel.new(1)
	m6.era = 5
	m6.measures = 3
	t.near(EconomyLogic.inflation_rate(m6), 0.4, "3 medidas = 40 %")
	EconomyLogic.month_end(m6)
	t.check(not m6.won, "todavía no gana")
	# la inflación corre también offline
	var m7: GameModel = GameModel.new(1)
	m7.money = BigNumber.from_float(50.0)
	var rep: Dictionary = EconomyLogic.simulate_offline(m7, 600.0)
	t.eq(rep["months"], 20, "10 min offline = 20 meses")
	t.check(m7.price_level.to_float() > 1.7, "P creció offline")
	var m8: GameModel = GameModel.new(1)
	var rep2: Dictionary = EconomyLogic.simulate_offline(m8, 1e9)
	t.check(rep2["capped"], "el offline tiene tope")
	t.near(float(rep2["seconds"]), 12.0 * 3600.0, "tope 12 h")
