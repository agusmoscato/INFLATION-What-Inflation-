extends Control
## Recorrido automático de capturas para revisar el layout a distintas resoluciones.
## Uso (ventana real, no headless):
##   SHOT_DIR=docs/screenshots godot --rendering-driver opengl3 --resolution 1920x1080 res://tests/ScreenshotTour.tscn
## Guarda <ancho>x<alto>_<nombre>.png en SHOT_DIR. Usa rutas de guardado aparte (no toca la partida real).

const STEP: int = 18

var main: Node
var frame: int = 0
var tag: String = ""
var steps: Array = []
var shot_vp: Viewport


func _ready() -> void:
	SaveSystem.save_path = "user://test_save.json"
	Settings.path = "user://test_settings.cfg"
	SaveSystem.delete_save()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	main = load("res://scenes/Main.tscn").instantiate()
	shot_vp = get_viewport()
	var sz: Vector2i = get_window().size
	var res: String = OS.get_environment("TOUR_RES")
	if res != "":
		# Render offscreen a tamaño exacto, emulando el escalado del proyecto (canvas_items + expand).
		sz = Vector2i(res.get_slice("x", 0).to_int(), res.get_slice("x", 1).to_int())
		var s: float = minf(float(sz.x) / 1280.0, float(sz.y) / 720.0)
		var sv: SubViewport = SubViewport.new()
		sv.size = sz
		sv.size_2d_override = Vector2i(int(round(float(sz.x) / s)), int(round(float(sz.y) / s)))
		sv.size_2d_override_stretch = true
		sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(sv)
		sv.add_child(main)
		shot_vp = sv
	else:
		add_child(main)
	tag = "%dx%d" % [sz.x, sz.y]
	steps = [
		["menu", _menu],
		["00_tutorial", _tut],
		["01_juego_era1", _early],
		["02_negocios_era3", _mid],
		["02b_remarcando", _remark],
		["02c_decision", _decision],
		["03_mejoras", _tab.bind(1)],
		["04_refugios", _tab.bind(2)],
		["05_reforma", _tab.bind(3)],
		["06_billetes", _tab.bind(4)],
		["07_logros", _tab.bind(5)],
		["08_hiperinflacion", _hyper],
		["09_reforma_tijera", _reform_anim],
		["10_opciones", _options],
		["11_creditos", _credits],
		["12_demo_fin", _demo_end],
	]


func _process(_delta: float) -> void:
	frame += 1
	if frame % STEP != 0:
		return
	var i: int = frame / STEP - 1
	if i > 0 and i - 1 < steps.size():
		_shot(steps[i - 1][0])
	if i < steps.size():
		steps[i][1].call()
	else:
		SaveSystem.delete_save()
		DirAccess.remove_absolute(Settings.path)
		print("TOUR OK ", tag)
		get_tree().quit(0)


func _shot(name: String) -> void:
	var dir: String = OS.get_environment("SHOT_DIR")
	if dir == "":
		dir = "user://"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir) if dir.begins_with("user://") or dir.begins_with("res://") else dir)
	shot_vp.get_texture().get_image().save_jpg("%s/%s_%s.jpg" % [dir, tag, name], 0.9)


func _g() -> GameScreen:
	return main._game


func _menu() -> void:
	pass


func _tut() -> void:
	if OS.get_environment("TOUR_QUALITY") != "":
		Settings.quality = OS.get_environment("TOUR_QUALITY").to_int()
		Settings.apply()
	Settings.tutorial_done = false
	main.start_game(false)


func _early() -> void:
	Settings.tutorial_done = false
	Settings.language = "es"
	Settings.apply()
	main.start_game(false)
	var m: GameModel = GameState.m
	m.money = BigNumber.from_float(900.0)
	Economy.buy_business("empanadas", 3)
	Economy.buy_business("kiosco", 1)
	m.money = BigNumber.from_float(412.0)
	for i in range(5):
		Economy.click()


func _mid() -> void:
	var m: GameModel = GameState.m
	m.era = 3
	m.reforms = 3
	m.credibility = 40
	m.album = [0, 1, 2]
	m.achievements["first_sale"] = true
	m.achievements["era_2"] = true
	m.achievements["era_3"] = true
	m.lifetime_real = BigNumber.from_float(5e11)
	m.run_real = BigNumber.from_float(1e12)
	m.money = BigNumber.from_string("3.4e14")
	m.price_level = BigNumber.from_float(84.0)
	m.my_prices = BigNumber.from_float(61.0)
	m.dirty = true
	for def in GameData.businesses:
		if def["era"] <= 3:
			m.owned[def["id"]] = 8 + int(def["idx"]) * 5
	m.upgrades["auto_remark1"] = true
	m.upgrades["click1"] = true
	m.dirty = true
	Economy.refuge_buy("usd", 0.02)
	Economy.refuge_buy("gold", 0.02)
	EconomyLogic.start_event(m, "aguinaldo", 1)
	Economy.flush()
	_g()._select_tab(0)


func _remark() -> void:
	Economy.remark()


func _decision() -> void:
	var m: GameModel = GameState.m
	m.pending_choice = {}
	EconomyLogic.start_event(m, "corrida")
	Economy.flush()


func _tab(i: int) -> void:
	_g()._select_tab(i)


func _hyper() -> void:
	var m: GameModel = GameState.m
	m.era = 5
	m.measures = 1
	m.active_events = []
	EconomyLogic.start_event(m, "cepo", 1)
	m.dirty = true
	_g()._select_tab(0)
	EconomyLogic.month_end(m)
	Economy.flush()


func _reform_anim() -> void:
	var m: GameModel = GameState.m
	m.run_real = BigNumber.from_float(1e14)
	m.price_level = BigNumber.from_string("1e9")
	Economy.reform()


func _options() -> void:
	main.show_options()


func _demo_end() -> void:
	main.show_demo_end()


func _credits() -> void:
	GameState.m.won = true
	main.show_credits(true)
