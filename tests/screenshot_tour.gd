extends Control
## Recorrido automático de capturas para revisar el layout a distintas resoluciones (diseño v2).
## Uso (ventana real, no headless):
##   SHOT_DIR=docs/screenshots godot --rendering-driver opengl3 --resolution 1920x1080 res://tests/ScreenshotTour.tscn
## Guarda <ancho>x<alto>_<nombre>.jpg en SHOT_DIR. Usa rutas de guardado aparte (no toca la partida real).

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
	process_mode = Node.PROCESS_MODE_ALWAYS          # el recorrido sigue aunque el juego esté en pausa
	main.process_mode = Node.PROCESS_MODE_PAUSABLE
	shot_vp = get_viewport()
	var sz: Vector2i = get_window().size
	var res: String = OS.get_environment("TOUR_RES")
	if res != "":
		# Render offscreen a tamaño exacto, emulando el escalado del proyecto (canvas_items + expand).
		sz = Vector2i(res.get_slice("x", 0).to_int(), res.get_slice("x", 1).to_int())
		var base: Vector2 = Vector2(720.0, 1280.0) if sz.y > sz.x else Vector2(1280.0, 720.0)
		var s: float = minf(float(sz.x) / base.x, float(sz.y) / base.y)
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
		["01_juego_vuelta1", _early],
		["01b_primera_reforma", _first_reform],
		["01c_arbol_recomendado", _first_tree],
		["02_juego_avanzado", _mid],
		["02b_billete_volador", _bill, 30],
		["02c_noticia", _decision],
		["03_arbol", _tree],
		["04_arbol_zoom", _tree_zoom],
		["05_reforma", _reform_dialog],
		["06_album", _album],
		["06b_sobre_rasgando", _pack, 20],
		["06c_sobre_figuritas", _noop, 150],
		["06f_raspadita_rascando", _scratch, 45],
		["06g_raspadita_premio", _noop, 150],
		["07_logros", _ach],
		["08_hiperinflacion", _hyper],
		["09_reforma_tijera", _reform_anim, 40],
		["09b_resumen_vuelta", _noop, 60],
		["10_opciones", _options],
		["11_creditos", _credits],
		["12_demo_fin", _demo_end],
		["13_comprable_juego", _mix, 30],
		["14_comprable_arbol", _mix_tree, 20],
		["15_pausa", _pause, 20],
	]
	var only: String = OS.get_environment("TOUR_ONLY")
	if only != "":
		var keep: Array = []
		for st in steps:
			if str(st[0]).begins_with("00_") or only.split(",").has(str(st[0]).get_slice("_", 0)):
				keep.append(st)
		steps = keep


var _next_at: int = STEP
var _idx: int = 0


## Cada paso: [nombre_de_la_captura, acción, frames_de_espera_extra_antes_de_la_captura (opcional)].
func _process(_delta: float) -> void:
	frame += 1
	if OS.get_environment("SHOT_CLEAN") != "" and _idx > 1:
		_strip()
	if frame < _next_at:
		return
	if _idx > 0 and _idx - 1 < steps.size():
		_shot(steps[_idx - 1][0])
	if _idx < steps.size():
		steps[_idx][1].call()
		var extra: int = int(steps[_idx][2]) if steps[_idx].size() > 2 else 0
		_next_at = frame + STEP + extra
		_idx += 1
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
	if OS.get_environment("SHOT_PNG") != "":
		shot_vp.get_texture().get_image().save_png("%s/%s_%s.png" % [dir, tag, name])
	else:
		shot_vp.get_texture().get_image().save_jpg("%s/%s_%s.jpg" % [dir, tag, name], 0.9)


func _g() -> GameScreen:
	return main._game


func _menu() -> void:
	pass


func _tut() -> void:
	if OS.get_environment("TOUR_QUALITY") != "":
		Settings.quality = OS.get_environment("TOUR_QUALITY").to_int()
	Settings.language = "es"
	Settings.apply()
	main.start_game(false)


func _early() -> void:
	var m: GameModel = GameState.m
	m.clicks = 40
	m.money = BigNumber.from_float(220.0)
	m.run_earned = BigNumber.from_float(1450.0)
	m.owned["empanadas"] = 6
	m.owned["kiosco"] = 1
	m.run_time = 70.0
	m.ln_p = 0.25
	m.tutorial_done = true
	m.dirty = true


## La primera vez que se abre la reforma: la explicación en tiza.
func _first_reform() -> void:
	var m: GameModel = GameState.m
	m.run_earned = BigNumber.from_float(7.5e4)
	m.money = BigNumber.from_float(3200.0)
	m.owned = {"empanadas": 22, "kiosco": 12, "choripan": 6, "lavadero": 2}
	m.run_time = 255.0
	m.dirty = true
	_g()._open_reform_dialog()


## Después de la primera reforma: el árbol con la flecha al nodo recomendado.
func _first_tree() -> void:
	var m: GameModel = GameState.m
	m.reforms = 1
	m.run_index = 2
	m.credibility = 8
	m.best_run = BigNumber.from_float(7.5e4)
	m.run_earned = BigNumber.zero()
	m.owned = {}
	m.dirty = true
	_g()._open_tree()


func _mid() -> void:
	var m: GameModel = GameState.m
	_g()._close_overlay()
	for n in GameData.tree:
		if int(n["ring"]) <= 3 and not bool(n["final"]):
			m.tree[n["id"]] = true
	m.reforms = 6
	m.run_index = 7
	m.credibility = 85
	m.money = BigNumber.from_string("4.2e9")
	m.run_earned = BigNumber.from_string("9e9")
	m.owned = {"empanadas": 45, "kiosco": 32, "choripan": 25, "lavadero": 18, "panaderia": 11, "almacen": 4}
	m.run_clicks = 900
	m.run_time = 150.0
	m.ln_p = 1.2
	m.combo = 14
	m.combo_idle = 0.0
	m.dirty = true


func _bill() -> void:
	GameState.m.bill_timer = 0.0


func _decision() -> void:
	EconomyLogic.start_event(GameState.m, "aguinaldo")
	Economy.flush()


func _tree() -> void:
	GameState.m.pending_choice = {}
	_g()._open_tree()


func _tree_zoom() -> void:
	_g()._tree_view.zoom = 1.0
	_g()._tree_view.focus("neg_3")


func _reform_dialog() -> void:
	GameState.m.collapse_shown = true
	_g()._open_reform_dialog()


func _album() -> void:
	var m: GameModel = GameState.m
	Unlocks.unlock_all(m)
	for id in ["biz_empanadas", "biz_kiosco", "biz_choripan", "biz_almacen", "pj_verdulera", "pj_perro", "pj_contador", "hl_1", "hl_3", "ev_corrida", "gold_3"]:
		StickerLogic.give(m, id)
	StickerLogic.give(m, "biz_kiosco")
	StickerLogic.give(m, "biz_kiosco")
	m.notifications.clear()
	_g()._open_album()


func _pack() -> void:
	var m: GameModel = GameState.m
	var res: Array = StickerLogic.gift_pack(m, ["common", "rare", "common", "golden", "common"])
	var ov: PackOpening = _g()._open_pack_overlay(res)
	ov.auto_open(0.3)


func _scratch() -> void:
	_g()._close_overlay()
	GameState.m.money = BigNumber.from_string("2.5e12")
	var ov: ScratchOverlay = _g()._open_scratch("x10")
	if ov != null:
		ov.auto_scratch(1.5)


func _ach() -> void:
	var m: GameModel = GameState.m
	if _g()._scratch_overlay != null and is_instance_valid(_g()._scratch_overlay):
		_g()._scratch_overlay.queue_free()
		_g()._scratch_overlay = null
	for id in ["first_sale", "clicks_1000", "first_biz", "first_remark", "first_bill", "first_reform", "paranoid", "nodes_10"]:
		m.achievements[id] = true
	_g()._open_achievements()


func _hyper() -> void:
	var m: GameModel = GameState.m
	_g()._close_overlay()
	m.run_time = 330.0
	m.ln_p = 24.0
	m.money = BigNumber.from_string("3e12")
	m.dirty = true


func _reform_anim() -> void:
	var m: GameModel = GameState.m
	m.collapse_shown = true
	m.run_earned = BigNumber.from_string("4.2e12")
	m.ln_p = 22.0
	Economy.reform()


func _options() -> void:
	main.show_options()


func _demo_end() -> void:
	main.show_demo_end()


func _credits() -> void:
	GameState.m.won = true
	main.show_credits(true)


## Una partida a mitad de camino con de todo: negocios y mejoras que te alcanzan, otros que no, y "Próximas" bloqueadas.
func _mix() -> void:
	var m: GameModel = GameState.m
	if _g() == null:
		main.start_game(false)
	_g()._close_overlay()
	m.demo_mode = false
	m.demo_finished = false
	m.won = false
	m.tree = {}
	for n in GameData.tree:
		if int(n["ring"]) <= 2 and not bool(n["final"]):
			m.tree[n["id"]] = true
	m.reforms = 3
	m.run_index = 4
	m.credibility = 40
	m.owned = {"empanadas": 22, "kiosco": 14, "choripan": 7, "lavadero": 3}
	m.upgrades = {}
	m.run_clicks = 120
	m.clicks = 2000
	m.run_time = 200.0
	m.ln_p = 0.05
	m.freeze_left = 0.0
	m.pending_choice = {}
	m.dirty = true
	EconomyLogic.ensure_fresh(m)
	for i in range(40):
		EconomyLogic.reveal_next(m)
	m.run_earned = BigNumber.from_float(2.0e5)
	m.best_run = BigNumber.from_float(1.0e12)      # lejos de la pared: inflación tranquila
	m.money = BigNumber.from_float(2600.0)
	m.combo = 8
	m.combo_idle = 0.0


## El árbol con nodos que se pueden comprar ya (latiendo), otros que no alcanzan (apagados con su costo) y comprados.
func _mix_tree() -> void:
	GameState.m.credibility = 27      # alcanza para los de 25, no para los de 29
	_g()._open_tree()
	_g()._tree_view.zoom = 0.8
	_g()._tree_view.focus("")


func _pause() -> void:
	_g()._close_overlay()
	_g().open_pause()


func _noop() -> void:
	pass


## Para las capturas de Steam: saca la nota del tutorial (tapa la pantalla).
func _strip() -> void:
	if main._game != null and is_instance_valid(main._game) and main._game.tutorial_note != null:
		main._game.tutorial_note.visible = false
