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
	t.near(EconomyLogic.income_per_sec(mb).to_float(), 0.25, "un carrito produce 0,25/s")
	mb.ln_p = log(10.0)
	t.near(EconomyLogic.business_cost(mb, cart, 1).to_float(), 15.0 * 1.15 * 10.0, "con P = 10 todo cuesta x10")
	t.near(EconomyLogic.income_per_sec(mb).to_float(), 0.25, "la producción no sube con P")
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
	t.near(EconomyLogic.income_per_sec(mh).to_float(), 0.25 * 100.0 * 16.0, "100 unidades: x16 (4 hitos)")
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
	t.eq(EconomyLogic.visible_upgrades(mu).size(), 0, "las mejoras aparecen de a una, en el tick")
	EconomyLogic.tick(mu, 2.5)
	var vis: Array = EconomyLogic.visible_upgrades(mu)
	t.check(vis.size() == 1, "aparece una mejora (la más barata al alcance)")
	var e1: Dictionary = GameData.upgrades[GameData.upgrade_idx["empanadas_1"]]
	t.near(EconomyLogic.upgrade_cost(mu, e1).to_float(), 90.0 * EconomyLogic.cost_factor(mu).to_float(), "la primera mejora del carrito cuesta $90")
	mu.revealed["empanadas_1"] = true
	mu.run_clicks = 15
	EconomyLogic.tick(mu, 0.6)
	t.eq(EconomyLogic.visible_upgrades(mu).size(), 2, "en las primeras vueltas, una mejora nueva cada 10 s como mucho (la revelada + la del carrito)")
	EconomyLogic.tick(mu, 10.0)
	t.check(EconomyLogic.visible_upgrades(mu).size() >= 3, "a los 10 s aparece la siguiente")
	var far: Dictionary = GameData.upgrades[GameData.upgrade_idx["click_3"]]
	mu.run_clicks = 300
	t.check(not EconomyLogic.upgrade_in_reach(mu, far), "una mejora a más de 10 minutos de ingreso no está al alcance")
	EconomyLogic.tick(mu, 25.0)
	t.check(not mu.revealed.has("click_3"), "y no aparece en la fila")
	t.check(EconomyLogic.upcoming_upgrades(mu).has(far), "queda en Próximas")
	mu.run_clicks = 15
	var before: float = EconomyLogic.income_per_sec(mu).to_float()
	t.check(EconomyLogic.buy_upgrade(mu, "empanadas_1"), "compra la mejora")
	t.near(EconomyLogic.income_per_sec(mu).to_float(), before * 2.0, "la mejora duplica el carrito")
	t.check(EconomyLogic.buy_upgrade(mu, "click_1"), "mejora de clic a los 15 clics")
	t.near(EconomyLogic.click_value(mu).to_float(), 2.0, "clic x2")
	t.eq(GameData.upgrades.size(), 232, "232 mejoras (12 niveles por negocio, 13 de clic, 15 sinergias, 4 globales, 80 campañas)")
	# ---- inflación: atada al progreso de la vuelta, con freno y tope ----
	var mi: GameModel = GameModel.new(8)
	t.check(EconomyLogic.ln_limit(mi) <= 0.0, "sin producción el freno no deja subir los precios (12 clics no pagan el carrito de $15)")
	mi.owned["kiosco"] = 10
	mi.dirty = true
	var r0: float = EconomyLogic.raw_rate(mi)
	mi.run_earned = BigNumber.from_float(1e4)
	t.check(EconomyLogic.raw_rate(mi) > r0 * 5.0, "la inflación sube con lo ganado en la vuelta")
	var r_run: float = EconomyLogic.raw_rate(mi)
	mi.run_time = 3000.0
	t.near(EconomyLogic.raw_rate(mi), r_run, "y no con el reloj")
	mi.reforms = 3
	t.check(EconomyLogic.raw_rate(mi) > r_run, "la primera vuelta es más suave que las siguientes")
	mi.reforms = 0
	for i in range(600):
		EconomyLogic.tick(mi, 1.0)
		var cheap: BigNumber = EconomyLogic.cheapest_business(mi)
		var limit: BigNumber = mi.base_income.add(EconomyLogic.base_click_value(mi)).mul_f(30.0).add(EconomyLogic.base_click_value(mi).mul_f(30.0))
		if cheap.gt(limit) and mi.ln_p > 0.0:
			t.check(false, "freno: el negocio más barato no puede costar más que 30 s de ingreso + 30 clics (t=%d)" % i)
			break
	t.check(EconomyLogic.price_level(mi).log10() <= EconomyLogic.ln_cap(mi) / BigNumber.LN10 + 1e-6, "tope de la vuelta: los precios no pasan de x10^tope")
	t.near(EconomyLogic.ln_cap(mi) / BigNumber.LN10, 0.7, "en la vuelta 1 los precios no pasan de x5")
	# remarcar congela la inflación
	var mr: GameModel = GameModel.new(9)
	mr.run_time = 200.0
	mr.owned["kiosco"] = 50
	mr.run_earned = BigNumber.from_float(1e5)
	mr.dirty = true
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
	var ck: float = EconomyLogic.B("cred_k")
	var cc: float = EconomyLogic.B("cred_c")
	t.near(EconomyLogic.cred_curve(5.0), ck * pow(5.0 - cc, 2.0), "Credibilidad = k (log10(ganado) - c)^2")
	var tg: BigNumber = EconomyLogic.reform_target(mc)
	t.near(EconomyLogic.cred_curve(tg.log10()), 5.0, "la reforma se habilita cuando da 5 (%s)" % tg.format(), 0.001)
	t.check(tg.log10() < 4.5, "en la vuelta 1 el mínimo es bajo: menos de $32 K (%s)" % tg.format())
	mc.run_earned = tg.mul_f(0.99)
	t.check(not EconomyLogic.can_reform(mc), "un poco antes, todavía no")
	mc.run_earned = tg
	t.check(EconomyLogic.can_reform(mc), "desde ahí se puede reformar (sin esperar ningún colapso)")
	t.eq(EconomyLogic.reform_gain(mc), 5, "y da 5 de Credibilidad")
	mc.run_earned = BigNumber.from_float(1e5)
	t.near(EconomyLogic.reform_gain_f(mc), ck * pow(5.0 - cc, 2.0), "$100 K dan k (5 - c)^2")
	mc.owned["kiosco"] = 3
	mc.money = BigNumber.from_float(5e4)
	var s: Dictionary = EconomyLogic.do_reform(mc)
	var c100: int = int(floor(ck * pow(5.0 - cc, 2.0)))
	t.check(c100 >= 5 and c100 <= 10, "$100 K (unos 4-5 min de la primera vuelta) dan entre 5 y 10 (%d)" % c100)
	t.eq(int(s["cred"]), c100, "la reforma dio eso")
	t.eq(mc.credibility, c100, "Credibilidad acumulada")
	t.eq(mc.reforms, 1, "1 reforma")
	t.check(mc.money.is_zero() and mc.owned.is_empty() and mc.run_earned.is_zero(), "se reinicia la vuelta")
	t.eq(mc.run_index, 2, "vuelta 2")
	t.eq(mc.album, [0], "el billete 0 al álbum")
	t.check(mc.zeros_cut >= 1, "la tijera corta al menos un cero")
	t.near(EconomyLogic.reform_target(mc).log10(), maxf(4.5, cc + sqrt(5.0 / ck)), "vuelta 2: hay que llegar a medio cero de la mejor vuelta (o a lo que da 5)", 0.001)
	mc.best_run = BigNumber.from_float(1e9)
	t.near(EconomyLogic.reform_target(mc).log10(), 8.5, "con una mejor vuelta de $1.000 M hay que llegar a medio cero de ella", 0.001)
	mc.run_time = 130.0
	t.check(EconomyLogic.reform_target(mc).log10() < 5.0, "pasados 2 minutos esa regla ya no bloquea: alcanza con que dé 5")
	mc.run_time = 0.0
	mc.best_run = BigNumber.from_float(1e5)
	mc.run_earned = BigNumber.from_float(1e7)
	t.near(EconomyLogic.reform_gain_f(mc), ck * pow(7.0 - cc, 2.0), "la Credibilidad de la vuelta se cobra completa, sin importar la mejor vuelta")
	# trabado: 15 s sin poder comprar nada
	var mx: GameModel = GameModel.new(14)
	mx.run_earned = BigNumber.from_float(1e6)
	mx.owned["empanadas"] = 1
	mx.dirty = true
	EconomyLogic.tick(mx, 16.0)
	t.check(EconomyLogic.stuck(mx), "16 s sin poder comprar nada: trabado")
	EconomyLogic.tick(mx, 0.6)
	var col: bool = false
	for n in mx.notifications:
		if n["sig"] == "collapse":
			col = true
	t.check(col and EconomyLogic.reform_advised(mx), "trabado: el juego avisa y aconseja reformar")
	# ---- offline ----
	var mo: GameModel = GameModel.new(15)
	mo.owned["kiosco"] = 9
	mo.dirty = true
	var rep: Dictionary = EconomyLogic.simulate_offline(mo, 1000.0)
	t.near((rep["gain"] as BigNumber).to_float(), 18.0 * 1000.0 * 0.10, "offline: 10 % de la producción")
	var cap: Dictionary = EconomyLogic.simulate_offline(mo, 1e6)
	t.check(bool(cap["capped"]), "offline con tope de 8 h")
	# ---- tutorial ----
	var mt: GameModel = GameModel.new(16)
	t.eq(EconomyLogic.tutorial_step(mt), 0, "tutorial: tocá la empanada")
	mt.clicks = 5
	t.eq(EconomyLogic.tutorial_step(mt), 1, "tutorial: comprá un carrito")
	mt.owned["kiosco"] = 20
	mt.run_earned = BigNumber.from_float(3e4)
	mt.dirty = true
	mt.run_time = 80.0
	mt.ln_p = 0.5
	t.eq(EconomyLogic.tutorial_step(mt), 2, "tutorial: remarcá")
	mt.remarks = 1
	mt.run_earned = BigNumber.from_float(1e6)
	mt.run_time = 250.0
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
