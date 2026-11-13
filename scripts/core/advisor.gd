class_name Advisor
extends RefCounted
## "Una sola acción destacada": decide cuál es la próxima cosa que el jugador debería tocar. La interfaz la marca con una
## flecha de tiza y un brillo que late; lo demás queda tranquilo. Lógica pura (sin interfaz) para poder probarla.
##
## Devuelve {kind, id, why}:
##   kind: "decision" (hay un evento para elegir), "click" (la empanada), "remark", "tab" (id = índice de pestaña),
##         "buy" (id = negocio), "upgrade" (id = mejora) o "" (nada que destacar).
##   why: clave de texto corta ("adv.click", "adv.remark", ...).

## Por debajo de este atraso en los precios no vale la pena remarcar todavía.
const REMARK_MIN_LAG: float = 0.05

const TAB_OF_FEATURE: Dictionary = {"upgrades": 1, "refuges": 2, "reform": 3, "album": 4, "timba": 5}


## `seen_tabs`: pestañas que el jugador ya abrió alguna vez. Una mecánica recién desbloqueada se destaca hasta abrirla.
static func recommend(m: GameModel, seen_tabs: Array = []) -> Dictionary:
	if not m.pending_choice.is_empty():
		return {"kind": "decision", "id": "", "why": "adv.decision"}
	if EconomyLogic.tutorial_step(m) == 0:
		return {"kind": "click", "id": "", "why": "adv.click"}
	# precios viejos: remarcar es plata regalada
	var tutorial_remark: bool = EconomyLogic.tutorial_step(m) == 3      # el tutorial pide remarcar aunque todavía sea poquito
	if EconomyLogic.needs_remark(m) and m.remark_cd <= 0.0 and (lag(m) >= REMARK_MIN_LAG or tutorial_remark or m.remark_window > 0.0):
		return {"kind": "remark", "id": "", "why": "adv.remark"}
	# mecánica nueva todavía sin abrir
	for f in Unlocks.FEATURES:
		if m.unlocked.has(f) and TAB_OF_FEATURE.has(f) and not seen_tabs.has(int(TAB_OF_FEATURE[f])):
			return {"kind": "tab", "id": int(TAB_OF_FEATURE[f]), "why": "adv.tab"}
	# el objetivo, cuando ya alcanza la plata (o es ir a una pestaña)
	var cur: Dictionary = ObjectiveLogic.current(m)
	if not bool(cur["done"]):
		var st: Dictionary = ObjectiveLogic.status(m, ObjectiveLogic.LIST[m.obj_index])
		var go: Dictionary = st["go"]
		if bool(st["ready"]) and not go.is_empty() and str(go["kind"]) != "remark":
			return {"kind": str(go["kind"]), "id": go.get("id", ""), "why": "adv.obj"}
	# la compra más rentable que se alcanza ahora
	var best: Dictionary = best_buy(m)
	if not best.is_empty():
		return {"kind": str(best["kind"]), "id": str(best["id"]), "why": "adv.buy"}
	# no alcanza para nada: juntar plata. Tocar la empanada solo sirve mientras el clic pesa frente al ingreso por segundo.
	var click_v: float = EconomyLogic.click_value(m).to_float()
	var inc: float = EconomyLogic.income_per_sec(m).to_float()
	if m.total_businesses() == 0 or (m.era <= 2 and inc < click_v * 20.0):
		return {"kind": "click", "id": "", "why": "adv.click"}
	return {"kind": "objective", "id": "", "why": "adv.wait"}

## Fracción de ingreso que se pierde por tener los precios atrasados (0 = al día).
static func lag(m: GameModel) -> float:
	if not EconomyLogic.needs_remark(m):
		return 0.0
	return 1.0 - clampf(m.my_prices.div(m.price_level).to_float(), 0.0, 1.0)


## Candidato de compra (negocio o mejora) más rentable entre los que ya alcanzan. {} si no hay.
static func best_buy(m: GameModel) -> Dictionary:
	var best: Dictionary = {}
	var best_pb: float = INF
	for c in EconomyLogic.candidates(m):
		if (c["cost"] as BigNumber).gt(m.money):
			continue
		if float(c["payback"]) < best_pb:
			best_pb = float(c["payback"])
			best = {"kind": "buy" if c["kind"] == "biz" else "upgrade", "id": c["id"]}
	return best
