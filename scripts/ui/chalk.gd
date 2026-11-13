class_name Chalk
extends RefCounted
## Utilidades de "tiza": paleta, tipografías, ruido estable y primitivas de dibujo a mano
## (líneas con jitter estable, doble trazo, hachurado, texto que se escribe letra a letra).

const WHITE: Color = Color("#F2EFE6")
const YELLOW: Color = Color("#F7E27A")
const PINK: Color = Color("#F59AB5")
const BLUE: Color = Color("#8FD3F4")
const GREEN: Color = Color("#A8E6A1")
const ORANGE: Color = Color("#F7B267")
const RED: Color = Color("#E8707A")        ## tiza roja: solo para alertas ("ÚLTIMA HORA")
const BOARD: Color = Color("#2F4A3A")

static var title_font: Font
static var hand_font: Font
static var _fonts_loaded: bool = false


static func load_fonts() -> void:
	if _fonts_loaded:
		return
	_fonts_loaded = true
	title_font = _try_font("res://assets/fonts/CabinSketch-Bold.ttf")
	hand_font = _try_font("res://assets/fonts/CaveatBrush-Regular.ttf")


static func _try_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		var f: Resource = load(path)
		if f is Font:
			return f
	return null


## Color de tiza del código de la paleta ("w","y","p","b","g","o","r").
static func key(k: String) -> Color:
	match k:
		"y": return YELLOW
		"p": return PINK
		"b": return BLUE
		"g": return GREEN
		"o": return ORANGE
		"r": return RED
	return WHITE


## Lleva un color cualquiera a la tiza de la paleta más cercana por tono (los oscuros/grises -> blanco).
static func nearest(c: Color) -> Color:
	if c.s < 0.25 or c.v < 0.35:
		return WHITE
	var h: float = c.h
	var best: Color = WHITE
	var best_d: float = 9.0
	for p in [YELLOW, PINK, BLUE, GREEN, ORANGE, RED]:
		var d: float = absf(p.h - h)
		d = minf(d, 1.0 - d)
		if d < best_d:
			best_d = d
			best = p
	return best


# ---------------------------------------------------------------------
#  Ruido estable
# ---------------------------------------------------------------------
static func rnd(seed_v: int, i: int) -> float:
	var h: int = (seed_v * 374761393 + i * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h & 0xffff) / 65535.0


static func rnd_s(seed_v: int, i: int) -> float:
	return rnd(seed_v, i) * 2.0 - 1.0


# ---------------------------------------------------------------------
#  Geometría a mano alzada
# ---------------------------------------------------------------------
static func jitter_line(a: Vector2, b: Vector2, seed_v: int, amp: float = 1.4, step: float = 16.0) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var d: Vector2 = b - a
	var len: float = d.length()
	if len < 0.01:
		out.append(a)
		out.append(a + Vector2(0.01, 0.0))      # draw_polyline necesita al menos 2 puntos
		return out
	var n: int = maxi(2, int(len / step) + 1)
	var perp: Vector2 = Vector2(-d.y, d.x) / len
	for i in range(n + 1):
		var t: float = float(i) / float(n)
		var o: float = rnd_s(seed_v, i) * amp
		if i == 0 or i == n:
			o *= 0.5
		out.append(a + d * t + perp * o)
	return out


## Cuatro bordes de un rectángulo, cada uno una línea independiente que se pasa un poco de la esquina.
static func rect_edges(size: Vector2, seed_v: int, amp: float = 1.6, overshoot: float = 5.0) -> Array:
	var c: Array = [Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(0, size.y)]
	for i in range(4):
		c[i] += Vector2(rnd_s(seed_v, 40 + i), rnd_s(seed_v, 50 + i)) * amp * 1.4
	var edges: Array = []
	for i in range(4):
		var a: Vector2 = c[i]
		var b: Vector2 = c[(i + 1) % 4]
		var dir: Vector2 = (b - a).normalized()
		a -= dir * rnd(seed_v, 60 + i) * overshoot
		b += dir * rnd(seed_v, 70 + i) * overshoot
		edges.append(jitter_line(a, b, seed_v * 7 + i, amp))
	return edges


static func ellipse_pts(center: Vector2, rx: float, ry: float, seed_v: int, amp: float = 1.2, turns: float = 1.0, n: int = 28) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var start: float = rnd(seed_v, 1) * TAU
	var steps: int = int(n * turns)
	for i in range(steps + 1):
		var a: float = start + TAU * turns * float(i) / float(n)
		var k: float = 1.0 + rnd_s(seed_v, i + 3) * amp / maxf(rx, 1.0)
		out.append(center + Vector2(cos(a) * rx, sin(a) * ry) * k)
	return out


## Segmentos de hachurado (pares de puntos) dentro de un polígono. angle en radianes.
static func hatch_segments(poly: PackedVector2Array, spacing: float, angle: float, seed_v: int = 0) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	if poly.size() < 3:
		return out
	var rot: Transform2D = Transform2D(-angle, Vector2.ZERO)
	var inv: Transform2D = Transform2D(angle, Vector2.ZERO)
	var rp: PackedVector2Array = PackedVector2Array()
	var miny: float = INF
	var maxy: float = -INF
	for p in poly:
		var q: Vector2 = rot * p
		rp.append(q)
		miny = minf(miny, q.y)
		maxy = maxf(maxy, q.y)
	var y: float = miny + spacing * 0.5
	var idx: int = 0
	while y < maxy:
		var xs: Array = []
		for i in range(rp.size()):
			var a: Vector2 = rp[i]
			var b: Vector2 = rp[(i + 1) % rp.size()]
			if (a.y <= y and b.y > y) or (b.y <= y and a.y > y):
				xs.append(a.x + (y - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		var k: int = 0
		while k + 1 < xs.size():
			var j: float = rnd_s(seed_v, idx * 2 + k) * 1.5
			var p1: Vector2 = inv * Vector2(float(xs[k]) + 1.5, y + j)
			var p2: Vector2 = inv * Vector2(float(xs[k + 1]) - 1.5, y - j)
			if p1.distance_to(p2) > 2.0:
				out.append(p1)
				out.append(p2)
			k += 2
		y += spacing
		idx += 1
	return out


# ---------------------------------------------------------------------
#  Primitivas de dibujo sobre un CanvasItem (llamar dentro de _draw)
# ---------------------------------------------------------------------
static func line(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float, seed_v: int, amp: float = 1.2) -> void:
	ci.draw_polyline(jitter_line(a, b, seed_v, amp), col, w, true)
	ci.draw_polyline(jitter_line(a + Vector2(0.9, 0.7), b + Vector2(-0.6, 1.0), seed_v + 101, amp), Color(col, col.a * 0.5), w * 0.55, true)


static func polyline(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float, seed_v: int, amp: float = 1.0) -> void:
	if pts.size() < 2:
		return
	var rough: PackedVector2Array = PackedVector2Array()
	for i in range(pts.size()):
		rough.append(pts[i] + Vector2(rnd_s(seed_v, i * 2), rnd_s(seed_v, i * 2 + 1)) * amp)
	ci.draw_polyline(rough, col, w, true)
	var second: PackedVector2Array = PackedVector2Array()
	for i in range(pts.size()):
		second.append(pts[i] + Vector2(rnd_s(seed_v + 31, i * 2), rnd_s(seed_v + 31, i * 2 + 1)) * amp + Vector2(0.8, 0.8))
	ci.draw_polyline(second, Color(col, col.a * 0.5), w * 0.55, true)


## Contorno cerrado de un polígono con doble trazo y, opcionalmente, relleno hachurado.
static func polygon(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float, seed_v: int, fill: bool = false, fill_col: Color = Color(0, 0, 0, 0), spacing: float = 6.0, amp: float = 1.0) -> void:
	if pts.size() < 3:
		return
	if fill:
		var fc: Color = fill_col if fill_col.a > 0.0 else Color(col, col.a * 0.55)
		var segs: PackedVector2Array = hatch_segments(pts, spacing, -0.7, seed_v)
		if segs.size() >= 2:
			ci.draw_multiline(segs, fc, maxf(1.2, w * 0.45), true)
	var closed: PackedVector2Array = pts.duplicate()
	closed.append(pts[0])
	polyline(ci, closed, col, w, seed_v, amp)


static func circle(ci: CanvasItem, c: Vector2, r: float, col: Color, w: float, seed_v: int, fill: bool = false, spacing: float = 5.0, rx_scale: float = 1.0) -> void:
	var pts: PackedVector2Array = ellipse_pts(c, r * rx_scale, r, seed_v, 1.1, 1.08)
	if fill:
		var base: PackedVector2Array = ellipse_pts(c, r * rx_scale, r, seed_v, 0.0, 1.0)
		var segs: PackedVector2Array = hatch_segments(base, spacing, -0.7, seed_v)
		if segs.size() >= 2:
			ci.draw_multiline(segs, Color(col, col.a * 0.55), maxf(1.2, w * 0.45), true)
	ci.draw_polyline(pts, col, w, true)
	var pts2: PackedVector2Array = ellipse_pts(c + Vector2(0.8, 0.6), r * rx_scale, r, seed_v + 13, 1.1, 1.0)
	ci.draw_polyline(pts2, Color(col, col.a * 0.5), w * 0.55, true)


# ---------------------------------------------------------------------
#  Texto que se escribe letra a letra
# ---------------------------------------------------------------------
static func text_width(font: Font, text: String, size: int, tight: float = 1.0) -> float:
	var x: float = 0.0
	for i in range(text.length()):
		x += font.get_string_size(text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * tight
	return x


## Dibuja `text` con la base en `pos`; solo la fracción `progress` (0..1) ya está escrita.
## `tilt` torcido por letra (radianes), `tight` apretado del espaciado. Devuelve el ancho total.
static func draw_written(ci: CanvasItem, font: Font, text: String, pos: Vector2, size: int, col: Color, progress: float = 1.0, seed_v: int = 1, tilt: float = 0.0, tight: float = 1.0) -> float:
	var x: float = 0.0
	var n: int = text.length()
	var shown: float = progress * float(n)
	for i in range(n):
		var ch: String = text[i]
		var adv: float = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * tight
		if float(i) < shown:
			var a: float = clampf(shown - float(i), 0.0, 1.0)
			var rot: float = rnd_s(seed_v, i) * tilt
			var dy: float = rnd_s(seed_v, i + 99) * tilt * float(size) * 0.45
			ci.draw_set_transform(pos + Vector2(x, dy), rot, Vector2.ONE)
			ci.draw_string(font, Vector2.ZERO, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(col, col.a * a))
		x += adv
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return x


# ---------------------------------------------------------------------
#  Animaciones rebotonas
# ---------------------------------------------------------------------
static func pop(node: Control, amount: float = 1.25, duration: float = 0.45) -> void:
	if node == null or not node.is_inside_tree():
		return
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2(amount, amount)
	var tw: Tween = node.create_tween()
	tw.tween_property(node, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


static func wobble(node: Control, angle: float = 0.08, duration: float = 0.5) -> void:
	if node == null or not node.is_inside_tree():
		return
	node.pivot_offset = node.size / 2.0
	node.rotation = angle
	var tw: Tween = node.create_tween()
	tw.tween_property(node, "rotation", 0.0, duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
