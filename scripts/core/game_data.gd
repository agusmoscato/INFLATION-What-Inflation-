class_name GameData
extends RefCounted
## Carga (una sola vez) todo el contenido balanceable desde data/*.json (diseño v2: clicker con renacimientos).

static var _loaded: bool = false
static var balance: Dictionary = {}
static var era_thresholds: Array = []       # Array[BigNumber]: ganado en la vuelta para las capas 2, 3 y 4
static var eras: Array = []                 # {id,name_key,color}
static var businesses: Array = []           # {id,name_key,desc_key,tier,base_cost,base_income,color,idx,unlock}
static var business_idx: Dictionary = {}
static var upgrades: Array = []             # {id,kind,biz,req,cost,fx,name_key,desc_key,icon}
static var upgrade_idx: Dictionary = {}
static var events: Array = []
static var event_idx: Dictionary = {}
static var banknotes: Array = []
static var achievements: Array = []
static var headlines: Array = []
static var stickers: Array = []             # {id,page,rarity,art,name_key,joke_key}
static var sticker_idx: Dictionary = {}
static var sticker_pages: Array = []        # {id,bonus}
static var tree_branches: Array = []        # {id,angle,color}
static var tree: Array = []                 # {id,branch,ring,slot,pos:Vector2,parents:Array,req_all:bool,cost:int,fx,seal,cap,bridge,unlock,final}
static var tree_idx: Dictionary = {}

const TREE_RING_PX: float = 150.0


static func _read(file_name: String) -> Variant:
	var f: FileAccess = FileAccess.open("res://data/%s.json" % file_name, FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir data/%s.json" % file_name)
		return null
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed == null:
		push_error("JSON inválido: data/%s.json" % file_name)
	return parsed


static func B(key: String) -> float:
	return float(balance[key])


static func ensure() -> void:
	if _loaded:
		return
	_loaded = true
	balance = _read("balance")
	era_thresholds.clear()
	for s in balance["era_thresholds"]:
		era_thresholds.append(BigNumber.from_string(str(s)))

	eras.clear()
	for d in _read("eras"):
		eras.append({"id": int(d["id"]), "name_key": d["name_key"], "color": Color.html(str(d["color"]))})

	businesses.clear()
	business_idx.clear()
	var i: int = 0
	for d in _read("businesses"):
		var id: String = d["id"]
		businesses.append({
			"id": id, "name_key": "biz." + id, "desc_key": "biz.%s.d" % id, "tier": int(d["tier"]),
			"base_cost": BigNumber.from_string(str(d["base_cost"])),
			"base_income": BigNumber.from_string(str(d["base_income"])),
			"color": Color.html(str(d["color"])), "idx": i, "unlock": str(d.get("unlock", "")),
		})
		business_idx[id] = i
		i += 1

	_load_upgrades()

	events.clear()
	event_idx.clear()
	for d in _read("events"):
		d["name_key"] = "ev." + str(d["id"])
		d["headline_key"] = "hl.ev." + str(d["id"])
		event_idx[d["id"]] = events.size()
		events.append(d)

	banknotes.clear()
	for d in _read("banknotes"):
		d["color"] = Color.html(str(d["color"]))
		banknotes.append(d)

	achievements.clear()
	for d in _read("achievements"):
		d["name_key"] = "ach." + str(d["id"])
		d["desc_key"] = "ach.%s.d" % d["id"]
		d["secret"] = bool(d.get("secret", false))
		achievements.append(d)

	headlines = _read("headlines")

	var sd: Dictionary = _read("stickers")
	sticker_pages = sd["pages"]
	stickers.clear()
	sticker_idx.clear()
	for s in sd["stickers"]:
		s["name_key"] = "stk." + str(s["id"])
		s["joke_key"] = "stk.%s.j" % s["id"]
		sticker_idx[s["id"]] = stickers.size()
		stickers.append(s)

	_load_tree()


static func _load_upgrades() -> void:
	upgrades.clear()
	upgrade_idx.clear()
	var ud: Dictionary = _read("upgrades")
	for b in businesses:
		for t in ud["per_business"]:
			_add_upgrade({
				"id": "%s_%s" % [b["id"], t["suffix"]], "kind": "biz", "biz": b["id"], "req": int(t["owned"]),
				"cost": b["base_cost"].mul(BigNumber.from_string(str(t["cost_mult"]))),
				"fx": {"type": "biz_mult", "value": float(t["mult"]), "biz": b["id"]},
				"name_key": "upg.biz_" + str(t["suffix"]), "desc_key": "upg.biz.d", "icon": b["id"],
			})
	# niveles altos por negocio: x2 a las 75, 100, 150... unidades; cuestan ~50 unidades de ese nivel
	var lv: Dictionary = ud["per_business_levels"]
	for b in businesses:
		var k: int = 5
		for n in lv["owned"]:
			_add_upgrade({
				"id": "%s_%d" % [b["id"], k], "kind": "biz", "biz": b["id"], "req": int(n),
				"cost": b["base_cost"].mul(BigNumber.from_float(1.15).pow_f(float(n))).mul_f(float(lv["units_cost"])),
				"fx": {"type": "biz_mult", "value": float(lv["mult"]), "biz": b["id"]},
				"name_key": "upg.biz_%d" % k, "desc_key": "upg.biz.d", "icon": b["id"],
			})
			k += 1
	for c in ud["click"]:
		_add_upgrade({
			"id": c["id"], "kind": "click", "biz": "", "req": int(c["clicks"]),
			"cost": BigNumber.from_string(str(c["cost"])),
			"fx": {"type": str(c["type"]), "value": float(c["value"])},
			"name_key": "upg." + str(c["id"]), "desc_key": "upg.%s.d" % c["id"], "icon": "empanada",
		})
	# de clic por el total de clics (en toda la partida); el precio se ajusta a tu ingreso
	for c in ud["click_total"]:
		_add_upgrade({
			"id": c["id"], "kind": "clicktotal", "biz": "", "req": int(c["clicks"]),
			"cost": BigNumber.from_float(100.0), "cost_s": float(c["cost_s"]),
			"fx": {"type": str(c["type"]), "value": float(c["value"])},
			"name_key": "upg." + str(c["id"]), "desc_key": "upg.%s.d" % c["id"], "icon": "empanada",
		})
	for s in ud["synergy_small"]:
		var o2: Dictionary = businesses[business_idx[s["b"]]]
		_add_upgrade({
			"id": s["id"], "kind": "syn", "biz": s["a"], "other": s["b"], "req": int(ud["synergy_small_req"]),
			"cost": o2["base_cost"].mul(BigNumber.from_string(str(ud["synergy_small_cost_mult"]))),
			"fx": {"type": "synergy", "value": float(s["pct"]), "biz": s["a"], "other": s["b"]},
			"name_key": "upg." + str(s["id"]), "desc_key": "upg.syn.d", "icon": s["a"],
		})
	# campañas de publicidad: nunca se acaban (todo x1,05; cada una cuesta más segundos de ingreso que la anterior)
	var pr: Dictionary = ud["promo"]
	for i in range(int(pr["levels"])):
		_add_upgrade({
			"id": "promo_%d" % (i + 1), "kind": "promo", "biz": "", "req": int(pr["first_req"]), "level": i + 1,
			"cost": BigNumber.from_float(50.0), "cost_s": float(pr["cost_s"]) * pow(float(pr["cost_growth"]), float(i)),
			"fx": {"type": "all_mult", "value": float(pr["value"])},
			"name_key": "upg.promo_%d" % (i % int(pr["names"])), "desc_key": "upg.promo.d", "icon": "star",
		})
	for s in ud["synergy"]:
		var other: Dictionary = businesses[business_idx[s["b"]]]
		_add_upgrade({
			"id": s["id"], "kind": "syn", "biz": s["a"], "other": s["b"], "req": int(ud["synergy_req"]),
			"cost": other["base_cost"].mul(BigNumber.from_string(str(ud["synergy_cost_mult"]))),
			"fx": {"type": "synergy", "value": float(s["pct"]), "biz": s["a"], "other": s["b"]},
			"name_key": "upg." + str(s["id"]), "desc_key": "upg.syn.d", "icon": s["a"],
		})
	for g in ud["global"]:
		_add_upgrade({
			"id": g["id"], "kind": "global", "biz": "", "req": int(g["buildings"]),
			"cost": BigNumber.from_string(str(g["cost"])),
			"fx": {"type": "all_mult", "value": float(g["value"])},
			"name_key": "upg." + str(g["id"]), "desc_key": "upg.glob.d", "icon": "star",
		})


static func _add_upgrade(u: Dictionary) -> void:
	upgrade_idx[u["id"]] = upgrades.size()
	upgrades.append(u)


## Árbol de habilidades: posiciones en anillos alrededor del nodo final (centro), una rama cada 60°.
static func _load_tree() -> void:
	tree.clear()
	tree_idx.clear()
	var td: Dictionary = _read("tree")
	tree_branches = td["branches"]
	var angles: Dictionary = {}
	for b in tree_branches:
		angles[str(b["id"])] = float(b["angle"])
	var ring_costs: Array = balance["tree_ring_costs"]
	var by_pos: Dictionary = {}       # "branch:r:s" -> id
	var fin: Dictionary = td["final"]
	_add_node({"id": fin["id"], "branch": "final", "ring": 0, "slot": 0, "pos": Vector2.ZERO, "parents": fin["req"],
		"req_all": true, "cost": int(B("tree_final_cost")), "fx": fin["fx"], "seal": false, "cap": false, "bridge": false,
		"unlock": "", "final": true})
	for d in td["nodes"]:
		var id: String = d["id"]
		var r: int = int(d["r"])
		if bool(d.get("bridge", false)):
			var ang: float = deg_to_rad(float(d["angle"]))
			_add_node({"id": id, "branch": "bridge", "ring": r, "slot": 0,
				"pos": Vector2(cos(ang), sin(ang)) * TREE_RING_PX * float(r), "parents": d["req"], "req_all": true,
				"cost": int(B("tree_bridge_cost")), "fx": d["fx"], "seal": false, "cap": false, "bridge": true,
				"unlock": str(d.get("unlock", "")), "final": false})
			continue
		var br: String = id.get_slice("_", 0)
		var s: int = int(d.get("s", 0))
		var step: float = minf(0.30, 115.0 / (TREE_RING_PX * float(r)))
		var a: float = deg_to_rad(angles[br]) + float(s) * step
		var parents: Array = []
		if r > 1:
			var key_same: String = "%s:%d:%d" % [br, r - 1, s]
			parents.append(by_pos[key_same] if by_pos.has(key_same) else by_pos["%s:%d:0" % [br, r - 1]])
		var cost: float = float(ring_costs[r - 1])
		if s != 0:
			cost *= B("tree_side_mult")
		_add_node({"id": id, "branch": br, "ring": r, "slot": s,
			"pos": Vector2(cos(a), sin(a)) * TREE_RING_PX * float(r), "parents": parents, "req_all": true,
			"cost": int(round(cost)), "fx": d["fx"], "seal": bool(d.get("seal", false)), "cap": bool(d.get("cap", false)),
			"bridge": false, "unlock": str(d.get("unlock", "")), "final": false})
		by_pos["%s:%d:%d" % [br, r, s]] = id


static func _add_node(n: Dictionary) -> void:
	n["name_key"] = "node." + str(n["id"])
	n["desc_key"] = "node.%s.d" % n["id"]
	tree_idx[n["id"]] = tree.size()
	tree.append(n)


static func node(id: String) -> Dictionary:
	return tree[tree_idx[id]]


static func branch_color(branch: String) -> Color:
	for b in tree_branches:
		if str(b["id"]) == branch:
			return Color.html(str(b["color"]))
	return Color("#F2EFE6")


static func upgrade_title(u: Dictionary) -> String:
	if u["kind"] == "biz":
		return TranslationServer.translate(u["name_key"]) % TranslationServer.translate("biz." + str(u["biz"]))
	if u["kind"] == "promo":
		return "%s (%d)" % [TranslationServer.translate(u["name_key"]), int(u["level"])]
	return TranslationServer.translate(u["name_key"])


static func era_def(era: int) -> Dictionary:
	return eras[clampi(era, 1, eras.size()) - 1]
