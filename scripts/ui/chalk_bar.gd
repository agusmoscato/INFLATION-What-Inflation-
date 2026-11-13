class_name ChalkBar
extends Control
## Barra de progreso de tiza: riel dibujado a mano y relleno garabateado en zigzag.

var value: float = 0.0:
	set(v):
		value = v
		queue_redraw()
var max_value: float = 1.0
var fill_color: Color = Chalk.RED
var show_percentage: bool = false
var seed_v: int = 3


func _init() -> void:
	custom_minimum_size = Vector2(0, 14)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var mid: float = h * 0.5
	Chalk.line(self, Vector2(1, mid + 4), Vector2(w - 1, mid + 4), Color(Chalk.WHITE, 0.55), 2.0, seed_v)
	draw_line(Vector2(1, mid - 3), Vector2(1, mid + 8), Color(Chalk.WHITE, 0.55), 2.0, true)
	draw_line(Vector2(w - 1, mid - 3), Vector2(w - 1, mid + 8), Color(Chalk.WHITE, 0.55), 2.0, true)
	var f: float = clampf(value / maxf(max_value, 0.0001), 0.0, 1.0)
	if f <= 0.01:
		return
	var x_end: float = 4.0 + (w - 8.0) * f
	var pts: PackedVector2Array = PackedVector2Array()
	var x: float = 4.0
	var i: int = 0
	while x < x_end:
		pts.append(Vector2(x, mid + (5.0 if i % 2 == 0 else -4.0) + Chalk.rnd_s(seed_v, i) * 1.2))
		x += 5.0
		i += 1
	pts.append(Vector2(x_end, mid))
	draw_polyline(pts, fill_color, 3.2, true)
