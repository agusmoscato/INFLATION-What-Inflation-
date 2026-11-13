extends RefCounted
## Consistencia de los datos JSON y de las traducciones.


func run(t) -> void:
	GameData.ensure()
	t.eq(GameData.eras.size(), 5, "5 eras")
	t.eq(GameData.businesses.size(), 16, "16 negocios")
	for era in range(1, 6):
		var n: int = 0
		for b in GameData.businesses:
			if b["era"] == era:
				n += 1
		t.check(n >= 2, "era %d tiene negocios" % era)
	var ids: Dictionary = {}
	for u in GameData.upgrades:
		t.check(not ids.has(u["id"]), "id de mejora único: %s" % u["id"])
		ids[u["id"]] = true
	for i in range(1, GameData.businesses.size()):
		t.check(GameData.businesses[i]["base_cost"].gt(GameData.businesses[i - 1]["base_cost"]), "costo creciente %d" % i)
	for i in range(1, GameData.eras.size()):
		t.check(GameData.eras[i]["threshold"].gt(GameData.eras[i - 1]["threshold"]), "umbral de era creciente %d" % i)
	# traducciones: todas las claves usadas existen en es y en
	var keys: Array = I18n.all_keys()
	t.check(keys.size() > 100, "CSV cargado (%d claves)" % keys.size())
	var needed: Array = []
	for b in GameData.businesses:
		needed.append(b["name_key"])
		needed.append(b["desc_key"])
	for u in GameData.upgrades:
		needed.append(u["name_key"])
		needed.append(u["desc_key"])
	for e in GameData.events:
		needed.append_array([e["name_key"], e["desc_key"], e["headline_key"]])
	for r in GameData.refuges:
		needed.append_array([r["name_key"], r["desc_key"]])
	for p in GameData.plans:
		needed.append_array([p["name_key"], p["desc_key"]])
	for e in GameData.eras:
		needed.append_array([e["name_key"], e["desc_key"]])
	for a in GameData.achievements:
		needed.append_array([a["name_key"], a["desc_key"]])
	for b in GameData.banknotes:
		needed.append(b["name_key"])
	for h in GameData.headlines:
		needed.append(h["key"])
	for k in needed:
		t.check(I18n.has_key(k, "es"), "falta ES: " + str(k))
		t.check(I18n.has_key(k, "en"), "falta EN: " + str(k))
	# claves tr("...") usadas en la UI
	var re: RegEx = RegEx.new()
	re.compile("tr\\(\"([^\"]+)\"\\)")
	var dir: DirAccess = DirAccess.open("res://scripts/ui")
	for fname in dir.get_files():
		if not fname.ends_with(".gd"):
			continue
		var src: String = FileAccess.get_file_as_string("res://scripts/ui/" + fname)
		for mt in re.search_all(src):
			var key: String = mt.get_string(1)
			t.check(I18n.has_key(key, "es") and I18n.has_key(key, "en"), "UI %s usa clave inexistente: %s" % [fname, key])
	for tab in GameScreen.TABS:
		t.check(I18n.has_key(tab, "es") and I18n.has_key(tab, "en"), "pestaña " + tab)
	for k in ["toast.measure", "toast.shock"]:
		t.check(I18n.has_key(k, "es") and I18n.has_key(k, "en"), k)
	# los marcadores de formato (%s, %d) coinciden entre español e inglés
	var ph: RegEx = RegEx.new()
	ph.compile("%[sd]")
	for k in I18n.all_keys():
		var es_n: int = ph.search_all(I18n.get_text(k, "es")).size()
		var en_n: int = ph.search_all(I18n.get_text(k, "en")).size()
		t.eq(es_n, en_n, "marcadores de formato iguales en " + str(k))
