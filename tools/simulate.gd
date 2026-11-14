extends SceneTree
## Simulador headless del diseño v2 (clicker con renacimientos). Juega hasta el 100 % (o 5 h) y escribe docs/balance_v2.md.
## Uso: godot --headless --script tools/simulate.gd [-- --seed=1 --hours=5 --qa --quiet]
##   --qa       termina con código 1 si no se cumplen los objetivos de duración (docs/DISENO_V2.md, sección 1)
##   --seeds=1,2,3  corre varias semillas y verifica todas (el reporte detallado es de la primera)
##
## El bot es BotPolicy (scripts/core/bot_policy.gd), el mismo que juega el QA del juego real.

const STEP: float = 0.25

# objetivos (docs/DISENO_V2.md, sección 1)
const FIRST_REFORM_MIN: Array = [4.0, 6.0]
const FINAL_MIN: Array = [50.0, 70.0]
const FULL_MIN: Array = [180.0, 240.0]
const MAX_GAP_S: float = 20.0
const SPEEDUP: float = 5.0          ## la vuelta 10 llega a la plata de la vuelta 1 en <= 1/5 del tiempo


var quiet: bool = false
var trace: bool = false
var out_path: String = "res://docs/balance_v2.md"


func _init() -> void:
	var hours: float = 5.0
	var seeds: Array = [1]
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
	for sd in seeds:
		var r: Dictionary = run_sim(int(sd), hours)
		results.append(r)
		all_ok = all_ok and bool(r["ok"])
	_write_report(results)
	print("Simulación en %.1f s reales. Reporte: docs/balance_v2.md" % [float(Time.get_ticks_msec() - started) / 1000.0])
	print("RESULTADO: %s" % ("PASA" if all_ok else "FALLA"))
	quit(1 if (qa and not all_ok) else 0)


# =====================================================================
#  Una partida completa
# =====================================================================
func run_sim(seed_value: int, hours: float) -> Dictionary:
	var m: GameModel = GameModel.new(seed_value)
	var ach: LocalAchievements = LocalAchievements.new(m.achievements)
	var bot: BotPolicy = BotPolicy.new(seed_value)
	var total_steps: int = int(hours * 3600.0 / STEP)
	var reforms: Array = []                 # [{n, minute, dur, earned, cred, nodes_bought}]
	var final_min: float = -1.0
	var full_min: float = -1.0
	var last_afford_t: float = 0.0
	var max_gap: float = 0.0
	var gap_at: float = 0.0
	var run1_target: BigNumber = null
	var reach_times: Dictionary = {}        # vuelta -> segundos hasta llegar a la plata máxima de la vuelta 1
	var t: float = 0.0
	for step in range(total_steps):
		t = float(step) * STEP
		var n_before: int = TreeLogic.count(m)
		var cred_before: int = m.credibility
		var earned: BigNumber = m.run_earned
		var dur: float = m.run_time
		var idx: int = m.run_index
		var s: Dictionary = bot.step(m, STEP)
		if not s.is_empty():
			if run1_target == null:
				run1_target = earned
				reach_times[1] = dur
			reforms.append({"n": idx, "minute": t / 60.0, "dur": dur, "earned": earned, "cred": int(s["cred"]),
				"nodes_bought": TreeLogic.count(m) - n_before})
			if trace:
				print("  REFORMA %d min %.1f ganado=%s +%d cred (quedan %d) -> nodos: %s" % [idx, t / 60.0, earned.format(), int(s["cred"]), m.credibility,
					str(m.tree.keys().slice(n_before))])
		# ¿algo comprable? (primera hora)
		if t <= 3600.0 and EconomyLogic.anything_affordable(m):
			if t - last_afford_t > max_gap:
				max_gap = t - last_afford_t
				gap_at = t
			last_afford_t = t
		EconomyLogic.tick(m, STEP)
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
		if trace and step % int(30.0 / STEP) == 0 and t <= 600.0:
			print("    %4.0f s vuelta %d (%3.0f s) ganado=%s plata=%s $/s=%s P=%s mensual=%.0f%% gain=%.2f negocios=%d mejoras=%d" % [t, m.run_index, m.run_time,
				m.run_earned.format(), m.money.format(), EconomyLogic.income_per_sec(m).format(), EconomyLogic.price_level(m).format(),
				EconomyLogic.monthly_pct(m), EconomyLogic.reform_gain_f(m), m.total_businesses(), m.upgrades.size()])
		if not quiet and step % int(900.0 / STEP) == 0:
			print("  t=%5.1f min vuelta=%d reformas=%d cred=%d(total %d) nodos=%d figus=%d logros=%d ganado=%s P=%s" % [t / 60.0, m.run_index, m.reforms,
				m.credibility, m.cred_total, TreeLogic.count(m), m.stickers.size(), m.achievements.size(), m.run_earned.format(),
				EconomyLogic.price_level(m).format()])
	# ---- verificación ----
	var checks: Array = []
	var first_min: float = float(reforms[0]["minute"]) if not reforms.is_empty() else -1.0
	checks.append(_chk("Primer renacimiento (min)", first_min, FIRST_REFORM_MIN))
	checks.append(_chk("Final: Estabilizar la economía (min)", final_min, FINAL_MIN))
	checks.append(_chk("100 %: árbol + álbum + logros (min)", full_min, FULL_MIN))
	checks.append({"name": "Máxima espera sin nada comprable en la 1.ª hora (s)", "value": max_gap, "target": "<= %d" % int(MAX_GAP_S),
		"ok": max_gap <= MAX_GAP_S, "note": "en el min %.1f" % (gap_at / 60.0)})
	var r10: float = float(reach_times.get(10, -1.0))
	var r1: float = float(reach_times.get(1, -1.0))
	var sp_ok: bool = r10 > 0.0 and r1 > 0.0 and r10 * SPEEDUP <= r1
	checks.append({"name": "Vuelta 10 llega a la plata de la vuelta 1 (s)", "value": r10, "target": "<= %.0f (1/5 de %.0f)" % [r1 / SPEEDUP, r1],
		"ok": sp_ok, "note": ""})
	var ok: bool = true
	for c in checks:
		ok = ok and bool(c["ok"])
		print("%-55s %8.1f  objetivo %-14s %s" % [c["name"], float(c["value"]), str(c["target"]), "PASA" if c["ok"] else "FALLA"])
	return {"seed": seed_value, "ok": ok, "checks": checks, "reforms": reforms, "final": final_min, "full": full_min,
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
func _write_report(results: Array) -> void:
	var r: Dictionary = results[0]
	var s: String = "# Balance v2 (simulador)\n\n"
	s += "Generado por `godot --headless --script tools/simulate.gd` (bot descripto en el encabezado del script). "
	s += "Objetivos en [DISENO_V2.md](DISENO_V2.md), sección 1.\n\n"
	s += "## Objetivos\n\n| Semilla | Chequeo | Valor | Objetivo | Resultado |\n| --- | --- | --- | --- | --- |\n"
	for res in results:
		for c in res["checks"]:
			var note: String = (" (" + str(c["note"]) + ")") if str(c["note"]) != "" else ""
			s += "| %d | %s | %.1f%s | %s | %s |\n" % [res["seed"], c["name"], float(c["value"]), note, c["target"], "PASA" if c["ok"] else "**FALLA**"]
	s += "\n## Reformas (semilla %d)\n\n" % r["seed"]
	s += "| Vuelta | Minuto | Duración | Plata máxima ganada | +Credibilidad | Nodos comprados después | Llega a la plata de la vuelta 1 en |\n"
	s += "| --- | --- | --- | --- | --- | --- | --- |\n"
	var reach: Dictionary = r["reach"]
	for f in r["reforms"]:
		var n: int = int(f["n"])
		var rt: String = ("%.0f s" % float(reach[n])) if reach.has(n) else "—"
		s += "| %d | %.1f | %d:%02d | $%s | %d | %d | %s |\n" % [n, float(f["minute"]), int(f["dur"]) / 60, int(f["dur"]) % 60,
			(f["earned"] as BigNumber).format(), int(f["cred"]), int(f.get("nodes_bought", 0)), rt]
	s += "\n- Final (Estabilizar la economía): minuto **%.1f**\n" % float(r["final"])
	s += "- 100 %%: minuto **%.1f** (nodos %d/%d, figuritas %d/%d, logros %d/%d)\n" % [float(r["full"]), int(r["nodes"]), TreeLogic.total(),
		int(r["stickers"]), StickerLogic.total(), int(r["ach"]), GameData.achievements.size()]
	s += "- Vueltas jugadas: %d · ceros cortados: %d
" % [int(r["runs"]), int(r["zeros"])]
	if not (r["missing_ach"] as Array).is_empty():
		s += "- Logros que faltaron: %s\n" % ", ".join(r["missing_ach"])
	var f: FileAccess = FileAccess.open(out_path, FileAccess.WRITE)
	if f != null:
		f.store_string(s)
		f.close()
