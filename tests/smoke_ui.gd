extends Control
## Prueba de humo de la interfaz (diseño v2): arranca Main, hace clic, compra, abre el árbol, el álbum, la raspadita,
## los logros, reforma, guarda y carga, opciones, créditos y vuelve en inglés.
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
			m.run_earned = BigNumber.from_float(1e9)
			m.run_clicks = 500
			m.dirty = true
		if frame > 20 and frame % 7 == 0:
			for def in GameData.businesses:
				Economy.buy_business(def["id"], 1)
			EconomyLogic.smart_buy(m)
		if frame == 30:
			Economy.remark()
			m.bill_timer = 0.0
		if frame == 36:
			for b in m.bills_active.duplicate():
				Economy.click_bill(int(b["id"]))
		if frame == 40:
			Unlocks.unlock_all(m)
			m.credibility = 50
			EconomyLogic.start_event(m, "feriado")
		if frame == 44:
			Economy.choose_event(1)
		if frame == 46:
			g._open_tree()
		if frame == 50:
			g._tree_view.zoom_by(1.3)
			_shot("2_tree")
		if frame == 54:
			g._open_album()
		if frame == 58:
			_shot("3_album")
			m.free_packs_pending = 1
		if frame == 60:
			g._open_pack_overlay(Economy.open_free_pack())
		if frame == 66:
			g._open_achievements()
		if frame == 70:
			g._close_overlay()
			g._open_scratch()
		if frame == 76:
			if g._scratch_overlay != null:
				g._scratch_overlay.queue_free()
				g._scratch_overlay = null
			m.collapse_shown = true
			g._open_reform_dialog()
		if frame == 80:
			_shot("4_reform_dialog")
			g._close_overlay()
			Economy.reform()
		if frame == 150:
			print("save:", SaveSystem.save_game(), " load:", SaveSystem.load_game())
		if frame == 160:
			g.show_offline_report({"seconds": 3600.0, "capped": false, "money_before": BigNumber.one(), "money_after": BigNumber.from_float(5.0), "gain": BigNumber.from_float(4.0)})
		if frame == 200:
			main.show_options()
	if frame == 220:
		main.show_credits(true)
	if frame == 240:
		main.show_menu()
	if frame == 250:
		Settings.language = "en"
		Settings.apply()
		main.start_game(true)
	if frame == 270:
		_shot("5_english")
		Settings.language = "es"
		Settings.apply()
	if frame == 285:
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
