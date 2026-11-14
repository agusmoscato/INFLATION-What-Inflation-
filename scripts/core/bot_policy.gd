class_name BotPolicy
extends RefCounted
## El "jugador casual atento" que usan el simulador (tools/simulate.gd) y el QA del juego real (main.gd).
##  - 5 clics/s con combo (en una vuelta "sin manos" no hace clic, para el logro secreto, si ya tiene autoclicker).
##  - Toca el 85 % de los billetes voladores, 1,5 s después de que aparecen.
##  - Remarca apenas puede cuando la inflación mensual pasa el 4 %.
##  - Compra lo de mejor repago (negocios y mejoras) una vez por segundo.
##  - Reforma cuando la Credibilidad que suma por minuto (últimos 30 s) cae debajo del promedio de la vuelta.
##  - Nodos: sellos y final primero; después el más barato, con preferencia NEGOCIOS > EMPANADA > RENACER > INFLACIÓN >
##    FIGURITAS > SUERTE. Abre los sobres de regalo, compra sobres baratos, hace chupi y juega raspaditas para el álbum.

const CPS: float = 5.0
const BILL_CATCH: float = 0.85
const BILL_REACT: float = 1.5
const REFORM_DROP: float = 0.97
const BRANCH_W: Dictionary = {"neg": 1.0, "emp": 1.1, "ren": 1.0, "inf": 1.2, "fig": 1.4, "sue": 1.5, "bridge": 1.3, "final": 0.5}

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var click_acc: float = 0.0
var bill_plan: Dictionary = {}          # id -> {catch, age}
var hist: Array = []                    # Credibilidad posible cada 5 s
var hist_t: float = 0.0
var buy_t: float = 0.0
var tree_t: float = 0.0
var album_t: float = 0.0
var scratch_t: float = 0.0
var last_gain: int = 0
var lazy: bool = false
## Callables opcionales para que el QA del juego real pase por la interfaz (señales, efectos): click(), bill(id), reform()
var on_click: Callable
var on_bill: Callable
var on_reform: Callable


func _init(seed_value: int = 1) -> void:
	rng.seed = seed_value * 7919


## Un paso del bot (antes del tick de la economía). Devuelve el resumen si reformó ({} si no).
func step(m: GameModel, dt: float) -> Dictionary:
	EconomyLogic.ensure_fresh(m)
	# clics
	if not lazy:
		click_acc += CPS * dt
		while click_acc >= 1.0:
			click_acc -= 1.0
			if on_click.is_valid():
				on_click.call()
			else:
				EconomyLogic.do_click(m, true)
	# billetes voladores
	for b in m.bills_active.duplicate():
		var bid: int = int(b["id"])
		if not bill_plan.has(bid):
			bill_plan[bid] = {"catch": rng.randf() < BILL_CATCH, "age": 0.0}
		bill_plan[bid]["age"] = float(bill_plan[bid]["age"]) + dt
		if bool(bill_plan[bid]["catch"]) and float(bill_plan[bid]["age"]) >= BILL_REACT:
			bill_plan[bid]["catch"] = false
			if on_bill.is_valid():
				on_bill.call(bid)
			else:
				EconomyLogic.click_bill(m, bid)
	# remarcar
	if EconomyLogic.can_remark(m) and m.freeze_left <= 0.0:
		var paranoid: bool = not m.achievements.has("paranoid") and m.reforms >= 3 and m.run_time < 8.0
		if EconomyLogic.monthly_pct(m) >= 4.0 or paranoid:
			EconomyLogic.remark(m, true)
	# noticias
	if not m.pending_choice.is_empty():
		EconomyLogic.choose(m, 1 if str(m.pending_choice["id"]) in ["aguinaldo", "turistas"] else 0)
	# compras
	buy_t += dt
	if buy_t >= 1.0:
		buy_t = 0.0
		var guard: int = 0
		while guard < 40 and EconomyLogic.smart_buy(m):
			guard += 1
	tree_t += dt
	if tree_t >= 2.0:
		tree_t = 0.0
		buy_nodes(m)
	album_t += dt
	if album_t >= 5.0:
		album_t = 0.0
		album_policy(m)
	scratch_t += dt
	if scratch_t >= 20.0:
		scratch_t = 0.0
		if GambleLogic.unlocked(m) and m.run_time > 30.0 and (StickerLogic.missing_count(m) > 0 or not m.achievements.has("scratch_x10") or not m.achievements.has("bad_luck")):
			GambleLogic.play_scratch(m)
	return _reform_policy(m, dt)


## Marginal (últimos 30 s) contra promedio de la vuelta: cuando lo que suma ahora por minuto cae debajo del promedio,
## conviene reformar (regla clásica de parada óptima).
func _reform_policy(m: GameModel, dt: float) -> Dictionary:
	var gf: float = EconomyLogic.reform_gain_f(m)
	hist_t += dt
	if hist_t >= 5.0:
		hist_t = 0.0
		hist.append(gf)
		if hist.size() > 7:
			hist.pop_front()
	if EconomyLogic.reform_gain(m) < 1 or m.run_time < 45.0 or hist.size() < 7:
		return {}
	var avg: float = gf / (m.run_time / 60.0)
	var marginal: float = (gf - float(hist[0])) / 0.5
	# completista: después del final, si falta el logro de hiperinflación, deja correr una vuelta hasta el 1000 %
	var hyper_wait: bool = m.won and not m.achievements.has("hyper_1000") and EconomyLogic.monthly_pct(m) < 1000.0
	if marginal >= avg * REFORM_DROP or not EconomyLogic.can_reform(m) or hyper_wait:
		return {}
	var cred_before: int = m.credibility
	var s: Dictionary = on_reform.call() if on_reform.is_valid() else EconomyLogic.do_reform(m)
	if s.is_empty():
		return {}
	last_gain = m.credibility - cred_before
	hist.clear()
	bill_plan.clear()
	buy_nodes(m)
	album_policy(m)
	lazy = float(m.mods["autoclick"]) > 0.0 and not m.achievements.has("no_hands")
	return s


## Compra nodos del árbol por prioridad. Si ya están los 6 sellos y le falta poco para el final, junta para el final.
func buy_nodes(m: GameModel) -> void:
	var guard: int = 0
	while guard < 30:
		guard += 1
		var final_ready: bool = not m.tree.has("final") and TreeLogic.requirements_met(m, "final") and not TreeLogic.demo_locked(m, "final")
		if final_ready and TreeLogic.buy(m, "final"):
			continue
		var best: String = ""
		var best_score: float = INF
		for n in GameData.tree:
			var id: String = n["id"]
			if m.tree.has(id) or bool(n["final"]) or not TreeLogic.visible(m, id) or not TreeLogic.requirements_met(m, id) or TreeLogic.demo_locked(m, id):
				continue
			var score: float = float(n["cost"]) * float(BRANCH_W.get(str(n["branch"]), 1.0))
			if int(n["slot"]) == 0 and int(n["ring"]) <= 4:
				score *= 0.6          # el camino a los sellos
			if bool(n["seal"]):
				score *= 0.5
			if score < best_score:
				best_score = score
				best = id
		if best == "":
			return
		if final_ready and m.credibility + 4 * last_gain >= TreeLogic.cost("final") and TreeLogic.cost(best) > TreeLogic.cost("final") * 0.05:
			return
		if not TreeLogic.buy(m, best):
			return


## Álbum: abre los sobres de regalo, compra sobres si salen menos del 10 % de la plata y hace chupi.
func album_policy(m: GameModel) -> void:
	if not TreeLogic.has(m, "album"):
		return
	while m.free_packs_pending > 0:
		m.free_packs_pending -= 1
		StickerLogic.gift_pack(m)
	if StickerLogic.missing_count(m) > 0 and StickerLogic.pack_cost(m).le(m.money.mul_f(0.10)):
		StickerLogic.buy_pack(m)
	for s in GameData.stickers:
		var id: String = s["id"]
		if int(s["page"]) == StickerLogic.PAGE_BILLETES or m.stickers.has(id):
			continue
		if StickerLogic.repes(m) >= StickerLogic.trade_cost(m, id):
			StickerLogic.trade(m, id)
