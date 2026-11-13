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
	if win != null and not (get_viewport() is SubViewport):
		_fit_initial_window(win)
	if win != null and win.size.y > win.size.x and not (get_viewport() is SubViewport):
		win.content_scale_size = Vector2i(1080, 1920)     # pantalla vertical (con escala 1,5: layout de 720x1280)
	show_menu()
	var ua: PackedStringArray = OS.get_cmdline_user_args()
	if ua.has("--record-clip") and ua.find("--record-clip") + 1 < ua.size():
		call_deferred("_start_clip", ua[ua.find("--record-clip") + 1])
	if OS.get_cmdline_user_args().has("--qa-newplayer-shots"):
		call_deferred("_qa_newplayer_shots")
	if OS.get_cmdline_user_args().has("--qa-windows"):
		call_deferred("_qa_windows_only")
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
		Unlocks.unlock_all(m)
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
	await _qa_windows(failures)
	get_window().size = Vector2i(1280, 720)
	await _qa_newplayer(failures)      # 5 minutos de jugador nuevo: sin carteles/notas/flechas encimados ni órdenes repetidas
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
	get_window().always_on_top = true      # una ventana tapada por otras se queda sin dibujar y el video sale salteado
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
		Unlocks.unlock_all(m)
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
	Unlocks.unlock_all(m)
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


## Ventana inicial: 1600x900 o el 80 % de la pantalla (la menor, en 16:9), centrada y redimensionable.
func _fit_initial_window(win: Window) -> void:
	if OS.has_feature("web") or DisplayServer.get_name() == "headless":
		return
	var ua: PackedStringArray = OS.get_cmdline_user_args()
	for a in ["--record-clip", "--qa-screenshot", "--clip-size"]:
		if ua.has(a):
			return
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var k: float = minf(1.0, minf(float(usable.size.x) * 0.8 / 1600.0, float(usable.size.y) * 0.8 / 900.0))
	win.min_size = Vector2i(960, 540)
	win.size = Vector2i(int(1600.0 * k), int(900.0 * k))
	win.position = usable.position + (usable.size - win.size) / 2


## QA de la ventana real: menú, juego y todas las pestañas en 1280x720, 1366x768, 1600x900 y 1920x1080.
## Falla si algún botón o texto queda fuera de la ventana o se pisa con otro. Capturas win_<tamaño>_<pantalla>.png en user://qa/.
const QA_WINDOW_SIZES: Array = [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080)]
const QA_TABS: Array = ["negocios", "mejoras", "refugios", "reforma", "album", "timba", "logros"]


func _qa_win_check(name: String, failures: Array) -> void:
	var bad: Array = QaCheck.layout(self, get_viewport().get_visible_rect())
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
		Settings.tutorial_done = true
		start_game(false)
		await _qa_wait(1.0)
		_qa_win_check("%s_juego_era1" % tag, failures)
		var m: GameModel = GameState.m
		m.era = 3
		Unlocks.unlock_all(m)
		m.money = BigNumber.from_string("5e12")
		m.base_income = BigNumber.from_float(1e8)
		m.owned["kiosco"] = 4
		m.owned["empanadas"] = 10
		m.dirty = true
		for id in ["biz_empanadas", "biz_kiosco", "pj_perro", "hl_2", "gold_1", "note_0"]:
			StickerLogic.give(m, id)
		m.notifications.clear()
		await _qa_wait(0.5)
		for i in range(QA_TABS.size()):
			_game._select_tab(i)
			await _qa_wait(0.5)
			_qa_win_check("%s_%s" % [tag, QA_TABS[i]], failures)


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
	print("QA ventanas: %d problemas" % failures.size())
	get_tree().quit(1 if not failures.is_empty() else 0)


# =====================================================================
#  QA de la primera partida de un jugador nuevo: godot -- --qa-newplayer-shots
#  Un "jugador que hace lo que le marca la pantalla" (sigue la acción destacada) juega 5 minutos a velocidad x10 y se saca
#  una captura cada 15 s de juego en user://qa/newplayer/. tools/qa_newplayer.ps1 las junta en docs/qa/primeros_5_min.jpg.
# =====================================================================
const NP_SECONDS: float = 900.0      # 15 minutos de juego (a velocidad x10 son unos 90 s reales)
const NP_SHOT_EVERY: float = 15.0
const NP_SPEED: float = 10.0


func _qa_newplayer_shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://qa/newplayer"))
	SaveSystem.save_path = "user://qa_np_save.json"
	Settings.path = "user://qa_np_settings.cfg"
	get_window().borderless = true
	get_window().size = Vector2i(1280, 720)      # ventana sin bordes: si no, Windows puede dejar de dibujarla y las capturas salen viejas
	get_window().always_on_top = true             # y siempre arriba: una ventana tapada por otras se queda sin dibujar y el QA se frena
	var failures: Array = []
	await _qa_newplayer(failures)
	var out: FileAccess = FileAccess.open("user://qa/newplayer/result.txt", FileAccess.WRITE)
	out.store_string("%s\n%s\n" % ["FAIL" if not failures.is_empty() else "PASS", "\n".join(failures)])
	out.close()
	SaveSystem.delete_save()
	for f in failures:
		printerr("QA newplayer FALLA: ", f)
	print("QA newplayer: %s" % ("FALLA (%d problemas)" % failures.size() if not failures.is_empty() else "OK"))
	get_tree().quit(1 if not failures.is_empty() else 0)


## Un solo cartel, nota o flecha de acción a la vez; y ninguna orden del tutorial queda más de 30 s con el mismo texto.
## `tr_state` guarda el texto visible de la nota del tutorial y desde cuándo (segundos de juego).
func _qa_attention_check(gt: float, tr_state: Dictionary, failures: Array) -> void:
	var seen: Array = []
	for n in get_tree().get_nodes_in_group("attention"):
		var ci: CanvasItem = n as CanvasItem
		if ci == null or not ci.is_visible_in_tree():
			continue
		var a: float = 1.0
		var p: Node = n
		while p != null:
			if p is CanvasItem:
				a *= (p as CanvasItem).modulate.a
			p = p.get_parent()
		if a < 0.3:
			continue
		seen.append(n)
	if seen.size() > 1:
		var names: Array = []
		var rects: Array = []
		for n in seen:
			names.append("%s (%s)" % [n.get_class(), n.get_path()])
		var msg: String = "[%s] DOS CARTELES/NOTAS/FLECHAS A LA VEZ: %s" % [_fmt_t(gt), " + ".join(names)]
		if not tr_state.get("reported_multi", {}).has(msg.substr(10)):
			failures.append(msg)
			tr_state["reported_multi"][msg.substr(10)] = true
	# nota del tutorial: mismo texto > 30 s
	var text: String = ""
	if _game != null and _game._guide != null and is_instance_valid(_game._guide) and _game._guide._note.visible:
		text = _game._guide.shown_text
	if text != "" and text == str(tr_state.get("text", "")):
		if gt - float(tr_state["since"]) > 30.0 and not tr_state.get("reported_text", {}).has(text):
			failures.append("[%s] LA MISMA ORDEN DEL TUTORIAL DURANTE MÁS DE 30 s: «%s»" % [_fmt_t(gt), text])
			tr_state["reported_text"][text] = true
	else:
		tr_state["text"] = text
		tr_state["since"] = gt


func _fmt_t(gt: float) -> String:
	return "%d:%02d" % [int(gt) / 60, int(gt) % 60]


func _qa_newplayer(failures: Array) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://qa/newplayer"))
	var save_before: String = SaveSystem.save_path
	var settings_before: String = Settings.path
	SaveSystem.save_path = "user://qa_np_save.json"
	Settings.path = "user://qa_np_settings.cfg"
	Settings.language = "es"
	Settings.tutorial_done = false
	Settings.apply()
	start_game(false)
	await _qa_wait(0.5)
	Engine.time_scale = NP_SPEED       # se acelera TODO (también los cartelitos y los tweens): la hoja de contacto muestra tiempos reales
	var gt: float = 0.0
	var next_shot: float = 0.0
	var next_act: float = 0.0
	var next_check: float = 0.0
	var seen: Array = [0]
	var last_us: int = Time.get_ticks_usec()
	var log: Array = ["t_seg,plata,tipo_destacado,id,objetivo,tutorial,pestana,cartel_desbloqueo,notas_visibles,time_played"]
	var tr_state: Dictionary = {"reported_multi": {}, "reported_text": {}, "text": "", "since": 0.0}
	var last_sign: Node = null
	var buys_2min: int = 0
	var bought_prev: int = 0
	var first_cart: float = -1.0
	var first_kiosk: float = -1.0
	var obj_id: String = ""
	var obj_since: float = 0.0
	var rec_key: String = ""
	var rec_since: float = 0.0
	var red_since: float = -1.0
	var red_episodes: Array = []
	var sign_shot_at: float = -1.0
	var np_seconds: float = NP_SECONDS
	var ua: PackedStringArray = OS.get_cmdline_user_args()
	if ua.has("--np-seconds") and ua.find("--np-seconds") + 1 < ua.size():
		np_seconds = float(ua[ua.find("--np-seconds") + 1])
	while gt <= np_seconds + 0.01:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MINIMIZED:      # algo del sistema minimiza la ventana y Godot deja de dibujar
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_move_to_foreground()
		await get_tree().process_frame
		var now_us: int = Time.get_ticks_usec()
		gt += minf(float(now_us - last_us) / 1e6, 0.2) * NP_SPEED
		last_us = now_us
		var m: GameModel = GameState.m
		# captura extra cuando aparece un cartel de desbloqueo (para verlo en la hoja de contacto)
		var sign_now: Node = _game._unlock_sign if (_game._unlock_sign != null and is_instance_valid(_game._unlock_sign)) else null
		if sign_now != null and sign_now != last_sign:
			last_sign = sign_now
			sign_shot_at = gt + 1.0
		if sign_shot_at > 0.0 and gt >= sign_shot_at:
			sign_shot_at = -1.0
			await get_tree().process_frame
			RenderingServer.force_draw()
			get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("user://qa/newplayer/t_%03d_cartel.png" % int(round(gt))))
		# métricas del ritmo: compras (negocios + mejoras), primer carrito y kiosco, duración de cada objetivo
		var bought_now: int = m.total_businesses() + m.upgrades.size()
		if bought_now > bought_prev:
			if gt < 120.0:
				buys_2min += bought_now - bought_prev
			bought_prev = bought_now
		if first_cart < 0.0 and m.owned_count("empanadas") >= 1:
			first_cart = gt
		if first_kiosk < 0.0 and m.owned_count("kiosco") >= 1:
			first_kiosk = gt
		var oid: String = str(ObjectiveLogic.current(m)["id"])
		if oid != obj_id:
			obj_id = oid
			obj_since = gt
		elif gt - obj_since > 90.0 and gt < 900.0 and not tr_state.has("obj_" + oid):
			tr_state["obj_" + oid] = true
			failures.append("[%s] EL OBJETIVO «%s» LLEVA MÁS DE 90 s EN LOS PRIMEROS 15 MINUTOS" % [_fmt_t(gt), oid])
		# semáforo en rojo: tramos de 3 s o más (los "momentos de tensión" entre los minutos 5 y 15)
		var is_red: bool = Unlocks.has(m, "inflation") and not bool(EconomyLogic.race(m)["winning"])
		if is_red and red_since < 0.0:
			red_since = gt
		elif not is_red and red_since >= 0.0:
			if gt - red_since >= 2.5:
				red_episodes.append(red_since)
			red_since = -1.0
		if gt >= next_check:
			next_check = gt + 0.5
			_qa_attention_check(gt, tr_state, failures)
			_qa_structure_check(gt, tr_state, failures)
		if gt >= next_act:
			next_act = gt + 0.4
			var rec: Dictionary = Advisor.recommend(m, seen)
			var rk: String = "%s:%s" % [rec["kind"], rec["id"]]
			if rk != rec_key:
				rec_key = rk
				rec_since = gt
			match str(rec["kind"]) if gt - rec_since >= 3.0 else "":      # un jugador tarda ~3 s en leer la flecha y tocar
				"buy":
					_game._select_tab(0)
					Economy.buy_business(str(rec["id"]), 1)
				"upgrade":
					_game._select_tab(1)
					Economy.buy_upgrade(str(rec["id"]))
				"remark":
					Economy.remark()
				"tab":
					seen.append(int(rec["id"]))
					_game._select_tab(int(rec["id"]))
				"decision":
					Economy.choose_event(0)
				"objective":
					Economy.click()           # juntando plata para el objetivo: de a un clic cada tanto
				_:
					for i in range(1):
						Economy.click()           # sin nada destacado, un jugador nuevo toca la empanada
		if gt >= next_shot:
			await get_tree().process_frame
			RenderingServer.force_draw()      # dibuja un cuadro ya mismo (esperar frame_post_draw se traba hasta 30 s y sin esto la captura sale vieja)
			var tag: String = "%03d" % int(round(next_shot))

			get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("user://qa/newplayer/t_%s.png" % tag))
			var rec2: Dictionary = Advisor.recommend(m, seen)
			var visible_notes: int = 0
			for n in get_tree().get_nodes_in_group("attention"):
				if (n as CanvasItem).is_visible_in_tree():
					visible_notes += 1
			log.append("%s,\"%s\",%s,%s,%s,%d,%d,%s,%d,%d" % [tag, UIKit.money(m.money), str(rec2["kind"]), str(rec2["id"]), str(ObjectiveLogic.current(m)["id"]), EconomyLogic.tutorial_step(m), _game._tab, str(is_instance_valid(_game._unlock_sign)), visible_notes, int(m.time_played)])
			next_shot += NP_SHOT_EVERY if next_shot < 300.0 else 2.0 * NP_SHOT_EVERY      # cada 15 s los primeros 5 minutos y cada 30 s después
	Engine.time_scale = 1.0
	var tension_n: int = 0
	for e in red_episodes:
		if float(e) >= 300.0:
			tension_n += 1
	if tension_n < 2:
		failures.append("SOLO %d MOMENTOS DE TENSIÓN (semáforo en rojo) ENTRE LOS MINUTOS 5 Y 15 (mínimo 2)" % tension_n)
	print("QA tensión: %d momentos con el semáforo en rojo entre los minutos 5 y 15" % tension_n)
	if buys_2min < 6:
		failures.append("SOLO %d COMPRAS EN LOS PRIMEROS 2 MINUTOS (mínimo 6)" % buys_2min)
	if first_cart < 0.0 or first_cart > 15.0:
		failures.append("EL PRIMER CARRITO LLEGÓ A LOS %.0f s (tiene que ser alrededor de los 5-10 s)" % first_cart)
	if first_kiosk < 0.0 or first_kiosk > 90.0:
		failures.append("EL KIOSCO LLEGÓ A LOS %.0f s (tiene que ser antes de los 90 s)" % first_kiosk)
	print("QA ritmo: %d compras en 2 min, primer carrito %.0f s, primer kiosco %.0f s" % [buys_2min, first_cart, first_kiosk])
	var f: FileAccess = FileAccess.open("user://qa/newplayer/log.csv", FileAccess.WRITE)
	f.store_string("\n".join(log) + "\n")
	f.close()
	SaveSystem.delete_save()
	SaveSystem.save_path = save_before
	Settings.path = settings_before


## La pantalla de juego tiene que entrar entera en la ventana (la cinta de titulares y la columna izquierda no se pueden
## salir por abajo aunque el contenido crezca). Se avisa una sola vez por problema.
func _qa_structure_check(gt: float, state: Dictionary, failures: Array) -> void:
	if _game == null or not is_instance_valid(_game):
		return
	var vr: Rect2 = get_viewport().get_visible_rect()
	var parts: Dictionary = {"cinta de titulares": _game.ticker_clip, "columna izquierda": _game.left_col, "cuerpo": _game.body}
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
