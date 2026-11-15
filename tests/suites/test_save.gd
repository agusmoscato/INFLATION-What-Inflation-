extends RefCounted

const PATH: String = "user://test_save.json"


func run(t) -> void:
	var m: GameModel = GameModel.new(5)
	m.money = BigNumber.from_float(1e6)
	EconomyLogic.buy_business(m, "empanadas", 10)
	EconomyLogic.buy_business(m, "kiosco", 3)
	EconomyLogic.tick(m, 2.5)
	EconomyLogic.buy_upgrade(m, "empanadas_1")
	m.tree["neg_1"] = true
	m.tree["fig_1"] = true
	m.album.append(0)
	m.credibility = 7
	m.cred_total = 30
	m.clicks = 123
	m.ln_p = 30.0
	m.run_time = 200.0
	m.best_run = BigNumber.from_string("4.2e77")
	m.achievements["first_sale"] = true
	m.runs.append({"n": 1, "earned": "1e6", "time": 250.0, "cred": 4})
	StickerLogic.give(m, "biz_kiosco")
	EconomyLogic.start_event(m, "aguinaldo")
	EconomyLogic.choose(m, 1)
	m.dirty = true
	# ida y vuelta por JSON
	var d: Dictionary = m.to_dict()
	var parsed: Variant = JSON.parse_string(JSON.stringify(d))
	t.check(typeof(parsed) == TYPE_DICTIONARY, "JSON válido")
	var m2: GameModel = GameModel.new(1)
	t.check(m2.from_dict(parsed), "carga la versión 2")
	t.check(m2.money.approx_eq(m.money), "dinero")
	t.near(m2.ln_p, 30.0, "nivel de precios")
	t.eq(m2.owned_count("empanadas"), 10, "empanadas")
	t.eq(m2.owned_count("kiosco"), 3, "kiosco")
	t.check(m2.upgrades.has("empanadas_1"), "mejora")
	t.check(m2.tree.has("neg_1") and m2.tree.has("fig_1"), "árbol")
	t.eq(m2.album, [0], "álbum de billetes")
	t.eq(m2.credibility, 7, "credibilidad")
	t.eq(m2.cred_total, 30, "credibilidad total")
	t.eq(m2.clicks, 123, "clics")
	t.check(m2.best_run.approx_eq(m.best_run), "mejor vuelta")
	t.check(m2.achievements.has("first_sale"), "logros")
	t.eq(m2.runs.size(), 1, "historial de vueltas")
	t.eq(m2.active_events.size(), 1, "noticia activa")
	t.eq(StickerLogic.owned(m2, "biz_kiosco"), 1, "figuritas")
	t.near(EconomyLogic.income_per_sec(m2).to_float(), EconomyLogic.income_per_sec(m).to_float(), "mismo ingreso")
	# archivo real
	t.check(SaveIO.save_model(m, PATH), "guardar archivo")
	var m3: GameModel = GameModel.new(1)
	var rep: Dictionary = SaveIO.load_into(m3, PATH, m.saved_unix + 5.0)
	t.check(not rep.is_empty(), "cargar archivo")
	t.eq(m3.owned_count("kiosco"), 3, "archivo: kiosco")
	# offline: 1 hora afuera
	var m4: GameModel = GameModel.new(1)
	var now: float = Time.get_unix_time_from_system()
	var rep2: Dictionary = SaveIO.load_into(m4, PATH, now + 3600.0)
	t.check(float(rep2.get("seconds", 0.0)) > 3000.0, "reporte offline de 1 h")
	t.check(m4.money.gt(m.money), "offline suma plata")
	# partidas de la versión 1 (el tycoon): no se convierten
	SaveIO.write(PATH, {"version": 1, "money": "1e9", "era": 3})
	var m5: GameModel = GameModel.new(1)
	var rep3: Dictionary = SaveIO.load_into(m5, PATH, now)
	t.check(rep3.has("old"), "una partida vieja se detecta y no se carga")
	SaveIO.remove(PATH)
	t.check(not FileAccess.file_exists(PATH), "borrar save")
	t.check(SaveIO.load_into(GameModel.new(1), PATH, now).is_empty(), "sin save devuelve vacío")
