extends Control
## Raíz del juego: administra las pantallas (menú, juego, opciones, créditos) y las capas del pizarrón.

var current: Control
var sfx: SoundFx
var board: ChalkBoard
var _pending_offline: Dictionary = {}
var _game: GameScreen


func _ready() -> void:
	I18n.load_all()
	Settings.load_settings()
	Chalk.load_fonts()
	theme = ChalkTheme.build()
	# capas: pizarrón (abajo) -> pantallas -> efecto tiza (pantalla completa) -> marco de madera
	board = ChalkBoard.new()
	add_child(board)
	var post_layer: CanvasLayer = CanvasLayer.new()
	post_layer.layer = 50
	add_child(post_layer)
	post_layer.add_child(ChalkPost.new())
	var frame_layer: CanvasLayer = CanvasLayer.new()
	frame_layer.layer = 60
	add_child(frame_layer)
	frame_layer.add_child(WoodFrame.new())
	sfx = SoundFx.new()
	add_child(sfx)
	Settings.apply()
	EventBus.offline_report.connect(func(r: Dictionary) -> void: _pending_offline = r)
	show_menu()
	if OS.get_cmdline_user_args().has("--qa-screenshot"):
		call_deferred("_qa_run")


func _set_screen(screen: Control) -> void:
	if current != null:
		current.queue_free()
	current = screen
	add_child(screen)
	move_child(screen, 1)      # justo encima del pizarrón, debajo de las capas de efecto
	if screen is GameScreen:
		_game = screen
	else:
		_game = null


func show_menu() -> void:
	Economy.running = false
	var s: MenuScreen = MenuScreen.new()
	s.continue_game.connect(func() -> void: start_game(true))
	s.new_game.connect(func() -> void: start_game(false))
	s.open_options.connect(show_options)
	s.open_howto.connect(show_howto)
	s.open_credits.connect(func() -> void: show_credits(false))
	s.quit_game.connect(func() -> void:
		SaveSystem.save_game()
		get_tree().quit())
	_set_screen(s)
	if board != null:
		board.set_smudge(0.0)


func show_options() -> void:
	var s: OptionsScreen = OptionsScreen.new()
	s.closed.connect(show_menu)
	s.language_changed.connect(show_options)
	_set_screen(s)


func show_credits(victory: bool) -> void:
	Economy.running = false
	var s: CreditsScreen = CreditsScreen.new()
	s.victory = victory
	s.back_to_menu.connect(func() -> void:
		SaveSystem.save_game()
		show_menu())
	s.keep_playing.connect(func() -> void: start_game(true, true))
	_set_screen(s)


func start_game(continue_save: bool, resume_memory: bool = false) -> void:
	_pending_offline = {}
	if resume_memory:
		pass
	elif continue_save:
		if not SaveSystem.load_game():
			GameState.new_game()
	else:
		SaveSystem.delete_save()
		GameState.new_game()
	var g: GameScreen = GameScreen.new()
	g.request_menu.connect(func() -> void:
		SaveSystem.save_game()
		show_menu())
	g.request_demo_end.connect(show_demo_end)
	g.request_credits.connect(func() -> void:
		if not GameState.m.won_notified:
			GameState.m.won_notified = true
			SaveSystem.save_game()
			show_credits(true))
	if GameState.m.demo_finished:
		g.free()
		show_demo_end()
		return
	_set_screen(g)
	if not _pending_offline.is_empty():
		g.show_offline_report(_pending_offline)
		_pending_offline = {}


func _unhandled_input(event: InputEvent) -> void:
	if _game != null and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		Economy.click()
		_game.empanada.poke()


func show_demo_end() -> void:
	Economy.running = false
	SaveSystem.save_game()
	var s: DemoEndScreen = DemoEndScreen.new()
	s.back_to_menu.connect(show_menu)
	_set_screen(s)


func show_howto() -> void:
	var s: HowToScreen = HowToScreen.new()
	s.closed.connect(show_menu)
	_set_screen(s)


# =====================================================================
#  Control de calidad: godot/exe --qa-screenshot
#  Recorre menú -> partida nueva -> negocios -> álbum -> timba (en español e inglés), saca capturas a user://qa/
#  y falla (código de salida 1) si algún texto visible es una clave de traducción sin traducir.
# =====================================================================
func _qa_wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _qa_shot(name: String, failures: Array) -> void:
	var bad: Array = QaCheck.scan(self)
	for b in bad:
		failures.append("[%s] %s" % [name, b])
	if DisplayServer.get_name() != "headless":
		var img: Image = get_viewport().get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path("user://qa/%s.png" % name))
	print("QA captura %-22s claves sin traducir: %d" % [name, bad.size()])


func _qa_run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://qa"))
	SaveSystem.save_path = "user://qa_save.json"
	Settings.path = "user://qa_settings.cfg"
	var failures: Array = []
	for lang in ["es", "en"]:
		Settings.language = lang
		Settings.apply()
		show_menu()
		await _qa_wait(0.8)
		_qa_shot("menu_" + lang, failures)
		show_howto()
		await _qa_wait(0.6)
		_qa_shot("comojuega_" + lang, failures)
		Settings.tutorial_done = false
		start_game(false)
		await _qa_wait(1.0)
		_qa_shot("negocios_" + lang, failures)
		var m: GameModel = GameState.m
		m.era = 3
		m.money = BigNumber.from_string("5e12")
		m.base_income = BigNumber.from_float(1e8)
		m.owned["kiosco"] = 4
		m.owned["empanadas"] = 10
		m.dirty = true
		for id in ["biz_empanadas", "biz_kiosco", "pj_perro", "hl_2", "gold_1", "note_0"]:
			StickerLogic.give(m, id)
		m.notifications.clear()
		await _qa_wait(0.4)
		_game._select_tab(4)
		await _qa_wait(0.6)
		_qa_shot("album_" + lang, failures)
		_game._select_tab(5)
		await _qa_wait(0.6)
		_qa_shot("timba_" + lang, failures)
		_game._select_tab(3)
		await _qa_wait(0.4)
		_qa_shot("reforma_" + lang, failures)
	var f: FileAccess = FileAccess.open("user://qa/result.txt", FileAccess.WRITE)
	f.store_string("%s\n%s\n" % ["FAIL" if not failures.is_empty() else "PASS", "\n".join(failures)])
	f.close()
	SaveSystem.delete_save()
	DirAccess.remove_absolute(Settings.path)
	if failures.is_empty():
		print("QA OK: ningún texto visible es una clave de traducción")
	else:
		printerr("QA FALLA: %d textos sin traducir:\n%s" % [failures.size(), "\n".join(failures)])
	get_tree().quit(1 if not failures.is_empty() else 0)
