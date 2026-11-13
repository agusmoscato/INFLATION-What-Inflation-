class_name WoodFrame
extends Control
## Marco de madera del pizarrón, dibujado por código (veta, nudos, clavos y repisa con tiza y borrador).

const T: float = 15.0          # grosor lateral/superior
const TB: float = 22.0         # grosor inferior (repisa)
const BASE: Color = Color("#8A5A33")
const DARK: Color = Color("#5E3A1E")
const LIGHT: Color = Color("#B88450")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var bars: Array = [
		PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w - T, T), Vector2(T, T)]),
		PackedVector2Array([Vector2(0, h), Vector2(w, h), Vector2(w - T, h - TB), Vector2(T, h - TB)]),
		PackedVector2Array([Vector2(0, 0), Vector2(T, T), Vector2(T, h - TB), Vector2(0, h)]),
		PackedVector2Array([Vector2(w, 0), Vector2(w, h), Vector2(w - T, h - TB), Vector2(w - T, T)]),
	]
	var i: int = 0
	for b in bars:
		draw_colored_polygon(b, BASE.darkened(0.08 * float(i % 2)))
		i += 1
	# veta: líneas largas y onduladas
	for k in range(7):
		var y: float = 2.0 + float(k) * 2.0
		_grain(Vector2(0, y), Vector2(w, y), 100 + k, 0.0)
	for k in range(9):
		var yb: float = h - TB + 2.0 + float(k) * 2.2
		_grain(Vector2(0, yb), Vector2(w, yb), 200 + k, 0.0)
	for k in range(6):
		var x: float = 2.0 + float(k) * 2.2
		_grain(Vector2(x, 0), Vector2(x, h), 300 + k, 0.0)
		_grain(Vector2(w - x, 0), Vector2(w - x, h), 400 + k, 0.0)
	# bisel interior claro y sombra
	draw_polyline(PackedVector2Array([Vector2(T, h - TB), Vector2(T, T), Vector2(w - T, T)]), DARK, 2.5, true)
	draw_polyline(PackedVector2Array([Vector2(w - T, T), Vector2(w - T, h - TB), Vector2(T, h - TB)]), LIGHT, 2.0, true)
	# uniones en inglete
	for c in [[Vector2(0, 0), Vector2(T, T)], [Vector2(w, 0), Vector2(w - T, T)], [Vector2(0, h), Vector2(T, h - TB)], [Vector2(w, h), Vector2(w - T, h - TB)]]:
		draw_line(c[0], c[1], DARK, 1.5, true)
	# clavos
	for p in [Vector2(T * 0.5, T * 0.5), Vector2(w - T * 0.5, T * 0.5), Vector2(T * 0.5, h - TB * 0.5), Vector2(w - T * 0.5, h - TB * 0.5)]:
		draw_circle(p, 2.4, DARK)
		draw_circle(p + Vector2(-0.6, -0.6), 1.0, LIGHT)


func _grain(a: Vector2, b: Vector2, seed_v: int, _unused: float) -> void:
	var pts: PackedVector2Array = Chalk.jitter_line(a, b, seed_v, 0.9, 40.0)
	draw_polyline(pts, Color(DARK, 0.28), 1.0, true)
