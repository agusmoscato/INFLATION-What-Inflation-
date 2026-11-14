class_name EconomyLogic
extends RefCounted
## Toda la lógica económica del clicker (diseño v2), sin nodos ni autoloads: testeable y simulable headless.
## Una vuelta: clic + negocios + mejoras contra la inflación, que sube sola (reloj τ) y hace que todo cueste × P.
## La reforma reinicia la vuelta y da Credibilidad para el árbol.


static func B(key: String) -> float:
	return GameData.B(key)


# =====================================================================
#  Derivados
# =====================================================================
static func ensure_fresh(m: GameModel) -> void:
	if m.dirty:
		recalc(m)


static func milestone_count(n: int) -> int:
	var c: int = 0
	for t in GameData.balance["milestones"]:
		if n >= int(t):
			c += 1
	return c


static func golden_owned(m: GameModel) -> int:
	var n: int = 0
	for id in m.stickers:
		if StickerLogic.def(id)["rarity"] == "golden":
			n += 1
	return n


static func recalc(m: GameModel) -> void:
	m.dirty = false
	m.mods = TreeLogic.compute_mods(m)
	var md: Dictionary = m.mods
	var biz_up: Dictionary = {}
	var syn: Dictionary = {}
	var all_mult: float = 1.0
	var cm: float = float(md["click_mult"])
	var cp: float = float(md["click_pct"])
	for uid in m.upgrades:
		var u: Dictionary = GameData.upgrades[GameData.upgrade_idx[uid]]
		var fx: Dictionary = u["fx"]
		match str(fx["type"]):
			"biz_mult":
				biz_up[fx["biz"]] = float(biz_up.get(fx["biz"], 1.0)) * float(fx["value"])
			"click_mult":
				cm *= float(fx["value"])
			"click_pct":
				cp += float(fx["value"])
			"synergy":
				syn[fx["biz"]] = float(syn.get(fx["biz"], 0.0)) + float(fx["value"]) * float(md["synergy_mult"]) * float(m.owned_count(fx["other"]))
			"all_mult":
				all_mult *= float(fx["value"])
	var buildings: int = m.total_businesses()
	var pages: int = StickerLogic.pages_done(m)
	var gm: float = float(md["prod_mult"]) * all_mult
	gm *= 1.0 + float(md["album_income"])
	gm *= 1.0 + float(md["collection"]) * float(m.stickers.size())
	gm *= 1.0 + float(md["gold_bonus"]) * float(golden_owned(m))
	gm *= pow(float(md["page_prod"]), float(pages))
	gm *= 1.0 + float(md["per_building"]) * float(buildings)
	var base: BigNumber = BigNumber.zero()
	m.biz_income = {}
	for def in GameData.businesses:
		var n: int = m.owned_count(def["id"])
		if n == 0:
			continue
		var bm: float = float(biz_up.get(def["id"], 1.0)) * pow(float(md["milestone_mult"]), float(milestone_count(n)))
		bm *= 1.0 + float(syn.get(def["id"], 0.0))
		var inc: BigNumber = def["base_income"].mul_f(float(n) * bm * gm)
		m.biz_income[def["id"]] = inc
		base = base.add(inc)
	m.base_income = base
	m.click_mult = cm * (1.0 + float(md["click_per_building"]) * float(buildings))
	m.click_pct = cp


# =====================================================================
#  Inflación
# =====================================================================
## ln P acumulado en la vuelta (sube con la tasa salvo con precios congelados).
static func ln_price(m: GameModel) -> float:
	return m.ln_p


static func exp_big(x: float) -> BigNumber:
	var l10: float = x / BigNumber.LN10
	var e: int = floori(l10)
	return BigNumber.new(pow(10.0, l10 - float(e)), e)


static func price_level(m: GameModel) -> BigNumber:
	return exp_big(ln_price(m))


## Lo que multiplica a todos los precios de la vuelta (P, o P^k con la Tablita).
static func cost_factor(m: GameModel) -> BigNumber:
	ensure_fresh(m)
	return exp_big(ln_price(m) * float(m.mods["cost_p_exp"]))


static func event_mult(m: GameModel, key: String) -> float:
	var r: float = 1.0
	for ev in m.active_events:
		r *= float(ev["fx"].get(key, 1.0))
	return r


static func infl_speed(m: GameModel) -> float:
	ensure_fresh(m)
	return float(m.mods["infl_speed"]) * maxf(0.3, 1.0 - float(m.mods["album_inflation"])) * event_mult(m, "infl_mult")


## Tasa instantánea (por segundo) sin contar el congelamiento: r = A · velocidad · e^(t/T), con t = tiempo de la vuelta.
## Sube sola durante la vuelta (se duplica cada ~54 s): esa es la pared. El árbol baja la velocidad.
static func rate_per_sec(m: GameModel) -> float:
	return B("infl_base") * exp(m.run_time / B("infl_T")) * infl_speed(m)


## Inflación "mensual" que se muestra (1 mes = 10 s), en %.
static func monthly_pct(m: GameModel) -> float:
	return (exp(rate_per_sec(m) * B("month_seconds")) - 1.0) * 100.0


static func frozen(m: GameModel) -> bool:
	return m.freeze_left > 0.0


## Capa visual (los nombres de las viejas eras): por lo ganado en la vuelta; Hiperinflación si la mensual pasa el 100 %.
static func era_of(m: GameModel) -> int:
	if monthly_pct(m) >= B("hyper_month_pct"):
		return 5
	var e: int = 1
	for i in range(1, GameData.era_thresholds.size()):
		if m.run_earned.ge(GameData.era_thresholds[i]):
			e = i + 1
	return e


# =====================================================================
#  Producción y clic
# =====================================================================
static func earn(m: GameModel, nominal: BigNumber) -> void:
	m.money = m.money.add(nominal)
	m.run_earned = m.run_earned.add(nominal)


## Producción por segundo (con frenesí, eventos, arranque rápido, indexación y "la inflación te paga").
static func income_per_sec(m: GameModel) -> BigNumber:
	ensure_fresh(m)
	var md: Dictionary = m.mods
	var k: float = event_mult(m, "prod_mult")
	if m.frenzy_left > 0.0:
		k *= float(md["frenzy_mult"])
	if m.run_time < float(md["early_boost_s"]):
		k *= B("early_boost_mult")
	if float(md["indexation"]) > 0.0 and monthly_pct(m) >= 50.0:
		k *= 1.0 + float(md["indexation"])
	if float(md["infl_pays"]) > 0.0:
		k *= 1.0 + float(md["infl_pays"]) * ln_price(m) / BigNumber.LN10      # "la inflación te paga": +50 % por cada cero de P
	return m.base_income.mul_f(k)


static func combo_mult(m: GameModel) -> float:
	return 1.0 + float(m.mods.get("combo_step", B("combo_step"))) * float(m.combo)


static func click_value(m: GameModel) -> BigNumber:
	ensure_fresh(m)
	var k: float = (B("click_base") + float(m.mods["click_add"])) * m.click_mult * combo_mult(m) * event_mult(m, "click_mult")
	if m.clickfrenzy_left > 0.0:
		k *= B("clickfrenzy_mult")
	var v: BigNumber = BigNumber.from_float(k)
	if m.click_pct > 0.0:
		v = v.add(income_per_sec(m).mul_f(m.click_pct * combo_mult(m)))
	return v


## Un clic en la empanada. `manual` = del jugador (arma combo); los del autoclicker no.
## Devuelve {value: BigNumber, crit: bool, combo: int}.
static func do_click(m: GameModel, manual: bool = true) -> Dictionary:
	ensure_fresh(m)
	if manual:
		if m.combo_idle <= float(m.mods["combo_window"]):
			m.combo = mini(m.combo + 1, int(m.mods["combo_cap"]))
		else:
			m.combo = 1
		m.combo_idle = 0.0
		m.max_combo = maxi(m.max_combo, m.combo)
		m.run_manual_clicks += 1
	var v: BigNumber = click_value(m)
	var crit: bool = float(m.mods["crit_chance"]) > 0.0 and m.rng.randf() < float(m.mods["crit_chance"])
	if crit:
		v = v.mul_f(float(m.mods["crit_mult"]))
		m.crits += 1
	earn(m, v)
	m.clicks += 1
	m.run_clicks += 1
	return {"value": v, "crit": crit, "combo": m.combo}


# =====================================================================
#  Negocios
# =====================================================================
static func growth_pow(k: float) -> BigNumber:
	return BigNumber.from_float(B("cost_growth")).pow_f(k)


static func business_available(m: GameModel, def: Dictionary) -> bool:
	var u: String = str(def["unlock"])
	if u == "":
		return true
	ensure_fresh(m)
	return bool(m.mods.get(u, false))


static func business_cost(m: GameModel, def: Dictionary, qty: int = 1) -> BigNumber:
	ensure_fresh(m)
	var first: BigNumber = def["base_cost"].mul(growth_pow(float(m.owned_count(def["id"])))).mul(cost_factor(m)).mul_f(float(m.mods["cost_mult"]))
	if qty <= 1:
		return first
	return first.mul(growth_pow(float(qty)).sub(BigNumber.one())).div_f(B("cost_growth") - 1.0)


static func max_affordable(m: GameModel, def: Dictionary) -> int:
	var unit: BigNumber = business_cost(m, def, 1)
	if unit.gt(m.money):
		return 0
	var g: float = B("cost_growth")
	var t: BigNumber = m.money.div(unit).mul_f(g - 1.0).add_f(1.0)
	var n: int = clampi(floori(t.log10() / (log(g) / BigNumber.LN10) + 1e-9), 0, 100000)
	while n > 0 and business_cost(m, def, n).gt(m.money):
		n -= 1
	return n


## qty < 0 => máximo posible. Devuelve cuántos compró.
static func buy_business(m: GameModel, id: String, qty: int = 1) -> int:
	if not GameData.business_idx.has(id):
		return 0
	var def: Dictionary = GameData.businesses[GameData.business_idx[id]]
	if not business_available(m, def):
		return 0
	var n: int = max_affordable(m, def) if qty < 0 else qty
	if n <= 0:
		return 0
	var cost: BigNumber = business_cost(m, def, n)
	if cost.gt(m.money):
		return 0
	var before: int = m.owned_count(id)
	m.money = m.money.sub(cost)
	m.owned[id] = before + n
	m.dirty = true
	_track_buildings(m)
	m.push("business_bought", [id, n])
	if milestone_count(before + n) > milestone_count(before):
		m.push("milestone", [id, before + n])
	return n


static func _track_buildings(m: GameModel) -> void:
	m.max_buildings = maxi(m.max_buildings, m.total_businesses())
	m.max_carts = maxi(m.max_carts, m.owned_count("empanadas"))
	for def in GameData.businesses:
		if m.owned_count(def["id"]) > 0:
			m.max_tier = maxi(m.max_tier, int(def["tier"]))


# =====================================================================
#  Mejoras (fila de íconos)
# =====================================================================
static func upgrade_visible(m: GameModel, u: Dictionary) -> bool:
	if m.upgrades.has(u["id"]):
		return false
	match str(u["kind"]):
		"biz":
			var def: Dictionary = GameData.businesses[GameData.business_idx[u["biz"]]]
			return business_available(m, def) and m.owned_count(u["biz"]) >= int(u["req"])
		"click":
			return m.run_clicks >= int(u["req"])
		"syn":
			return m.owned_count(u["biz"]) >= int(u["req"]) and m.owned_count(u["other"]) >= int(u["req"])
		"global":
			return m.total_businesses() >= int(u["req"])
	return false


static func upgrade_cost(m: GameModel, u: Dictionary) -> BigNumber:
	return u["cost"].mul(cost_factor(m))


static func visible_upgrades(m: GameModel) -> Array:
	var out: Array = []
	for u in GameData.upgrades:
		if upgrade_visible(m, u):
			out.append(u)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["cost"].lt(b["cost"]))
	return out


static func buy_upgrade(m: GameModel, id: String) -> bool:
	if not GameData.upgrade_idx.has(id):
		return false
	var u: Dictionary = GameData.upgrades[GameData.upgrade_idx[id]]
	if not upgrade_visible(m, u):
		return false
	var cost: BigNumber = upgrade_cost(m, u)
	if cost.gt(m.money):
		return false
	m.money = m.money.sub(cost)
	m.upgrades[id] = true
	m.max_upgrades = maxi(m.max_upgrades, m.upgrades.size())
	m.dirty = true
	m.push("upgrade_bought", [id])
	return true


# =====================================================================
#  Compra inteligente (bot, Encargado y simulador)
# =====================================================================
static func _biz_gain(m: GameModel, def: Dictionary) -> BigNumber:
	var n: int = m.owned_count(def["id"])
	var per_unit: BigNumber = def["base_income"].mul_f(float(m.mods["prod_mult"]))
	if n > 0 and m.biz_income.has(def["id"]):
		per_unit = m.biz_income[def["id"]].div_f(float(n))
	var k: float = 1.0
	if milestone_count(n + 1) > milestone_count(n):
		k = float(m.mods["milestone_mult"]) * float(n + 1) / float(maxi(n, 1))
	return per_unit.mul_f(k)


## Candidatos con su repago (s). `biz_only` = solo negocios (el Encargado).
static func candidates(m: GameModel, biz_only: bool = false) -> Array:
	ensure_fresh(m)
	var out: Array = []
	var total: BigNumber = BigNumber.max_of(m.base_income, BigNumber.from_float(0.5))
	for def in GameData.businesses:
		if not business_available(m, def):
			continue
		var cost: BigNumber = business_cost(m, def, 1)
		var gain: BigNumber = _biz_gain(m, def)
		out.append({"kind": "biz", "id": def["id"], "cost": cost, "payback": cost.div(gain).to_float()})
	if biz_only:
		return out
	for u in GameData.upgrades:
		if not upgrade_visible(m, u):
			continue
		var fx: Dictionary = u["fx"]
		var v: float = float(fx["value"])
		var gain2: BigNumber = BigNumber.zero()
		match str(fx["type"]):
			"biz_mult":
				gain2 = m.biz_income.get(fx["biz"], BigNumber.zero()).mul_f(v - 1.0)
			"all_mult":
				gain2 = total.mul_f(v - 1.0)
			"click_mult":
				gain2 = click_value(m).mul_f(4.0 * (v - 1.0))
			"click_pct":
				gain2 = total.mul_f(v * 4.0)
			"synergy":
				gain2 = m.biz_income.get(fx["biz"], BigNumber.zero()).mul_f(v * float(m.owned_count(fx["other"])))
		if gain2.is_zero():
			gain2 = total.mul_f(0.01)
		var cost2: BigNumber = upgrade_cost(m, u)
		out.append({"kind": "upg", "id": u["id"], "cost": cost2, "payback": cost2.div(gain2).to_float()})
	return out


## Compra el mejor candidato asequible (o uno casi tan bueno). true si compró algo.
static func smart_buy(m: GameModel, tolerance: float = 1.8, biz_only: bool = false) -> bool:
	var cands: Array = candidates(m, biz_only)
	if cands.is_empty():
		return false
	var best_payback: float = INF
	for c in cands:
		best_payback = minf(best_payback, float(c["payback"]))
	var pick: Dictionary = {}
	var pick_payback: float = INF
	for c in cands:
		var pb: float = float(c["payback"])
		if pb <= best_payback * tolerance and pb < pick_payback and (c["cost"] as BigNumber).le(m.money):
			pick = c
			pick_payback = pb
	if pick.is_empty():
		return false
	if pick["kind"] == "biz":
		return buy_business(m, pick["id"], 1) > 0
	return buy_upgrade(m, pick["id"])


## ¿Hay algo comprable ya mismo? (negocio, mejora o nodo del árbol)
static func anything_affordable(m: GameModel) -> bool:
	for def in GameData.businesses:
		if business_available(m, def) and business_cost(m, def, 1).le(m.money):
			return true
	for u in GameData.upgrades:
		if upgrade_visible(m, u) and upgrade_cost(m, u).le(m.money):
			return true
	return TreeLogic.any_affordable(m)


static func cheapest_business(m: GameModel) -> BigNumber:
	var best: BigNumber = null
	for def in GameData.businesses:
		if not business_available(m, def):
			continue
		var c: BigNumber = business_cost(m, def, 1)
		if best == null or c.lt(best):
			best = c
	return best if best != null else BigNumber.zero()


# =====================================================================
#  Remarcar: congela la inflación un rato
# =====================================================================
static func can_remark(m: GameModel) -> bool:
	return m.remark_cd <= 0.0


static func remark(m: GameModel, manual: bool = true) -> bool:
	ensure_fresh(m)
	if not can_remark(m):
		return false
	var secs: float = float(m.mods["remark_freeze"]) + float(m.mods["album_remark"])
	m.freeze_left = maxf(m.freeze_left, secs)
	m.remark_cd = maxf(5.0, float(m.mods["remark_cd"]))
	m.remarks += 1
	if manual and m.run_time < 10.0:
		m.early_remark = 1
	m.push("remarked", [secs, manual])
	return true


# =====================================================================
#  Billete volador
# =====================================================================
static func _next_bill_interval(m: GameModel) -> float:
	ensure_fresh(m)
	return m.rng.randf_range(B("bill_min"), B("bill_max")) * float(m.mods["bill_interval"])


static func _spawn_bill(m: GameModel) -> void:
	m.bill_seq += 1
	var t: float = B("bill_flight") * float(m.mods["bill_slow"])
	m.bills_active.append({"id": m.bill_seq, "left": t, "total": t})
	m.push("bill_spawn", [m.bill_seq])


static func update_bills(m: GameModel, dt: float) -> void:
	var i: int = m.bills_active.size() - 1
	while i >= 0:
		var b: Dictionary = m.bills_active[i]
		b["left"] = float(b["left"]) - dt
		if float(b["left"]) <= 0.0:
			m.bills_active.remove_at(i)
			m.bills_missed += 1
			m.push("bill_missed", [b["id"]])
		i -= 1
	m.bill_timer -= dt
	if m.bill_timer <= 0.0:
		m.bill_timer = _next_bill_interval(m)
		_spawn_bill(m)
		if m.rng.randf() < float(m.mods["bill_double"]):
			_spawn_bill(m)


static func bill_prize_kind(m: GameModel) -> String:
	var w: Dictionary = GameData.balance["bill_weights"].duplicate()
	if not bool(m.mods["album"]):
		w["sticker"] = 0
	else:
		w["sticker"] = float(w["sticker"]) * float(m.mods["sticker_bill"]) / B("sticker_bill_base")
	if bool(m.mods["clickfrenzy"]):
		w["clickfrenzy"] = 15
	var total: float = 0.0
	for k in w:
		total += float(w[k])
	var roll: float = m.rng.randf() * total
	for k in w:
		roll -= float(w[k])
		if roll <= 0.0 and float(w[k]) > 0.0:
			return str(k)
	return "money"


## El jugador tocó un billete. Devuelve {kind, amount: BigNumber, seconds: float, sticker: String} ({} si no existe).
static func click_bill(m: GameModel, bill_id: int, force: String = "") -> Dictionary:
	ensure_fresh(m)
	var idx: int = -1
	for i in range(m.bills_active.size()):
		if int(m.bills_active[i]["id"]) == bill_id:
			idx = i
	if idx < 0:
		return {}
	m.bills_active.remove_at(idx)
	m.bills += 1
	var kind: String = force if force != "" else bill_prize_kind(m)
	var res: Dictionary = {"kind": kind, "amount": BigNumber.zero(), "seconds": 0.0, "sticker": ""}
	match kind:
		"frenzy":
			m.frenzy_left = float(m.mods["frenzy_dur"])
			m.frenzies += 1
			res["seconds"] = m.frenzy_left
			if bool(m.mods["frenzy_freeze"]):
				m.freeze_left = maxf(m.freeze_left, m.frenzy_left)
		"freeze":
			m.freeze_left = maxf(m.freeze_left, B("freeze_seconds") + float(m.mods["freeze_bonus"]))
			res["seconds"] = m.freeze_left
		"clickfrenzy":
			m.clickfrenzy_left = B("clickfrenzy_seconds")
			res["seconds"] = m.clickfrenzy_left
		"sticker":
			var s: Dictionary = StickerLogic.award(m)
			res["sticker"] = s["id"]
		_:
			res["kind"] = "money"
			var a: BigNumber = BigNumber.max_of(income_per_sec(m).mul_f(B("bill_money_s")), click_value(m).mul_f(B("bill_money_clicks")))
			a = a.mul_f(float(m.mods["bill_money"]))
			earn(m, a)
			res["amount"] = a
	m.push("bill_prize", [res])
	return res


# =====================================================================
#  Noticias (eventos con dos opciones)
# =====================================================================
static func event_def(id: String) -> Dictionary:
	return GameData.events[GameData.event_idx[id]]


static func start_event(m: GameModel, id: String) -> void:
	ensure_fresh(m)
	m.events_seen += 1
	var secs: float = B("event_choice_seconds")
	m.pending_choice = {"id": id, "remaining": secs, "total": secs}
	m.push("event_choice", [id])


static func choose(m: GameModel, idx: int) -> bool:
	if m.pending_choice.is_empty():
		return false
	ensure_fresh(m)
	var id: String = str(m.pending_choice["id"])
	m.pending_choice = {}
	var choices: Array = event_def(id)["choices"]
	var fx: Dictionary = choices[clampi(idx, 0, choices.size() - 1)]["fx"]
	var em: float = float(m.mods["event_mult"]) * (1.0 + float(m.mods["album_events"]))
	if fx.has("bonus_seconds"):
		earn(m, income_per_sec(m).mul_f(float(fx["bonus_seconds"]) * em))
	if fx.has("pay_seconds"):
		var cost: BigNumber = income_per_sec(m).mul_f(float(fx["pay_seconds"]))
		m.money = m.money.sub(BigNumber.min_of(cost, m.money))
	if fx.has("freeze"):
		m.freeze_left = maxf(m.freeze_left, float(fx["freeze"]))
	if fx.has("sticker"):
		if bool(m.mods["album"]):
			StickerLogic.award(m)
		else:
			earn(m, income_per_sec(m).mul_f(30.0))
	if float(fx.get("duration", 0.0)) > 0.0:
		var keep: Dictionary = {}
		for k in ["prod_mult", "click_mult", "infl_mult"]:
			if fx.has(k):
				var v: float = float(fx[k])
				keep[k] = 1.0 + (v - 1.0) * em if v > 1.0 and k != "infl_mult" else v
		m.active_events.append({"id": id, "remaining": float(fx["duration"]), "fx": keep})
	m.push("event_choice_done", [id, idx])
	return true


static func update_events(m: GameModel, dt: float) -> void:
	var i: int = m.active_events.size() - 1
	while i >= 0:
		var ev: Dictionary = m.active_events[i]
		ev["remaining"] = float(ev["remaining"]) - dt
		if float(ev["remaining"]) <= 0.0:
			m.active_events.remove_at(i)
			m.push("event_ended", [ev["id"]])
		i -= 1
	if not m.pending_choice.is_empty():
		m.pending_choice["remaining"] = float(m.pending_choice["remaining"]) - dt
		if float(m.pending_choice["remaining"]) <= 0.0:
			choose(m, 0)
		return
	if not bool(m.mods["events"]):
		return
	m.event_timer -= dt
	if m.event_timer <= 0.0:
		m.event_timer = m.rng.randf_range(B("event_min"), B("event_max"))
		var total: float = 0.0
		for d in GameData.events:
			total += float(d["weight"])
		var roll: float = m.rng.randf() * total
		for d in GameData.events:
			roll -= float(d["weight"])
			if roll <= 0.0:
				start_event(m, str(d["id"]))
				return


# =====================================================================
#  Reforma monetaria (renacer)
# =====================================================================
## Credibilidad base de una vuelta según lo máximo que se ganó en ella: k · (log10(ganado) − c)^p (logarítmica, no explota).
static func cred_of(earned: BigNumber) -> float:
	var l: float = earned.log10()
	if is_inf(l) or l <= B("cred_c"):
		return 0.0
	return B("cred_k") * pow(l - B("cred_c"), B("cred_p"))


## Cuánto cuenta la vuelta: completa si iguala o supera tu mejor vuelta; nada si quedó más de `cred_window` ceros abajo
## (así no conviene reformar a los 20 segundos una y otra vez). Con la economía colapsada cuenta al menos un 15 %.
static func best_factor(m: GameModel) -> float:
	if m.best_run.is_zero():
		return 1.0
	var l: float = m.run_earned.log10()
	var best: float = m.best_run.log10()
	if is_inf(l):
		return 0.0
	var w: float = B("cred_window")
	var f: float = clampf((l - (best - w)) / w, 0.0, 1.0)
	if m.collapse_shown:
		f = maxf(f, B("cred_collapse_floor"))      # contra la pared nadie queda trabado sin poder reformar
	return f


## Credibilidad que daría reformar ahora, sin redondear.
static func reform_gain_f(m: GameModel) -> float:
	ensure_fresh(m)
	var md: Dictionary = m.mods
	var k: float = float(md["cred_mult"]) * (1.0 + float(md["album_cred"])) * (1.0 + float(md["cred_per_page"]) * float(StickerLogic.pages_done(m)))
	var g: float = cred_of(m.run_earned) * best_factor(m) * k
	return g + float(md["cred_flat"]) if g >= 1.0 else g


static func reform_gain(m: GameModel) -> int:
	return int(floor(reform_gain_f(m)))


## Alcanza la Credibilidad mínima (y la demo no llegó a su tope).
static func reform_ready(m: GameModel) -> bool:
	if m.demo_mode and m.reforms >= int(B("demo_max_reforms")):
		return false
	return reform_gain(m) >= int(B("reform_min_gain"))


## La primera reforma recién se habilita cuando la economía colapsa (el cartel la sugiere); después, cuando se quiera.
static func can_reform(m: GameModel) -> bool:
	if m.reforms == 0 and not m.collapse_shown:
		return false
	return reform_ready(m)


static func collapsed(m: GameModel) -> bool:
	if price_level(m).lt(BigNumber.from_float(B("collapse_min_price"))):
		return false
	var inc: BigNumber = income_per_sec(m)
	return cheapest_business(m).gt(inc.mul_f(B("collapse_payback_s")))


static func do_reform(m: GameModel) -> Dictionary:
	if not can_reform(m):
		return {}
	var gain: int = reform_gain(m)
	var prev: Dictionary = m.runs[m.runs.size() - 1] if not m.runs.is_empty() else {}
	var summary: Dictionary = {"n": m.run_index, "earned": m.run_earned.to_save(), "time": m.run_time, "cred": gain,
		"prev_earned": str(prev.get("earned", "")), "prev_time": float(prev.get("time", 0.0)), "prev_cred": int(prev.get("cred", 0))}
	m.credibility += gain
	m.cred_total += gain
	m.reforms += 1
	var cut: int = maxi(1, floori(ln_price(m) / BigNumber.LN10))      # la tijera corta al menos un cero
	m.zeros_cut += cut
	summary["cut"] = cut
	if m.run_earned.gt(m.best_run):
		m.best_run = m.run_earned
	m.fastest_run = minf(m.fastest_run, m.run_time) if gain >= 10 else m.fastest_run
	if m.run_manual_clicks <= 10 and gain >= 1:
		m.lazy_run = 1
	m.runs.append({"n": m.run_index, "earned": m.run_earned.to_save(), "time": m.run_time, "cred": gain})
	m.lifetime_earned = m.lifetime_earned.add(m.run_earned)
	var note: int = -1
	if m.album.size() < GameData.banknotes.size():
		note = m.album.size()
		m.album.append(note)
		StickerLogic.give(m, "note_%d" % note)
	summary["note"] = note
	ensure_fresh(m)
	if bool(m.mods["album"]):
		m.free_packs_pending += int(m.mods["free_packs"])
	var last_earned: BigNumber = m.run_earned
	_reset_run(m, last_earned)
	m.push("reform_done", [summary])
	if m.demo_mode and m.reforms >= int(B("demo_max_reforms")):
		m.demo_finished = true
		m.push("demo_end")
	return summary


static func _reset_run(m: GameModel, last_earned: BigNumber) -> void:
	ensure_fresh(m)
	var kept: Dictionary = {}
	if bool(m.mods["keep_click_upg"]):
		for uid in m.upgrades:
			if GameData.upgrades[GameData.upgrade_idx[uid]]["kind"] == "click":
				kept[uid] = true
	m.money = BigNumber.from_float(float(m.mods["start_money"])).add(last_earned.mul_f(float(m.mods["start_money_frac"])))
	m.run_earned = BigNumber.zero()
	m.run_time = 0.0
	m.ln_p = 0.0
	m.owned = {}
	var sb: Dictionary = m.mods["start_biz"]
	for b in sb:
		m.owned[b] = int(sb[b])
	m.upgrades = kept
	m.run_clicks = 0
	m.run_manual_clicks = 0
	m.run_index += 1
	m.freeze_left = 0.0
	m.remark_cd = 0.0
	m.frenzy_left = 0.0
	m.clickfrenzy_left = 0.0
	m.combo = 0
	m.combo_idle = 99.0
	m.bills_active = []
	m.bill_timer = minf(20.0, _next_bill_interval(m))
	m.active_events = []
	m.pending_choice = {}
	m.event_timer = m.rng.randf_range(B("event_min"), B("event_max")) * 0.5
	m.collapse_shown = false
	m.max_rate_run = 0.0
	m.dirty = true
	_track_buildings(m)


# =====================================================================
#  Tick
# =====================================================================
static func tick(m: GameModel, dt: float, offline: bool = false) -> void:
	ensure_fresh(m)
	m.time_played += dt
	m.run_time += dt
	m.combo_idle += dt
	if m.combo_idle > float(m.mods["combo_window"]):
		m.combo = 0
	m.remark_cd = maxf(0.0, m.remark_cd - dt)
	m.frenzy_left = maxf(0.0, m.frenzy_left - dt)
	m.clickfrenzy_left = maxf(0.0, m.clickfrenzy_left - dt)
	# inflación: P sube con la tasa salvo con precios congelados
	var live: float = dt
	if m.freeze_left > 0.0:
		var used: float = minf(dt, m.freeze_left)
		m.freeze_left -= used
		live = dt - used
	if live > 0.0:
		m.ln_p += rate_per_sec(m) * live
	var inc: BigNumber = income_per_sec(m)
	if not inc.is_zero():
		earn(m, inc.mul_f(dt))
	if offline:
		return
	var md: Dictionary = m.mods
	if float(md["autoclick"]) > 0.0:
		m.auto_click_acc += float(md["autoclick"]) * dt
		var n: int = 0
		while m.auto_click_acc >= 1.0 and n < 60:
			m.auto_click_acc -= 1.0
			do_click(m, false)
			n += 1
		m.auto_click_acc = minf(m.auto_click_acc, 1.0)
	if float(md["manager"]) > 0.0:
		m.manager_timer += dt
		if m.manager_timer >= float(md["manager"]):
			m.manager_timer = 0.0
			smart_buy(m, 1.8, true)
	if bool(md["auto_remark"]) and can_remark(m) and m.freeze_left <= 0.0 and m.run_time > 5.0:
		remark(m, false)
	if float(md["auto_scratch"]) > 0.0 and bool(md["scratch"]):
		m.auto_scratch_timer += dt
		if m.auto_scratch_timer >= float(md["auto_scratch"]):
			m.auto_scratch_timer = 0.0
			GambleLogic.play_scratch(m, true)
	update_bills(m, dt)
	update_events(m, dt)
	var pct: float = monthly_pct(m)
	m.max_rate_pct = maxf(m.max_rate_pct, pct)
	m.max_rate_run = maxf(m.max_rate_run, pct)
	if not m.collapse_shown and reform_ready(m) and collapsed(m):
		m.collapse_shown = true
		m.push("collapse")


## Progreso offline: la producción sigue a un 10 % (más con el árbol), sin inflación, hasta 8 h.
static func simulate_offline(m: GameModel, seconds: float) -> Dictionary:
	ensure_fresh(m)
	var cap: float = B("offline_cap_hours") * 3600.0
	var total: float = clampf(seconds, 0.0, cap)
	var before: BigNumber = m.money
	var gain: BigNumber = m.base_income.mul_f(total * float(m.mods["offline_frac"]))
	earn(m, gain)
	m.time_played += total
	return {"seconds": total, "capped": seconds > cap, "money_before": before, "money_after": m.money, "gain": gain}


# =====================================================================
#  Estadísticas (logros y menú)
# =====================================================================
static func stats(m: GameModel) -> Dictionary:
	var ml: float = m.money.log10()
	var rl: float = m.run_earned.log10()
	var bl: float = BigNumber.max_of(m.best_run, m.run_earned).log10()
	return {
		"clicks": m.clicks, "max_combo": m.max_combo, "crits": m.crits, "buildings": m.total_businesses(),
		"max_buildings": m.max_buildings, "max_carts": m.max_carts, "max_tier": m.max_tier, "max_upgrades": m.max_upgrades,
		"remarks": m.remarks, "early_remark": m.early_remark, "max_rate_pct": m.max_rate_pct, "rate_pct": monthly_pct(m),
		"bills": m.bills, "bills_missed": m.bills_missed, "frenzies": m.frenzies, "reforms": m.reforms,
		"fastest_run": m.fastest_run, "lazy_run": m.lazy_run, "zeros_cut": m.zeros_cut, "cred_total": m.cred_total,
		"nodes": TreeLogic.count(m), "nodes_pct": 100.0 * float(TreeLogic.count(m)) / float(TreeLogic.total()),
		"caps": TreeLogic.caps(m), "won": 1 if m.won else 0, "packs": m.packs_opened, "golden_owned": golden_owned(m),
		"pages_done": StickerLogic.pages_done(m), "stickers": m.stickers.size(),
		"stickers_pct": 100.0 * float(m.stickers.size()) / float(StickerLogic.total()), "trades": m.trades,
		"scratches": m.scratches, "scratch_big": m.scratch_big, "loss_streak_max": m.loss_streak_max,
		"events_seen": m.events_seen, "minutes": m.time_played / 60.0,
		"money_log10": ml if not is_inf(ml) else -1.0, "run_log10": rl if not is_inf(rl) else -1.0,
		"best_run_log10": bl if not is_inf(bl) else -1.0,
	}


## % de completado total: (nodos + figuritas + logros) / (total de los tres).
static func completion(m: GameModel) -> float:
	var have: int = TreeLogic.count(m) + m.stickers.size() + m.achievements.size()
	var all: int = TreeLogic.total() + StickerLogic.total() + GameData.achievements.size()
	return 100.0 * float(have) / float(all)


# =====================================================================
#  Tutorial mínimo (solo la primera vuelta)
# =====================================================================
const TUTORIAL_STEPS: int = 4


## 0 clic, 1 primer carrito, 2 remarcar (cuando la inflación se nota), 3 reforma (al colapsar); 4 = terminado.
static func tutorial_step(m: GameModel) -> int:
	if m.tutorial_done or m.reforms > 0:
		return TUTORIAL_STEPS
	if m.clicks < 5:
		return 0
	if m.total_businesses() < 1:
		return 1
	if m.remarks < 1:
		return 2 if m.run_time >= 75.0 else -1
	if can_reform(m) and (m.collapse_shown or m.run_time >= 270.0):
		return 3
	return -1
