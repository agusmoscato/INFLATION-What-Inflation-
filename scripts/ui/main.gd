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
	var win: Window = get_window()
	if win != null and win.size.y > win.size.x and not (get_viewport() is SubViewport):
		win.content_scale_size = Vector2i(720, 1280)      # pantalla vertical: layout de 720x1280
	show_menu()
	var ua: PackedStringArray = OS.get_cmdline_user_args()
	if ua.has("--record-clip") and ua.find("--record-clip") + 1 < ua.size():
		call_deferred("_start_clip", ua[ua.find("--record-clip") + 1])
	if OS.get_cmdline_user_args().has("--qa-screenshot"):
		call_deferred("_qa_run")
	if OS.has_feature("web"):
		var q: String = str(JavaScriptBridge.eval("window.location.search"))
		if q.contains("qa=web"):
			call_deferred("_qa_web", 2 if q.contains("phase=2") else 1)


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
	if DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
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


## Grabación de clips: godot --write-movie out.avi --fixed-fps 30 --resolution 1920x1080 -- --record-clip <nombre>
func _start_clip(clip_name: String) -> void:
	SaveSystem.save_path = "user://clip_save.json"
	SaveSystem.ignore_close = true
	Settings.path = "user://clip_settings.cfg"
	Settings.tutorial_done = true
	Settings.language = "es"
	Settings.apply()
	var ua: PackedStringArray = OS.get_cmdline_user_args()
	if ua.has("--clip-size"):
		var wh: PackedStringArray = ua[ua.find("--clip-size") + 1].split("x")
		get_window().size = Vector2i(int(wh[0]), int(wh[1]))
		print("clip window: ", get_window().size)
	start_game(false)
	var d: ClipDirector = ClipDirector.new(self, clip_name)
	add_child(d)


# =====================================================================
#  QA del build web: http://.../index.html?qa=web  (fase 1) y ?qa=web&phase=2 (despues de recargar).
#  tools/web_qa.ps1 lo maneja con Chrome headless: mira las lineas "QA_*" de la consola y hace los arrastres del mouse.
# =====================================================================
func _qa_translation(langs: Array) -> Array:
	var failures: Array = []
	for lang in langs:
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
	return failures


func _qa_web(phase: int) -> void:
	SaveSystem.save_path = "user://qa_web_save.json"
	Settings.path = "user://qa_web_settings.cfg"
	if phase == 2:
		await _qa_wait(1.0)
		var ok: bool = SaveSystem.load_game()
		print("QA_PERSIST loaded=%s clicks=%d packs=%d" % [ok, GameState.m.clicks, GameState.m.packs_opened])
		return
	var failures: Array = await _qa_translation(["es", "en"])
	print("QA_I18N bad=%d %s" % [failures.size(), " | ".join(failures)])
	Settings.language = "es"
	Settings.apply()
	Settings.tutorial_done = true
	start_game(false)
	await _qa_wait(1.0)
	var m: GameModel = GameState.m
	m.era = 3
	m.money = BigNumber.from_string("5e12")
	m.base_income = BigNumber.from_float(1e8)
	m.dirty = true
	Input.use_accumulated_input = false      # Chrome headless corre a pocos cuadros por segundo: sin esto se pierden los movimientos del mouse
	# raspadita con el mouse
	var ov: ScratchOverlay = _game._open_scratch(0.05)
	await _qa_wait(0.8)
	var st: Transform2D = get_viewport().get_screen_transform()
	var a: Vector2 = st * ov._card.position
	var b: Vector2 = st * ov._card.end
	print("QA_DRAG scratch %d %d %d %d" % [a.x + 40, a.y + 40, b.x - 40, b.y - 40])
	var t0: int = Time.get_ticks_msec()
	while ov != null and is_instance_valid(ov) and not ov._done and Time.get_ticks_msec() - t0 < 25000:
		await _qa_wait(0.2)
	print("QA_SCRATCH done=%s revealed=%d" % [ov._done, ov._revealed])
	_game._scratch_overlay.queue_free()
	_game._scratch_overlay = null
	await _qa_wait(0.4)
	# sobre de figuritas con el mouse
	var pk: PackOpening = _game._open_pack_overlay(StickerLogic.gift_pack(m))
	await _qa_wait(0.8)
	st = get_viewport().get_screen_transform()
	a = st * Vector2(pk._env.position.x - 10.0, pk._env.position.y + 56.0)
	b = st * Vector2(pk._env.end.x + 10.0, pk._env.position.y + 56.0)
	print("QA_DRAG pack %d %d %d %d" % [a.x, a.y, b.x, b.y])
	t0 = Time.get_ticks_msec()
	while is_instance_valid(pk) and pk.state != PackOpening.State.DONE and Time.get_ticks_msec() - t0 < 25000:
		await _qa_wait(0.2)
	print("QA_PACK state=%d tear=%.2f" % [pk.state, pk.tear])
	# guardado: se marca la partida y se guarda; la fase 2 (tras recargar la pagina) tiene que verla
	m.clicks = 4242
	print("QA_SAVE ok=%s" % str(SaveSystem.save_game()))
	print("QA_SAVED clicks=4242 packs=%d" % m.packs_opened)
