extends Control
## Prueba de layout (headless): godot --headless res://tests/LayoutUI.tscn
##  1. Textos de tarjetas: todas las mejoras, en español e inglés, con el precio más largo y con su condición, entran en
##     la tarjeta sin cortarse (la letra se achica; el nombre puede ir en dos líneas).
##  2. La empanada no se mueve ni cambia de tamaño: en varias ventanas mide su rectángulo (relativo a su panel) con y sin
##     accesorios, con combo, con la calle llena, con el texto de la reforma largo, con avisos, con números enormes y en
##     medio del squash del clic. Tiene que ser siempre el mismo (y el mismo tamaño en todas las ventanas); el squash es
##     solo visual y vuelve a escala 1 exacta. El "+$X" de los clics nunca pisa el gorrito ni la corona.
## Termina con código 1 si algo falla (y lo lista).

const WINDOWS: Array = [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1366, 768), Vector2i(2560, 1080), Vector2i(1024, 768)]

var failures: Array = []


func _ready() -> void:
	SaveSystem.save_path = "user://test_layout_save.json"
	Settings.path = "user://test_layout_settings.cfg"
	I18n.load_all()
	Chalk.load_fonts()
	_check_cards()
	_check_empanada()


func _check_cards() -> void:
	var m: GameModel = GameModel.new(5)
	var n: int = 0
	for lang in ["es", "en"]:
		TranslationServer.set_locale(lang)
		for u in GameData.upgrades:
			for locked in [false, true]:
				var ic: UpgradeIcon = UpgradeIcon.new(u, locked)
				ic.price_text = "$888,88 Qad"
				ic.cond_text = EconomyLogic.upgrade_condition_text(m, u) if locked else ""
				add_child(ic)
				for p in ic.text_layout()["problems"]:
					failures.append("[%s] %s: %s" % [lang, str(u["id"]), p])
				ic.queue_free()
				n += 1
	TranslationServer.set_locale("es")
	var sample: UpgradeIcon = UpgradeIcon.new(GameData.upgrades[GameData.upgrade_idx["syn_1"]])
	print("tarjetas revisadas: %d (ejemplo syn_1: %s / %s)" % [n, str(sample.text_layout()["name"]), UpgradeIcon.effect(sample.upg)])
	sample.free()


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame


func _check_empanada() -> void:
	var sizes_seen: Dictionary = {}
	for ws in WINDOWS:
		var base: Vector2 = Vector2(1280.0, 720.0)
		var s: float = minf(float(ws.x) / base.x, float(ws.y) / base.y)
		var sv: SubViewport = SubViewport.new()
		sv.size = ws
		sv.size_2d_override = Vector2i(int(round(float(ws.x) / s)), int(round(float(ws.y) / s)))
		sv.size_2d_override_stretch = true
		add_child(sv)
		var main: Node = load("res://scenes/Main.tscn").instantiate()
		sv.add_child(main)
		await _frames(3)
		main.start_game(false)
		await _frames(6)
		var g: GameScreen = main._game
		var m: GameModel = GameState.m
		m.tutorial_done = true
		var tag: String = "%dx%d" % [ws.x, ws.y]
		var ref: Array = _measure(g)
		sizes_seen[tag] = ref[1]
		var cases: Array = [
			["accesorios (gorrito, anteojos, corona, dorada)", func() -> void:
				for n in GameData.tree:
					if not bool(n["final"]) and (bool(n["seal"]) or int(n["ring"]) <= 3):
						m.tree[n["id"]] = true
				m.won = true
				m.dirty = true],
			["combo al máximo", func() -> void:
				m.combo = int(m.mods["combo_cap"])
				m.combo_idle = 0.0],
			["calle llena (los 10 negocios)", func() -> void:
				for def in GameData.businesses:
					m.owned[def["id"]] = 150
				m.dirty = true],
			["texto de reforma largo y trabado", func() -> void:
				m.run_earned = BigNumber.from_string("1e40")
				m.stuck_t = 99.0],
			["avisos y números enormes", func() -> void:
				m.money = BigNumber.from_string("8.8888e305")
				for i in range(5):
					g._toast("Aviso de prueba con un texto bastante largo número %d" % i, Chalk.YELLOW)],
			["en medio del squash del clic", func() -> void:
				for i in range(4):
					Economy.click()],
		]
		for c in cases:
			(c[1] as Callable).call()
			await _frames(3)
			var got: Array = _measure(g)
			if not got[0].is_equal_approx(ref[0]) or not got[1].is_equal_approx(ref[1]):
				failures.append("[%s] LA EMPANADA SE MOVIÓ O CAMBIÓ DE TAMAÑO con %s: %s %s (antes %s %s)" % [tag, c[0], str(got[0]), str(got[1]), str(ref[0]), str(ref[1])])
			if g.empanada.scale != Vector2.ONE or g.empanada.rotation != 0.0:
				failures.append("[%s] el control de la empanada tiene escala %s / rotación %f con %s (el squash tiene que ser solo visual)" % [tag, str(g.empanada.scale), g.empanada.rotation, c[0]])
		# el "+$X" de los clics nunca pisa el gorrito ni la corona (ni al nacer ni al terminar su recorrido)
		var ko: Rect2 = g.empanada.keep_out_rect()
		var er: Rect2 = g.empanada.get_global_rect()
		for fx in [0.1, 0.3, 0.5, 0.7, 0.9]:
			for fy in [0.0, 0.1, 0.25, 0.5, 0.9]:
				var pos: Vector2 = er.position + er.size * Vector2(fx, fy)
				var path: Array = GameScreen.click_float_path(g.empanada, pos, Vector2(150, 34))
				for pt in path:
					if Rect2(pt, Vector2(150, 34)).intersects(ko):
						failures.append("[%s] el +$X de un clic en %s pisa el gorrito/corona" % [tag, str(pos)])
		# el squash termina en escala 1 exacta
		await get_tree().create_timer(1.0).timeout
		await _frames(2)
		if g.empanada.squash() != Vector2.ONE:
			failures.append("[%s] el squash no volvió a escala 1 exacta: %s" % [tag, str(g.empanada.squash())])
		print("empanada %s: %s en %s (relativo a su panel)" % [tag, str(ref[1]), str(ref[0])])
		Economy.running = false
		sv.queue_free()
		await _frames(3)
	var first: Vector2 = sizes_seen.values()[0]
	for tag in sizes_seen:
		if not (sizes_seen[tag] as Vector2).is_equal_approx(first):
			failures.append("la empanada tiene otro tamaño en %s: %s (en %s: %s)" % [tag, str(sizes_seen[tag]), str(sizes_seen.keys()[0]), str(first)])
	_finish()


## [posición relativa a su panel, tamaño]
func _measure(g: GameScreen) -> Array:
	var e: EmpanadaButton = g.empanada
	var panel: Control = e.get_parent().get_parent()
	var r: Rect2 = e.get_global_rect()
	return [r.position - panel.get_global_rect().position, r.size]


func _finish() -> void:
	SaveSystem.delete_save()
	DirAccess.remove_absolute(Settings.path)
	for f in failures:
		printerr("LAYOUT FALLA: ", f)
	print("LAYOUT %s (%d problemas)" % ["OK" if failures.is_empty() else "FALLA", failures.size()])
	get_tree().quit(1 if not failures.is_empty() else 0)
