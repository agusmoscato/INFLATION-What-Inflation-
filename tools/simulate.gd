extends SceneTree
## Simulador headless del clicker con renacimientos. Juega con tres jugadores de prueba (scripts/core/bot_policy.gd:
## activo, pasivo y distraído) hasta el 100 % (o 5 h) y escribe docs/balance_v2.md.
## Uso: godot --headless --script tools/simulate.gd [-- --seeds=1,2 --profiles=activo,pasivo,distraido --qa --quiet]
##   --qa        termina con código 1 si algún chequeo falla
##   --seeds     semillas del jugador activo (los otros dos juegan con la primera)
##   --trace     imprime cada reforma y el estado cada 30 s de los primeros 10 minutos
##
## Chequeos para los tres jugadores (la regla de oro: nunca trabado y cada vuelta mejor que la anterior):
##   - nunca más de 20 s sin poder comprar nada ni reformar
##   - la vuelta 2 llega a la plata de la vuelta 1 en menos de la mitad del tiempo (y nunca más lenta)
##   - ninguna reforma da menos de 5 de Credibilidad; la primera da entre 5 y 10
##   - en el primer minuto de la vuelta 1, los clics son la fuente principal de plata (salvo el pasivo, que casi no clickea)
## Duración (jugador activo): primera reforma 4–6 min, final 50–70 min, 100 % en 3–4 h, vuelta 10 cinco veces más rápida.

const STEP: float = 0.25

const FIRST_REFORM_MIN: Array = [4.0, 6.0]
const FINAL_MIN: Array = [50.0, 70.0]
const FULL_MIN: Array = [180.0, 240.0]
const FIRST_CRED: Array = [5.0, 10.0]
const MAX_GAP_S: float = 20.0
const MAX_UPG_GAP_S: float = 20.0   ## en la primera hora, nunca más de 20 s sin una mejora que se pueda pagar ya o juntando 20 s
const MIN_CRED: int = 5
const SPEEDUP_10: float = 5.0       ## la vuelta 10 llega a la plata de la vuelta 1 en <= 1/5 del tiempo
const SPEEDUP_2: float = 2.0        ## la vuelta 2, en menos de la mitad


var quiet: bool = false
var trace: bool = false
var out_path: String = "res://docs/balance_v2.md"


func _init() -> void:
	var hours: float = 5.0
	var seeds: Array = [1]
	var profiles: Array = ["activo", "pasivo", "distraido"]
	var qa: bool = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--hours="):
			hours = a.get_slice("=", 1).to_float()
		elif a.begins_with("--seed="):
			seeds = [a.get_slice("=", 1).to_int()]
		elif a.begins_with("--seeds="):
			seeds = []
			for s in a.get_slice("=", 1).split(","):
				seeds.append(int(s))
		elif a.begins_with("--profiles="):
			profiles = Array(a.get_slice("=", 1).split(","))
		elif a == "--qa":
			qa = true
		elif a == "--quiet":
			quiet = true
		elif a == "--trace":
			trace = true
		elif a.begins_with("--out="):
			out_path = a.get_slice("=", 1)
	var started: int = Time.get_ticks_msec()
	var all_ok: bool = true
	var results: Array = []
	for p in profiles:
		var sl: Array = seeds if p == "activo" else [seeds[0]]
		for sd in sl:
			print("== %s, semilla %d" % [p, int(sd)])
			var r: Dictionary = run_sim(int(sd), hours, str(p))
			results.append(r)
			all_ok = all_ok and bool(r["ok"])
	_write_report(results)
	print("Simulación en %.1f s reales. Reporte: %s" % [float(Time.get_ticks_msec() - started) / 1000.0, out_path])
	print("RESULTADO: %s" % ("PASA" if all_ok else "FALLA"))
	quit(1 if (qa and not all_ok) else 0)


# =====================================================================
#  Una partida completa
# =====================================================================
func run_sim(seed_value: int, hours: float, profile: String) -> Dictionary:
	var m: GameModel = GameModel.new(seed_value)
	var ach: LocalAchievements = LocalAchievements.new(m.achievements)
	var bot: BotPolicy = BotPolicy.new(seed_value, profile)
	var total_steps: int = int(hours * 3600.0 / STEP)
	var reforms: Array = []                 # [{n, minute, dur, earned, cred, nodes_bought}]
	var final_min: float = -1.0
	var full_min: float = -1.0
	var last_ok_t: float = 0.0
	var last_upg_t: float = 0.0
	var max_upg_gap: float = 0.0
	var upg_gap_at: float = 0.0
	var max_gap: float = 0.0
	var gap_at: float = 0.0
	var run1_target: BigNumber = null
	var reach_times: Dictionary = {}        # vuelta -> segundos hasta llegar a la plata máxima de la vuelta 1
	var click_money: float = 0.0            # plata de clics en el primer minuto de la vuelta 1
	var total_money: float = 0.0
	var t: float = 0.0
	for step in range(total_steps):
		t = float(step) * STEP
		var n_before: int = TreeLogic.count(m)
		var earned: BigNumber = m.run_earned
		var dur: float = m.run_time
		var idx: int = m.run_index
		var first_min_run: bool = m.run_index == 1 and m.run_time < 60.0
		var e0: float = m.run_earned.to_float()
		# ¿se puede hacer algo? (comprar o reformar) — se mira antes de que el bot compre
		if EconomyLogic.anything_affordable(m) or EconomyLogic.can_reform(m):
			if t - last_ok_t > max_gap:
				max_gap = t - last_ok_t
				gap_at = t
			last_ok_t = t
		if t <= 3600.0 and EconomyLogic.any_upgrade_affordable(m, 20.0):
			if t - last_upg_t > max_upg_gap:
				max_upg_gap = t - last_upg_t
				upg_gap_at = t
			last_upg_t = t
		var upg_before: int = m.upgrades.size()
		var bought_before: int = m.total_businesses() + m.upgrades.size() + TreeLogic.count(m)
		if trace and t - last_ok_t > 20.0 and int(t / STEP) % 20 == 0:
			print("    ESPERA %.0f s (min %.1f) vuelta %d (%.0f s) plata=%s $/s=%s P=%.2f más barato=%s puede reformar=%s meta=%s ganado=%s" % [t - last_ok_t, t / 60.0,
				m.run_index, m.run_time, m.money.format(), EconomyLogic.income_per_sec(m).format(), EconomyLogic.price_level(m).to_float(),
				EconomyLogic.cheapest_business(m).format(), str(EconomyLogic.can_reform(m)), EconomyLogic.reform_target(m).format(), m.run_earned.format()])
		var s: Dictionary = bot.step(m, STEP)
		if m.upgrades.size() > upg_before and s.is_empty():
			last_upg_t = t
		if m.total_businesses() + m.upgrades.size() + TreeLogic.count(m) > bought_before:
			last_ok_t = t          # compró algo en este paso (la plata del clic llegó y la gastó enseguida)
		if first_min_run and s.is_empty():
			click_money += maxf(0.0, m.run_earned.to_float() - e0)
		if not s.is_empty():
			if run1_target == null:
				run1_target = earned
				reach_times[1] = dur
			reforms.append({"n": idx, "minute": t / 60.0, "dur": dur, "earned": earned, "cred": int(s["cred"]),
				"nodes_bought": TreeLogic.count(m) - n_before})
			if trace:
				print("  REFORMA %d min %.1f ganado=%s +%d cred (quedan %d) -> nodos: %s" % [idx, t / 60.0, earned.format(), int(s["cred"]), m.credibility,
					str(m.tree.keys().slice(n_before))])
		EconomyLogic.tick(m, STEP)
		if first_min_run:
			total_money = m.run_earned.to_float()
		if run1_target != null and not reach_times.has(m.run_index) and m.run_earned.ge(run1_target):
			reach_times[m.run_index] = m.run_time
		m.notifications.clear()
		if step % 4 == 0:
			AchievementTracker.check(m, ach)
		if m.won and final_min < 0.0:
			final_min = (t + STEP) / 60.0
		if full_min < 0.0 and TreeLogic.complete(m) and StickerLogic.missing_count(m) == 0 and m.achievements.size() >= GameData.achievements.size():
			full_min = (t + STEP) / 60.0
			break
		if trace and step % int(30.0 / STEP) == 0 and t <= 900.0:
			print("    %4.0f s vuelta %d (%3.0f s) ganado=%s plata=%s $/s=%s clic=%s P=%s mensual=%.0f%% gain=%.2f negocios=%d mejoras=%d/%d" % [t, m.run_index, m.run_time,
				m.run_earned.format(), m.money.format(), EconomyLogic.income_per_sec(m).format(), EconomyLogic.click_value(m).format(),
				EconomyLogic.price_level(m).format(), EconomyLogic.monthly_pct(m), EconomyLogic.reform_gain_f(m), m.total_businesses(),
				m.upgrades.size(), EconomyLogic.visible_upgrades(m).size()])
		if not quiet and step % int(900.0 / STEP) == 0:
			print("  t=%5.1f min vuelta=%d reformas=%d cred=%d(total %d) nodos=%d figus=%d logros=%d ganado=%s P=%s" % [t / 60.0, m.run_index, m.reforms,
				m.credibility, m.cred_total, TreeLogic.count(m), m.stickers.size(), m.achievements.size(), m.run_earned.format(),
				EconomyLogic.price_level(m).format()])
		# los jugadores pasivo y distraído se miden hasta el final + 1 hora (alcanza para ver que nunca se traban)
		if profile != "activo" and final_min > 0.0 and t > (final_min + 60.0) * 60.0:
			break
	# ---- verificación ----
	var checks: Array = []
	var first_min: float = float(reforms[0]["minute"]) if not reforms.is_empty() else -1.0
	var first_cred: float = float(reforms[0]["cred"]) if not reforms.is_empty() else -1.0
	var min_cred: int = 1 << 30
	var min_cred_n: int = 0
	for f in reforms:
		if int(f["cred"]) < min_cred:
			min_cred = int(f["cred"])
			min_cred_n = int(f["n"])
	if reforms.is_empty():
		min_cred = 0
	var r1: float = float(reach_times.get(1, -1.0))
	var r2: float = float(reach_times.get(2, -1.0))
	var r10: float = float(reach_times.get(10, -1.0))
	checks.append({"name": "Máxima espera sin poder comprar ni reformar (s)", "value": max_gap, "target": "<= %d" % int(MAX_GAP_S),
		"ok": max_gap <= MAX_GAP_S, "note": "en el min %.1f" % (gap_at / 60.0)})
	if t - last_upg_t > max_upg_gap and last_upg_t < 3600.0:
		max_upg_gap = minf(t, 3600.0) - last_upg_t
		upg_gap_at = minf(t, 3600.0)
	checks.append({"name": "Máxima espera sin mejora a tiro (<= 20 s de ingreso), 1.ª hora (s)", "value": max_upg_gap, "target": "<= %d" % int(MAX_UPG_GAP_S),
		"ok": max_upg_gap <= MAX_UPG_GAP_S, "note": "en el min %.1f" % (upg_gap_at / 60.0)})
	checks.append({"name": "Vuelta 2 llega a la plata de la vuelta 1 (s)", "value": r2, "target": "< %.0f (1/2 de %.0f)" % [r1 / SPEEDUP_2, r1],
		"ok": r2 > 0.0 and r1 > 0.0 and r2 * SPEEDUP_2 < r1, "note": ""})
	checks.append({"name": "Credibilidad mínima en una reforma", "value": float(min_cred), "target": ">= %d" % MIN_CRED,
		"ok": min_cred >= MIN_CRED, "note": "vuelta %d" % min_cred_n})
	checks.append(_chk("Credibilidad de la primera reforma", first_cred, FIRST_CRED))
	var share: float = click_money / maxf(1.0, total_money) * 100.0
	if profile != "pasivo":
		checks.append({"name": "Plata de clics en el primer minuto (%)", "value": share, "target": ">= 50", "ok": share >= 50.0, "note": ""})
	if profile == "activo":
		checks.append(_chk("Primer renacimiento (min)", first_min, FIRST_REFORM_MIN))
		checks.append(_chk("Final: Estabilizar la economía (min)", final_min, FINAL_MIN))
		checks.append(_chk("100 %: árbol + álbum + logros (min)", full_min, FULL_MIN))
		checks.append({"name": "Vuelta 10 llega a la plata de la vuelta 1 (s)", "value": r10, "target": "<= %.0f (1/5 de %.0f)" % [r1 / SPEEDUP_10, r1],
			"ok": r10 > 0.0 and r1 > 0.0 and r10 * SPEEDUP_10 <= r1, "note": ""})
	else:
		checks.append({"name": "Primer renacimiento (min)", "value": first_min, "target": "(informativo)", "ok": first_min > 0.0, "note": ""})
		checks.append({"name": "Final: Estabilizar la economía (min)", "value": final_min, "target": "(informativo)", "ok": final_min > 0.0, "note": ""})
	var ok: bool = true
	for c in checks:
		ok = ok and bool(c["ok"])
		print("%-50s %8.1f  objetivo %-20s %s" % [c["name"], float(c["value"]), str(c["target"]), "PASA" if c["ok"] else "FALLA"])
	return {"seed": seed_value, "profile": profile, "ok": ok, "checks": checks, "reforms": reforms, "final": final_min, "full": full_min,
		"reach": reach_times, "missing_ach": _missing_ach(m), "nodes": TreeLogic.count(m), "stickers": m.stickers.size(),
		"ach": m.achievements.size(), "minutes": t / 60.0, "zeros": m.zeros_cut, "runs": m.run_index}


func _chk(name: String, v: float, rng: Array) -> Dictionary:
	return {"name": name, "value": v, "target": "%.0f–%.0f" % [rng[0], rng[1]], "ok": v >= float(rng[0]) and v <= float(rng[1]), "note": ""}


func _missing_ach(m: GameModel) -> Array:
	var out: Array = []
	for a in GameData.achievements:
		if not m.achievements.has(a["id"]):
			out.append(a["id"])
	return out


# =====================================================================
#  Reporte
# =====================================================================
const PROFILE_NAME: Dictionary = {"activo": "Activo (clickea mucho)", "pasivo": "Pasivo (casi no clickea, compra lo más barato)",
	"distraido": "Distraído (deja de jugar 2 min a mitad de la vuelta)"}


func _write_report(results: Array) -> void:
	var s: String = "# Balance v2 (simulador)\n\n"
	s += "Generado por `godot --headless --script tools/simulate.gd`. Los jugadores de prueba están descriptos en "
	s += "`scripts/core/bot_policy.gd`; los objetivos, en [DISENO_V2.md](DISENO_V2.md).\n\n"
	s += "## Chequeos\n\n| Jugador | Semilla | Chequeo | Valor | Objetivo | Resultado |\n| --- | --- | --- | --- | --- | --- |\n"
	for res in results:
		for c in res["checks"]:
			var note: String = (" (" + str(c["note"]) + ")") if str(c["note"]) != "" else ""
			s += "| %s | %d | %s | %.1f%s | %s | %s |\n" % [res["profile"], res["seed"], c["name"], float(c["value"]), note, c["target"], "PASA" if c["ok"] else "**FALLA**"]
	var shown: Dictionary = {}
	for r in results:
		if shown.has(r["profile"]):
			continue
		shown[r["profile"]] = true
		s += "\n## %s, semilla %d\n\n" % [PROFILE_NAME.get(r["profile"], r["profile"]), r["seed"]]
		s += "| Vuelta | Minuto | Duración | Plata máxima ganada | +Credibilidad | Nodos comprados después | Llega a la plata de la vuelta 1 en |\n"
		s += "| --- | --- | --- | --- | --- | --- | --- |\n"
		var reach: Dictionary = r["reach"]
		var rows: Array = r["reforms"]
		for i in range(rows.size()):
			var f: Dictionary = rows[i]
			if i >= 25 and i < rows.size() - 3:
				if i == 25:
					s += "| … | | | | | | |\n"
				continue
			var n: int = int(f["n"])
			var rt: String = ("%.0f s" % float(reach[n])) if reach.has(n) else "—"
			s += "| %d | %.1f | %d:%02d | $%s | %d | %d | %s |\n" % [n, float(f["minute"]), int(f["dur"]) / 60, int(f["dur"]) % 60,
				(f["earned"] as BigNumber).format(), int(f["cred"]), int(f.get("nodes_bought", 0)), rt]
		s += "\n- Final (Estabilizar la economía): minuto **%.1f**\n" % float(r["final"])
		if float(r["full"]) > 0.0:
			s += "- 100 %%: minuto **%.1f**\n" % float(r["full"])
		s += "- Al terminar la simulación (min %.0f): nodos %d/%d, figuritas %d/%d, logros %d/%d, vueltas %d\n" % [float(r["minutes"]), int(r["nodes"]),
			TreeLogic.total(), int(r["stickers"]), StickerLogic.total(), int(r["ach"]), GameData.achievements.size(), int(r["runs"])]
		if r["profile"] == "activo" and not (r["missing_ach"] as Array).is_empty():
			s += "- Logros que faltaron: %s\n" % ", ".join(r["missing_ach"])
	var f2: FileAccess = FileAccess.open(out_path, FileAccess.WRITE)
	if f2 != null:
		f2.store_string(s)
		f2.close()
