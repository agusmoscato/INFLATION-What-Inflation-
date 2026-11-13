class_name ActionHighlight
extends Control
## "Una sola acción destacada": un aro de tiza que late alrededor del control recomendado, una flecha que lo señala y
## una frase corta. Si el jugador no hace nada en 10 s, la flecha y la frase crecen para que no se pierda.

var target: Control = null
var hint: String = ""
var idle: float = 0.0           ## segundos sin que el jugador toque nada (lo actualiza GameScreen)
## De qué lado viene la flecha: "left", "right", "top", "bottom".
var side: String = "left"
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


func set_target(c: Control, text: String, from_side: String) -> void:
	target = c
	hint = text
	side = from_side


var _ring: Rect2
var _tip: Vector2
var _tail: Vector2
var _dir: Vector2 = Vector2.RIGHT
var _k: float = 1.0
var _pulse: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	_grow = move_toward(_grow, 1.0 if idle >= 10.0 else 0.0, delta * 1.5)
	var show_it: bool = target != null and is_instance_valid(target) and target.is_visible_in_tree()
	visible = show_it
	if not show_it:
		return
	_compute()
	queue_redraw()


## Geometría de la flecha y posición de la frase (acá y no en _draw: no se pueden mover nodos mientras se dibuja).
func _compute() -> void:
	var r: Rect2 = target.get_global_rect()
	r.position -= get_global_rect().position
	_pulse = 0.5 + 0.5 * sin(_t * 5.0)
	_ring = r.grow(6.0 + _pulse * 5.0)
	_k = 1.0 + 0.65 * _grow
	var alen: float = 74.0 * _k
	var bob: float = 10.0 + sin(_t * 6.0) * 7.0
	var anchor: Vector2 = _ring.get_center()
	match side:
		"left":
			_dir = Vector2.RIGHT
			anchor = Vector2(_ring.position.x, _ring.get_center().y)
		"right":
			_dir = Vector2.LEFT
			anchor = Vector2(_ring.end.x, _ring.get_center().y)
		"top":
			_dir = Vector2.DOWN
			anchor = Vector2(_ring.get_center().x, _ring.position.y)
		_:
			_dir = Vector2.UP
			anchor = Vector2(_ring.get_center().x, _ring.end.y)
	_tip = anchor - _dir * bob
	_tail = _tip - _dir * alen
	_label.visible = hint != ""
	if hint == "":
		return
	_label.text = hint
	_label.add_theme_font_size_override("font_size", int(24.0 + 10.0 * _grow))
	_label.reset_size()
	var lp: Vector2 = _tail
	match side:
		"left":
			lp = Vector2(_tail.x - _label.size.x - 6.0, _tail.y - _label.size.y * 0.5)
		"right":
			lp = Vector2(_tail.x + 6.0, _tail.y - _label.size.y * 0.5)
		"top":
			lp = Vector2(_tail.x - _label.size.x * 0.5, _tail.y - _label.size.y - 4.0)
		_:
			lp = Vector2(_tail.x - _label.size.x * 0.5, _tail.y + 4.0)
	var vr: Vector2 = get_viewport_rect().size
	lp.x = clampf(lp.x, 8.0, maxf(8.0, vr.x - _label.size.x - 8.0))
	lp.y = clampf(lp.y, 8.0, maxf(8.0, vr.y - _label.size.y - 8.0))
	_label.position = lp


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
	# flecha de tiza
	var n: Vector2 = Vector2(-_dir.y, _dir.x)
	for pass_i in range(2):
		var c2: Color = Color("#1c1508", 0.7) if pass_i == 0 else Chalk.YELLOW
		var w: float = (11.0 if pass_i == 0 else 6.0) * (0.8 + 0.3 * _k)
		draw_line(_tail, _tip, c2, w, true)
		draw_line(_tip, _tip - _dir * 24.0 * _k + n * 16.0 * _k, c2, w, true)
		draw_line(_tip, _tip - _dir * 24.0 * _k - n * 16.0 * _k, c2, w, true)
