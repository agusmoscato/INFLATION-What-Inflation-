class_name ChalkTag
extends Control
## Etiqueta escrita en tiza roja y subrayada dos veces (para "ÚLTIMA HORA").

var text: String = ""
var color: Color = Chalk.RED
var font_size: int = 22


func _init(t: String = "") -> void:
	text = t
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	var f: Font = _font()
	var w: float = Chalk.text_width(f, text, font_size)
	custom_minimum_size = Vector2(w + 16.0, float(font_size) + 14.0)


func _font() -> Font:
	return Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font


func _draw() -> void:
	var f: Font = _font()
	var w: float = Chalk.text_width(f, text, font_size)
	var y: float = size.y * 0.5 + float(font_size) * 0.28
	Chalk.draw_written(self, f, text, Vector2(8.0, y), font_size, color, 1.0, 17, 0.03)
	# doble subrayado a mano
	Chalk.line(self, Vector2(4.0, y + 5.0), Vector2(w + 12.0, y + 4.0), color, 2.8, 61, 1.6)
	Chalk.line(self, Vector2(8.0, y + 10.0), Vector2(w + 8.0, y + 10.0), color, 2.4, 62, 1.6)
