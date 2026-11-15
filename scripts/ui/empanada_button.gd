class_name EmpanadaButton
extends Control
## La empanada, personaje del juego: dibujada en tiza con cara expresiva.
## Squash & stretch al clic; transpira con inflación alta y entra en pánico en la hiperinflación.

signal pressed(global_pos: Vector2)

## Tasa de inflación mensual actual (la actualiza GameScreen): define el ánimo.
var rate: float = 0.03
## La empanada evoluciona con el árbol (la actualiza GameScreen): gorrito de cocinera, anteojos de sol, corona y,
## con el final, brillo dorado.
var hat: bool = false
var glasses: bool = false
var crown: bool = false
var gold: bool = false
## Transpira cuando la vuelta se acerca a la pared (aunque el freno evite la traba).
var sweat: float = 0.0

var _tween: Tween
var _t: float = 0.0
var _o_mouth: float = 0.0
var _blink: float = 0.0


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(280, 220)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_update_pivot()
	resized.connect(_update_pivot)


func _update_pivot() -> void:
	pivot_offset = Vector2(size.x / 2.0, size.y * 0.92)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		poke()
		pressed.emit(get_global_mouse_position())


## Squash & stretch exagerado + boca en "o".
func poke() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_o_mouth = 0.35
	scale = Vector2(1.28, 0.72)
	rotation = randf_range(-0.05, 0.05)
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(0.86, 1.2), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "rotation", 0.0, 0.42).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_t += delta
	_o_mouth = maxf(0.0, _o_mouth - delta)
	_blink = maxf(0.0, _blink - delta)
	if _blink <= 0.0 and fmod(_t, 3.6) < delta:
		_blink = 0.13
	if rate > 0.5 and (_tween == null or not _tween.is_running()):
		rotation = sin(_t * 38.0) * 0.025          # temblor de pánico
	queue_redraw()


func _draw() -> void:
	var c: Vector2 = Vector2(size.x / 2.0, size.y * 0.68)
	var r: float = minf(size.x * 0.42, size.y * 0.74)
	if gold:
		# brillo dorado del final: halo que respira y rayitos
		var k: float = 0.5 + 0.5 * sin(_t * 2.5)
		draw_circle(c + Vector2(0, -r * 0.45), r * (1.05 + 0.05 * k), Color(Chalk.YELLOW, 0.10 + 0.06 * k))
		for i in range(10):
			var a0: float = PI + PI * (float(i) + 0.5) / 10.0
			draw_line(c + Vector2(cos(a0), sin(a0)) * r * 1.15, c + Vector2(cos(a0), sin(a0)) * r * (1.3 + 0.06 * k), Color(Chalk.YELLOW, 0.5), 2.0, true)
	# cuerpo: media luna
	var body: PackedVector2Array = PackedVector2Array()
	for i in range(0, 25):
		var a: float = PI + PI * float(i) / 24.0
		body.append(c + Vector2(cos(a), sin(a)) * r)
	Chalk.polygon(self, body, Chalk.ORANGE, 5.0, 11, true, Color(Chalk.YELLOW, 0.32), 11.0, 1.4)
	var inner: PackedVector2Array = PackedVector2Array()
	for i in range(3, 22):
		var a2: float = PI + PI * float(i) / 24.0
		inner.append(c + Vector2(cos(a2), sin(a2)) * r * 0.82)
	draw_polyline(inner, Color(Chalk.WHITE, 0.25), 2.0, true)
	# repulgue a lo largo del lado plano
	var n: int = 13
	for i in range(n):
		var x: float = c.x - r + (2.0 * r) * (float(i) + 0.5) / float(n)
		Chalk.circle(self, Vector2(x, c.y + 3.0), r * 0.07, Chalk.ORANGE, 2.6, 20 + i, true, 3.0)
	Chalk.line(self, c + Vector2(-r, 0), c + Vector2(r, 0), Chalk.ORANGE, 4.0, 33, 1.5)
	_draw_face(c, r)
	_draw_outfit(c, r)
	if sweat > 0.0 and rate <= 0.15:
		# gotitas de transpiración cerca de la pared (la cara preocupada ya trae las suyas con inflación alta)
		for i in range(int(ceil(sweat * 3.0))):
			var f: float = fmod(_t * (0.8 + 0.25 * float(i)) + float(i) * 0.41, 1.0)
			var sx: float = c.x + r * (0.55 + 0.12 * float(i)) * (1.0 if i % 2 == 0 else -1.0)
			_drop(Vector2(sx, c.y - r * 0.85 + f * r * 0.6), r * 0.07, (1.0 - f) * clampf(sweat, 0.3, 1.0))


## Accesorios: gorrito de cocinera (o corona), anteojos de sol.
func _draw_outfit(c: Vector2, r: float) -> void:
	var top: Vector2 = c + Vector2(0, -r * 0.98)
	if crown:
		var w: float = r * 0.62
		var pts: PackedVector2Array = PackedVector2Array([top + Vector2(-w / 2.0, 0), top + Vector2(-w / 2.0, -r * 0.3), top + Vector2(-w / 4.0, -r * 0.14),
			top + Vector2(0, -r * 0.36), top + Vector2(w / 4.0, -r * 0.14), top + Vector2(w / 2.0, -r * 0.3), top + Vector2(w / 2.0, 0)])
		Chalk.polygon(self, pts, Chalk.YELLOW, 3.0, 201, true, Color(Chalk.YELLOW, 0.45), 6.0)
		for i in range(3):
			draw_circle(top + Vector2(-w / 2.0 + w * 0.5 * float(i), -r * (0.3 if i != 1 else 0.36)), 3.5, Chalk.PINK)
	elif hat:
		var hw: float = r * 0.36
		Chalk.polygon(self, PackedVector2Array([top + Vector2(-hw, 2), top + Vector2(-hw, -r * 0.12), top + Vector2(hw, -r * 0.12), top + Vector2(hw, 2)]), Chalk.WHITE, 2.6, 211, true, Color(Chalk.WHITE, 0.35), 5.0)
		Chalk.circle(self, top + Vector2(-hw * 0.45, -r * 0.3), r * 0.2, Chalk.WHITE, 2.4, 212, true, 5.0)
		Chalk.circle(self, top + Vector2(hw * 0.45, -r * 0.3), r * 0.2, Chalk.WHITE, 2.4, 213, true, 5.0)
		Chalk.circle(self, top + Vector2(0, -r * 0.42), r * 0.22, Chalk.WHITE, 2.4, 214, true, 5.0)
	if glasses:
		var ey: float = c.y - r * 0.42
		var ex: float = r * 0.30
		var lw: float = r * 0.2
		for s in [-1.0, 1.0]:
			var ec: Vector2 = Vector2(c.x + ex * s, ey)
			draw_rect(Rect2(ec - Vector2(lw, lw * 0.6), Vector2(lw * 2.0, lw * 1.25)), Color(0.05, 0.05, 0.07, 0.92))
			draw_line(ec + Vector2(-lw * 0.6, -lw * 0.3), ec + Vector2(-lw * 0.1, -lw * 0.3), Color(Chalk.WHITE, 0.6), 2.0)
		draw_line(Vector2(c.x - ex + lw, ey - lw * 0.2), Vector2(c.x + ex - lw, ey - lw * 0.2), Color(0.05, 0.05, 0.07), 3.0)


func _draw_face(c: Vector2, r: float) -> void:
	var panic: bool = rate > 0.5
	var worried: bool = rate > 0.15
	var look: Vector2 = Vector2.ZERO
	if is_inside_tree():
		var d: Vector2 = get_local_mouse_position() - (c + Vector2(0, -r * 0.4))
		look = d.normalized() * minf(d.length() * 0.05, r * 0.05)
	var ey: float = -r * 0.42
	var ex: float = r * 0.30
	var er: float = r * (0.19 if panic else 0.14)
	for s in [-1.0, 1.0]:
		var ec: Vector2 = c + Vector2(ex * s, ey)
		if _blink > 0.0 and not panic:
			Chalk.line(self, ec + Vector2(-er, 0), ec + Vector2(er, 0), Chalk.WHITE, 3.0, 50 + int(s))
		else:
			Chalk.circle(self, ec, er, Chalk.WHITE, 2.6, 60 + int(s * 3.0), false)
			draw_circle(ec, er * 0.9, Color(Chalk.WHITE, 0.92))
			draw_circle(ec + look, er * (0.28 if panic else 0.45), Color("#26302B"))
		# cejas
		var brow_y: float = ey - er * 1.7
		if panic:
			Chalk.line(self, c + Vector2(ex * s - er, brow_y - 4), c + Vector2(ex * s + er, brow_y + 2 - 6 * (0.5 - s * 0.5)), Chalk.WHITE, 3.0, 70 + int(s))
		elif worried:
			Chalk.line(self, c + Vector2(ex * s - er * s * 0.0 - er, brow_y + 4 * s), c + Vector2(ex * s + er, brow_y - 4 * s), Chalk.WHITE, 3.0, 70 + int(s))
	# mejillas
	for s2 in [-1.0, 1.0]:
		Chalk.circle(self, c + Vector2(r * 0.55 * s2, -r * 0.22), r * 0.09, Chalk.PINK, 2.2, 80 + int(s2 * 2.0), true, 3.5)
	# boca
	var mc: Vector2 = c + Vector2(0, -r * 0.18)
	if _o_mouth > 0.0:
		Chalk.circle(self, mc, r * 0.1, Chalk.WHITE, 3.0, 90, true, 3.5, 0.9)
	elif panic:
		var big: PackedVector2Array = Chalk.ellipse_pts(mc + Vector2(0, 4), r * 0.2, r * 0.12 + sin(_t * 30.0) * 2.0, 91, 1.0, 1.0)
		Chalk.polygon(self, big, Chalk.WHITE, 3.0, 91, true, Color(Chalk.PINK, 0.6), 4.0, 0.6)
	elif worried:
		var wave: PackedVector2Array = PackedVector2Array()
		for i in range(7):
			wave.append(mc + Vector2(-r * 0.2 + r * 0.4 * float(i) / 6.0, sin(float(i) * 2.2) * 4.0))
		draw_polyline(wave, Chalk.WHITE, 3.0, true)
	else:
		draw_arc(mc + Vector2(0, -2), r * 0.2, 0.25, PI - 0.25, 14, Chalk.WHITE, 3.2, true)
	# transpiración
	if worried:
		var drops: int = 3 if panic else 1
		for i in range(drops):
			var f: float = fmod(_t * (0.9 + 0.3 * float(i)) + float(i) * 0.37, 1.0)
			var sx: float = c.x + r * (0.62 + 0.1 * float(i)) * (1.0 if i % 2 == 0 else -1.0)
			var sy: float = c.y - r * 0.8 + f * r * 0.7
			_drop(Vector2(sx, sy), r * 0.07, 1.0 - f * 0.6)
	# rayitas de susto alrededor de la cabeza
	if panic:
		for i in range(5):
			var a: float = PI + PI * (float(i) + 0.5) / 5.0
			var p0: Vector2 = c + Vector2(cos(a), sin(a)) * (r * 1.12)
			var p1: Vector2 = c + Vector2(cos(a), sin(a)) * (r * 1.28 + sin(_t * 20.0 + float(i)) * 4.0)
			draw_line(p0, p1, Color(Chalk.YELLOW, 0.9), 3.0, true)


func _drop(p: Vector2, s: float, alpha: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array([
		p + Vector2(0, -s * 1.6), p + Vector2(s * 0.9, s * 0.3), p + Vector2(s * 0.6, s * 1.1),
		p + Vector2(0, s * 1.4), p + Vector2(-s * 0.6, s * 1.1), p + Vector2(-s * 0.9, s * 0.3)])
	Chalk.polygon(self, pts, Color(Chalk.BLUE, alpha), 2.4, 5, true, Color(Chalk.BLUE, alpha * 0.6), 3.0, 0.4)
