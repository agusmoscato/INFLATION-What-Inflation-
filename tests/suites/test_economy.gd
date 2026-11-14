extends RefCounted
## Economía del clicker (diseño v2): clic y combo, negocios e hitos, mejoras, inflación, remarcar, billetes, noticias,
## reforma y Credibilidad.


func run(t) -> void:
	# ---- clic y combo ----
	var m: GameModel = GameModel.new(3)
	var r1: Dictionary = EconomyLogic.do_click(m, true)
	t.near((r1["value"] as BigNumber).to_float(), 1.0 * (1.0 + 0.05), "primer clic: $1 con combo 1")
	for i in range(30):
		EconomyLogic.do_click(m, true)
	t.eq(m.combo, 20, "el combo tiene tope 20")
	t.near(EconomyLogic.combo_mult(m), 2.0, "combo máximo = x2")
	EconomyLogic.tick(m, 1.5)
	t.eq(m.combo, 0, "sin clics 1 s el combo se cae")
	t.eq(m.clicks, 31, "clics contados")
	t.eq(m.max_combo, 20, "combo máximo registrado")
	var auto_before: int = m.run_manual_clicks
	EconomyLogic.do_click(m, false)
	t.eq(m.run_manual_clicks, auto_before, "los clics automáticos no cuentan como manuales")
	# ---- negocios: costo x1,15 por unidad y por P ----
	var mb: GameModel = GameModel.new(4)
	var cart: Dictionary = GameData.businesses[0]
	t.near(EconomyLogic.business_cost(mb, cart, 1).to_float(), 15.0, "el carrito cuesta 15")
	mb.money = BigNumber.from_float(1000.0)
	t.eq(EconomyLogic.buy_business(mb, "empanadas", 1), 1, "compra 1 carrito")
	t.near(EconomyLogic.business_cost(mb, cart, 1).to_float(), 15.0 * 1.15, "el segundo cuesta x1,15")
	t.near(EconomyLogic.business_cost(mb, cart, 3).to_float(), 15.0 * 1.15 * (pow(1.15, 3) - 1.0) / 0.15, "costo de 3 juntos (serie geométrica)")
	t.near(EconomyLogic.income_per_sec(mb).to_float(), 0.5, "un carrito produce 0,5/s")
	mb.ln_p = log(10.0)
	t.near(EconomyLogic.business_cost(mb, cart, 1).to_float(), 15.0 * 1.15 * 10.0, "con P = 10 todo cuesta x10")
	t.near(EconomyLogic.income_per_sec(mb).to_float(), 0.5, "la producción no sube con P")
	mb.ln_p = 0.0
	var n_max: int = EconomyLogic.max_affordable(mb, cart)
	t.check(EconomyLogic.business_cost(mb, cart, n_max).le(mb.money) and EconomyLogic.business_cost(mb, cart, n_max + 1).gt(mb.money), "máximo comprable exacto")
	# hitos x2 a las 10/25/50/100 unidades
	var mh: GameModel = GameModel.new(5)
	mh.owned["empanadas"] = 9
	mh.dirty = true
	var inc9: float = EconomyLogic.income_per_sec(mh).to_float()
	mh.money = BigNumber.from_float(1e6)
	EconomyLogic.buy_business(mh, "empanadas", 1)
	t.near(EconomyLogic.income_per_sec(mh).to_float(), inc9 / 9.0 * 10.0 * 2.0, "hito de 10 unidades: x2")
	var ms_sig: bool = false
	for n in mh.notifications:
		if n["sig"] == "milestone":
			ms_sig = true
	t.check(ms_sig, "el hito avisa")
	mh.owned["empanadas"] = 100
	mh.dirty = true
	t.near(EconomyLogic.income_per_sec(mh).to_float(), 0.5 * 100.0 * 16.0, "100 unidades: x16 (4 hitos)")
	# negocios avanzados y exclusivos se desbloquean en el árbol
	var ma: GameModel = GameModel.new(6)
	ma.money = BigNumber.from_string("1e15")
	t.eq(EconomyLogic.buy_business(ma, "remiseria", 1), 0, "la remisería necesita el nodo")
	ma.tree["neg_3"] = true
	ma.dirty = true
	t.eq(EconomyLogic.buy_business(ma, "remiseria", 1), 1, "con Negocios avanzados se puede")
	t.eq(EconomyLogic.buy_business(ma, "imprenta", 1), 0, "la imprenta es del capstone")
	# ---- mejoras ----
	var mu: GameModel = GameModel.new(7)
	t.eq(EconomyLogic.visible_upgrades(mu).size(), 0, "sin nada no hay mejoras")
	mu.money = BigNumber.from_float(1e4)
	EconomyLogic.buy_business(mu, "empanadas", 1)
	var vis: Array = EconomyLogic.visible_upgrades(mu)
	t.check(vis.size() >= 1 and vis[0]["id"] == "empanadas_1", "con 1 carrito aparece su primera mejora")
	var before: float = EconomyLogic.income_per_sec(mu).to_float()
	t.check(EconomyLogic.buy_upgrade(mu, "empanadas_1"), "compra la mejora")
	t.near(EconomyLogic.income_per_sec(mu).to_float(), before * 2.0, "la mejora duplica el carrito")
	mu.run_clicks = 15
	t.check(EconomyLogic.buy_upgrade(mu, "click_1"), "mejora de clic a los 15 clics")
	t.near(EconomyLogic.click_value(mu).to_float(), 2.0, "clic x2")
	t.eq(GameData.upgrades.size(), 55, "55 mejoras")
	# ---- inflación ----
	var mi: GameModel = GameModel.new(8)
	t.near(EconomyLogic.monthly_pct(mi), (exp(0.002 * 10.0) - 1.0) * 100.0, "inflación inicial ~2 % mensual")
	mi.owned["empanadas"] = 1
	mi.dirty = true
	for i in range(300):
		EconomyLogic.tick(mi, 1.0)
	t.check(EconomyLogic.monthly_pct(mi) > 100.0, "a los 5 min la inflación pasa el 100 por ciento mensual (%.0f)" % EconomyLogic.monthly_pct(mi))
	var p5: float = EconomyLogic.price_level(mi).log10()
	t.check(p5 > 2.0 and p5 < 5.0, "a los 5 min P está entre 100 y 100.000 (1e%.1f)" % p5)
	t.eq(EconomyLogic.era_of(mi), 5, "capa visual: Hiperinflación")
	# remarcar congela la inflación
	var mr: GameModel = GameModel.new(9)
	mr.run_time = 200.0
	t.check(EconomyLogic.remark(mr, true), "remarca")
	t.check(not EconomyLogic.remark(mr, true), "después hay que esperar la recarga")
	var lp: float = mr.ln_p
	EconomyLogic.tick(mr, 4.0)
	t.near(mr.ln_p, lp, "precios congelados: P no sube")
	EconomyLogic.tick(mr, 30.0)
	t.check(mr.ln_p > lp, "al terminar el congelamiento P vuelve a subir")
	t.check(EconomyLogic.can_remark(mr), "la recarga terminó")
	# ---- billete volador ----
	var mv: GameModel = GameModel.new(10)
	mv.owned["kiosco"] = 10
	mv.dirty = true
	mv.bill_timer = 0.1
	EconomyLogic.tick(mv, 0.2)
	t.eq(mv.bills_active.size(), 1, "aparece un billete")
	var bid: int = int(mv.bills_active[0]["id"])
	var r: Dictionary = EconomyLogic.click_bill(mv, bid, "frenzy")
	t.eq(str(r["kind"]), "frenzy", "premio frenesí")
	var base_inc: float = mv.base_income.to_float()
	t.near(EconomyLogic.income_per_sec(mv).to_float(), base_inc * 7.0, "frenesí x7")
	t.eq(mv.bills, 1, "billete contado")
	mv.bill_timer = 0.1
	EconomyLogic.tick(mv, 0.2)
	EconomyLogic.tick(mv, 30.0)
	t.eq(mv.bills_missed, 1, "un billete que no se toca se vuela")
	mv.bill_timer = 0.1
	EconomyLogic.tick(mv, 0.2)
	var money0: BigNumber = mv.money
	var rm: Dictionary = EconomyLogic.click_bill(mv, int(mv.bills_active[0]["id"]), "money")
	t.check(mv.money.gt(money0) and (rm["amount"] as BigNumber).gt(BigNumber.zero()), "premio en plata")
	var mf: GameModel = GameModel.new(11)
	mf.bill_timer = 0.1
	EconomyLogic.tick(mf, 0.2)
	EconomyLogic.click_bill(mf, int(mf.bills_active[0]["id"]), "freeze")
	t.check(mf.freeze_left >= 14.0, "premio: precios congelados 15 s")
	# ---- noticias ----
	var me: GameModel = GameModel.new(12)
	me.owned["kiosco"] = 5
	me.dirty = true
	EconomyLogic.start_event(me, "aguinaldo")
	t.check(not me.pending_choice.is_empty(), "la noticia espera una decisión")
	EconomyLogic.choose(me, 1)
	t.eq(me.active_events.size(), 1, "invertir el aguinaldo deja un efecto")
	t.near(EconomyLogic.income_per_sec(me).to_float(), me.base_income.to_float() * 2.0, "aguinaldo invertido: x2")
	EconomyLogic.start_event(me, "feriado")
	EconomyLogic.tick(me, 11.0)
	t.check(me.pending_choice.is_empty(), "si no se elige, a los 10 s se aplica la primera opción")
	t.check(not TreeLogic.has(GameModel.new(1), "events"), "las noticias se desbloquean en el árbol")
	# ---- reforma y Credibilidad ----
	var mc: GameModel = GameModel.new(13)
	t.check(not EconomyLogic.can_reform(mc), "sin plata no hay reforma")
	mc.run_earned = BigNumber.from_float(1e6)
	t.near(EconomyLogic.reform_gain_f(mc), 4.0, "Credibilidad = (log10(ganado) - 4)^2: $1 M da 4")
	t.check(not EconomyLogic.can_reform(mc), "la primera reforma espera el colapso")
	mc.collapse_shown = true
	t.check(EconomyLogic.can_reform(mc), "con el colapso se puede reformar")
	mc.owned["kiosco"] = 3
	mc.money = BigNumber.from_float(5e5)
	var s: Dictionary = EconomyLogic.do_reform(mc)
	t.eq(int(s["cred"]), 4, "la reforma dio 4")
	t.eq(mc.credibility, 4, "Credibilidad acumulada")
	t.eq(mc.reforms, 1, "1 reforma")
	t.check(mc.money.is_zero() and mc.owned.is_empty() and mc.run_earned.is_zero(), "se reinicia la vuelta")
	t.eq(mc.run_index, 2, "vuelta 2")
	t.eq(mc.album, [0], "el billete 0 al álbum")
	t.check(mc.zeros_cut >= 1, "la tijera corta al menos un cero")
	mc.run_earned = BigNumber.from_float(1e3)
	t.near(EconomyLogic.reform_gain_f(mc), 0.0, "una vuelta muy por debajo de la mejor no da Credibilidad")
	mc.run_earned = BigNumber.from_float(1e5)
	t.near(EconomyLogic.best_factor(mc), 0.5, "a 1 cero de la mejor vuelta cuenta la mitad")
	mc.run_earned = BigNumber.from_float(1e8)
	t.near(EconomyLogic.reform_gain_f(mc), 16.0, "superar la mejor vuelta cuenta completo")
	t.check(EconomyLogic.can_reform(mc), "desde la segunda reforma no hace falta el colapso")
	# colapso
	var mx: GameModel = GameModel.new(14)
	mx.owned["empanadas"] = 1
	mx.run_earned = BigNumber.from_float(1e6)
	mx.dirty = true
	mx.ln_p = log(1e4)
	EconomyLogic.tick(mx, 0.1)
	var col: bool = false
	for n in mx.notifications:
		if n["sig"] == "collapse":
			col = true
	t.check(col and mx.collapse_shown, "con precios x10.000 y la producción chica, la economía colapsa")
	# ---- offline ----
	var mo: GameModel = GameModel.new(15)
	mo.owned["kiosco"] = 9
	mo.dirty = true
	var rep: Dictionary = EconomyLogic.simulate_offline(mo, 1000.0)
	t.near((rep["gain"] as BigNumber).to_float(), 36.0 * 1000.0 * 0.10, "offline: 10 % de la producción")
	var cap: Dictionary = EconomyLogic.simulate_offline(mo, 1e6)
	t.check(bool(cap["capped"]), "offline con tope de 8 h")
	# ---- tutorial ----
	var mt: GameModel = GameModel.new(16)
	t.eq(EconomyLogic.tutorial_step(mt), 0, "tutorial: tocá la empanada")
	mt.clicks = 5
	t.eq(EconomyLogic.tutorial_step(mt), 1, "tutorial: comprá un carrito")
	mt.owned["empanadas"] = 1
	mt.run_time = 80.0
	t.eq(EconomyLogic.tutorial_step(mt), 2, "tutorial: remarcá")
	mt.remarks = 1
	mt.run_earned = BigNumber.from_float(1e6)
	mt.collapse_shown = true
	t.eq(EconomyLogic.tutorial_step(mt), 3, "tutorial: reformá")
	mt.reforms = 1
	t.eq(EconomyLogic.tutorial_step(mt), EconomyLogic.TUTORIAL_STEPS, "el tutorial dura solo la primera vuelta")
	# ---- bot: juega 7 minutos y reforma una vez entre los minutos 4 y 6 ----
	var mbot: GameModel = GameModel.new(17)
	var bot: BotPolicy = BotPolicy.new(17)
	var first: float = -1.0
	var tt: float = 0.0
	while tt < 420.0:
		if not bot.step(mbot, 0.25).is_empty() and first < 0.0:
			first = tt
		EconomyLogic.tick(mbot, 0.25)
		mbot.notifications.clear()
		tt += 0.25
	t.check(first >= 240.0 and first <= 360.0, "el bot reforma por primera vez entre los minutos 4 y 6 (%.1f)" % (first / 60.0))
