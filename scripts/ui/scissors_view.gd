class_name ScissorsView
extends Control
## Tijera dibujada por código (para cortar ceros en la reforma monetaria).

var open: float = 0.5:
	set(v):
		open = v
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(120, 120)


func _draw() -> void:
	var c: Vector2 = size / 2.0
	for sign_v in [-1.0, 1.0]:
		var a: float = open * sign_v
		var dir: Vector2 = Vector2.LEFT.rotated(a)
		var perp: Vector2 = dir.rotated(PI / 2.0)
		var tip: Vector2 = c + dir * 50.0
		var blade: PackedVector2Array = PackedVector2Array([c + perp * 5.0, tip, c - perp * 5.0])
		draw_colored_polygon(blade, Color("#cfd8dc"))
		var handle_c: Vector2 = c - dir * 22.0 + perp * 12.0 * sign_v
		draw_arc(handle_c, 12.0, 0.0, TAU, 20, Color("#e05d5d"), 5.0)
	draw_circle(c, 5.0, Color("#455a64"))
