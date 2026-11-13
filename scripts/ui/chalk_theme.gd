class_name ChalkTheme
extends RefCounted
## Tema global: tipografía a mano y estilos de tiza para los controles estándar.


static func build() -> Theme:
	Chalk.load_fonts()
	var t: Theme = Theme.new()
	if Chalk.hand_font != null:
		t.default_font = Chalk.hand_font
	t.default_font_size = int(20.0 * UIKit.FS)
	for cls in ["Label", "Button", "OptionButton", "CheckBox", "PopupMenu"]:
		t.set_color("font_color", cls, Chalk.WHITE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(Chalk.WHITE, 0.35))
	# botones y desplegables: trazo de tiza
	for cls in ["Button", "OptionButton"]:
		var st: Dictionary = UIKit.chalk_button_styles(Chalk.WHITE)
		for k in st:
			t.set_stylebox(k, cls, st[k])
	# menú desplegable
	var pm: StyleBoxFlat = StyleBoxFlat.new()
	pm.bg_color = Color("#26342b")
	pm.set_border_width_all(2)
	pm.border_color = Chalk.WHITE
	pm.set_content_margin_all(6)
	t.set_stylebox("panel", "PopupMenu", pm)
	var hover: StyleBoxFlat = StyleBoxFlat.new()
	hover.bg_color = Color(Chalk.YELLOW, 0.22)
	t.set_stylebox("hover", "PopupMenu", hover)
	t.set_font_size("font_size", "PopupMenu", int(20.0 * UIKit.FS))
	# slider: línea de tiza
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = Color(Chalk.WHITE, 0.55)
	track.set_content_margin_all(0)
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	t.set_stylebox("slider", "HSlider", track)
	var area: StyleBoxFlat = StyleBoxFlat.new()
	area.bg_color = Color(Chalk.YELLOW, 0.9)
	area.content_margin_top = 2
	area.content_margin_bottom = 2
	t.set_stylebox("grabber_area", "HSlider", area)
	t.set_stylebox("grabber_area_highlight", "HSlider", area)
	# barras de scroll
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(Chalk.WHITE, 0.35)
	sb.set_corner_radius_all(3)
	t.set_stylebox("grabber", "VScrollBar", sb)
	t.set_stylebox("grabber_highlight", "VScrollBar", sb)
	t.set_stylebox("grabber_pressed", "VScrollBar", sb)
	t.set_stylebox("scroll", "VScrollBar", StyleBoxEmpty.new())
	return t
