class_name EraBackdrop
extends Control
## Dibujos tenues de fondo detrás de la empanada, según la capa de la vuelta:
## 1 "El puesto" (un toldo y un sol), 2 "El barrio" (casitas y un árbol), 3 "La ciudad" (edificios y nubes),
## 4 "Las finanzas" (rascacielos, signos de $ y una flecha que sube), 5 "¡Hiperinflación!" (llamas y billetes volando).
## Se redibuja solo al cambiar de capa (o de tamaño): no cuesta nada por frame.

var era: int = 1:
	set(v):
		if v != era:
			era = v
			queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_meta("qa_ignore", true)
	resized.connect(queue_redraw)


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 10.0 or h < 10.0:
		return
	var col: Color = Color(GameData.era_def(era)["color"], 0.16)
	var base: float = h * 0.62
	match era:
		1:
			# toldo del puesto y un sol
			Chalk.circle(self, Vector2(w * 0.86, h * 0.14), 16.0, col, 2.0, 3)
			for i in range(8):
				var a: float = TAU * float(i) / 8.0
				Chalk.line(self, Vector2(w * 0.86, h * 0.14) + Vector2(cos(a), sin(a)) * 22.0, Vector2(w * 0.86, h * 0.14) + Vector2(cos(a), sin(a)) * 30.0, col, 1.6, 10 + i, 0.5)
			for i in range(5):
				var x0: float = w * 0.05 + float(i) * 22.0
				Chalk.polyline(self, PackedVector2Array([Vector2(x0, h * 0.1), Vector2(x0 + 11, h * 0.16), Vector2(x0 + 22, h * 0.1)]), col, 1.8, 20 + i)
		2:
			for i in range(3):
				var x: float = w * (0.06 + 0.3 * float(i))
				var hw: float = 34.0
				Chalk.polygon(self, PackedVector2Array([Vector2(x, base), Vector2(x, base - 26), Vector2(x + hw / 2.0, base - 42), Vector2(x + hw, base - 26), Vector2(x + hw, base)]), col, 1.8, 30 + i)
			Chalk.circle(self, Vector2(w * 0.9, base - 40), 16.0, col, 1.8, 40)
			Chalk.line(self, Vector2(w * 0.9, base - 24), Vector2(w * 0.9, base), col, 2.0, 41)
		3:
			for i in range(7):
				var x2: float = w * 0.02 + float(i) * w * 0.14
				var hh: float = 30.0 + float((i * 37) % 50)
				Chalk.polygon(self, PackedVector2Array([Vector2(x2, base), Vector2(x2, base - hh), Vector2(x2 + w * 0.1, base - hh), Vector2(x2 + w * 0.1, base)]), col, 1.6, 50 + i)
			Chalk.circle(self, Vector2(w * 0.2, h * 0.12), 12.0, col, 1.6, 60, false, 5.0, 2.0)
			Chalk.circle(self, Vector2(w * 0.75, h * 0.18), 10.0, col, 1.6, 61, false, 5.0, 2.2)
		4:
			for i in range(5):
				var x3: float = w * 0.03 + float(i) * w * 0.2
				var hh2: float = 60.0 + float((i * 53) % 70)
				Chalk.polygon(self, PackedVector2Array([Vector2(x3, base), Vector2(x3, base - hh2), Vector2(x3 + w * 0.08, base - hh2 - 12), Vector2(x3 + w * 0.13, base - hh2), Vector2(x3 + w * 0.13, base)]), col, 1.6, 70 + i)
			var f: Font = Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font
			for i in range(4):
				draw_string(f, Vector2(w * (0.12 + 0.24 * float(i)), h * (0.1 + 0.08 * float(i % 2))), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, col)
			Chalk.polyline(self, PackedVector2Array([Vector2(w * 0.55, h * 0.3), Vector2(w * 0.68, h * 0.22), Vector2(w * 0.74, h * 0.26), Vector2(w * 0.9, h * 0.08)]), col, 2.2, 80)
		5:
			var red: Color = Color(Chalk.RED, 0.2)
			for i in range(9):
				var x4: float = w * (0.03 + 0.11 * float(i))
				Chalk.polyline(self, PackedVector2Array([Vector2(x4, base), Vector2(x4 + 8, base - 26 - float(i % 3) * 8), Vector2(x4 + 16, base)]), red, 2.0, 90 + i)
			for i in range(4):
				var p: Vector2 = Vector2(w * (0.15 + 0.22 * float(i)), h * (0.1 + 0.07 * float(i % 2)))
				Chalk.polygon(self, PackedVector2Array([p, p + Vector2(28, -6), p + Vector2(32, 10), p + Vector2(4, 16)]), red, 1.6, 100 + i)
