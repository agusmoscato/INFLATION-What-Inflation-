extends SceneTree
## Simulador headless: juega hasta 10 horas con una estrategia simple y escribe docs/balance.csv.
## Uso: godot --headless --script tools/simulate.gd [-- --hours=10 --seed=1]
##
## Estrategia del bot (un jugador "promedio" activo):
##  - 1 clic por segundo.
##  - Remarca apenas aparece el cartel de aumento (cobra el bono "a tiempo").
##  - Compra lo más rentable (EconomyLogic.smart_buy) cada 2 s.
##  - Reforma cada >= 40 min si la Credibilidad ganada >= max(REFORM_MIN_GAIN, credibilidad_actual * REFORM_RATIO).
##  - Hace cada plan económico (Emisión, Convertibilidad, Estabilización) apenas puede.
##  - En la Era 5 ahorra para las medidas antiinflacionarias y las compra apenas puede.
## No usa refugios (solo su arrastre en reformas): documentado en README.

const REFORM_MIN_GAIN: int = 4
const REFORM_RATIO: float = 1.0
const REFORM_MIN_RUN_MIN: float = 40.0
const PLAN_ORDER: Array = ["emission", "convertibility", "stabilization"]

var rows: Array = []   # [evento, minuto, detalle]
var no_prestige: bool = false
var use_refuges: bool = true
var qa_newplayer: bool = false
var do_park: bool = true
var do_events: bool = true       ## false = siempre la opción por defecto de los eventos (--defaultevents)
var refuge_stats: Dictionary = {"parked": 0, "sold": 0, "event_sells": 0, "strikes": 0}

const SAVE_PAYBACK_S: float = 600.0   ## ahorra para la cartera si lo mejor a comprar repaga en más de esto


func _init() -> void:
	var hours: float = 10.0
	var seed_value: int = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--hours="):
			hours = a.get_slice("=", 1).to_float()
		elif a == "--nopark":
			do_park = false
		elif a == "--noevents":
			do_events = false
		elif a == "--defaultevents":
			do_events = false
		elif a == "--norefuges":
			use_refuges = false
		elif a == "--qa-newplayer":
			qa_newplayer = true
		elif a == "--noprestige":
			no_prestige = true
		elif a.begins_with("--seed="):
			seed_value = a.get_slice("=", 1).to_int()
	var started: int = Time.get_ticks_msec()
	if qa_newplayer:
		_qa_newplayer(seed_value)
		return
	var m: GameModel = GameModel.new(seed_value)
	var total: int = int(hours * 3600.0)
	var last_era: int = 1
	var max_gap: float = 0.0
	var last_purchase_t: int = 0
	var purchases: int = 0
	for t in range(total):
		EconomyLogic.do_click(m)
		if m.remark_window > 0.0 and EconomyLogic.needs_remark(m):
			EconomyLogic.remark(m, true)
		_event_policy(m)
		var saving: bool = false
		var port_saving: bool = false
		if m.era >= 5 and m.measures < EconomyLogic.measure_count_total():
			if EconomyLogic.buy_measure(m):
				rows.append(["medida", float(t) / 60.0, "medidas=%d" % m.measures])
			saving = EconomyLogic.income_per_sec(m).mul_f(900.0).ge(EconomyLogic.measure_cost(m))
		if use_refuges and t % 2 == 0:
			port_saving = _refuge_policy(m)
		if t % 2 == 0 and not saving and not port_saving:
			var guard: int = 0
			var bought_any: bool = false
			while guard < 40 and EconomyLogic.smart_buy(m):
				guard += 1
				bought_any = true
			if bought_any:
				purchases += 1
				max_gap = maxf(max_gap, float(t - last_purchase_t))
				last_purchase_t = t
		if m.era >= 5:
			EconomyLogic.buy_measure(m)
		if no_prestige:
			pass
		elif EconomyLogic.can_plan(m):
			var plan: String = PLAN_ORDER[m.plans_used.size()]
			var minute_p: float = float(t) / 60.0
			EconomyLogic.do_plan(m, plan)
			rows.append(["plan", minute_p, "plan=%s n=%d" % [plan, m.plans_done]])
		elif EconomyLogic.can_reform(m) and not saving:
			var gain: int = EconomyLogic.reform_gain(m)
			if m.run_time >= REFORM_MIN_RUN_MIN * 60.0 and gain >= maxi(REFORM_MIN_GAIN, int(float(m.credibility) * REFORM_RATIO)):
				var minute_r: float = float(t) / 60.0
				var p_log: float = m.price_level.log10()
				EconomyLogic.do_reform(m)
				rows.append(["reforma", minute_r, "n=%d cred=%d P=1e%.1f" % [m.reforms, m.credibility, p_log]])
		EconomyLogic.tick(m, 1.0)
		m.notifications.clear()
		if m.era != last_era:
			last_era = m.era
			rows.append(["era", float(t) / 60.0, "era=%d" % m.era])
		if m.won:
			rows.append(["victoria", float(t) / 60.0, "inflación 0 (medidas=%d)" % m.measures])
			break
		if t % 900 == 0:
			print("  t=%4.0f min era=%d cred=%d life=1e%.1f money=%s P=%s inc/s=%s" % [float(t) / 60.0, m.era, m.credibility, m.lifetime_real.log10(),
				m.money.format(), m.price_level.format(), EconomyLogic.income_per_sec(m).format()])
	rows.append(["fin", float(total) / 60.0 if not m.won else rows[rows.size() - 1][1],
		"era=%d cred=%d reformas=%d planes=%d compras=%d max_espera_s=%.0f medidas=%d refugios=%s" % [m.era, m.credibility, m.reforms, m.plans_done, purchases, max_gap, m.measures, str(refuge_stats)]])
	_report(started)
	quit(0)


func _report(started: int) -> void:
	print("")
	print("%-10s %10s  %s" % ["evento", "minuto", "detalle"])
	var csv: String = "evento,minuto,detalle\n"
	for r in rows:
		print("%-10s %10.1f  %s" % [r[0], r[1], r[2]])
		csv += "%s,%.1f,%s\n" % [r[0], r[1], str(r[2]).replace(",", ";")]
	var f: FileAccess = FileAccess.open("res://docs/balance.csv", FileAccess.WRITE)
	if f != null:
		f.store_string(csv)
		f.close()
	print("Simulación en %.1f s reales. CSV: docs/balance.csv" % [float(Time.get_ticks_msec() - started) / 1000.0])


# =====================================================================
#  Política de refugios y eventos del bot
# =====================================================================
## Mantiene una cartera diversificada: cada refugio con ahorros >= 2 min de ingresos da +5 % de ingresos.
## Ahorra para armarla solo cuando lo mejor que puede comprar rinde poco (repago > SAVE_PAYBACK_S).
## Responde a eventos:
##  - corrida cambiaria: vende el dólar que saltó (la cartera lo recompra después);
##  - cepo: no puede mover nada (se espera);
##  - paro: negocia si sale barato;
##  - aguinaldo: gasta todo el efectivo enseguida (no ahorra para la cartera mientras dura).
## Devuelve true si está ahorrando para la cartera (el bot frena sus compras).
## (Las decisiones de eventos las toma _event_policy.)
func _refuge_policy(m: GameModel) -> bool:
	if not EconomyLogic.refuges_unlocked(m):
		return false
	EconomyLogic.ensure_fresh(m)
	if EconomyLogic.refuges_blocked(m):
		return false
	if not do_park:
		return false
	var need_real: BigNumber = m.base_income.mul_f(EconomyLogic.B("refuge_bonus_seconds") * 1.15)
	if need_real.is_zero():
		return false
	for r in GameData.refuges:
		var id: String = r["id"]
		var have_real: BigNumber = m.refuge_units[id].mul_f(float(m.refuge_price[id]))
		if have_real.ge(need_real):
			continue
		var missing: BigNumber = need_real.sub(have_real).mul(m.price_level).div_f(1.0 - EconomyLogic.refuge_fee(m, id))
		if m.money.ge(missing):
			if EconomyLogic.refuge_buy(m, id, missing):
				refuge_stats["parked"] += 1
			continue
		return _best_payback(m) > SAVE_PAYBACK_S
	return false


func _best_payback(m: GameModel) -> float:
	var best: float = INF
	for c in EconomyLogic.candidates(m):
		best = minf(best, float(c["payback"]))
	return best


## Decisiones de eventos. Con --defaultevents siempre se elige la opción por defecto (como si no se contestara).
## Si no, elige según el estado:
##  - feriado: liquidar si los clics ya no valen nada frente a los ingresos; si no, abrir;
##  - aguinaldo: invertirlo (x2 durante 2 min rinde más que cobrarlo);
##  - corrida: aguantar si hay cartera diversificada (el bono vale más), vender si no;
##  - cepo: quedarse en pesos (el dólar blue sale carísimo);
##  - paro: horas extra si hay con qué pagar; si no, cerrar.
func _event_policy(m: GameModel) -> void:
	if m.pending_choice.is_empty():
		return
	var id: String = str(m.pending_choice["id"])
	var pick: int = EconomyLogic.default_choice(id)
	if do_events:
		match id:
			"feriado":
				var click: float = EconomyLogic.click_value(m).to_float()
				var inc: float = EconomyLogic.income_per_sec(m).to_float()
				pick = 1 if click < 0.1 * inc else 0
			"aguinaldo":
				pick = 1
			"corrida":
				pick = 1 if EconomyLogic.refuge_diversified_count(m) >= 1 else 0
			"cepo":
				pick = 1
			"paro":
				var cost: BigNumber = EconomyLogic.income_per_sec(m).mul_f(25.0)
				pick = 1 if cost.le(m.money) else 0
	EconomyLogic.choose(m, pick)
	refuge_stats["events"] = int(refuge_stats.get("events", 0)) + 1
	refuge_stats["event_" + id + "_" + str(pick)] = int(refuge_stats.get("event_" + id + "_" + str(pick), 0)) + 1


# =====================================================================
#  QA de jugador nuevo: los primeros 15 minutos con las acciones más obvias
# =====================================================================
## El jugador nuevo hace clic todo el tiempo, compra lo que pide el objetivo (o lo más rentable) y remarca cuando puede.
func _qa_newplayer(seed_value: int) -> void:
	const MAX_GAP: float = 60.0
	const TOTAL: int = 900
	var m: GameModel = GameModel.new(seed_value)
	var done: Array = []     # [[segundo, id], ...]
	var last_t: float = 0.0
	var max_gap: float = 0.0
	var streak: int = 0          # segundos seguidos sin nada alcanzable
	var max_streak: int = 0
	var streak_at: int = 0
	var micro_secs: int = 0
	for t in range(TOTAL):
		EconomyLogic.do_click(m)
		if m.remark_window > 0.0 and EconomyLogic.needs_remark(m):
			EconomyLogic.remark(m, true)
		if t % 2 == 0:
			var cur: Dictionary = ObjectiveLogic.current(m)
			if not cur["done"]:
				var o: Dictionary = ObjectiveLogic.LIST[m.obj_index]
				match str(o["kind"]):
					"money_biz", "own":
						EconomyLogic.buy_business(m, str(o["biz"]), 1)
					"upg_id":
						EconomyLogic.buy_upgrade(m, str(o["upg"]))
			var guard: int = 0
			while guard < 20 and EconomyLogic.smart_buy(m):
				guard += 1
		EconomyLogic.tick(m, 1.0)
		for n in m.notifications:
			if n["sig"] == "objective_done":
				max_gap = maxf(max_gap, float(t) - last_t)
				done.append([t, str(n["args"][0])])
				last_t = float(t)
		m.notifications.clear()
		# ¿hay algo alcanzable? (objetivo actual en <= 60 s o una meta chica)
		var cur2: Dictionary = ObjectiveLogic.current(m)
		var ok_now: bool = true
		if not cur2["done"]:
			var eta: float = ObjectiveLogic.eta(m, ObjectiveLogic.LIST[m.obj_index])
			if eta > MAX_GAP:
				if ObjectiveLogic.micro(m).is_empty():
					ok_now = false
				else:
					micro_secs += 1
		if ok_now:
			streak = 0
		else:
			streak += 1
			if streak > max_streak:
				max_streak = streak
				streak_at = t
	print("")
	print("QA jugador nuevo (%d min simulados, semilla %d)" % [TOTAL / 60, seed_value])
	var csv: String = "segundo,objetivo\n"
	for d in done:
		print("  %4d s  %s" % [d[0], d[1]])
		csv += "%d,%s\n" % [d[0], d[1]]
	print("Objetivos cumplidos: %d | mayor espera entre objetivos cumplidos: %.0f s" % [done.size(), max_gap])
	print("Segundos en los que el objetivo tardaba mas de 60 s y se mostro una 'meta chica': %d" % micro_secs)
	print("Mayor tramo SIN nada alcanzable: %d s (en el segundo %d)" % [max_streak, streak_at])
	var ok: bool = max_streak <= int(MAX_GAP)
	print("RESULTADO: %s (limite %d s sin objetivo alcanzable)" % ["PASA" if ok else "FALLA", int(MAX_GAP)])
	var f: FileAccess = FileAccess.open("res://docs/qa_newplayer.csv", FileAccess.WRITE)
	if f != null:
		f.store_string(csv)
		f.close()
	quit(0 if ok else 1)
