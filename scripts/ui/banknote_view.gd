class_name BanknoteView
extends Control
## Billete ficticio dibujado por código. Cada billete del álbum tiene más ceros.

var note_color: Color = Color("#b8c4a0")
var zeros: int = 3
var title: String = ""
var unknown: bool = false
var cut_zeros: int = 0     ## cuántos ceros ya fueron "cortados" (se dibujan tachados/ausentes)


func _init() -> void:
	custom_minimum_size = Vector2(190, 92)


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


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var base: Color = Color("#3a4654") if unknown else note_color
	draw_rect(rect, base)
	draw_rect(rect.grow(-5), base.darkened(0.25), false, 2.0)
	draw_rect(rect.grow(-9), base.darkened(0.1), false, 1.0)
	var font: Font = ThemeDB.fallback_font
	if unknown:
		draw_string(font, Vector2(0, size.y * 0.62), "???", HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, Color(1, 1, 1, 0.35))
		return
	draw_circle(Vector2(size.x * 0.17, size.y * 0.5), size.y * 0.24, base.darkened(0.15))
	draw_circle(Vector2(size.x * 0.17, size.y * 0.5), size.y * 0.16, base.lightened(0.1))
	var shown: int = maxi(0, zeros - cut_zeros)
	var text: String = "$" + denomination(shown)
	var fs: int = 26 if text.length() < 11 else (20 if text.length() < 16 else 15)
	draw_string(font, Vector2(size.x * 0.3, size.y * 0.52), text, HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.66, fs, Color("#1d2a1d"))
	draw_string(font, Vector2(size.x * 0.3, size.y * 0.82), title, HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.66, 12, Color("#2e3d2e"))
