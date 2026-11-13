class_name ChalkStyle
extends StyleBox
## Recuadro dibujado a mano con tiza: polilíneas con jitter estable, doble trazo y una rotación mínima.
## Pressed: trazo grueso y relleno hachurado. Disabled: trazo tenue y salteado (medio borrado).

enum Mode { BOX, UNDERLINE, ELLIPSE, NONE, STRIKE }

var stroke: Color = Chalk.WHITE
var fill: Color = Color(0, 0, 0, 0.14)
var width: float = 2.4
var seed_v: int = 1
var tilt: float = 0.0
var hatch: bool = false
var faded: bool = false
var mode: int = Mode.BOX

var _cache_size: Vector2 = Vector2(-1, -1)
var _edges: Array = []
var _chunks: Array = []
var _second: Array = []
var _fill_poly: PackedVector2Array = PackedVector2Array()
var _hatch: PackedVector2Array = PackedVector2Array()
var _extra: PackedVector2Array = PackedVector2Array()
var _extra2: PackedVector2Array = PackedVector2Array()


func _init() -> void:
	content_margin_left = 12.0
	content_margin_right = 12.0
	content_margin_top = 7.0
	content_margin_bottom = 7.0


func _rebuild(sz: Vector2) -> void:
	_cache_size = sz
	_edges = Chalk.rect_edges(sz, seed_v, 1.3, 3.5)
	_second = Chalk.rect_edges(sz + Vector2(1, 1), seed_v + 17, 1.5, 3.0)
	_fill_poly = PackedVector2Array([_edges[0][0], _edges[1][0], _edges[2][0], _edges[3][0]])
	_hatch = PackedVector2Array()
	if hatch:
		var inner: PackedVector2Array = PackedVector2Array([Vector2(4, 4), Vector2(sz.x - 4, 4), Vector2(sz.x - 4, sz.y - 4), Vector2(4, sz.y - 4)])
		_hatch = Chalk.hatch_segments(inner, 6.0, -0.75, seed_v)
	_chunks = []
	if faded:
		for e in _edges:
			var pts: PackedVector2Array = e
			var i: int = 0
			var k: int = 0
			while i < pts.size() - 1:
				var run: int = 2 + int(Chalk.rnd(seed_v, 500 + k) * 3.0)
				var seg: PackedVector2Array = PackedVector2Array()
				for j in range(i, mini(i + run, pts.size())):
					seg.append(pts[j])
				if Chalk.rnd(seed_v, 600 + k) > 0.38 and seg.size() >= 2:
					_chunks.append(seg)
				i += run + (1 if Chalk.rnd(seed_v, 700 + k) > 0.5 else 0)
				k += 1
	_extra = PackedVector2Array()
	_extra2 = PackedVector2Array()
	if mode == Mode.UNDERLINE:
		_extra = Chalk.jitter_line(Vector2(2, sz.y - 2), Vector2(sz.x - 2, sz.y - 3), seed_v + 5, 2.2, 14.0)
		_extra2 = Chalk.jitter_line(Vector2(6, sz.y + 1), Vector2(sz.x - 8, sz.y), seed_v + 9, 2.0, 14.0)
	elif mode == Mode.STRIKE:
		_extra = Chalk.jitter_line(Vector2(-2, sz.y * 0.5 + 2), Vector2(sz.x + 2, sz.y * 0.5 - 3), seed_v + 5, 2.4, 12.0)
		_extra2 = Chalk.jitter_line(Vector2(4, sz.y * 0.5 + 8), Vector2(sz.x - 6, sz.y * 0.5 + 3), seed_v + 9, 2.2, 12.0)
	elif mode == Mode.ELLIPSE:
		_extra = Chalk.ellipse_pts(sz / 2.0, sz.x / 2.0 + 6.0, sz.y / 2.0 + 3.0, seed_v + 5, 3.0, 1.12)
		_extra2 = Chalk.ellipse_pts(sz / 2.0 + Vector2(1, 1), sz.x / 2.0 + 8.0, sz.y / 2.0 + 5.0, seed_v + 9, 3.0, 1.05)


func _draw(ci: RID, rect: Rect2) -> void:
	if mode == Mode.NONE:
		return
	if rect.size != _cache_size:
		_rebuild(rect.size)
	var c: Vector2 = rect.size / 2.0
	var max_tilt: float = 4.0 / maxf(c.x, 1.0)      # en paneles anchos la rotación no desplaza más de ~4 px
	var xf: Transform2D = Transform2D(0.0, rect.position + c) * Transform2D(clampf(tilt, -max_tilt, max_tilt), Vector2.ZERO) * Transform2D(0.0, -c)
	RenderingServer.canvas_item_add_set_transform(ci, xf)
	var sc: Color = Color(stroke, stroke.a * (0.4 if faded else 0.95))
	var sc2: Color = Color(stroke, sc.a * 0.5)
	if mode == Mode.BOX:
		if fill.a > 0.0:
			RenderingServer.canvas_item_add_polygon(ci, _fill_poly, PackedColorArray([fill]))
		if hatch and _hatch.size() >= 2:
			RenderingServer.canvas_item_add_multiline(ci, _hatch, PackedColorArray([Color(stroke, 0.45)]), 2.2, true)
		var w: float = width * (1.7 if hatch else 1.0)
		if faded:
			for ch in _chunks:
				RenderingServer.canvas_item_add_polyline(ci, ch, PackedColorArray([sc]), w, true)
		else:
			for e in _edges:
				RenderingServer.canvas_item_add_polyline(ci, e, PackedColorArray([sc]), w, true)
			for e2 in _second:
				RenderingServer.canvas_item_add_polyline(ci, e2, PackedColorArray([sc2]), w * 0.55, true)
	else:
		if _extra.size() >= 2:
			RenderingServer.canvas_item_add_polyline(ci, _extra, PackedColorArray([sc]), width * 1.1, true)
		if _extra2.size() >= 2:
			RenderingServer.canvas_item_add_polyline(ci, _extra2, PackedColorArray([sc2]), width * 0.7, true)
	RenderingServer.canvas_item_add_set_transform(ci, Transform2D.IDENTITY)
