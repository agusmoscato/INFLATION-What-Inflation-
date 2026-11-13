class_name GameData
extends RefCounted
## Carga (una sola vez) todo el contenido balanceable desde data/*.json.

static var _loaded: bool = false
static var balance: Dictionary = {}
static var cred_base: BigNumber
static var measure_costs: Array = []        # Array[BigNumber] (en términos reales)
static var eras: Array = []                 # {id,name_key,desc_key,threshold:BigNumber,inflation:float,color:Color}
static var businesses: Array = []           # {id,name_key,desc_key,era,base_cost,base_income,color,idx}
static var business_idx: Dictionary = {}
static var upgrades: Array = []             # {id,name_key,desc_key,biz,cost,era,effect,req_owned}
static var upgrade_idx: Dictionary = {}
static var events: Array = []
static var event_idx: Dictionary = {}
static var refuges: Array = []
static var refuge_idx: Dictionary = {}
static var plans: Array = []
static var plan_idx: Dictionary = {}
static var banknotes: Array = []
static var achievements: Array = []
static var headlines: Array = []


static func _read(file_name: String) -> Variant:
	var f: FileAccess = FileAccess.open("res://data/%s.json" % file_name, FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir data/%s.json" % file_name)
		return null
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed == null:
		push_error("JSON inválido: data/%s.json" % file_name)
	return parsed


static func ensure() -> void:
	if _loaded:
		return
	_loaded = true
	balance = _read("balance")
	cred_base = BigNumber.from_string(str(balance["cred_base"]))
	measure_costs.clear()
	for s in balance["measures"]:
		measure_costs.append(BigNumber.from_string(str(s)))

	eras.clear()
	for d in _read("eras"):
		eras.append({
			"id": int(d["id"]), "name_key": d["name_key"], "desc_key": d["desc_key"],
			"threshold": BigNumber.from_string(str(d["threshold"])),
			"inflation": float(d["inflation"]), "color": Color.html(str(d["color"])),
		})

	businesses.clear()
	business_idx.clear()
	var i: int = 0
	for d in _read("businesses"):
		var id: String = d["id"]
		businesses.append({
			"id": id, "name_key": "biz." + id, "desc_key": "biz.%s.d" % id, "era": int(d["era"]),
			"base_cost": BigNumber.from_string(str(d["base_cost"])),
			"base_income": BigNumber.from_string(str(d["base_income"])),
			"color": Color.html(str(d["color"])), "idx": i,
		})
		business_idx[id] = i
		i += 1

	upgrades.clear()
	upgrade_idx.clear()
	var ud: Dictionary = _read("upgrades")
	for b in businesses:
		for t in ud["per_business"]:
			var uid: String = "%s_%s" % [b["id"], t["suffix"]]
			_add_upgrade({
				"id": uid, "name_key": "upg.biz_" + str(t["suffix"]), "desc_key": "upg.biz_%s.d" % t["suffix"],
				"biz": b["id"], "era": b["era"],
				"cost": b["base_cost"].mul(BigNumber.from_string(str(t["cost_mult"]))),
				"effect": {"type": "business_mult", "value": float(t["mult"]), "biz": b["id"]},
				"req_owned": int(t["owned"]),
			})
	for s in ud["special"]:
		_add_upgrade({
			"id": s["id"], "name_key": "upg." + str(s["id"]), "desc_key": "upg.%s.d" % s["id"],
			"biz": "", "era": int(s["era"]), "cost": BigNumber.from_string(str(s["cost"])),
			"effect": s["effect"], "req_owned": 0,
		})

	events.clear()
	event_idx.clear()
	for d in _read("events"):
		d["name_key"] = "ev." + str(d["id"])
		d["desc_key"] = "ev.%s.d" % d["id"]
		d["headline_key"] = "hl.ev." + str(d["id"])
		event_idx[d["id"]] = events.size()
		events.append(d)

	refuges.clear()
	refuge_idx.clear()
	for d in _read("refuges"):
		d["name_key"] = "ref." + str(d["id"])
		d["desc_key"] = "ref.%s.d" % d["id"]
		d["color"] = Color.html(str(d["color"]))
		refuge_idx[d["id"]] = refuges.size()
		refuges.append(d)

	plans.clear()
	plan_idx.clear()
	for d in _read("plans"):
		d["name_key"] = "plan." + str(d["id"])
		d["desc_key"] = "plan.%s.d" % d["id"]
		plan_idx[d["id"]] = plans.size()
		plans.append(d)

	banknotes.clear()
	for d in _read("banknotes"):
		d["color"] = Color.html(str(d["color"]))
		banknotes.append(d)

	achievements.clear()
	for d in _read("achievements"):
		d["name_key"] = "ach." + str(d["id"])
		d["desc_key"] = "ach.%s.d" % d["id"]
		achievements.append(d)

	headlines = _read("headlines")


static func _add_upgrade(u: Dictionary) -> void:
	upgrade_idx[u["id"]] = upgrades.size()
	upgrades.append(u)


static func upgrade_title(u: Dictionary) -> String:
	if u["biz"] != "":
		return TranslationServer.translate(u["name_key"]) % TranslationServer.translate("biz." + str(u["biz"]))
	return TranslationServer.translate(u["name_key"])


static func era_def(era: int) -> Dictionary:
	return eras[clampi(era, 1, eras.size()) - 1]
