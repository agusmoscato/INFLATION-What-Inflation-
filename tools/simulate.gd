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
var timbero: bool = false
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
		elif a == "--timbero":
			timbero = true
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
	m.intro_grace = true
	var total: int = int(hours * 3600.0)
	var last_era: int = 1
	var max_gap: float = 0.0
	var last_purchase_t: int = 0
	var purchases: int = 0
	for t in range(total):
		EconomyLogic.do_click(m)
		if Unlocks.has(m, "remark") and m.remark_window > 0.0 and EconomyLogic.needs_remark(m):
			EconomyLogic.remark(m, true)
		_event_policy(m)
		var saving: bool = false
		var port_saving: bool = false
		if timbero and t % 30 == 0:
			_timba_policy(m)
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
	const TOTAL: int = 900                 # 15 minutos
	const FIRST_MINUTES: int = 900         # el control de duración de objetivos vale para los primeros 15 minutos
	const MAX_OBJ_S: int = 90              # ningún objetivo puede durar más de 90 s ahí
	const MIN_BUYS_2MIN: int = 6           # y tiene que haber al menos 6 compras en los primeros 2 minutos
	const CLICKS_PER_S: float = 2.5
	var m: GameModel = GameModel.new(seed_value)
	m.intro_grace = true
	var seen: Array = [0]
	var click_acc: float = 0.0
	var buys: Array = []              # [[segundo, "biz:empanadas"|"upg:click1"], ...]
	var obj_start: Dictionary = {}    # id -> segundo en que pasó a ser el objetivo
	var obj_log: Array = []           # [[id, inicio, fin]]
	var unlock_log: Array = []        # [[segundo, mecánica], ...]
	var cur_id: String = ""
	var cur_since: int = 0
	var rec_key: String = ""         # recomendación actual y desde cuándo (un jugador tarda ~2 s en reaccionar)
	var rec_since: int = 0
	var red_secs: int = 0            # segundos seguidos con el semáforo en rojo
	var red_episodes: Array = []     # [[inicio, duración]] de cada tramo en rojo de 3 s o más
	var red_start: int = 0
	for t in range(TOTAL):
		click_acc += CLICKS_PER_S
		while click_acc >= 1.0:
			click_acc -= 1.0
			EconomyLogic.do_click(m)
		# un jugador obediente hace lo que marca la pantalla: la acción destacada (que coincide con el objetivo)
		var rec: Dictionary = Advisor.recommend(m, seen)
		var key: String = "%s:%s" % [rec["kind"], rec["id"]]
		if key != rec_key:
			rec_key = key
			rec_since = t
		var reacted: bool = t - rec_since >= 3      # un jugador necesita ~3 s para leer la flecha y tocar
		match str(rec["kind"]) if reacted else "":
			"buy":
				if EconomyLogic.buy_business(m, str(rec["id"]), 1) > 0:
					buys.append([t, "biz:" + str(rec["id"])])
			"upgrade":
				if EconomyLogic.buy_upgrade(m, str(rec["id"])):
					buys.append([t, "upg:" + str(rec["id"])])
			"remark":
				EconomyLogic.remark(m, true)
			"tab":
				seen.append(int(rec["id"]))
		EconomyLogic.tick(m, 1.0)
		# semáforo: ¿en rojo? (tramos de 3 s o más, para contar los "momentos de tensión")
		if not bool(EconomyLogic.race(m)["winning"]) and Unlocks.has(m, "inflation"):
			if red_secs == 0:
				red_start = t
			red_secs += 1
		else:
			if red_secs >= 3:
				red_episodes.append([red_start, red_secs])
			red_secs = 0
		for n in m.notifications:
			if n["sig"] == "unlock":
				unlock_log.append([t, str(n["args"][0])])
		m.notifications.clear()
		var cur: Dictionary = ObjectiveLogic.current(m)
		var id_now: String = str(cur["id"])
		if id_now != cur_id:
			if cur_id != "":
				obj_log.append([cur_id, cur_since, t])
			cur_id = id_now
			cur_since = t
	obj_log.append([cur_id, cur_since, TOTAL])
	print("")
	print("QA jugador nuevo OBEDIENTE (%d min simulados, semilla %d, %.1f clics/s)" % [TOTAL / 60, seed_value, CLICKS_PER_S])
	var csv: String = "objetivo,desde_s,hasta_s,duracion_s\n"
	var long_objs: Array = []
	for o in obj_log:
		var dur: int = int(o[2]) - int(o[1])
		csv += "%s,%d,%d,%d\n" % [o[0], o[1], o[2], dur]
		print("  %4d s -> %4d s  (%3d s)  %s" % [o[1], o[2], dur, o[0]])
		if int(o[1]) < FIRST_MINUTES and dur > MAX_OBJ_S:
			long_objs.append("%s (%d s)" % [o[0], dur])
	# compras
	var buys_2min: int = 0
	var first_cart: int = -1
	var first_kiosk: int = -1
	for b in buys:
		if int(b[0]) < 120:
			buys_2min += 1
		if first_cart < 0 and str(b[1]) == "biz:empanadas":
			first_cart = int(b[0])
		if first_kiosk < 0 and str(b[1]) == "biz:kiosco":
			first_kiosk = int(b[0])
	print("Primer carrito: %d s | primer kiosco: %d s | compras en los primeros 2 min: %d (mínimo %d)" % [first_cart, first_kiosk, buys_2min, MIN_BUYS_2MIN])
	var buys_ok: bool = buys_2min >= MIN_BUYS_2MIN and first_cart >= 0 and first_cart <= 12 and first_kiosk >= 0 and first_kiosk <= 90
	print("Compras iniciales: %s" % ("PASA" if buys_ok else "FALLA (carrito antes de 12 s, kiosco antes de 90 s y 6 compras en 2 min)"))
	var dur_ok: bool = long_objs.is_empty()
	print("Objetivos de más de %d s en los primeros %d min: %s" % [MAX_OBJ_S, FIRST_MINUTES / 60, "ninguno -> PASA" if dur_ok else "FALLA: " + ", ".join(long_objs)])
	# ritmo de desbloqueos: como mucho una mecánica cada 2 minutos y en el orden pensado
	print("Desbloqueos (segundo, mecánica):")
	var pace_ok: bool = true
	var expect: Array = ["inflation", "remark", "upgrades", "album"]
	for i in range(unlock_log.size()):
		var u: Array = unlock_log[i]
		print("  %4d s (min %.1f)  %s" % [u[0], float(u[0]) / 60.0, u[1]])
		if i > 0 and float(u[0]) - float(unlock_log[i - 1][0]) < 120.0:
			print("    ^ demasiado pegado al anterior (< 120 s)")
			pace_ok = false
		if i < expect.size() and str(u[1]) != expect[i]:
			print("    ^ se esperaba %s" % expect[i])
			pace_ok = false
	if unlock_log.size() < 4:
		print("  (faltan desbloqueos de la cadena temprana en %d min)" % [TOTAL / 60])
		pace_ok = false
	print("Ritmo de desbloqueos: %s" % ("PASA" if pace_ok else "FALLA"))
	# tensión entre los minutos 5 y 15: el semáforo tiene que ponerse rojo al menos 2 veces (3 s o más)
	var tension_n: int = 0
	for e in red_episodes:
		if int(e[0]) >= 300:
			tension_n += 1
	print("Momentos de tensión (semáforo en rojo 3 s o más) entre los minutos 5 y 15: %d (mínimo 2)" % tension_n)
	var tension_ok: bool = tension_n >= 2
	print("Tensión: %s" % ("PASA" if tension_ok else "FALLA"))
	var ok: bool = buys_ok and dur_ok and pace_ok and tension_ok
	print("RESULTADO: %s" % ("PASA" if ok else "FALLA"))
	var f: FileAccess = FileAccess.open("res://docs/qa_newplayer.csv", FileAccess.WRITE)
	if f != null:
		f.store_string(csv)
		f.close()
	quit(0 if ok else 1)


## Modo "timbero": juega todo el tiempo a la timba (raspadita 5 %, quiniela y dólar al azar, 5 % de su plata cada 30 s).
func _timba_policy(m: GameModel) -> void:
	if Unlocks.has(m, "timba"):
		GambleLogic.play_scratch(m, 0.05)
	if Unlocks.has(m, "quiniela"):
		GambleLogic.place_quiniela(m, m.rng.randi_range(0, 99), GambleLogic.stake_for(m, 0.05, GambleLogic.quiniela_stake_max(m)))
	if Unlocks.has(m, "dollar"):
		GambleLogic.place_dollar(m, "up" if m.rng.randf() < 0.5 else "down", GambleLogic.stake_for(m, 0.05, GambleLogic.dollar_stake_max(m)))
	m.notifications.clear()
