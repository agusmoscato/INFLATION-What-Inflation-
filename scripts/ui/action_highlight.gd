class_name ActionHighlight
extends Control
## "Una sola acción destacada": un aro de tiza que late alrededor del control recomendado, una flecha que lo señala y
## una frase corta. Si el jugador no hace nada en 10 s, la flecha y la frase crecen para que no se pierda.

var target: Control = null
var hint: String = ""
var idle: float = 0.0           ## segundos sin que el jugador toque nada (lo actualiza GameScreen)
## De qué lado viene la flecha: "left", "right", "top", "bottom".
var side: String = "left"
var arrow_on: bool = true      ## false = solo el brillo (por ejemplo, una pestaña recién desbloqueada)
var _t: float = 0.0
var _grow: float = 0.0
var _label: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 5


func _ready() -> void:
	_label = UIKit.label("", 20, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, true)
	_label.add_theme_color_override("font_outline_color", Color("#1c1508"))
	_label.add_theme_constant_override("outline_size", 7)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# cartelito oscuro detrás de la frase: se lee aunque caiga sobre otro texto
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.09, 0.07, 0.94)
	bg.border_color = Chalk.YELLOW
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(6)
	bg.content_margin_left = 10.0
	bg.content_margin_right = 10.0
	bg.content_margin_top = 3.0
	bg.content_margin_bottom = 3.0
	_label.add_theme_stylebox_override("normal", bg)
	add_child(_label)


func set_target(c: Control, text: String, from_side: String, with_arrow: bool = true) -> void:
	arrow_on = with_arrow
	target = c
	hint = text
	side = from_side


## Rectángulos (coordenadas de esta capa) con texto de la pantalla: la flecha y la frase no se dibujan encima de ninguno.
var occupied: Array = []
var _ring: Rect2
var _tip: Vector2
var _tail: Vector2
var _dir: Vector2 = Vector2.RIGHT
var _k: float = 1.0
var _pulse: float = 0.0
var _arrow_ok: bool = false


func _process(delta: float) -> void:
	_t += delta
	_grow = move_toward(_grow, 1.0 if idle >= 10.0 else 0.0, delta * 1.5)
	var show_it: bool = target != null and is_instance_valid(target) and target.is_visible_in_tree()
	visible = show_it
	if show_it and not is_in_group("attention"):
		add_to_group("attention")      # el QA verifica que nunca haya dos notas o flechas a la vez
	elif not show_it and is_in_group("attention"):
		remove_from_group("attention")
	if not show_it:
		return
	_compute()
	queue_redraw()


## Geometría de la flecha de un lado dado: {dir, tip, tail, label_pos, label_rect, rects}
func _geom(s: String, ring: Rect2) -> Dictionary:
	var alen: float = 74.0 * _k
	var bob: float = 10.0 + sin(_t * 6.0) * 7.0
	var d: Vector2 = Vector2.RIGHT
	var anchor: Vector2 = ring.get_center()
	match s:
		"left":
			d = Vector2.RIGHT
			anchor = Vector2(ring.position.x, ring.get_center().y)
		"right":
			d = Vector2.LEFT
			anchor = Vector2(ring.end.x, ring.get_center().y)
		"top":
			d = Vector2.DOWN
			anchor = Vector2(ring.get_center().x, ring.position.y)
		_:
			d = Vector2.UP
			anchor = Vector2(ring.get_center().x, ring.end.y)
	var tip: Vector2 = anchor - d * bob
	var tail: Vector2 = tip - d * alen
	var lp: Vector2 = tail
	var ls: Vector2 = _label.size if (hint != "") else Vector2.ZERO
	match s:
		"left":
			lp = Vector2(tail.x - ls.x - 6.0, tail.y - ls.y * 0.5)
		"right":
			lp = Vector2(tail.x + 6.0, tail.y - ls.y * 0.5)
		"top":
			lp = Vector2(tail.x - ls.x * 0.5, tail.y - ls.y - 4.0)
		_:
			lp = Vector2(tail.x - ls.x * 0.5, tail.y + 4.0)
	var vr: Vector2 = get_viewport_rect().size
	lp.x = clampf(lp.x, 8.0, maxf(8.0, vr.x - ls.x - 8.0))
	lp.y = clampf(lp.y, 8.0, maxf(8.0, vr.y - ls.y - 8.0))
	var shaft: Rect2 = Rect2(tail, tip - tail).abs().grow(18.0 * _k)
	var rects: Array = [shaft]
	var lrect: Rect2 = Rect2(lp, ls)
	if hint != "":
		rects.append(lrect)
	return {"dir": d, "tip": tip, "tail": tail, "label_pos": lp, "rects": rects}


func _blocked(rects: Array) -> bool:
	for r in rects:
		for o in occupied:
			var inter: Rect2 = (r as Rect2).intersection(o as Rect2)
			if inter.size.x > 4.0 and inter.size.y > 4.0:
				return true
	return false


## Posiciona el aro y elige un lado libre para la flecha. Si todos los lados caen sobre texto, solo late el aro.
func _compute() -> void:
	var r: Rect2 = target.get_global_rect()
	r.position -= get_global_rect().position
	_pulse = 0.5 + 0.5 * sin(_t * 5.0)
	_ring = r.grow(6.0 + _pulse * 5.0)
	_k = 1.0 + 0.65 * _grow
	_arrow_ok = false
	_label.visible = false
	if not arrow_on:
		return
	if hint != "":
		_label.text = hint
		_label.add_theme_font_size_override("font_size", int(24.0 + 10.0 * _grow))
		_label.reset_size()
	var order: Array = [side]
	for s in ["left", "right", "top", "bottom"]:
		if not order.has(s):
			order.append(s)
	for s in order:
		var g: Dictionary = _geom(s, _ring)
		var on_target: bool = hint != "" and (g["rects"][1] as Rect2).intersects(_ring)      # la frase no se apoya sobre el control destacado
		if not on_target and not _blocked(g["rects"]):
			_arrow_ok = true
			_dir = g["dir"]
			_tip = g["tip"]
			_tail = g["tail"]
			if hint != "":
				_label.position = g["label_pos"]
				_label.visible = true
			return


func _draw() -> void:
	if target == null or not is_instance_valid(target):
		return
	# aro que late (doble trazo de tiza amarilla)
	var col: Color = Color(Chalk.YELLOW, 0.65 + 0.35 * _pulse)
	var edges: Array = Chalk.rect_edges(_ring.size, 31, 2.0, 5.0)
	for e in edges:
		var pts: PackedVector2Array = PackedVector2Array()
		var src: PackedVector2Array = e
		if src.size() < 2:
			continue
		for p in src:
			pts.append(p + _ring.position)
		draw_polyline(pts, Color("#1c1508", 0.55), 8.0 + _pulse * 2.0, true)
		draw_polyline(pts, col, 4.5 + _pulse * 2.0, true)
	if not _arrow_ok:
		return
	# flecha de tiza
	var n: Vector2 = Vector2(-_dir.y, _dir.x)
	for pass_i in range(2):
		var c2: Color = Color("#1c1508", 0.7) if pass_i == 0 else Chalk.YELLOW
		var w: float = (11.0 if pass_i == 0 else 6.0) * (0.8 + 0.3 * _k)
		draw_line(_tail, _tip, c2, w, true)
		draw_line(_tip, _tip - _dir * 24.0 * _k + n * 16.0 * _k, c2, w, true)
		draw_line(_tip, _tip - _dir * 24.0 * _k - n * 16.0 * _k, c2, w, true)
