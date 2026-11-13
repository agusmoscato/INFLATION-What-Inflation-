extends SceneTree
## Simulador headless: juega hasta 10 horas con una estrategia simple y escribe docs/balance.csv.
## Uso: godot --headless --script tools/simulate.gd [-- --hours=10 --seed=1]
##
## Estrategia del bot (un jugador "promedio" activo):
##  - 1 clic por segundo.
##  - Remarca apenas aparece el cartel de aumento (cobra el bono "a tiempo").
##  - Compra lo más rentable (EconomyLogic.smart_buy) cada 2 s.
##  - Hace reforma cuando la Credibilidad ganada >= max(REFORM_MIN_GAIN, credibilidad_actual * REFORM_RATIO).
##  - Hace plan económico apenas puede (alterna Emisión / Estabilización).
##  - Compra medidas antiinflacionarias en la Era 5 apenas puede.
## No usa refugios (solo su arrastre en reformas): documentado en README.

const REFORM_MIN_GAIN: int = 4
const REFORM_RATIO: float = 1.0
const REFORM_MIN_RUN_MIN: float = 40.0
const PLAN_ORDER: Array = ["emission", "convertibility", "stabilization"]

var rows: Array = []   # [evento, minuto, detalle]
var no_prestige: bool = false


func _init() -> void:
	var hours: float = 10.0
	var seed_value: int = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--hours="):
			hours = a.get_slice("=", 1).to_float()
		elif a == "--noprestige":
			no_prestige = true
		elif a.begins_with("--seed="):
			seed_value = a.get_slice("=", 1).to_int()
	var started: int = Time.get_ticks_msec()
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
		var saving: bool = false
		if m.era >= 5 and m.measures < EconomyLogic.measure_count_total():
			if EconomyLogic.buy_measure(m):
				rows.append(["medida", float(t) / 60.0, "medidas=%d" % m.measures])
			saving = EconomyLogic.income_per_sec(m).mul_f(900.0).ge(EconomyLogic.measure_cost(m))
		if t % 2 == 0 and not saving:
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
		"era=%d cred=%d reformas=%d planes=%d compras=%d max_espera_s=%.0f medidas=%d" % [m.era, m.credibility, m.reforms, m.plans_done, purchases, max_gap, m.measures]])
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
