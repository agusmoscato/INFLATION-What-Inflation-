class_name ChalkFaces
extends RefCounted
## Los 10 personajes del barrio, dibujados por código con cara caricaturesca y un accesorio distinto.
## 0 verdulera, 1 kiosquero, 2 taxista, 3 abuela, 4 perro, 5 gato, 6 contador, 7 economista, 8 delivery, 9 cartonero.


static func draw(ci: CanvasItem, idx: int, r: Rect2, tint: Color = Color(0, 0, 0, 0)) -> void:
	var c: Vector2 = r.get_center() + Vector2(0, r.size.y * 0.06)
	var R: float = r.size.x * 0.32
	var w: float = maxf(2.0, r.size.x * 0.035)
	var skin: Color = Chalk.ORANGE if idx != 3 else Chalk.WHITE
	if idx == 4:
		skin = Chalk.ORANGE
	if idx == 5:
		skin = Chalk.WHITE
	if tint.a > 0.0:
		skin = tint
	var s: int = 7 + idx * 13
	# orejas de animal (detrás de la cabeza)
	if idx == 4:
		Chalk.polygon(ci, PackedVector2Array([c + Vector2(-R * 0.9, -R * 0.4), c + Vector2(-R * 1.25, R * 0.7), c + Vector2(-R * 0.55, R * 0.35)]), Chalk.PINK, w, s + 1, true)
		Chalk.polygon(ci, PackedVector2Array([c + Vector2(R * 0.9, -R * 0.4), c + Vector2(R * 1.25, R * 0.7), c + Vector2(R * 0.55, R * 0.35)]), Chalk.PINK, w, s + 2, true)
	if idx == 5:
		Chalk.polygon(ci, PackedVector2Array([c + Vector2(-R * 0.95, -R * 0.2), c + Vector2(-R * 0.7, -R * 1.35), c + Vector2(-R * 0.1, -R * 0.85)]), skin, w, s + 1, true)
		Chalk.polygon(ci, PackedVector2Array([c + Vector2(R * 0.95, -R * 0.2), c + Vector2(R * 0.7, -R * 1.35), c + Vector2(R * 0.1, -R * 0.85)]), skin, w, s + 2, true)
	# cabeza
	Chalk.circle(ci, c, R, skin, w, s, true, maxf(4.0, R * 0.2))
	# ojos
	var er: float = R * 0.13
	for sx in [-1.0, 1.0]:
		var ec: Vector2 = c + Vector2(sx * R * 0.38, -R * 0.15)
		draw_eye(ci, ec, er, idx == 2)
	# boca
	var mc: Vector2 = c + Vector2(0, R * 0.38)
	if idx == 7:
		ci.draw_line(mc + Vector2(-R * 0.25, 0), mc + Vector2(R * 0.25, 0), Chalk.WHITE, w, true)
	else:
		ci.draw_arc(mc + Vector2(0, -R * 0.1), R * 0.3, 0.3, PI - 0.3, 10, Chalk.WHITE, w, true)
	# accesorios
	match idx:
		0:  # pañuelo rosa con nudo
			Chalk.polygon(ci, PackedVector2Array([c + Vector2(-R * 1.0, -R * 0.2), c + Vector2(-R * 0.6, -R * 1.2), c + Vector2(R * 0.6, -R * 1.2), c + Vector2(R * 1.0, -R * 0.2), c + Vector2(0, -R * 0.55)]), Chalk.PINK, w, s + 3, true)
		1:  # gorra azul y bigote
			Chalk.polygon(ci, PackedVector2Array([c + Vector2(-R * 0.95, -R * 0.35), c + Vector2(-R * 0.7, -R * 1.2), c + Vector2(R * 0.7, -R * 1.2), c + Vector2(R * 0.95, -R * 0.35), c + Vector2(R * 1.5, -R * 0.3), c + Vector2(R * 1.0, -R * 0.15)]), Chalk.BLUE, w, s + 3, true)
			Chalk.line(ci, mc + Vector2(-R * 0.4, -R * 0.38), mc + Vector2(R * 0.4, -R * 0.38), Chalk.WHITE, w * 1.5, s + 4)
		2:  # gorra amarilla y anteojos oscuros
			Chalk.polygon(ci, PackedVector2Array([c + Vector2(-R * 0.9, -R * 0.4), c + Vector2(-R * 0.6, -R * 1.1), c + Vector2(R * 0.6, -R * 1.1), c + Vector2(R * 0.9, -R * 0.4)]), Chalk.YELLOW, w, s + 3, true)
			for sx2 in [-1.0, 1.0]:
				Chalk.circle(ci, c + Vector2(sx2 * R * 0.38, -R * 0.15), R * 0.2, Chalk.WHITE, w, s + 5, true, 3.0)
		3:  # rodete y anteojos
			Chalk.circle(ci, c + Vector2(0, -R * 1.2), R * 0.35, Chalk.WHITE, w, s + 3, true, 4.0)
			for sx3 in [-1.0, 1.0]:
				Chalk.circle(ci, c + Vector2(sx3 * R * 0.38, -R * 0.15), R * 0.24, Chalk.BLUE, w * 0.8, s + 6)
			Chalk.line(ci, c + Vector2(-R * 0.14, -R * 0.15), c + Vector2(R * 0.14, -R * 0.15), Chalk.BLUE, w * 0.8, s + 7)
		4:  # nariz de perro
			Chalk.circle(ci, c + Vector2(0, R * 0.12), R * 0.14, Chalk.WHITE, w, s + 3, true, 3.0)
		5:  # bigotes de gato
			for sy in [-1.0, 0.0, 1.0]:
				Chalk.line(ci, c + Vector2(R * 0.3, R * 0.25 + sy * R * 0.1), c + Vector2(R * 1.1, R * 0.2 + sy * R * 0.3), Chalk.WHITE, w * 0.7, s + 8 + int(sy))
				Chalk.line(ci, c + Vector2(-R * 0.3, R * 0.25 + sy * R * 0.1), c + Vector2(-R * 1.1, R * 0.2 + sy * R * 0.3), Chalk.WHITE, w * 0.7, s + 12 + int(sy))
		6:  # anteojos y corbata
			for sx4 in [-1.0, 1.0]:
				Chalk.circle(ci, c + Vector2(sx4 * R * 0.38, -R * 0.15), R * 0.22, Chalk.GREEN, w * 0.8, s + 9)
			Chalk.polygon(ci, PackedVector2Array([c + Vector2(0, R * 1.05), c + Vector2(-R * 0.15, R * 1.5), c + Vector2(R * 0.15, R * 1.5)]), Chalk.GREEN, w, s + 10, true)
		7:  # calvo, anteojos grandes y corbata
			for sx5 in [-1.0, 1.0]:
				Chalk.circle(ci, c + Vector2(sx5 * R * 0.38, -R * 0.15), R * 0.3, Chalk.WHITE, w * 0.8, s + 11)
			Chalk.polygon(ci, PackedVector2Array([c + Vector2(0, R * 1.05), c + Vector2(-R * 0.18, R * 1.5), c + Vector2(R * 0.18, R * 1.5)]), Chalk.PINK, w, s + 12, true)
		8:  # casco verde y bufanda
			Chalk.polygon(ci, PackedVector2Array([c + Vector2(-R * 1.0, -R * 0.2), c + Vector2(-R * 0.7, -R * 1.2), c + Vector2(R * 0.7, -R * 1.2), c + Vector2(R * 1.0, -R * 0.2)]), Chalk.GREEN, w, s + 3, true)
			Chalk.line(ci, c + Vector2(-R * 0.7, R * 1.0), c + Vector2(R * 0.7, R * 1.0), Chalk.PINK, w * 2.0, s + 13)
		9:  # sombrero naranja
			Chalk.polygon(ci, PackedVector2Array([c + Vector2(-R * 1.5, -R * 0.55), c + Vector2(-R * 0.6, -R * 0.65), c + Vector2(-R * 0.4, -R * 1.3), c + Vector2(R * 0.4, -R * 1.3), c + Vector2(R * 0.6, -R * 0.65), c + Vector2(R * 1.5, -R * 0.55)]), Chalk.ORANGE, w, s + 3, true)


static func draw_eye(ci: CanvasItem, ec: Vector2, er: float, hidden: bool) -> void:
	if hidden:
		return
	ci.draw_circle(ec, er * 1.15, Color(Chalk.WHITE, 0.95))
	ci.draw_circle(ec + Vector2(er * 0.15, er * 0.1), er * 0.55, Color("#26302B"))
