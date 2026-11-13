class_name UIKit
extends RefCounted
## Utilidades de estilo: toda la UI se arma por código con StyleBoxFlat.

const GAME_NAME: String = "INFLATION? What Inflation?"

const C_BG: Color = Color("#14202b")
const C_PANEL: Color = Color("#1e2f3d")
const C_PANEL2: Color = Color("#27405a")
const C_TEXT: Color = Color("#e8eef2")
const C_DIM: Color = Color("#8fa3b3")
const C_GOLD: Color = Color("#f0c14b")
const C_GREEN: Color = Color("#5cb85c")
const C_RED: Color = Color("#e05d5d")
const C_BLUE: Color = Color("#4a90d9")


static func box(color: Color, radius: int = 8, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	if border_w > 0:
		s.border_color = border
		s.set_border_width_all(border_w)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


static func style_button(b: Button, base: Color, font_size: int = 16) -> void:
	b.add_theme_stylebox_override("normal", box(base, 8))
	b.add_theme_stylebox_override("hover", box(base.lightened(0.15), 8))
	b.add_theme_stylebox_override("pressed", box(base.darkened(0.2), 8))
	b.add_theme_stylebox_override("disabled", box(base.darkened(0.55), 8))
	b.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), 8, C_GOLD, 2))
	b.add_theme_color_override("font_color", C_TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))
	b.add_theme_font_size_override("font_size", font_size)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


static func label(text: String, size: int = 16, color: Color = C_TEXT, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align as HorizontalAlignment
	return l


static func panel(color: Color = C_PANEL, radius: int = 8) -> PanelContainer:
	var p: PanelContainer = PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(color, radius))
	return p


static func money(b: BigNumber) -> String:
	return "$" + b.format()


static func duration(seconds: float) -> String:
	var s: int = int(seconds)
	if s >= 3600:
		return "%d h %d min" % [s / 3600, (s % 3600) / 60]
	if s >= 60:
		return "%d min %d s" % [s / 60, s % 60]
	return "%d s" % s


static func clear_children(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()
