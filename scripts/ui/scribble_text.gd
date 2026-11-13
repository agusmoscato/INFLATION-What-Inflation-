class_name ScribbleText
extends Control
## Texto gigante garabateado: se dibuja rápido, con subrayado y flechas, y después se borra con un manchón.
## Se usa para "¡AUMENTO!".

var text: String = ""
var color: Color = Chalk.RED
var font_size: int = 104
var _write: float = 0.0
var _erase: float = 0.0
var _seed: int = 1
var _tween: Tween
var _active: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_text(t: String, seed_v: int = 1, hold: float = 0.7) -> void:
	text = t
	_seed = seed_v
	_active = true
	_write = 0.0
	_erase = 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	pivot_offset = size / 2.0
	rotation = randf_range(-0.05, 0.05)
	scale = Vector2(1.15, 1.15)
	_tween = create_tween()
	_tween.tween_property(self, "_write", 1.0, 0.32)
	_tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(0.7)
	_tween.tween_property(self, "_erase", 1.0, 0.45)
	_tween.tween_callback(func() -> void:
		_active = false
		queue_redraw())


func _process(_delta: float) -> void:
	if _active:
		queue_redraw()


func _draw() -> void:
	if not _active or text == "":
		return
	var font: Font = Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font
	var tight: float = 0.95
	var w: float = Chalk.text_width(font, text, font_size, tight)
	var x0: float = (size.x - w) * 0.5
	var base: float = size.y * 0.62
	# letras: las que ya borró el trapo no se dibujan
	var n: int = text.length()
	var x: float = 0.0
	for i in range(n):
		var ch: String = text[i]
		var adv: float = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x * tight
		var shown: float = clampf(_write * float(n) - float(i), 0.0, 1.0)
		if shown > 0.0 and float(i) / float(n) >= _erase:
			var rot: float = Chalk.rnd_s(_seed, i) * 0.07
			draw_set_transform(Vector2(x0 + x, base + Chalk.rnd_s(_seed, i + 40) * 6.0), rot, Vector2.ONE)
			draw_string(font, Vector2.ZERO, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(color, shown))
			draw_string_outline(font, Vector2.ZERO, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color(Chalk.WHITE, 0.35 * shown))
		x += adv
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# subrayado doble garabateado y flechitas
	if _erase < 0.5:
		var u: float = clampf(_write * 1.3 - 0.2, 0.0, 1.0)
		if u > 0.0:
			var y1: float = base + 14.0
			var end_x: float = x0 + w * u
			Chalk.line(self, Vector2(x0, y1), Vector2(end_x, y1 + 4.0), Chalk.YELLOW, 6.0, _seed + 3, 3.0)
			Chalk.line(self, Vector2(x0 + 14.0, y1 + 16.0), Vector2(end_x - 20.0, y1 + 14.0), Chalk.YELLOW, 4.0, _seed + 8, 3.0)
		if _write > 0.8:
			var ay: float = base - float(font_size) * 0.4
			for s in [-1.0, 1.0]:
				var ax: float = (x0 - 30.0) if s < 0.0 else (x0 + w + 30.0)
				Chalk.line(self, Vector2(ax, ay - 40.0), Vector2(ax + 24.0 * s * -1.0, ay + 10.0), Chalk.YELLOW, 4.0, _seed + 20 + int(s))
	# manchón del trapo al borrar
	if _erase > 0.0 and _erase < 1.0:
		var sx: float = x0 + w * _erase
		draw_colored_polygon(Chalk.ellipse_pts(Vector2(sx, base - float(font_size) * 0.3), 60.0, float(font_size) * 0.65, _seed + 5, 6.0, 1.0, 18), Color(1, 1, 1, 0.22))
