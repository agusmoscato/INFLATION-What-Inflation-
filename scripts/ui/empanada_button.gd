class_name EmpanadaButton
extends Control
## La empanada, personaje del juego. El cuerpo es una textura (assets/empanada_nueva/empanada_body.png, filtro lineal
## con mipmaps); todo lo demás se dibuja por código encima: la cara (ojos que siguen el mouse, parpadeo, boca en "o"
## al clic, pánico, transpiración), los cachetes, el vapor, los accesorios del árbol y el brillo dorado del final.
## Squash & stretch al clic; transpira con inflación alta o cerca de la pared y entra en pánico en la hiperinflación.
## Con calidad de tiza Baja se mantiene la textura y se apagan el vapor y el halo.

signal pressed(global_pos: Vector2)

const BODY: Texture2D = preload("res://assets/empanada_nueva/empanada_body.png")
const INK: Color = Color("#1E1A17")
const EYE_WHITE: Color = Color("#F4F1E8")
const CHEEK: Color = Color(0.96, 0.6, 0.71, 0.85)
## Coordenadas (u, v) dentro de la textura, sacadas de referencia_empanada.png (encuadre 36,22 - 476,462 del SVG).
const CENTER_UV: Vector2 = Vector2(0.5, 0.70)          ## centro del lado plano
const EYE_UV: Array = [Vector2(0.3727, 0.5455), Vector2(0.6273, 0.5455)]
const EYE_R: Vector2 = Vector2(0.0614, 0.0705)
const PUPIL_OFF: Vector2 = Vector2(0.0136, 0.0136)
const PUPIL_R: float = 0.0318
const CHEEK_UV: Array = [Vector2(0.2818, 0.6591), Vector2(0.7182, 0.6591)]
const CHEEK_R: Vector2 = Vector2(0.0545, 0.0318)
const MOUTH_A: Vector2 = Vector2(0.4364, 0.6432)
const MOUTH_C: Vector2 = Vector2(0.5, 0.7136)
const MOUTH_B: Vector2 = Vector2(0.5636, 0.6432)
const TOP_UV: Vector2 = Vector2(0.5, 0.20)             ## arriba de la cabeza (para el gorrito y la corona)
const STEAM_U: Array = [0.3636, 0.5, 0.6364]

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
## Racha de clics (0..1): el vapor sube más rápido.
var streak: float = 0.0
## Vapor y halo (se apagan con calidad Baja; en el menú se pueden forzar).
var show_face: bool = true

var _tween: Tween
var _t: float = 0.0
var _o_mouth: float = 0.0
var _blink: float = 0.0
var _steam_phase: float = 0.0
var _S: float = 100.0                 # lado de la textura en pantalla
var _o: Vector2 = Vector2.ZERO        # esquina de la textura en pantalla


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(280, 220)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_update_pivot()
	resized.connect(_update_pivot)


func _update_pivot() -> void:
	pivot_offset = Vector2(size.x / 2.0, size.y * 0.88)


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
	_steam_phase += delta * (0.35 + 1.1 * clampf(streak, 0.0, 1.0))
	_o_mouth = maxf(0.0, _o_mouth - delta)
	_blink = maxf(0.0, _blink - delta)
	if _blink <= 0.0 and fmod(_t, 3.6) < delta:
		_blink = 0.13
	if rate > 0.5 and (_tween == null or not _tween.is_running()):
		rotation = sin(_t * 38.0) * 0.025          # temblor de pánico
	queue_redraw()


## Punto de la textura (u, v) en coordenadas del control.
func T(uv: Vector2) -> Vector2:
	return _o + uv * _S


func _layout() -> void:
	_S = minf(size.x / 0.95, size.y / 0.78)
	var c: Vector2 = Vector2(size.x / 2.0, size.y * 0.86)
	_o = c - CENTER_UV * _S


## Zona prohibida para los "+$X" de los clics (global): arriba de la cabeza, donde van el gorrito, la corona y el vapor.
func keep_out_rect() -> Rect2:
	_layout()
	var gr: Rect2 = get_global_rect()
	var bottom: float = T(TOP_UV).y + 6.0
	return Rect2(gr.position, Vector2(gr.size.x, bottom * get_global_transform().get_scale().y))


func _fancy() -> bool:
	return Settings.quality < 2


func _draw() -> void:
	_layout()
	var c: Vector2 = T(CENTER_UV)
	if gold and _fancy():
		# halo dorado que late, detrás del cuerpo
		var k: float = 0.5 + 0.5 * sin(_t * 2.5)
		var hc: Vector2 = T(Vector2(0.5, 0.5))
		for i in range(3):
			draw_circle(hc, _S * (0.40 + 0.06 * float(i) + 0.03 * k), Color(Chalk.YELLOW, (0.10 - 0.025 * float(i)) * (0.7 + 0.5 * k)))
		for i in range(12):
			var a0: float = PI + PI * (float(i) + 0.5) / 12.0
			draw_line(hc + Vector2(cos(a0), sin(a0)) * _S * 0.5, hc + Vector2(cos(a0), sin(a0)) * _S * (0.56 + 0.04 * k), Color(Chalk.YELLOW, 0.45), 2.0, true)
	# cuerpo: la textura (dorada con el final)
	var mod: Color = Color(1.0, 0.86, 0.42) if gold else Color.WHITE
	draw_texture_rect(BODY, Rect2(_o, Vector2(_S, _S)), false, mod)
	if _fancy():
		_draw_steam()
	if show_face:
		_draw_face(c)
	_draw_outfit()
	if sweat > 0.0 and rate <= 0.15:
		# gotitas de transpiración cerca de la pared (la cara preocupada ya trae las suyas con inflación alta)
		for i in range(int(ceil(sweat * 3.0))):
			var f: float = fmod(_t * (0.8 + 0.25 * float(i)) + float(i) * 0.41, 1.0)
			var u: float = 0.16 + 0.05 * float(i) if i % 2 == 0 else 0.84 - 0.05 * float(i)
			_drop(T(Vector2(u, 0.38 + f * 0.22)), _S * 0.028, (1.0 - f) * clampf(sweat, 0.3, 1.0))


## Vapor: 3 líneas onduladas de tiza que suben despacio (más rápido con racha de clics).
func _draw_steam() -> void:
	for i in range(3):
		var f: float = fmod(_steam_phase + float(i) * 0.33, 1.0)
		var alpha: float = sin(f * PI) * 0.75
		if alpha <= 0.02:
			continue
		var base: Vector2 = T(Vector2(STEAM_U[i], 0.16 - f * 0.06))
		var pts: PackedVector2Array = PackedVector2Array()
		for k in range(9):
			var y: float = -float(k) / 8.0 * _S * 0.13
			pts.append(base + Vector2(sin(float(k) * 0.9 + _t * 2.0 + float(i)) * _S * 0.018, y))
		draw_polyline(pts, Color(Chalk.WHITE, alpha), maxf(2.0, _S * 0.014), true)


## Accesorios: gorrito de cocinera (o corona), anteojos de sol.
func _draw_outfit() -> void:
	var top: Vector2 = T(TOP_UV)
	var r: float = _S * 0.34
	if crown:
		var w: float = r * 0.62
		var pts: PackedVector2Array = PackedVector2Array([top + Vector2(-w / 2.0, 0), top + Vector2(-w / 2.0, -r * 0.3), top + Vector2(-w / 4.0, -r * 0.14),
			top + Vector2(0, -r * 0.36), top + Vector2(w / 4.0, -r * 0.14), top + Vector2(w / 2.0, -r * 0.3), top + Vector2(w / 2.0, 0)])
		Chalk.polygon(self, pts, Chalk.YELLOW, 3.0, 201, true, Color(Chalk.YELLOW, 0.55), 6.0)
		for i in range(3):
			draw_circle(top + Vector2(-w / 2.0 + w * 0.5 * float(i), -r * (0.3 if i != 1 else 0.36)), 3.5, Chalk.PINK)
	elif hat:
		var hw: float = r * 0.36
		Chalk.polygon(self, PackedVector2Array([top + Vector2(-hw, 2), top + Vector2(-hw, -r * 0.12), top + Vector2(hw, -r * 0.12), top + Vector2(hw, 2)]), Chalk.WHITE, 2.6, 211, true, Color(Chalk.WHITE, 0.6), 5.0)
		for p in [Vector2(-hw * 0.45, -r * 0.3), Vector2(hw * 0.45, -r * 0.3), Vector2(0, -r * 0.42)]:
			draw_circle(top + p, r * 0.2, Color(Chalk.WHITE, 0.85))
			Chalk.circle(self, top + p, r * 0.2, Chalk.WHITE, 2.4, 212 + int(p.x), false)
	if glasses:
		var lw: Vector2 = Vector2(EYE_R.x * 1.45, EYE_R.y * 1.0) * _S
		for e in EYE_UV:
			var ec: Vector2 = T(e)
			draw_rect(Rect2(ec - lw, lw * 2.0), Color(0.05, 0.05, 0.07, 0.94))
			draw_line(ec + Vector2(-lw.x * 0.6, -lw.y * 0.45), ec + Vector2(-lw.x * 0.1, -lw.y * 0.45), Color(Chalk.WHITE, 0.6), 2.0)
		draw_line(T(EYE_UV[0]) + Vector2(lw.x, -lw.y * 0.3), T(EYE_UV[1]) + Vector2(-lw.x, -lw.y * 0.3), Color(0.05, 0.05, 0.07), 3.0)


func _ellipse(center: Vector2, rad: Vector2, col: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(24):
		var a: float = TAU * float(i) / 24.0
		pts.append(center + Vector2(cos(a) * rad.x, sin(a) * rad.y))
	draw_colored_polygon(pts, col)


func _draw_face(_c: Vector2) -> void:
	var panic: bool = rate > 0.5
	var worried: bool = rate > 0.15
	var mid: Vector2 = (T(EYE_UV[0]) + T(EYE_UV[1])) / 2.0
	var look: Vector2 = Vector2.ZERO
	if is_inside_tree():
		var d: Vector2 = get_local_mouse_position() - mid
		look = d.normalized() * minf(d.length() * 0.04, _S * 0.018)
	var er: Vector2 = EYE_R * _S * (1.22 if panic else 1.0)
	for i in range(2):
		var ec: Vector2 = T(EYE_UV[i])
		var s: float = -1.0 if i == 0 else 1.0
		if _blink > 0.0 and not panic:
			draw_line(ec + Vector2(-er.x, 0), ec + Vector2(er.x, 0), INK, maxf(2.0, _S * 0.012), true)
		else:
			_ellipse(ec, er, EYE_WHITE)
			var pr: float = PUPIL_R * _S * (0.6 if panic else 1.0)
			var pc: Vector2 = ec + (Vector2.ZERO if panic else PUPIL_OFF * _S) + look
			draw_circle(pc, pr, INK)
			draw_circle(pc + Vector2(pr * 0.35, -pr * 0.42), pr * 0.36, EYE_WHITE)
		# cejas
		var by: float = ec.y - er.y * 1.5
		if panic:
			draw_line(Vector2(ec.x - er.x, by - 4 * s), Vector2(ec.x + er.x, by + 4 * s), INK, maxf(2.0, _S * 0.011), true)
		elif worried:
			draw_line(Vector2(ec.x - er.x, by + 4 * s), Vector2(ec.x + er.x, by - 4 * s), INK, maxf(2.0, _S * 0.011), true)
	# cachetes
	for cu in CHEEK_UV:
		_ellipse(T(cu), CHEEK_R * _S, CHEEK)
	# boca
	var a: Vector2 = T(MOUTH_A)
	var b: Vector2 = T(MOUTH_B)
	var mw: float = maxf(2.5, _S * 0.018)
	if _o_mouth > 0.0:
		_ellipse(T(Vector2(0.5, 0.665)), Vector2(0.032, 0.036) * _S, INK)
	elif panic:
		_ellipse(T(Vector2(0.5, 0.67)), Vector2(0.06, 0.04 + sin(_t * 30.0) * 0.004) * _S, INK)
		_ellipse(T(Vector2(0.5, 0.69)), Vector2(0.035, 0.015) * _S, Color(Chalk.PINK, 0.9))
	elif worried:
		var wave: PackedVector2Array = PackedVector2Array()
		for i in range(7):
			wave.append(a.lerp(b, float(i) / 6.0) + Vector2(0, sin(float(i) * 2.2) * _S * 0.008 + _S * 0.02))
		draw_polyline(wave, INK, mw, true)
	else:
		var ctrl: Vector2 = T(MOUTH_C)
		var pts: PackedVector2Array = PackedVector2Array()
		for i in range(13):
			var t: float = float(i) / 12.0
			pts.append(a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))
		draw_polyline(pts, INK, mw, true)
	# transpiración
	if worried:
		var drops: int = 3 if panic else 1
		for i in range(drops):
			var f: float = fmod(_t * (0.9 + 0.3 * float(i)) + float(i) * 0.37, 1.0)
			var u: float = 0.2 + 0.04 * float(i) if i % 2 == 0 else 0.8 - 0.04 * float(i)
			_drop(T(Vector2(u, 0.4 + f * 0.25)), _S * 0.028, 1.0 - f * 0.6)
	# rayitas de susto alrededor de la cabeza
	if panic:
		var hc: Vector2 = T(Vector2(0.5, 0.62))
		for i in range(5):
			var ang: float = PI + PI * (float(i) + 0.5) / 5.0
			var p0: Vector2 = hc + Vector2(cos(ang) * 0.5, sin(ang) * 0.48) * _S
			var p1: Vector2 = hc + Vector2(cos(ang) * 0.58, sin(ang) * 0.56) * _S + Vector2(0, sin(_t * 20.0 + float(i)) * 4.0)
			draw_line(p0, p1, Color(Chalk.YELLOW, 0.9), 3.0, true)


func _drop(p: Vector2, s: float, alpha: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array([
		p + Vector2(0, -s * 1.6), p + Vector2(s * 0.9, s * 0.3), p + Vector2(s * 0.6, s * 1.1),
		p + Vector2(0, s * 1.4), p + Vector2(-s * 0.6, s * 1.1), p + Vector2(-s * 0.9, s * 0.3)])
	Chalk.polygon(self, pts, Color(Chalk.BLUE, alpha), 2.4, 5, true, Color(Chalk.BLUE, alpha * 0.6), 3.0, 0.4)
