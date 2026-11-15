extends Control
## Raíz del juego: administra las pantallas (menú, juego, opciones, créditos) y las capas del pizarrón.
## También corre el QA de los exportados (--qa-screenshot), el del build web (?qa=web) y el del jugador nuevo
## (--qa-newplayer-shots: 60 minutos de juego real a velocidad x20 con capturas para las hojas de contacto).

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
	if win != null and not (get_viewport() is SubViewport):
		_fit_initial_window(win)
	show_menu()
	var ua: PackedStringArray = OS.get_cmdline_user_args()
	if ua.has("--record-clip") and ua.find("--record-clip") + 1 < ua.size():
		call_deferred("_start_clip", ua[ua.find("--record-clip") + 1])
	if ua.has("--qa-newplayer-shots"):
		call_deferred("_qa_newplayer_shots")
	if ua.has("--qa-windows"):
		call_deferred("_qa_windows_only")
	if ua.has("--qa-screenshot"):
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
	_game = screen if screen is GameScreen else null


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
	if GameState.m.demo_finished:
		show_demo_end()
		return
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
	_set_screen(g)
	if not _pending_offline.is_empty():
		g.show_offline_report(_pending_offline)
		_pending_offline = {}


func _unhandled_input(event: InputEvent) -> void:
	if _game != null and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		Economy.click()


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


## Ventana inicial: 1600x900 o el 80 % de la pantalla (la menor, en 16:9), centrada y redimensionable.
func _fit_initial_window(win: Window) -> void:
	if OS.has_feature("web") or DisplayServer.get_name() == "headless":
		return
	var ua: PackedStringArray = OS.get_cmdline_user_args()
	for a in ["--record-clip", "--qa-screenshot", "--clip-size", "--qa-newplayer-shots"]:
		if ua.has(a):
			return
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var k: float = minf(1.0, minf(float(usable.size.x) * 0.8 / 1600.0, float(usable.size.y) * 0.8 / 900.0))
	win.min_size = Vector2i(960, 540)
	win.size = Vector2i(int(1600.0 * k), int(900.0 * k))
	win.position = usable.position + (usable.size - win.size) / 2


## Grabación de clips: godot --write-movie out.avi --fixed-fps 30 --resolution 1920x1080 -- --record-clip <nombre>
func _start_clip(clip_name: String) -> void:
	SaveSystem.save_path = "user://clip_save.json"
	SaveSystem.ignore_close = true
	get_window().always_on_top = true      # una ventana tapada por otras se queda sin dibujar y el video sale salteado
	Settings.path = "user://clip_settings.cfg"
	Settings.language = "es"
	Settings.apply()
	var ua: PackedStringArray = OS.get_cmdline_user_args()
	if ua.has("--clip-size"):
		var wh: PackedStringArray = ua[ua.find("--clip-size") + 1].split("x")
		get_window().size = Vector2i(int(wh[0]), int(wh[1]))
	start_game(false)
	var d: ClipDirector = ClipDirector.new(self, clip_name)
	add_child(d)


# =====================================================================
#  QA de los exportados: godot/exe --qa-screenshot
#  Menú, cómo se juega, juego, árbol, álbum, raspadita, logros y reforma en español e inglés (falla si algún texto visible
#  es una clave de traducción); después el layout en 4 tamaños de ventana y 10 minutos de jugador nuevo.
# =====================================================================
func _qa_wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _qa_shot(name: String, failures: Array) -> void:
	var bad: Array = QaCheck.scan(self)
	for b in bad:
		failures.append("[%s] %s" % [name, b])
	if DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
		get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("user://qa/%s.png" % name))
	print("QA captura %-22s claves sin traducir: %d" % [name, bad.size()])


## Partida "avanzada" para mostrar todo: árbol medio comprado, álbum y raspadita desbloqueados, plata y negocios.
func _qa_setup_rich() -> void:
	var m: GameModel = GameState.m
	for n in GameData.tree:
		if int(n["ring"]) <= 3 and not bool(n["final"]) and not TreeLogic.demo_locked(m, n["id"]):
			m.tree[n["id"]] = true
	m.credibility = 240
	m.reforms = maxi(m.reforms, 2)
	m.tutorial_done = true
	m.money = BigNumber.from_string("5e9")
	m.owned["empanadas"] = 30
	m.owned["kiosco"] = 18
	m.owned["choripan"] = 8
	m.owned["lavadero"] = 3
	m.run_clicks = 300
	m.dirty = true
	for id in ["biz_empanadas", "biz_kiosco", "pj_perro", "hl_2", "gold_1", "note_0"]:
		StickerLogic.give(m, id)
	m.notifications.clear()


func _qa_screens(lang: String, failures: Array, tag: String = "") -> void:
	var suffix: String = lang + tag
	_qa_setup_rich()
	await _qa_wait(0.5)
	_qa_shot("juego_" + suffix, failures)
	_game._open_tree()
	await _qa_wait(0.5)
	_qa_shot("arbol_" + suffix, failures)
	_game._open_album()
	await _qa_wait(0.5)
	_qa_shot("album_" + suffix, failures)
	_game._open_achievements()
	await _qa_wait(0.5)
	_qa_shot("logros_" + suffix, failures)
	_game._close_overlay()
	GameState.m.collapse_shown = true
	GameState.m.run_earned = BigNumber.from_string("3e9")
	_game._open_reform_dialog()
	await _qa_wait(0.5)
	_qa_shot("reforma_" + suffix, failures)
	_game._close_overlay()
	var ov: ScratchOverlay = _game._open_scratch("x10")
	await _qa_wait(0.5)
	if ov != null:
		ov.auto_scratch(0.3)
		await _qa_wait(0.8)
	_qa_shot("raspadita_" + suffix, failures)
	if _game._scratch_overlay != null and is_instance_valid(_game._scratch_overlay):
		_game._scratch_overlay.queue_free()
		_game._scratch_overlay = null


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
		start_game(false)
		await _qa_wait(1.0)
		_qa_shot("inicio_" + lang, failures)
		await _qa_screens(lang, failures)
	await _qa_windows(failures)
	get_window().size = Vector2i(1280, 720)
	await _qa_newplayer(failures, 600.0, false)      # 10 minutos de jugador nuevo con la interfaz real
	var f: FileAccess = FileAccess.open("user://qa/result.txt", FileAccess.WRITE)
	f.store_string("%s\n%s\n" % ["FAIL" if not failures.is_empty() else "PASS", "\n".join(failures)])
	f.close()
	SaveSystem.delete_save()
	DirAccess.remove_absolute(Settings.path)
	if failures.is_empty():
		print("QA OK")
	else:
		printerr("QA FALLA: %d problemas:\n%s" % [failures.size(), "\n".join(failures)])
	get_tree().quit(1 if not failures.is_empty() else 0)


# =====================================================================
#  QA del build web: http://.../index.html?qa=web  (fase 1) y ?qa=web&phase=2 (después de recargar).
#  tools/web_qa.ps1 lo maneja con Chrome headless: mira las líneas "QA_*" de la consola y hace los arrastres del mouse.
# =====================================================================
func _qa_web(phase: int) -> void:
	SaveSystem.save_path = "user://qa_web_save.json"
	Settings.path = "user://qa_web_settings.cfg"
	if phase == 2:
		await _qa_wait(1.0)
		var ok: bool = SaveSystem.load_game()
		print("QA_PERSIST loaded=%s clicks=%d packs=%d" % [ok, GameState.m.clicks, GameState.m.packs_opened])
		return
	var failures: Array = []
	for lang in ["es", "en"]:
		Settings.language = lang
		Settings.apply()
		show_menu()
		await _qa_wait(0.8)
		_qa_shot("menu_" + lang, failures)
		start_game(false)
		await _qa_wait(1.0)
		_qa_shot("inicio_" + lang, failures)
		_qa_setup_rich()
		_game._open_tree()
		await _qa_wait(0.6)
		_qa_shot("arbol_" + lang, failures)
		_game._open_album()
		await _qa_wait(0.6)
		_qa_shot("album_" + lang, failures)
		_game._close_overlay()
	print("QA_I18N bad=%d %s" % [failures.size(), " | ".join(failures)])
	Settings.language = "es"
	Settings.apply()
	start_game(false)
	await _qa_wait(1.0)
	_qa_setup_rich()
	var m: GameModel = GameState.m
	Input.use_accumulated_input = false      # Chrome headless corre a pocos cuadros por segundo: sin esto se pierden los movimientos del mouse
	var ov: ScratchOverlay = _game._open_scratch()
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
	m.clicks = 4242
	print("QA_SAVE ok=%s" % str(SaveSystem.save_game()))
	print("QA_SAVED clicks=4242 packs=%d" % m.packs_opened)


# =====================================================================
#  QA de la ventana real: menú, juego, árbol, álbum y logros en 1280x720, 1366x768, 1600x900 y 1920x1080.
#  Falla si algún botón o texto queda fuera de la ventana o se pisa con otro.
# =====================================================================
const QA_WINDOW_SIZES: Array = [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080)]


func _qa_win_check(name: String, failures: Array) -> void:
	var bad: Array = QaCheck.layout(self, get_viewport().get_visible_rect())
	bad.append_array(QaCheck.card_texts(self))
	for b in bad:
		failures.append("[%s] %s" % [name, b])
	if DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
		get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("user://qa/win_%s.png" % name))
	print("QA ventana %-28s problemas de layout: %d" % [name, bad.size()])


func _qa_windows(failures: Array) -> void:
	var win: Window = get_window()
	win.borderless = true
	Settings.language = "es"
	Settings.apply()
	for s in QA_WINDOW_SIZES:
		win.size = s
		await _qa_wait(0.6)
		var tag: String = "%dx%d" % [s.x, s.y]
		show_menu()
		await _qa_wait(0.8)
		_qa_win_check("%s_menu" % tag, failures)
		start_game(false)
		GameState.m.tutorial_done = true
		await _qa_wait(1.0)
		_qa_win_check("%s_juego_inicio" % tag, failures)
		_qa_setup_rich()
		await _qa_wait(0.6)
		_qa_win_check("%s_juego" % tag, failures)
		_game._open_tree()
		await _qa_wait(0.5)
		_qa_win_check("%s_arbol" % tag, failures)
		_game._open_album()
		await _qa_wait(0.5)
		_qa_win_check("%s_album" % tag, failures)
		_game._open_achievements()
		await _qa_wait(0.5)
		_qa_win_check("%s_logros" % tag, failures)
		_game._close_overlay()


## Solo la parte de ventana real del QA (más rápido para iterar): godot -- --qa-windows
func _qa_windows_only() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://qa"))
	SaveSystem.save_path = "user://qa_save.json"
	Settings.path = "user://qa_settings.cfg"
	var failures: Array = []
	await _qa_windows(failures)
	var out: FileAccess = FileAccess.open("user://qa/result_windows.txt", FileAccess.WRITE)
	out.store_string("%s\n%s\n" % ["FAIL" if not failures.is_empty() else "PASS", "\n".join(failures)])
	out.close()
	SaveSystem.delete_save()
	for f in failures:
		printerr("QA ventanas FALLA: ", f)
	print("QA ventanas: %d problemas" % failures.size())
	get_tree().quit(1 if not failures.is_empty() else 0)


# =====================================================================
#  QA de jugador nuevo con la interfaz real: godot -- --qa-newplayer-shots [--np-seconds 3600] [--np-profile pasivo]
#  BotPolicy (el mismo jugador de prueba del simulador) juega a velocidad x20 tocando la empanada y los billetes de verdad.
#  Capturas: cada 30 s hasta el minuto 10 y cada 2,5 min hasta el 60 (user://qa/newplayer/t_SSSS.png);
#  tools/qa_newplayer.ps1 arma las hojas de contacto docs/qa/v2_0_a_10_min_<perfil>.jpg y v2_10_a_60_min_<perfil>.jpg.
#  Falla si aparece un texto sin traducir, si la pantalla se sale de la ventana, si pasan más de 20 s sin poder comprar
#  ni reformar, si una reforma da menos de 5, si la vuelta 2 es más lenta que la 1 o (activo) si la primera reforma no
#  llega entre los minutos 4 y 6.
# =====================================================================
const NP_SPEED: float = 20.0


func _qa_newplayer_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://qa/newplayer"))
	SaveSystem.save_path = "user://qa_np_save.json"
	Settings.path = "user://qa_np_settings.cfg"
	get_window().borderless = true
	get_window().size = Vector2i(1280, 720)      # ventana sin bordes: si no, Windows puede dejar de dibujarla y las capturas salen viejas
	get_window().always_on_top = true
	var secs: float = 3600.0
	var profile: String = "activo"
	var ua: PackedStringArray = OS.get_cmdline_user_args()
	if ua.has("--np-seconds") and ua.find("--np-seconds") + 1 < ua.size():
		secs = float(ua[ua.find("--np-seconds") + 1])
	if ua.has("--np-profile") and ua.find("--np-profile") + 1 < ua.size():
		profile = ua[ua.find("--np-profile") + 1]
	var failures: Array = []
	await _qa_newplayer(failures, secs, true, profile)
	var out: FileAccess = FileAccess.open("user://qa/newplayer/result.txt", FileAccess.WRITE)
	out.store_string("%s\n%s\n" % ["FAIL" if not failures.is_empty() else "PASS", "\n".join(failures)])
	out.close()
	SaveSystem.delete_save()
	for f in failures:
		printerr("QA newplayer FALLA: ", f)
	print("QA newplayer: %s" % ("FALLA (%d problemas)" % failures.size() if not failures.is_empty() else "OK"))
	get_tree().quit(1 if not failures.is_empty() else 0)


func _fmt_t(gt: float) -> String:
	return "%d:%02d" % [int(gt) / 60, int(gt) % 60]


func _qa_newplayer(failures: Array, seconds: float, shots: bool, profile: String = "activo") -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://qa/newplayer"))
	var save_before: String = SaveSystem.save_path
	var settings_before: String = Settings.path
	SaveSystem.save_path = "user://qa_np_save.json"
	Settings.path = "user://qa_np_settings.cfg"
	Settings.language = "es"
	Settings.apply()
	start_game(false)
	await _qa_wait(0.5)
	var bot: BotPolicy = BotPolicy.new(3, profile)
	bot.on_click = func() -> void: Economy.click()
	bot.on_bill = func(id: int) -> void:
		var o: Variant = _game._bills.get(id, null)
		if o != null and is_instance_valid(o):
			var fb: FlyingBill = o as FlyingBill
			fb.caught.emit(id)
			fb.vanish(true)
		else:
			Economy.click_bill(id)
	bot.on_reform = func() -> Dictionary:
		_game._close_overlay()
		return Economy.reform()
	Engine.time_scale = NP_SPEED
	var log: Array = ["t_seg,vuelta,reformas,plata,ingreso_s,credibilidad,nodos,inflacion_mensual,comprable"]
	var next_shot: float = 0.0
	var next_check: float = 0.0
	var last_afford: float = 0.0
	var max_gap: float = 0.0
	var gap_at: float = 0.0
	var first_reform: float = -1.0
	var min_cred: int = 1 << 30
	var last_upg: float = 0.0
	var max_upg_gap: float = 0.0
	var run_start: float = 0.0
	var run1_time: float = -1.0
	var run1_money: BigNumber = null
	var run2_reach: float = -1.0
	var gt: float = 0.0
	var reported: Dictionary = {}
	var overlay_until: float = 0.0
	var last_us: int = Time.get_ticks_usec()
	while gt <= seconds + 0.01:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MINIMIZED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_move_to_foreground()
		await get_tree().process_frame
		var now_us: int = Time.get_ticks_usec()
		var dt: float = minf(float(now_us - last_us) / 1e6, 0.1) * NP_SPEED
		last_us = now_us
		gt += dt
		var m: GameModel = GameState.m
		if _game == null or not is_instance_valid(_game):
			# ganó: aparecen los créditos; un jugador toca "seguir jugando"
			await _qa_wait(0.3)
			if _game == null:
				start_game(true, true)
			continue
		# cerrar capas que tapan el juego (resumen de la reforma, sobres): un jugador las cierra enseguida
		if _game._busy_overlay != null and is_instance_valid(_game._busy_overlay) and _game._busy_overlay.get_child_count() > 3:
			_game._busy_overlay.queue_free()
			_game._busy_overlay = null
		if _game._overlay != null and gt >= overlay_until:
			_game._close_overlay()
		var earned_before: BigNumber = m.run_earned
		# ¿se puede hacer algo? (comprar o reformar) — se mira antes de que el bot compre
		if gt <= 3600.0 and (EconomyLogic.anything_affordable(m) or EconomyLogic.can_reform(m)):
			if gt - last_afford > max_gap:
				max_gap = gt - last_afford
				gap_at = gt
			last_afford = gt
		if gt <= 3600.0 and EconomyLogic.any_upgrade_affordable(m, 20.0):
			max_upg_gap = maxf(max_upg_gap, gt - last_upg)
			last_upg = gt
		var upg_before: int = m.upgrades.size()
		var bought_before: int = m.total_businesses() + m.upgrades.size() + TreeLogic.count(m)
		var s: Dictionary = bot.step(m, dt)
		if m.total_businesses() + m.upgrades.size() + TreeLogic.count(m) > bought_before:
			last_afford = gt
		if m.upgrades.size() > upg_before and s.is_empty():
			last_upg = gt
		Economy.flush()
		if not s.is_empty():
			min_cred = mini(min_cred, int(s["cred"]))
			if first_reform < 0.0:
				first_reform = gt
				run1_time = gt
				run1_money = earned_before
			run_start = gt
			# después de cada reforma se mira el árbol unos segundos (como haría un jugador)
			_game._open_tree()
			overlay_until = gt + 6.0
		if run1_money != null and run2_reach < 0.0 and m.run_index == 2 and m.run_earned.ge(run1_money):
			run2_reach = gt - run_start
		if gt >= next_check:
			next_check = gt + 1.0
			for b in QaCheck.scan(self):
				if not reported.has(b):
					reported[b] = true
					failures.append("[%s] TEXTO SIN TRADUCIR: %s" % [_fmt_t(gt), b])
			_qa_structure_check(gt, reported, failures)
		if gt >= next_shot:
			var tag: String = "%04d" % int(round(next_shot))
			if shots:
				await get_tree().process_frame
				RenderingServer.force_draw()
				get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("user://qa/newplayer/t_%s.png" % tag))
			log.append("%s,%d,%d,\"%s\",\"%s\",%d,%d,%.1f,%s" % [tag, m.run_index, m.reforms, UIKit.money(m.money), EconomyLogic.income_per_sec(m).format(),
				m.credibility, TreeLogic.count(m), EconomyLogic.monthly_pct(m), str(EconomyLogic.anything_affordable(m))])
			next_shot += 30.0 if next_shot < 600.0 else 150.0
	Engine.time_scale = 1.0
	if profile == "activo" and (first_reform < 240.0 or first_reform > 360.0):
		failures.append("LA PRIMERA REFORMA LLEGÓ A LOS %s (tiene que ser entre los minutos 4 y 6)" % _fmt_t(first_reform))
	if first_reform < 0.0:
		failures.append("NO HUBO NINGUNA REFORMA EN %s" % _fmt_t(gt))
	if max_gap > 20.0:
		failures.append("PASARON %.0f s SIN PODER COMPRAR NI REFORMAR (hasta el %s; máximo 20 s)" % [max_gap, _fmt_t(gap_at)])
	if max_upg_gap > 20.0:
		failures.append("PASARON %.0f s SIN NINGUNA MEJORA A TIRO (comprable ya o juntando 20 s; máximo 20 s en la primera hora)" % max_upg_gap)
	if min_cred < 5 and first_reform >= 0.0:
		failures.append("UNA REFORMA DIO %d DE CREDIBILIDAD (mínimo 5)" % min_cred)
	if run1_time > 0.0 and run2_reach > 0.0 and run2_reach >= run1_time:
		failures.append("LA VUELTA 2 FUE MÁS LENTA QUE LA 1 (%s contra %s)" % [_fmt_t(run2_reach), _fmt_t(run1_time)])
	print("QA jugador nuevo (%s): primera reforma %s, vuelta 2 llega a la plata de la 1 en %s, máxima espera sin poder comprar ni reformar %.1f s (hasta el %s), %d reformas en %s" % [profile, _fmt_t(first_reform), _fmt_t(run2_reach), max_gap, _fmt_t(gap_at), GameState.m.reforms, _fmt_t(gt)])
	var f: FileAccess = FileAccess.open("user://qa/newplayer/log.csv", FileAccess.WRITE)
	f.store_string("\n".join(log) + "\n")
	f.close()
	SaveSystem.delete_save()
	SaveSystem.save_path = save_before
	Settings.path = settings_before


## La pantalla de juego tiene que entrar entera en la ventana. Se avisa una sola vez por problema.
func _qa_structure_check(gt: float, state: Dictionary, failures: Array) -> void:
	if _game == null or not is_instance_valid(_game):
		return
	var vr: Rect2 = get_viewport().get_visible_rect()
	var parts: Dictionary = {"columna izquierda": _game.left_col, "cuerpo": _game.body, "titulares": _game.ticker_clip}
	for k in parts:
		var c: Control = parts[k]
		if c == null or not c.is_visible_in_tree():
			continue
		var r: Rect2 = c.get_global_rect()
		if r.end.y > vr.end.y + 1.5 or r.end.x > vr.end.x + 1.5 or r.position.y < -1.5:
			var key: String = "estructura_" + k
			if not state.has(key):
				state[key] = true
				failures.append("[%s] LA PANTALLA SE SALE DE LA VENTANA: %s %s (ventana %s)" % [_fmt_t(gt), k, QaCheck._fmt(r), QaCheck._fmt(vr)])
