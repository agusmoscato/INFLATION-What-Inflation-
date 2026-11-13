class_name EconomyLogic
extends RefCounted
## Toda la lógica económica del juego, sin nodos ni autoloads (testeable y simulable headless).
## Modelo: ingresos = base_real * M (tus precios) ; costos = base_real * P (nivel de precios).
## P sube cada "mes" según la tasa; M solo se pone al día al remarcar.



static func B(key: String) -> float:
	return float(GameData.balance[key])


# =====================================================================
#  Derivados
# =====================================================================
static func milestone_mult(n: int) -> float:
	var count: int = 0
	for t in GameData.balance["milestones"]:
		if n >= int(t):
			count += 1
	return pow(B("milestone_mult"), count)


static func album_bonus(m: GameModel) -> float:
	var b: float = m.album.size() * B("album_note_bonus")
	if m.album.size() >= GameData.banknotes.size():
		b += B("album_complete_bonus")
	return b


static func plan_def(m: GameModel) -> Dictionary:
	if m.plan_id != "" and GameData.plan_idx.has(m.plan_id):
		return GameData.plans[GameData.plan_idx[m.plan_id]]
	return {}


static func recalc(m: GameModel) -> void:
	m.dirty = false
	var gm: float = 1.0 + B("cred_bonus") * (float(m.credibility) + m.legacy_cred)
	gm *= 1.0 + album_bonus(m)
	gm *= pow(B("plan_perm_mult"), m.plans_done)
	var pd: Dictionary = plan_def(m)
	if not pd.is_empty():
		gm *= float(pd["income_mult"])
	m.biz_up_mult = {}
	m.click_mult = 1.0
	m.click_pct = 0.0
	m.auto_remark_interval = 0.0
	m.auto_buy_interval = 0.0
	m.infl_up_mult = 1.0
	m.fee_mult = 1.0
	m.remark_bonus_mult = 1.0
	for uid in m.upgrades:
		var u: Dictionary = GameData.upgrades[GameData.upgrade_idx[uid]]
		var ef: Dictionary = u["effect"]
		var v: float = float(ef["value"])
		match str(ef["type"]):
			"business_mult":
				m.biz_up_mult[ef["biz"]] = float(m.biz_up_mult.get(ef["biz"], 1.0)) * v
			"all_mult":
				gm *= v
			"click_mult":
				m.click_mult *= v
			"click_pct":
				m.click_pct += v
			"auto_remark":
				m.auto_remark_interval = v if m.auto_remark_interval == 0.0 else minf(m.auto_remark_interval, v)
			"auto_buy":
				m.auto_buy_interval = v if m.auto_buy_interval == 0.0 else minf(m.auto_buy_interval, v)
			"inflation_mult":
				m.infl_up_mult *= v
			"fee_mult":
				m.fee_mult *= v
			"remark_bonus":
				m.remark_bonus_mult *= v
	m.global_mult = gm
	var base: BigNumber = BigNumber.zero()
	for def in GameData.businesses:
		var n: int = m.owned_count(def["id"])
		if n == 0:
			continue
		var bm: float = float(m.biz_up_mult.get(def["id"], 1.0)) * milestone_mult(n)
		base = base.add(def["base_income"].mul_f(float(n) * bm * gm))
	m.base_income = base
	m.refuge_mult = 1.0 + B("refuge_bonus") * float(refuge_diversified_count(m))


static func ensure_fresh(m: GameModel) -> void:
	if m.dirty:
		recalc(m)


# ---- eventos activos ----
static func event_income_mult(m: GameModel) -> float:
	var r: float = 1.0
	for ev in m.active_events:
		var d: Dictionary = GameData.events[GameData.event_idx[ev["id"]]]
		r *= float(d.get("income_mult", 1.0))
	return r


static func event_inflation_mult(m: GameModel) -> float:
	var r: float = 1.0
	for ev in m.active_events:
		var d: Dictionary = GameData.events[GameData.event_idx[ev["id"]]]
		r *= float(d.get("inflation_mult", 1.0))
	return r


static func event_click_mult(m: GameModel) -> float:
	var r: float = 1.0
	for ev in m.active_events:
		var d: Dictionary = GameData.events[GameData.event_idx[ev["id"]]]
		r *= float(d.get("click_mult", 1.0))
	return r


static func refuges_blocked(m: GameModel) -> bool:
	for ev in m.active_events:
		var d: Dictionary = GameData.events[GameData.event_idx[ev["id"]]]
		if bool(d.get("block_refuges", false)):
			return true
	return false


static func has_event(m: GameModel, id: String) -> bool:
	for ev in m.active_events:
		if ev["id"] == id:
			return true
	return false


## Ingreso nominal por segundo.
static func income_per_sec(m: GameModel) -> BigNumber:
	ensure_fresh(m)
	return m.base_income.mul(m.my_prices).mul_f(event_income_mult(m) * m.refuge_mult)


## Poder adquisitivo: cuántas "empanadas del día 1" alcanzan con tu plata.
static func purchasing_power(m: GameModel) -> BigNumber:
	return m.money.div(m.price_level)


## Tasa mensual de inflación vigente (0.08 = 8 %).
static func inflation_rate(m: GameModel) -> float:
	ensure_fresh(m)
	var r: float = float(GameData.era_def(m.era)["inflation"])
	if m.era >= 5:
		r *= maxf(0.0, 1.0 - B("measure_reduction") * float(m.measures))
	r *= maxf(0.5, 1.0 / (1.0 + B("cred_inflation_reduction") * (float(m.credibility) + m.legacy_cred)))
	var pd: Dictionary = plan_def(m)
	if not pd.is_empty():
		r *= float(pd["inflation_mult"])
	r *= m.infl_up_mult
	r *= event_inflation_mult(m)
	return r


# =====================================================================
#  Ingresos y clic
# =====================================================================
static func earn(m: GameModel, nominal: BigNumber) -> void:
	m.money = m.money.add(nominal)
	var real: BigNumber = nominal.div(m.price_level)
	m.lifetime_real = m.lifetime_real.add(real)
	m.cycle_real = m.cycle_real.add(real)
	m.run_real = m.run_real.add(real)


static func click_value(m: GameModel) -> BigNumber:
	ensure_fresh(m)
	var real: float = B("click_base") * m.click_mult * event_click_mult(m)
	var v: BigNumber = m.my_prices.mul_f(real)
	if m.click_pct > 0.0:
		v = v.add(income_per_sec(m).mul_f(m.click_pct))
	return v


static func do_click(m: GameModel) -> BigNumber:
	var v: BigNumber = click_value(m)
	earn(m, v)
	m.clicks += 1
	return v


# =====================================================================
#  Negocios
# =====================================================================
static func growth_pow(k: float) -> BigNumber:
	return BigNumber.from_float(B("cost_growth")).pow_f(k)


static func business_cost(m: GameModel, def: Dictionary, qty: int = 1) -> BigNumber:
	var first: BigNumber = def["base_cost"].mul(growth_pow(float(m.owned_count(def["id"])))).mul(m.price_level)
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


static func is_unlocked(m: GameModel, def: Dictionary) -> bool:
	return int(def["era"]) <= m.era


## qty < 0 => máximo posible. Devuelve cuántos compró.
static func buy_business(m: GameModel, id: String, qty: int = 1) -> int:
	if not GameData.business_idx.has(id):
		return 0
	var def: Dictionary = GameData.businesses[GameData.business_idx[id]]
	if not is_unlocked(m, def):
		return 0
	var n: int = max_affordable(m, def) if qty < 0 else qty
	if n <= 0:
		return 0
	var cost: BigNumber = business_cost(m, def, n)
	if cost.gt(m.money):
		return 0
	m.money = m.money.sub(cost)
	m.owned[id] = m.owned_count(id) + n
	m.dirty = true
	m.push("business_bought", [id, n])
	return n


# =====================================================================
#  Mejoras
# =====================================================================
static func upgrade_visible(m: GameModel, u: Dictionary) -> bool:
	if m.upgrades.has(u["id"]) or int(u["era"]) > m.era:
		return false
	if int(u["req_owned"]) > 0 and m.owned_count(u["biz"]) < int(u["req_owned"]):
		return false
	return true


static func upgrade_cost(m: GameModel, u: Dictionary) -> BigNumber:
	return u["cost"].mul(m.price_level)


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
	m.dirty = true
	m.push("upgrade_bought", [id])
	return true


# =====================================================================
#  Compra inteligente (usada por el auto-comprador y el simulador)
# =====================================================================
static func unit_gain(m: GameModel, def: Dictionary) -> BigNumber:
	var n: int = m.owned_count(def["id"])
	var bm: float = float(m.biz_up_mult.get(def["id"], 1.0))
	var after: float = float(n + 1) * milestone_mult(n + 1)
	var before: float = float(n) * milestone_mult(n)
	return def["base_income"].mul_f(bm * m.global_mult * (after - before))


static func candidates(m: GameModel) -> Array:
	ensure_fresh(m)
	var out: Array = []
	var total: BigNumber = m.base_income
	var floor_income: BigNumber = BigNumber.max_of(total, BigNumber.one())
	for def in GameData.businesses:
		if not is_unlocked(m, def):
			continue
		var cost_real: BigNumber = def["base_cost"].mul(growth_pow(float(m.owned_count(def["id"]))))
		var gain: BigNumber = unit_gain(m, def)
		out.append({"kind": "biz", "id": def["id"], "cost": cost_real.mul(m.price_level),
			"payback": cost_real.div(gain).to_float()})
	for u in GameData.upgrades:
		if not upgrade_visible(m, u):
			continue
		var ef: Dictionary = u["effect"]
		var v: float = float(ef["value"])
		var gain2: BigNumber = BigNumber.zero()
		match str(ef["type"]):
			"business_mult":
				var bid: String = str(ef["biz"])
				var bdef: Dictionary = GameData.businesses[GameData.business_idx[bid]]
				var n: int = m.owned_count(bid)
				var contrib: BigNumber = bdef["base_income"].mul_f(float(n) * float(m.biz_up_mult.get(bid, 1.0)) * milestone_mult(n) * m.global_mult)
				gain2 = contrib.mul_f(v - 1.0)
			"all_mult":
				gain2 = total.mul_f(v - 1.0)
			"click_mult":
				gain2 = BigNumber.from_float(B("click_base") * m.click_mult * (v - 1.0))
			"click_pct":
				gain2 = total.mul_f(v)
			"auto_remark":
				gain2 = floor_income.mul_f(0.15)
			"auto_buy":
				gain2 = floor_income.mul_f(0.08)
			"remark_bonus", "inflation_mult":
				gain2 = floor_income.mul_f(0.05)
			_:
				gain2 = floor_income.mul_f(0.01)
		if gain2.is_zero():
			continue
		out.append({"kind": "upg", "id": u["id"], "cost": u["cost"].mul(m.price_level),
			"payback": u["cost"].div(gain2).to_float()})
	return out


## Compra el mejor candidato asequible (o uno casi tan bueno si el mejor no se puede pagar). true si compró algo.
static func smart_buy(m: GameModel, tolerance: float = 1.8) -> bool:
	var cands: Array = candidates(m)
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


# =====================================================================
#  Remarcar
# =====================================================================
static func needs_remark(m: GameModel) -> bool:
	return m.my_prices.lt(m.price_level)


static func remark(m: GameModel, manual: bool = true) -> BigNumber:
	if manual and m.remark_cd > 0.0:
		return BigNumber.zero()
	if not needs_remark(m):
		return BigNumber.zero()
	m.my_prices = m.price_level
	var bonus: BigNumber = BigNumber.zero()
	var on_time: bool = manual and m.remark_window > 0.0
	if manual:
		m.remarks += 1
		m.remark_cd = B("remark_cooldown")
	if on_time:
		bonus = income_per_sec(m).mul_f(B("remark_bonus_seconds") * m.remark_bonus_mult)
		earn(m, bonus)
		m.remark_window = 0.0
	if manual:
		m.push("remarked", [bonus, on_time])
	return bonus


# =====================================================================
#  Refugios
# =====================================================================
static func refuge_def(id: String) -> Dictionary:
	return GameData.refuges[GameData.refuge_idx[id]]


static func refuge_fee(m: GameModel, id: String) -> float:
	return float(refuge_def(id)["fee"]) * m.fee_mult


## Valor nominal actual de lo que tenés en un refugio.
static func refuge_value(m: GameModel, id: String) -> BigNumber:
	return m.refuge_units[id].mul_f(float(m.refuge_price[id])).mul(m.price_level)


static func refuge_value_total_real(m: GameModel) -> BigNumber:
	var t: BigNumber = BigNumber.zero()
	for r in GameData.refuges:
		t = t.add(m.refuge_units[r["id"]].mul_f(float(m.refuge_price[r["id"]])))
	return t


## Cuántos refugios tienen ahorros >= N segundos de ingresos (cartera diversificada).
static func refuge_diversified_count(m: GameModel) -> int:
	var thresh: BigNumber = m.base_income.mul_f(B("refuge_bonus_seconds"))
	var n: int = 0
	for r in GameData.refuges:
		var real: BigNumber = m.refuge_units[r["id"]].mul_f(float(m.refuge_price[r["id"]]))
		if not real.is_zero() and real.ge(thresh):
			n += 1
	return n


static func refuges_unlocked(m: GameModel) -> bool:
	return m.era >= 2 or m.reforms > 0


static func refuge_buy(m: GameModel, id: String, nominal: BigNumber) -> bool:
	if not refuges_unlocked(m) or refuges_blocked(m) or nominal.is_zero() or nominal.gt(m.money):
		return false
	var real: BigNumber = nominal.div(m.price_level).mul_f(1.0 - refuge_fee(m, id))
	m.money = m.money.sub(nominal)
	m.refuge_units[id] = m.refuge_units[id].add(real.div_f(float(m.refuge_price[id])))
	m.dirty = true
	m.push("refuge_changed")
	return true


static func refuge_sell(m: GameModel, id: String, fraction: float = 1.0) -> bool:
	if refuges_blocked(m) or m.refuge_units[id].is_zero():
		return false
	var f: float = clampf(fraction, 0.0, 1.0)
	var value: BigNumber = refuge_value(m, id).mul_f(f)
	m.refuge_units[id] = m.refuge_units[id].mul_f(1.0 - f)
	m.money = m.money.add(value.mul_f(1.0 - refuge_fee(m, id)))
	m.dirty = true
	m.push("refuge_changed")
	return true


static func refuge_monthly_update(m: GameModel, rate: float) -> void:
	for r in GameData.refuges:
		var id: String = r["id"]
		var pr: float = float(m.refuge_price[id])
		var vol: float = float(r["vol"])
		var drift: float = float(r["drift"]) + float(r["drift_infl"]) * rate
		var noise: float = m.rng.randfn(0.0, 1.0) * vol
		pr *= exp(drift + noise - 0.5 * vol * vol)
		pr += (1.0 - pr) * float(r["reversion"])
		m.refuge_price[id] = clampf(pr, float(r["min"]), float(r["max"]))
	m.dirty = true


# =====================================================================
#  Eventos
# =====================================================================
static func start_event(m: GameModel, id: String) -> void:
	var d: Dictionary = GameData.events[GameData.event_idx[id]]
	for ev in m.active_events:
		if ev["id"] == id:
			ev["remaining"] = float(d["duration"])
			return
	m.active_events.append({"id": id, "remaining": float(d["duration"])})
	m.events_seen += 1
	if d.has("bonus_seconds"):
		earn(m, income_per_sec(m).mul_f(float(d["bonus_seconds"])))
	if d.has("fx_jump"):
		var rd: Dictionary = refuge_def("usd")
		m.refuge_price["usd"] = clampf(float(m.refuge_price["usd"]) * float(d["fx_jump"]), float(rd["min"]), float(rd["max"]))
	m.push("event_started", [id])


static func pick_event(m: GameModel) -> String:
	var total: float = 0.0
	var pool: Array = []
	for d in GameData.events:
		if int(d["min_era"]) <= m.era and not has_event(m, d["id"]):
			pool.append(d)
			total += float(d["weight"])
	if pool.is_empty():
		return ""
	var roll: float = m.rng.randf() * total
	for d in pool:
		roll -= float(d["weight"])
		if roll <= 0.0:
			return d["id"]
	return pool[pool.size() - 1]["id"]


static func update_events(m: GameModel, dt: float, allow_spawn: bool) -> void:
	var i: int = m.active_events.size() - 1
	while i >= 0:
		var ev: Dictionary = m.active_events[i]
		ev["remaining"] = float(ev["remaining"]) - dt
		if float(ev["remaining"]) <= 0.0:
			m.active_events.remove_at(i)
			m.push("event_ended", [ev["id"]])
		i -= 1
	if allow_spawn and m.era >= int(B("events_min_era")):
		m.event_timer -= dt
		if m.event_timer <= 0.0:
			m.event_timer = m.rng.randf_range(B("event_interval_min"), B("event_interval_max"))
			var id: String = pick_event(m)
			if id != "":
				start_event(m, id)


static func strike_cost(m: GameModel) -> BigNumber:
	return income_per_sec(m).mul_f(B("strike_settle_seconds"))


static func settle_strike(m: GameModel) -> bool:
	if not has_event(m, "paro"):
		return false
	var cost: BigNumber = strike_cost(m)
	if cost.gt(m.money):
		return false
	m.money = m.money.sub(cost)
	for i in range(m.active_events.size() - 1, -1, -1):
		if m.active_events[i]["id"] == "paro":
			m.active_events.remove_at(i)
	m.push("event_ended", ["paro"])
	return true


# =====================================================================
#  Cruzada antiinflacionaria (final de la Era 5)
# =====================================================================
static func measure_count_total() -> int:
	return GameData.measure_costs.size()


static func measure_cost(m: GameModel) -> BigNumber:
	if m.measures >= measure_count_total():
		return BigNumber.zero()
	return GameData.measure_costs[m.measures].mul(m.price_level)


static func buy_measure(m: GameModel) -> bool:
	if m.era < 5 or m.measures >= measure_count_total():
		return false
	var cost: BigNumber = measure_cost(m)
	if cost.gt(m.money):
		return false
	m.money = m.money.sub(cost)
	m.measures += 1
	m.dirty = true
	m.push("toast", ["toast.measure"])
	return true


# =====================================================================
#  Reforma monetaria (prestige 1) y Plan económico (prestige 2)
# =====================================================================
## Credibilidad que daría reformar ahora: depende de lo ganado (en términos reales) en ESTA vuelta.
static func credibility_possible(m: GameModel) -> int:
	if m.run_real.lt(GameData.cred_base):
		return 0
	return m.run_real.div(GameData.cred_base).pow_f(B("cred_exp")).floor_to_int()


static func reform_gain(m: GameModel) -> int:
	return credibility_possible(m)


static func can_reform(m: GameModel) -> bool:
	return m.era >= int(B("reform_min_era")) and reform_gain(m) >= 1


static func _reset_run(m: GameModel) -> void:
	m.money = BigNumber.zero()
	m.price_level = BigNumber.one()
	m.my_prices = BigNumber.one()
	m.owned = {}
	m.upgrades = {}
	m.active_events = []
	m.run_real = BigNumber.zero()
	m.run_time = 0.0
	m.remark_window = 0.0
	m.auto_timer = 0.0
	m.auto_buy_timer = 0.0
	m.event_timer = 120.0
	m.dirty = true


static func do_reform(m: GameModel) -> bool:
	if not can_reform(m):
		return false
	m.credibility += reform_gain(m)
	var cut: int = maxi(0, floori(m.price_level.log10()))
	m.zeros_cut += cut
	var note: int = -1
	if m.album.size() < GameData.banknotes.size():
		note = m.album.size()
		m.album.append(note)
	for r in GameData.refuges:
		m.refuge_units[r["id"]] = m.refuge_units[r["id"]].mul_f(B("refuge_carry"))
	m.reforms += 1
	_reset_run(m)
	m.push("reform_done", [note, cut])
	return true


static func plan_min_cred(m: GameModel) -> int:
	var lst: Array = GameData.balance["plan_min_cred"]
	return int(lst[mini(m.plans_done, lst.size() - 1)])


static func can_plan(m: GameModel) -> bool:
	return m.era >= int(B("plan_min_era")) and m.plans_used.size() < GameData.plans.size() and m.credibility >= plan_min_cred(m)


static func do_plan(m: GameModel, plan: String) -> bool:
	if not can_plan(m) or not GameData.plan_idx.has(plan) or m.plans_used.has(plan):
		return false
	m.legacy_cred += float(m.credibility) * B("plan_legacy_frac")
	m.credibility = 0
	m.cycle_real = BigNumber.zero()
	m.plans_done += 1
	m.plan_id = plan
	m.plans_used.append(plan)
	for r in GameData.refuges:
		m.refuge_units[r["id"]] = m.refuge_units[r["id"]].mul_f(B("refuge_carry"))
	_reset_run(m)
	m.push("plan_done", [plan])
	return true


# =====================================================================
#  Tick
# =====================================================================
static func _update_era(m: GameModel) -> void:
	while m.era < GameData.eras.size() and m.lifetime_real.ge(GameData.eras[m.era]["threshold"]):
		m.era += 1
		m.dirty = true
		m.push("era_changed", [m.era])


static func month_end(m: GameModel) -> void:
	var rate: float = inflation_rate(m)
	m.month_count += 1
	m.price_level = m.price_level.mul_f(1.0 + rate)
	var pd: Dictionary = plan_def(m)
	if not pd.is_empty() and int(pd["shock_months"]) > 0 and m.month_count % int(pd["shock_months"]) == 0:
		m.price_level = m.price_level.mul_f(float(pd["shock_mult"]))
		m.push("toast", ["toast.shock"])
	if rate > 0.0:
		m.remark_window = B("remark_window")
	refuge_monthly_update(m, rate)
	m.push("month_passed", [rate])
	if m.era >= 5 and rate <= 0.0 and not m.won:
		m.won = true
		m.push("victory")


static func tick(m: GameModel, dt: float, offline: bool = false) -> void:
	ensure_fresh(m)
	m.time_played += dt
	m.run_time += dt
	m.remark_window = maxf(0.0, m.remark_window - dt)
	m.remark_cd = maxf(0.0, m.remark_cd - dt)
	var inc: BigNumber = income_per_sec(m)
	if not inc.is_zero():
		earn(m, inc.mul_f(dt))
	update_events(m, dt, not offline)
	if m.auto_remark_interval > 0.0:
		m.auto_timer += dt
		if m.auto_timer >= m.auto_remark_interval:
			m.auto_timer = 0.0
			remark(m, false)
	m.month_progress += dt
	var ms: float = B("month_seconds")
	while m.month_progress >= ms:
		m.month_progress -= ms
		month_end(m)
	if m.auto_buy_interval > 0.0:
		m.auto_buy_timer += dt
		if m.auto_buy_timer >= m.auto_buy_interval:
			m.auto_buy_timer = 0.0
			var guard: int = 0
			while smart_buy(m) and guard < 20:
				guard += 1
	_update_era(m)


## Progreso offline: la inflación corre igual, pero no hay clics ni eventos.
static func simulate_offline(m: GameModel, seconds: float) -> Dictionary:
	var cap: float = B("offline_cap_hours") * 3600.0
	var total: float = clampf(seconds, 0.0, cap)
	var step: float = B("offline_step")
	var money_before: BigNumber = m.money
	var power_before: BigNumber = purchasing_power(m)
	var months_before: int = m.month_count
	var t: float = 0.0
	while t < total:
		var dt: float = minf(step, total - t)
		tick(m, dt, true)
		t += dt
	return {
		"seconds": total, "capped": seconds > cap, "months": m.month_count - months_before,
		"money_before": money_before, "money_after": m.money,
		"power_before": power_before, "power_after": purchasing_power(m),
	}


# =====================================================================
#  Estadísticas (para logros)
# =====================================================================
static func stats(m: GameModel) -> Dictionary:
	var refuge_real: BigNumber = refuge_value_total_real(m)
	var ml: float = m.money.log10()
	var pl: float = purchasing_power(m).log10()
	return {
		"clicks": m.clicks, "remarks": m.remarks, "buildings": m.total_businesses(),
		"upgrades": m.upgrades.size(), "era": m.era, "events_seen": m.events_seen,
		"reforms": m.reforms, "plans": m.plans_done, "album": m.album.size(),
		"minutes": m.time_played / 60.0, "zeros_cut": m.zeros_cut, "measures": m.measures,
		"won": 1 if m.won else 0, "rate_pct": inflation_rate(m) * 100.0,
		"refuge_any": 1 if not refuge_real.is_zero() else 0,
		"money_log10": ml if not is_inf(ml) else -1.0,
		"power_log10": pl if not is_inf(pl) else -1.0,
	}
