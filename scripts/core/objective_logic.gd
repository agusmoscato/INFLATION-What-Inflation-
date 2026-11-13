class_name ObjectiveLogic
extends RefCounted
## Cadena de objetivos que cubre todo el juego. Siempre hay uno visible, con su progreso, y cada uno enseña algo.
## El índice solo avanza (m.obj_index), así que reformar o resetear la vuelta no hace retroceder la cadena.
##
## Cada entrada: {id, kind, ...}. El texto sale de la clave "obj.<id>" con dos %s: (progreso, meta).

const LIST: Array = [
	{"id": "click10", "kind": "clicks", "n": 10},
	{"id": "cart", "kind": "money_biz", "biz": "empanadas"},
	{"id": "inflation", "kind": "months", "n": 1},
	{"id": "remark", "kind": "remarks", "n": 1},
	{"id": "cart3", "kind": "own", "biz": "empanadas", "n": 3},
	{"id": "click1", "kind": "upg_id", "upg": "click1"},
	{"id": "cart5", "kind": "own", "biz": "empanadas", "n": 5},
	{"id": "cart_a", "kind": "upg_id", "upg": "empanadas_a"},
	{"id": "kiosk", "kind": "money_biz", "biz": "kiosco"},
	{"id": "kiosk2", "kind": "own", "biz": "kiosco", "n": 2},
	{"id": "kiosk3", "kind": "own", "biz": "kiosco", "n": 3},
	{"id": "kiosk4", "kind": "own", "biz": "kiosco", "n": 4},
	{"id": "kiosk5", "kind": "own", "biz": "kiosco", "n": 5},
	{"id": "kiosk_a", "kind": "upg_id", "upg": "kiosco_a"},
	{"id": "kiosk6", "kind": "own", "biz": "kiosco", "n": 6},
	{"id": "kiosk7", "kind": "own", "biz": "kiosco", "n": 7},
	{"id": "remarkbonus", "kind": "upg_id", "upg": "remarkbonus"},
	{"id": "choripan", "kind": "money_biz", "biz": "choripan"},
	{"id": "auto_remark", "kind": "upg_id", "upg": "auto_remark1"},
	{"id": "choripan2", "kind": "own", "biz": "choripan", "n": 2},
	{"id": "choripan3", "kind": "own", "biz": "choripan", "n": 3},
	{"id": "choripan4", "kind": "own", "biz": "choripan", "n": 4},
	{"id": "choripan5", "kind": "own", "biz": "choripan", "n": 5},
	{"id": "choripan_a", "kind": "upg_id", "upg": "choripan_a"},
	{"id": "lavadero", "kind": "money_biz", "biz": "lavadero"},
	{"id": "lavadero2", "kind": "own", "biz": "lavadero", "n": 2},
	{"id": "lavadero3", "kind": "own", "biz": "lavadero", "n": 3},
	{"id": "upg8", "kind": "upgrades", "n": 8},
	{"id": "lavadero4", "kind": "own", "biz": "lavadero", "n": 4},
	{"id": "lavadero5", "kind": "own", "biz": "lavadero", "n": 5},
	{"id": "panaderia", "kind": "money_biz", "biz": "panaderia"},
	{"id": "pack", "kind": "packs", "n": 1},
	{"id": "era2", "kind": "era", "n": 2},
	{"id": "refuge", "kind": "refuge"},
	{"id": "event", "kind": "events", "n": 1},
	{"id": "scratch", "kind": "scratches", "n": 1},
	{"id": "reform", "kind": "reforms", "n": 1},
	{"id": "stickers10", "kind": "stickers", "n": 10},
	{"id": "era3", "kind": "era", "n": 3},
	{"id": "refuge3", "kind": "refuges_n", "n": 3},
	{"id": "stickers25", "kind": "stickers", "n": 25},
	{"id": "era4", "kind": "era", "n": 4},
	{"id": "plan", "kind": "plans", "n": 1},
	{"id": "stickers45", "kind": "stickers", "n": 45},
	{"id": "era5", "kind": "era", "n": 5},
	{"id": "measures", "kind": "measures", "n": 3},
	{"id": "win", "kind": "won"},
]


static func count() -> int:
	return LIST.size()


static func _money(b: BigNumber) -> String:
	return "$" + b.format()


## ¿Se cumplió el objetivo `o`?
static func met(m: GameModel, o: Dictionary) -> bool:
	match str(o["kind"]):
		"clicks": return m.clicks >= int(o["n"])
		"money_biz": return m.owned_count(str(o["biz"])) >= 1
		"own": return m.owned_count(str(o["biz"])) >= int(o["n"])
		"months": return m.month_count >= int(o["n"])
		"remarks": return m.remarks >= int(o["n"])
		"upg_id": return m.upgrades.has(str(o["upg"]))
		"upgrades": return m.upgrades.size() >= int(o["n"])
		"era": return m.era >= int(o["n"])
		"refuge": return not EconomyLogic.refuge_value_total_real(m).is_zero()
		"refuges_n": return EconomyLogic.refuge_diversified_count(m) >= int(o["n"])
		"events": return m.events_seen >= int(o["n"])
		"reforms": return m.reforms >= int(o["n"])
		"plans": return m.plans_done >= int(o["n"])
		"measures": return m.measures >= int(o["n"])
		"packs": return m.packs_opened >= int(o["n"])
		"scratches": return m.scratches >= int(o["n"])
		"stickers": return m.stickers.size() >= int(o["n"])
		"won": return m.won
	return true


## Progreso del objetivo: {cur_s, tgt_s, frac}
static func progress(m: GameModel, o: Dictionary) -> Dictionary:
	var cur: float = 0.0
	var tgt: float = 1.0
	var cur_s: String = ""
	var tgt_s: String = ""
	match str(o["kind"]):
		"money_biz":
			var def: Dictionary = GameData.businesses[GameData.business_idx[str(o["biz"])]]
			var cost: BigNumber = EconomyLogic.business_cost(m, def, 1)
			cur_s = _money(m.money)
			tgt_s = _money(cost)
			cur = clampf(m.money.div(cost).to_float(), 0.0, 1.0)
		"own":
			var n: int = m.owned_count(str(o["biz"]))
			cur_s = str(n)
			tgt_s = str(int(o["n"]))
			cur = float(n) / float(o["n"])
		"clicks":
			cur_s = str(m.clicks)
			tgt_s = str(int(o["n"]))
			cur = float(m.clicks) / float(o["n"])
		"months":
			cur_s = str(m.month_count)
			tgt_s = str(int(o["n"]))
			cur = float(m.month_count) / float(o["n"])
		"remarks":
			cur_s = str(m.remarks)
			tgt_s = str(int(o["n"]))
			cur = float(m.remarks) / float(o["n"])
		"upg_id":
			var u: Dictionary = GameData.upgrades[GameData.upgrade_idx[str(o["upg"])]]
			var ucost: BigNumber = EconomyLogic.upgrade_cost(m, u)
			cur_s = _money(m.money)
			tgt_s = _money(ucost)
			cur = clampf(m.money.div(ucost).to_float(), 0.0, 1.0)
		"upgrades":
			cur_s = str(m.upgrades.size())
			tgt_s = str(int(o["n"]))
			cur = float(m.upgrades.size()) / float(o["n"])
		"era":
			var thr: BigNumber = GameData.eras[int(o["n"]) - 1]["threshold"]
			var l: float = maxf(m.lifetime_real.log10(), 0.0)
			cur = clampf(l / maxf(thr.log10(), 0.001), 0.0, 1.0)
			cur_s = "%d%%" % int(cur * 100.0)
			tgt_s = "100%"
		"reforms":
			var g: int = EconomyLogic.reform_gain(m)
			cur_s = str(g)
			tgt_s = "1"
			cur = clampf(float(g), 0.0, 1.0)
		"refuges_n":
			var c: int = EconomyLogic.refuge_diversified_count(m)
			cur_s = str(c)
			tgt_s = str(int(o["n"]))
			cur = float(c) / float(o["n"])
		"events":
			cur_s = str(m.events_seen)
			tgt_s = str(int(o["n"]))
			cur = float(m.events_seen) / float(o["n"])
		"plans":
			cur_s = str(m.plans_done)
			tgt_s = str(int(o["n"]))
			cur = float(m.plans_done) / float(o["n"])
		"measures":
			cur_s = str(m.measures)
			tgt_s = str(int(o["n"]))
			cur = float(m.measures) / float(o["n"])
		"packs":
			cur_s = str(m.packs_opened)
			tgt_s = str(int(o["n"]))
			cur = float(m.packs_opened) / float(o["n"])
		"scratches":
			cur_s = str(m.scratches)
			tgt_s = str(int(o["n"]))
			cur = float(m.scratches) / float(o["n"])
		"stickers":
			cur_s = str(m.stickers.size())
			tgt_s = str(int(o["n"]))
			cur = float(m.stickers.size()) / float(o["n"])
		_:
			cur_s = "0"
			tgt_s = "1"
	return {"cur_s": cur_s, "tgt_s": tgt_s, "frac": clampf(cur, 0.0, 1.0)}


## Objetivo actual: {id, cur_s, tgt_s, frac, done}. Si la cadena terminó, done = true.
static func current(m: GameModel) -> Dictionary:
	if m.obj_index >= LIST.size():
		return {"id": "end", "cur_s": "", "tgt_s": "", "frac": 1.0, "done": true}
	var o: Dictionary = LIST[m.obj_index]
	var p: Dictionary = progress(m, o)
	p["id"] = o["id"]
	p["done"] = false
	return p


## Avanza la cadena mientras se cumplan objetivos. Devuelve los ids completados.
static func update(m: GameModel) -> Array:
	var done: Array = []
	while m.obj_index < LIST.size() and met(m, LIST[m.obj_index]):
		done.append(LIST[m.obj_index]["id"])
		m.obj_index += 1
	for id in done:
		m.push("objective_done", [id])
	return done


# =====================================================================
#  Tiempo estimado y "meta chica" (para que siempre haya algo alcanzable)
# =====================================================================
const CLICKS_PER_SEC: float = 1.0
const MICRO_MAX_ETA: float = 45.0


static func _rate(m: GameModel) -> float:
	# plata por segundo con la que cuenta un jugador nuevo: ingresos + 1 clic/s
	return EconomyLogic.income_per_sec(m).to_float() + EconomyLogic.click_value(m).to_float() * CLICKS_PER_SEC


static func _eta_money(m: GameModel, cost: BigNumber) -> float:
	var gap: BigNumber = cost.sub(m.money)
	if gap.is_negative() or gap.is_zero():
		return 0.0
	var r: float = _rate(m)
	if r <= 0.0:
		return INF
	return gap.div(BigNumber.from_float(r)).to_float()


## Segundos estimados hasta cumplir el objetivo `o` (INF si no se puede estimar).
static func eta(m: GameModel, o: Dictionary) -> float:
	match str(o["kind"]):
		"clicks": return maxf(0.0, float(int(o["n"]) - m.clicks)) / CLICKS_PER_SEC
		"money_biz":
			return _eta_money(m, EconomyLogic.business_cost(m, GameData.businesses[GameData.business_idx[str(o["biz"])]], 1))
		"own":
			var def: Dictionary = GameData.businesses[GameData.business_idx[str(o["biz"])]]
			var missing: int = int(o["n"]) - m.owned_count(str(o["biz"]))
			if missing <= 0:
				return 0.0
			return _eta_money(m, EconomyLogic.business_cost(m, def, missing))
		"upg_id":
			return _eta_money(m, EconomyLogic.upgrade_cost(m, GameData.upgrades[GameData.upgrade_idx[str(o["upg"])]]))
		"months": return maxf(0.0, float(int(o["n"]) - m.month_count) * EconomyLogic.B("month_seconds") - m.month_progress)
		"remarks": return EconomyLogic.B("month_seconds") - m.month_progress
		"refuge": return 0.0 if EconomyLogic.refuges_unlocked(m) and not m.money.is_zero() else INF
		"events": return maxf(0.0, m.event_timer) + 10.0
		"packs", "scratches": return 20.0
	return INF


## Mejor compra "ya casi": el candidato más rentable que se alcanza en <= MICRO_MAX_ETA s. {} si no hay.
static func micro(m: GameModel) -> Dictionary:
	var best: Dictionary = {}
	var best_pb: float = INF
	for c in EconomyLogic.candidates(m):
		var e: float = _eta_money(m, c["cost"])
		if e <= MICRO_MAX_ETA and float(c["payback"]) < best_pb:
			best_pb = float(c["payback"])
			best = {"kind": c["kind"], "id": c["id"], "cost": c["cost"], "eta": e}
	return best


## ¿Hay algo alcanzable ahora? (el objetivo actual en <= 60 s, o una meta chica)
static func reachable(m: GameModel) -> bool:
	if m.obj_index >= LIST.size():
		return true
	if eta(m, LIST[m.obj_index]) <= 60.0:
		return true
	return not micro(m).is_empty()
