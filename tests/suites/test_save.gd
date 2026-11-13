extends RefCounted

const PATH: String = "user://test_save.json"


func run(t) -> void:
	var m: GameModel = GameModel.new(5)
	m.money = BigNumber.from_float(1e6)
	EconomyLogic.buy_business(m, "empanadas", 10)
	EconomyLogic.buy_business(m, "kiosco", 3)
	EconomyLogic.buy_upgrade(m, "click1")
	m.era = 2
	m.album.append(0)
	m.credibility = 7
	m.clicks = 123
	m.price_level = BigNumber.from_string("1.5e77")
	m.achievements["first_sale"] = true
	EconomyLogic.refuge_buy(m, "gold", BigNumber.from_float(1000.0))
	EconomyLogic.start_event(m, "cepo", 1)
	# ida y vuelta por JSON
	var d: Dictionary = m.to_dict()
	var parsed: Variant = JSON.parse_string(JSON.stringify(d))
	t.check(typeof(parsed) == TYPE_DICTIONARY, "JSON válido")
	var m2: GameModel = GameModel.new(1)
	m2.from_dict(parsed)
	t.check(m2.money.approx_eq(m.money), "dinero")
	t.check(m2.price_level.approx_eq(m.price_level), "nivel de precios 1,5e77")
	t.eq(m2.owned_count("empanadas"), 10, "empanadas")
	t.eq(m2.owned_count("kiosco"), 3, "kiosco")
	t.check(m2.upgrades.has("click1"), "mejora")
	t.eq(m2.era, 2, "era")
	t.eq(m2.album, [0], "álbum")
	t.eq(m2.credibility, 7, "credibilidad")
	t.eq(m2.clicks, 123, "clics")
	t.check(m2.achievements.has("first_sale"), "logros")
	t.check(m2.refuge_units["gold"].approx_eq(m.refuge_units["gold"]), "refugio")
	t.eq(m2.active_events.size(), 1, "evento activo")
	t.near(EconomyLogic.income_per_sec(m2).to_float(), EconomyLogic.income_per_sec(m).to_float(), "mismo ingreso")
	# archivo real
	t.check(SaveIO.save_model(m, PATH), "escribe el archivo")
	var m3: GameModel = GameModel.new(1)
	var now: float = Time.get_unix_time_from_system()
	var rep: Dictionary = SaveIO.load_into(m3, PATH, now + 5.0)
	t.eq(float(rep.get("seconds", -1.0)), 0.0, "sin offline si pasó poco")
	t.eq(m3.owned_count("kiosco"), 3, "carga desde archivo")
	# offline: 1 hora lejos
	var m4: GameModel = GameModel.new(1)
	var rep2: Dictionary = SaveIO.load_into(m4, PATH, now + 3600.0)
	t.near(float(rep2["seconds"]), 3600.0, "1 h offline", 0.01)
	t.eq(int(rep2["months"]), 12, "tope de 12 meses de inflación por ausencia")
	t.check(m4.price_level.gt(m.price_level), "P subió offline")
	t.check(m4.lifetime_real.ge(m.lifetime_real), "el progreso offline no pierde ganancias")
	# archivo corrupto / inexistente
	var m5: GameModel = GameModel.new(1)
	t.check(SaveIO.load_into(m5, "user://no_existe.json", now).is_empty(), "sin save => {}")
	var f: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("{esto no es json")
	f.close()
	t.check(SaveIO.read(PATH).is_empty(), "save corrupto no rompe")
	SaveIO.remove(PATH)
	t.check(not FileAccess.file_exists(PATH), "borrado")
	# logros
	var m6: GameModel = GameModel.new(1)
	var prov: LocalAchievements = LocalAchievements.new(m6.achievements)
	EconomyLogic.do_click(m6)
	var fresh: Array = AchievementTracker.check(m6, prov)
	t.check(fresh.has("first_sale"), "logro primera venta")
	t.check(AchievementTracker.check(m6, prov).is_empty(), "no se repite")
