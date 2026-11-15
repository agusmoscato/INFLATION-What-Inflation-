class_name TreeLogic
extends RefCounted
## Árbol de habilidades: visibilidad (con niebla), compra con Credibilidad y modificadores que aplica a la economía.

## Valores por defecto de todos los modificadores (el árbol y el álbum los cambian).
static func default_mods() -> Dictionary:
	return {
		"click_add": 0.0, "click_mult": 1.0, "click_pct": 0.0, "click_per_building": 0.0,
		"combo_cap": GameData.B("combo_cap"), "combo_step": GameData.B("combo_step"), "combo_window": GameData.B("combo_window"),
		"crit_chance": 0.0, "crit_mult": GameData.B("crit_mult"), "autoclick": 0.0,
		"prod_mult": 1.0, "cost_mult": 1.0, "milestone_mult": GameData.B("milestone_mult"), "synergy_mult": 1.0,
		"start_biz": {}, "per_building": 0.0, "adv_biz": false, "excl_biz": false, "manager": 0.0,
		"infl_speed": 1.0, "remark_freeze": GameData.B("remark_freeze"), "remark_cd": GameData.B("remark_cooldown"),
		"freeze_bonus": 0.0, "auto_remark": false, "cost_p_exp": 1.0, "infl_pays": 0.0, "indexation": 0.0,
		"events": false, "event_mult": 1.0,
		"bill_interval": 1.0, "bill_money": 1.0, "frenzy_dur": GameData.B("frenzy_seconds"), "frenzy_mult": GameData.B("frenzy_mult"),
		"bill_double": 0.0, "bill_slow": 1.0, "clickfrenzy": false, "frenzy_freeze": false,
		"scratch": false, "scratch_luck": 1.0, "scratch_pity": GameData.B("scratch_pity"), "scratch_gold": 1.0, "auto_scratch": 0.0,
		"album": false, "free_packs": 0.0, "pack_discount": 1.0, "sticker_bill": GameData.B("sticker_bill_base"),
		"golden_mult": 1.0, "trade_cost": float(StickerLogic.TRADE_COST), "pack_size": float(StickerLogic.PACK_SIZE),
		"collection": 0.0, "gold_bonus": 0.0, "page_mult": 1.0, "page_prod": 1.0,
		"cred_mult": 1.0, "cred_flat": 0.0, "cred_per_page": 0.0,
		"start_money": 0.0, "start_money_frac": 0.0, "early_boost_s": 0.0, "keep_click_upg": false,
		"offline_frac": GameData.B("offline_frac"), "final": false,
		# bonus del álbum (páginas completas)
		"album_income": 0.0, "album_inflation": 0.0, "album_cred": 0.0, "album_remark": 0.0, "album_events": 0.0,
	}


static func _apply(mods: Dictionary, fx: Array) -> void:
	for e in fx:
		var key: String = str(e[0])
		var op: String = str(e[1])
		var v: Variant = e[2]
		match op:
			"*":
				mods[key] = float(mods[key]) * float(v)
			"+":
				mods[key] = float(mods[key]) + float(v)
			"=":
				mods[key] = v
			"max":
				var cur: Dictionary = mods[key]
				for b in v:
					cur[b] = maxi(int(cur.get(b, 0)), int(v[b]))


## Modificadores de todos los nodos comprados más los bonus de páginas del álbum.
static func compute_mods(m: GameModel) -> Dictionary:
	var mods: Dictionary = default_mods()
	mods["start_biz"] = {}
	for n in GameData.tree:
		if m.tree.has(n["id"]):
			_apply(mods, n["fx"])
	var pm: float = float(mods["page_mult"])
	for p in range(GameData.sticker_pages.size()):
		if not StickerLogic.page_complete(m, p):
			continue
		var bon: Dictionary = GameData.sticker_pages[p]["bonus"]
		mods["album_income"] = float(mods["album_income"]) + float(bon.get("income", 0.0)) * pm
		mods["album_inflation"] = float(mods["album_inflation"]) + float(bon.get("inflation", 0.0)) * pm
		mods["album_cred"] = float(mods["album_cred"]) + float(bon.get("cred", 0.0)) * pm
		mods["album_remark"] = float(mods["album_remark"]) + float(bon.get("remark", 0.0)) * pm
		mods["album_events"] = float(mods["album_events"]) + float(bon.get("events", 0.0)) * pm
	return mods


static func total() -> int:
	return GameData.tree.size()


static func count(m: GameModel) -> int:
	return m.tree.size()


static func caps(m: GameModel) -> int:
	var n: int = 0
	for id in m.tree:
		if bool(GameData.node(id)["cap"]):
			n += 1
	return n


static func parents_owned(m: GameModel, n: Dictionary) -> int:
	var k: int = 0
	for p in n["parents"]:
		if m.tree.has(p):
			k += 1
	return k


## Visible y comprable a la vista (con nombre): raíces, el final y los hijos de nodos comprados.
static func visible(m: GameModel, id: String) -> bool:
	var n: Dictionary = GameData.node(id)
	if m.tree.has(id) or bool(n["final"]) or int(n["ring"]) == 1:
		return true
	if bool(n["bridge"]):
		return parents_owned(m, n) >= 1
	return parents_owned(m, n) >= 1


## Niebla: se dibuja como "?" (es vecino de algo visible pero todavía no se revela).
static func fog(m: GameModel, id: String) -> bool:
	if visible(m, id):
		return false
	var n: Dictionary = GameData.node(id)
	for p in n["parents"]:
		if visible(m, p):
			return true
	return false


static func requirements_met(m: GameModel, id: String) -> bool:
	var n: Dictionary = GameData.node(id)
	if n["parents"].is_empty():
		return true
	if bool(n["req_all"]):
		return parents_owned(m, n) == n["parents"].size()
	return parents_owned(m, n) >= 1


## En la demo solo se pueden comprar los anillos 1 a 3 (el final no).
static func demo_locked(m: GameModel, id: String) -> bool:
	if not m.demo_mode:
		return false
	var n: Dictionary = GameData.node(id)
	return bool(n["final"]) or int(n["ring"]) > int(GameData.B("demo_max_ring"))


static func cost(id: String) -> int:
	return int(GameData.node(id)["cost"])


static func can_buy(m: GameModel, id: String) -> bool:
	if m.tree.has(id) or not visible(m, id) or not requirements_met(m, id) or demo_locked(m, id):
		return false
	return m.credibility >= cost(id)


static func buy(m: GameModel, id: String) -> bool:
	if not GameData.tree_idx.has(id) or not can_buy(m, id):
		return false
	var n: Dictionary = GameData.node(id)
	m.credibility -= cost(id)
	m.tree[id] = true
	m.dirty = true
	m.push("node_bought", [id])
	if str(n["unlock"]) != "":
		m.push("unlock", [str(n["unlock"])])
	if bool(n["final"]) and not m.won:
		m.won = true
		m.push("victory")
	# arranque inmediato de lo que el nodo da al empezar la vuelta (si recién empezó)
	if str(n["unlock"]) == "album":
		m.free_packs_pending += 1
	return true


## ¿Hay algún nodo que se pueda comprar ya?
static func any_affordable(m: GameModel) -> bool:
	for n in GameData.tree:
		if can_buy(m, n["id"]):
			return true
	return false


## Cuántos nodos se pueden comprar ya mismo.
static func affordable_count(m: GameModel) -> int:
	var n: int = 0
	for nd in GameData.tree:
		if can_buy(m, nd["id"]):
			n += 1
	return n


static func cheapest_open(m: GameModel) -> int:
	var best: int = -1
	for n in GameData.tree:
		var id: String = n["id"]
		if m.tree.has(id) or not visible(m, id) or not requirements_met(m, id) or demo_locked(m, id):
			continue
		if best < 0 or cost(id) < best:
			best = cost(id)
	return best


static func complete(m: GameModel) -> bool:
	return m.tree.size() >= total()


static func has(m: GameModel, feature: String) -> bool:
	EconomyLogic.ensure_fresh(m)
	return bool(m.mods.get(feature, false))
