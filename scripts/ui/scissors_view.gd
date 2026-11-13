class_name ScissorsView
extends Control
## Tijera caricaturesca de tiza (con cara) que corta los ceros del billete en la reforma monetaria.

var open: float = 0.5:
	set(v):
		open = v
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(150, 130)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c: Vector2 = size / 2.0
	var i: int = 0
	for s in [-1.0, 1.0]:
		var a: float = open * s
		var dir: Vector2 = Vector2.LEFT.rotated(a)
		var perp: Vector2 = dir.rotated(PI / 2.0)
		var tip: Vector2 = c + dir * 64.0
		var blade: PackedVector2Array = PackedVector2Array([c + perp * 9.0, tip, c - perp * 7.0])
		Chalk.polygon(self, blade, Chalk.BLUE, 3.4, 20 + i, true, Color(Chalk.BLUE, 0.5), 5.0, 0.8)
		var hc: Vector2 = c - dir * 34.0 + perp * 17.0 * s
		Chalk.circle(self, hc, 15.0, Chalk.PINK, 5.0, 30 + i)
		Chalk.line(self, c - dir * 6.0, hc + dir * 12.0, Chalk.PINK, 4.0, 40 + i)
		i += 1
	# cara en el tornillo
	draw_circle(c, 11.0, Color("#26302B"))
	Chalk.circle(self, c, 11.0, Chalk.WHITE, 2.6, 50)
	draw_circle(c + Vector2(-4, -2), 2.4, Chalk.WHITE)
	draw_circle(c + Vector2(4, -2), 2.4, Chalk.WHITE)
	draw_arc(c + Vector2(0, 1), 5.0, 0.3, PI - 0.3, 8, Chalk.WHITE, 2.0, true)
