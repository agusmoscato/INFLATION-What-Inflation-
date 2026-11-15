class_name BotPolicy
extends RefCounted
## Jugadores de prueba que usan el simulador (tools/simulate.gd) y el QA del juego real (main.gd). Tres perfiles:
##  - "activo": clickea mucho (7 clics/s con combo), toca el 90 % de los billetes al segundo, remarca cuando la inflación
##    mensual pasa el 4 % y compra lo de mejor repago una vez por segundo.
##  - "pasivo": casi no clickea (1 clic/s), toca el 30 % de los billetes (tarde), no remarca hasta que la inflación pasa
##    el 25 % y compra siempre lo más barato que pueda pagar, cada 2 s.
##  - "distraido": juega como uno activo pero más lento (4 clics/s) y en las primeras vueltas deja de jugar 2 minutos a
##    mitad de la vuelta.
## Los tres reforman cuando el juego lo aconseja (el botón de reforma late: la Credibilidad que suman por minuto cae
## debajo del promedio de la vuelta, el tutorial de la primera vuelta lo pide o están trabados). Nodos: sellos y final primero; después el más barato, con preferencia
## NEGOCIOS > EMPANADA > RENACER > INFLACIÓN > FIGURITAS > SUERTE. Abren sobres, hacen chupi y juegan raspaditas.

const PROFILES: Dictionary = {
	"activo": {"cps": 7.0, "catch": 0.9, "react": 1.0, "remark_pct": 4.0, "buy_every": 1.0, "cheap": false, "afk": 0.0},
	"pasivo": {"cps": 1.0, "catch": 0.3, "react": 3.0, "remark_pct": 25.0, "buy_every": 2.0, "cheap": true, "afk": 0.0},
	"distraido": {"cps": 4.0, "catch": 0.7, "react": 2.0, "remark_pct": 8.0, "buy_every": 1.5, "cheap": false, "afk": 120.0},
}
const BRANCH_W: Dictionary = {"neg": 1.0, "emp": 1.0, "inf": 1.1, "ren": 1.25, "fig": 1.4, "sue": 1.5, "bridge": 1.3, "final": 0.5}

var profile: String = "activo"
var cfg: Dictionary = PROFILES["activo"]
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var click_acc: float = 0.0
var bill_plan: Dictionary = {}          # id -> {catch, age}
var buy_t: float = 0.0
var tree_t: float = 0.0
var album_t: float = 0.0
var scratch_t: float = 0.0
var last_gain: int = 0
var lazy: bool = false
var prev_run_time: float = 300.0        ## duración de la vuelta anterior (para saber cuándo es "la mitad")
var afk_left: float = 0.0
var afk_done: bool = false
## Callables opcionales para que el QA del juego real pase por la interfaz (señales, efectos): click(), bill(id), reform()
var on_click: Callable
var on_bill: Callable
var on_reform: Callable


func _init(seed_value: int = 1, profile_name: String = "activo") -> void:
	rng.seed = seed_value * 7919
	profile = profile_name if PROFILES.has(profile_name) else "activo"
	cfg = PROFILES[profile]


## ¿Está jugando ahora? (el distraído se va un rato)
func away() -> bool:
	return afk_left > 0.0


## Un paso del bot (antes del tick de la economía). Devuelve el resumen si reformó ({} si no).
func step(m: GameModel, dt: float) -> Dictionary:
	EconomyLogic.ensure_fresh(m)
	# el distraído: a mitad de las vueltas largas deja de jugar 2 minutos
	if float(cfg["afk"]) > 0.0 and not afk_done and prev_run_time >= 120.0 and m.run_time >= prev_run_time * 0.5:
		afk_done = true
		afk_left = float(cfg["afk"])
	if afk_left > 0.0:
		afk_left -= dt
		for b in m.bills_active:
			bill_plan[int(b["id"])] = {"catch": false, "age": 0.0}
		return {}
	# clics
	if not lazy:
		click_acc += float(cfg["cps"]) * dt
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
			bill_plan[bid] = {"catch": rng.randf() < float(cfg["catch"]), "age": 0.0}
		bill_plan[bid]["age"] = float(bill_plan[bid]["age"]) + dt
		if bool(bill_plan[bid]["catch"]) and float(bill_plan[bid]["age"]) >= float(cfg["react"]):
			bill_plan[bid]["catch"] = false
			if on_bill.is_valid():
				on_bill.call(bid)
			else:
				EconomyLogic.click_bill(m, bid)
	# remarcar
	if EconomyLogic.can_remark(m) and m.freeze_left <= 0.0:
		var paranoid: bool = profile == "activo" and not m.achievements.has("paranoid") and m.reforms >= 3 and m.run_time < 8.0
		if EconomyLogic.monthly_pct(m) >= float(cfg["remark_pct"]) or paranoid:
			EconomyLogic.remark(m, true)
	# noticias
	if not m.pending_choice.is_empty():
		EconomyLogic.choose(m, 1 if str(m.pending_choice["id"]) in ["aguinaldo", "turistas"] else 0)
	# compras
	buy_t += dt
	if buy_t >= float(cfg["buy_every"]):
		buy_t = 0.0
		var guard: int = 0
		while guard < 40 and (cheap_buy(m) if bool(cfg["cheap"]) else EconomyLogic.smart_buy(m)):
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


## El pasivo compra lo más barato que puede pagar (negocio o mejora). true si compró algo.
static func cheap_buy(m: GameModel) -> bool:
	var best_cost: BigNumber = null
	var best_id: String = ""
	var best_kind: String = ""
	for def in GameData.businesses:
		if not EconomyLogic.business_available(m, def):
			continue
		var c: BigNumber = EconomyLogic.business_cost(m, def, 1)
		if c.le(m.money) and (best_cost == null or c.lt(best_cost)):
			best_cost = c
			best_id = def["id"]
			best_kind = "biz"
	for u in EconomyLogic.visible_upgrades(m):
		var c2: BigNumber = EconomyLogic.upgrade_cost(m, u)
		if c2.le(m.money) and (best_cost == null or c2.lt(best_cost)):
			best_cost = c2
			best_id = u["id"]
			best_kind = "upg"
	if best_id == "":
		return false
	if best_kind == "biz":
		return EconomyLogic.buy_business(m, best_id, 1) > 0
	return EconomyLogic.buy_upgrade(m, best_id)


## Reforma cuando el juego lo aconseja (el botón late: trabado, el tutorial de la primera vuelta o "seguir rinde cada vez
## menos").
func _reform_policy(m: GameModel, _dt: float) -> Dictionary:
	if not EconomyLogic.reform_advised(m):
		return {}
	var cred_before: int = m.credibility
	var t_before: float = m.run_time
	var s: Dictionary = on_reform.call() if on_reform.is_valid() else EconomyLogic.do_reform(m)
	if s.is_empty():
		return {}
	last_gain = m.credibility - cred_before
	prev_run_time = t_before
	afk_done = false
	bill_plan.clear()
	buy_nodes(m)
	album_policy(m)
	lazy = profile == "activo" and float(m.mods["autoclick"]) > 0.0 and not m.achievements.has("no_hands")
	return s


## El nodo que el juego recomienda comprar (el mismo criterio que usa el bot): sellos y el camino a los sellos primero,
## después el más barato con preferencia por ramas. "" si no hay ninguno abierto.
static func recommended_node(m: GameModel) -> String:
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
	return best


## Compra nodos del árbol por prioridad. Con los 6 sellos comprados junta para el final (mientras tanto, solo nodos baratos).
func buy_nodes(m: GameModel) -> void:
	var guard: int = 0
	while guard < 30:
		guard += 1
		var final_ready: bool = not m.tree.has("final") and TreeLogic.requirements_met(m, "final") and not TreeLogic.demo_locked(m, "final")
		if final_ready and TreeLogic.buy(m, "final"):
			continue
		var best: String = recommended_node(m)
		if best == "":
			return
		if final_ready and TreeLogic.cost(best) > TreeLogic.cost("final") * 0.05:
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
