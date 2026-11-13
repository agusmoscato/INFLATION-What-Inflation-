class_name EmpanadaButton
extends Control
## La empanada gigante del clic, dibujada por código.

signal pressed(global_pos: Vector2)

var _tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(240, 190)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	pivot_offset = size / 2.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		poke()
		pressed.emit(get_global_mouse_position())


func poke() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	scale = Vector2(0.9, 0.9)
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var c: Vector2 = Vector2(size.x / 2.0, size.y * 0.62)
	var r: float = minf(size.x * 0.46, size.y * 0.8)
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(0, 33):
		var a: float = PI + PI * float(i) / 32.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, Color("#d79a3e"))
	var inner: PackedVector2Array = PackedVector2Array()
	for i in range(0, 33):
		var a2: float = PI + PI * float(i) / 32.0
		inner.append(c + Vector2(cos(a2), sin(a2)) * r * 0.86 - Vector2(0, 2))
	draw_colored_polygon(inner, Color("#e6b25a"))
	# repulgue (borde) a lo largo del lado plano
	var n: int = 14
	for i in range(n):
		var x: float = c.x - r + (2.0 * r) * (float(i) + 0.5) / float(n)
		draw_circle(Vector2(x, c.y + 2), r * 0.075, Color("#c58429"))
	draw_line(c + Vector2(-r, 0), c + Vector2(r, 0), Color("#a86d1f"), 3.0)
	# cara
	draw_circle(c + Vector2(-r * 0.28, -r * 0.4), r * 0.07, Color("#3a2410"))
	draw_circle(c + Vector2(r * 0.28, -r * 0.4), r * 0.07, Color("#3a2410"))
	draw_arc(c + Vector2(0, -r * 0.3), r * 0.22, 0.2, PI - 0.2, 12, Color("#3a2410"), 3.0)
	draw_circle(c + Vector2(-r * 0.5, -r * 0.25), r * 0.07, Color(0.9, 0.4, 0.3, 0.5))
	draw_circle(c + Vector2(r * 0.5, -r * 0.25), r * 0.07, Color(0.9, 0.4, 0.3, 0.5))
