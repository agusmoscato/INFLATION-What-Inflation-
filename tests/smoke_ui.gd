extends Control
## Prueba de humo de la interfaz: arranca Main, juega unos cientos de frames tocando todas las pestañas.
## Uso: godot --headless res://tests/SmokeUI.tscn   (cualquier "SCRIPT ERROR" en la salida es un fallo)

var main: Node
var frame: int = 0


func _ready() -> void:
	# Modo test: nunca tocar la partida ni las opciones reales.
	SaveSystem.save_path = "user://test_save.json"
	Settings.path = "user://test_settings.cfg"
	SaveSystem.delete_save()
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	frame += 1
	var m: GameModel = GameState.m
	if frame == 4:
		_shot("1_menu")
	if frame == 5:
		main.start_game(false)
	if main._game != null:
		var g: GameScreen = main._game
		if frame % 3 == 0:
			Economy.click()
		if frame == 20:
			m.money = BigNumber.from_float(1e9)
			m.era = 2
			m.lifetime_real = BigNumber.from_float(1e8)
			m.run_real = BigNumber.from_float(1e13)
			m.dirty = true
		if frame > 20 and frame % 7 == 0:
			for def in GameData.businesses:
				Economy.buy_business(def["id"], 1)
			EconomyLogic.smart_buy(m)
		if frame >= 30 and frame < 30 + 7 * 12:
			g._select_tab(((frame - 30) / 12) % 7)
		if frame == 60:
			Economy.remark()
			Economy.refuge_buy("gold", 0.25)
			EconomyLogic.start_event(m, "paro", 1)
			EconomyLogic.start_event(m, "cepo", 1)
		if frame == 55:
			_shot("2_biz")
		if frame == 42:
			_shot("3_upg")
		if frame == 66:
			_shot("4_refuge")
		if frame == 78:
			_shot("5_reform")
		if frame == 91:
			_shot("6_album")
		if frame == 92:
			_shot("7_after_month")
		if frame == 90:
			EconomyLogic.month_end(m)
		if frame == 100:
			m.era = 5
			m.measures = 0
			m.money = BigNumber.from_string("1e40")
			Economy.buy_measure()
		if frame == 110:
			Economy.reform()
		if frame == 112:
			Economy.reform()
		if frame == 200:
			m.era = 4
			m.credibility = 100
			Economy.plan("emission")
		if frame == 230:
			g.show_offline_report({"seconds": 3600.0, "months": 120, "money_before": BigNumber.one(), "money_after": BigNumber.from_float(5.0), "power_before": BigNumber.one(), "power_after": BigNumber.one()})
		if frame == 260:
			main.show_options()
	if frame == 280:
		main.show_credits(true)
	if frame == 300:
		main.show_menu()
	if frame == 150:
		print("save:", SaveSystem.save_game(), " load:", SaveSystem.load_game())
	if frame == 305:
		Settings.language = "en"
		Settings.apply()
		main.start_game(true)
	if frame == 330:
		_shot("8_english")
		Settings.language = "es"
		Settings.apply()
	if frame == 345:
		SaveSystem.delete_save()
		DirAccess.remove_absolute(Settings.path)
		print("SMOKE OK (frames=%d)" % frame)
		get_tree().quit(0)


func _shot(name: String) -> void:
	var dir: String = OS.get_environment("SHOT_DIR")
	if dir == "":
		return
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [dir, name])
