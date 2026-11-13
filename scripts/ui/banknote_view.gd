class_name BanknoteView
extends Control
## Billete ficticio dibujado en tiza. Cada billete del álbum tiene más ceros.

var note_color: Color = Color("#b8c4a0")
var zeros: int = 3
var title: String = ""
var unknown: bool = false
var cut_zeros: int = 0     ## cuántos ceros ya fueron "cortados" (se dibujan fantasma, tras una línea de corte)


func _init() -> void:
	custom_minimum_size = Vector2(190, 92)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


static func denomination(z: int) -> String:
	var digits: String = "1" + "0".repeat(z)
	var out: String = ""
	var sep: String = "." if BigNumber.decimal_comma else ","
	var count: int = 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = sep + out
	return out


func _font() -> Font:
	return Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font


func _draw() -> void:
	var k: float = maxf(1.0, size.y / 92.0)
	var tint: Color = Chalk.nearest(note_color) if not unknown else Chalk.WHITE
	var sc: Color = Color(tint, 0.35 if unknown else 0.95)
	var edges: Array = Chalk.rect_edges(size - Vector2(6, 6), 5 + zeros, 1.6, 4.0)
	for e in edges:
		var pts: PackedVector2Array = e
		var moved: PackedVector2Array = PackedVector2Array()
		for p in pts:
			moved.append(p + Vector2(3, 3))
		draw_polyline(moved, sc, 3.0 * minf(k, 1.6), true)
	var inner: Array = Chalk.rect_edges(size - Vector2(26, 26), 9 + zeros, 1.2, 2.0)
	for e2 in inner:
		var moved2: PackedVector2Array = PackedVector2Array()
		for p2 in e2:
			moved2.append(p2 + Vector2(13, 13))
		draw_polyline(moved2, Color(sc, sc.a * 0.55), 1.8, true)
	var font: Font = _font()
	if unknown:
		var fs0: int = int(34 * k)
		draw_string(font, Vector2(0, size.y * 0.62), "???", HORIZONTAL_ALIGNMENT_CENTER, size.x, fs0, Color(Chalk.WHITE, 0.4))
		return
	# medallón
	var mc: Vector2 = Vector2(size.x * 0.17, size.y * 0.5)
	Chalk.circle(self, mc, size.y * 0.24, tint, 2.6 * minf(k, 1.6), 3 + zeros, true, 6.0 * k)
	Chalk.circle(self, mc, size.y * 0.13, tint, 2.0, 4 + zeros)
	var shown: int = maxi(0, zeros - cut_zeros)
	var text: String = "$" + denomination(shown)
	var base_fs: int = 26 if text.length() < 11 else (20 if text.length() < 16 else 15)
	var fs: int = int(base_fs * k)
	var tx: float = size.x * 0.3
	var avail: float = size.x * 0.66
	var w: float = Chalk.text_width(font, text, fs)
	if w > avail:
		fs = int(float(fs) * avail / w)
		w = Chalk.text_width(font, text, fs)
	Chalk.draw_written(self, font, text, Vector2(tx, size.y * 0.54), fs, Chalk.WHITE, 1.0, 7 + zeros, 0.03)
	if cut_zeros > 0:
		# línea de corte y ceros fantasma
		var cx: float = tx + w + 6.0
		for i in range(0, int(size.y * 0.7), 10):
			draw_line(Vector2(cx, size.y * 0.15 + i), Vector2(cx, size.y * 0.15 + i + 5), Chalk.PINK, 2.4, true)
		var ghost: String = "0".repeat(mini(cut_zeros, 6))
		draw_string(font, Vector2(cx + 6.0, size.y * 0.54), ghost, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs * 0.9), Color(Chalk.PINK, 0.28))
	draw_string(font, Vector2(tx, size.y * 0.84), title, HORIZONTAL_ALIGNMENT_LEFT, avail, int(15.0 * k), Color(Chalk.WHITE, 0.7))
