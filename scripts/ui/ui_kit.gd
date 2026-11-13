class_name UIKit
extends RefCounted
## Utilidades de estilo. Toda la UI es "pizarrón de kiosco": trazos de tiza sobre fondo verde oscuro.

const GAME_NAME: String = "INFLATION? What Inflation?"

## Las tipografías manuscritas son más chicas: se escala todo el texto.
const FS: float = 1.22

## Tamaño mínimo de texto: 15 unidades lógicas = 22 px reales en una ventana de 1080p (la escala del proyecto es 1,5).
const MIN_FONT: int = 15

const C_BG: Color = Chalk.BOARD
const C_PANEL: Color = Color("#274034")
const C_PANEL2: Color = Color("#335444")
const C_TEXT: Color = Chalk.WHITE
const C_DIM: Color = Color("#E6E3D2")      # texto secundario: casi blanco (nunca gris sobre verde oscuro)
const C_GOLD: Color = Chalk.YELLOW
const C_GREEN: Color = Chalk.GREEN
const C_RED: Color = Chalk.RED
const C_BLUE: Color = Chalk.BLUE

static var _style_seed: int = 11


static func _next_seed() -> int:
	_style_seed += 7
	return _style_seed


## Estilo de recuadro de tiza. `soft` = trazo más tenue y fino (filas dentro de otro panel).
static func chalk_box(stroke: Color, fill: Color = Color(0, 0, 0, 0.14), width: float = 2.2, seed_v: int = -1, soft: bool = false) -> ChalkStyle:
	var s: ChalkStyle = ChalkStyle.new()
	s.stroke = Color(stroke, 0.62 if soft else 1.0)
	s.fill = fill
	s.width = width * (0.8 if soft else 1.0)
	s.seed_v = _next_seed() if seed_v < 0 else seed_v
	s.tilt = Chalk.rnd_s(s.seed_v, 3) * 0.032      # entre -1,8° y 1,8°
	return s


## Compatibilidad con el código anterior: `color` decide la tiza (los oscuros dan blanco).
static func box(color: Color, _radius: int = 8, border: Color = Color(0, 0, 0, 0), _border_w: int = 0) -> StyleBox:
	var src: Color = border if border.a > 0.0 else color
	return chalk_box(Chalk.nearest(src), Color(0, 0, 0, 0.14))


static func chalk_button_styles(stroke: Color) -> Dictionary:
	var seed_v: int = _next_seed()
	var normal: ChalkStyle = chalk_box(stroke, Color(0, 0, 0, 0.16), 2.6, seed_v)
	var hover: ChalkStyle = chalk_box(stroke.lerp(Color.WHITE, 0.35), Color(Chalk.YELLOW, 0.10), 3.0, seed_v)
	hover.tilt = normal.tilt * 1.6
	var pressed: ChalkStyle = chalk_box(stroke, Color(stroke, 0.10), 2.6, seed_v)
	pressed.hatch = true
	var disabled: ChalkStyle = chalk_box(stroke, Color(0, 0, 0, 0.05), 2.2, seed_v)
	disabled.faded = true
	var focus: ChalkStyle = chalk_box(Chalk.YELLOW, Color(0, 0, 0, 0), 1.6, seed_v + 3)
	return {"normal": normal, "hover": hover, "pressed": pressed, "disabled": disabled, "focus": focus}


static func style_button(b: Button, base: Color, font_size: int = 16) -> void:
	var st: Dictionary = chalk_button_styles(Chalk.nearest(base))
	for k in st:
		b.add_theme_stylebox_override(k, st[k])
	b.add_theme_color_override("font_color", C_TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Chalk.YELLOW)
	b.add_theme_color_override("font_disabled_color", Color(C_TEXT, 0.72))
	b.add_theme_font_size_override("font_size", maxi(int(font_size * FS), MIN_FONT))
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


## Pestaña: solo la palabra; la activa lleva un círculo/subrayado de tiza.
static func style_tab(b: Button, active: bool, font_size: int = 20) -> void:
	var seed_v: int = 40 + b.get_index() * 5
	var none: ChalkStyle = chalk_box(Chalk.WHITE, Color(0, 0, 0, 0), 2.4, seed_v)
	none.mode = ChalkStyle.Mode.NONE
	var on: ChalkStyle = chalk_box(Chalk.YELLOW, Color(0, 0, 0, 0), 2.6, seed_v)
	on.mode = ChalkStyle.Mode.ELLIPSE
	var under: ChalkStyle = chalk_box(Chalk.WHITE, Color(0, 0, 0, 0), 2.0, seed_v)
	under.mode = ChalkStyle.Mode.UNDERLINE
	under.stroke = Color(Chalk.WHITE, 0.55)
	b.add_theme_stylebox_override("normal", on if active else none)
	b.add_theme_stylebox_override("hover", on if active else under)
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("focus", none)
	b.add_theme_color_override("font_color", Chalk.YELLOW if active else Chalk.WHITE)
	b.add_theme_color_override("font_hover_color", Chalk.YELLOW)
	b.add_theme_color_override("font_pressed_color", Chalk.YELLOW)
	b.add_theme_font_size_override("font_size", maxi(int(font_size * FS), MIN_FONT))
	if Chalk.title_font != null:
		b.add_theme_font_override("font", Chalk.title_font)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


static func label(text: String, size: int = 16, color: Color = C_TEXT, align: int = HORIZONTAL_ALIGNMENT_LEFT, title: bool = false) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", maxi(int(size * (1.0 if title else FS)), MIN_FONT))
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align as HorizontalAlignment
	if title and Chalk.title_font != null:
		l.add_theme_font_override("font", Chalk.title_font)
	return l


static func panel(color: Color = C_PANEL, _radius: int = 8) -> PanelContainer:
	var p: PanelContainer = PanelContainer.new()
	var soft: bool = color == C_PANEL2
	var stroke: Color = Chalk.WHITE if (color == C_PANEL or color == C_PANEL2) else Chalk.nearest(color)
	p.add_theme_stylebox_override("panel", chalk_box(stroke, Color(0, 0, 0, 0.12 if soft else 0.16), 2.3, -1, soft))
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


## Pestaña bloqueada: el nombre tachado y "PRÓXIMAMENTE" debajo.
static func style_tab_locked(b: Button, font_size: int = 20) -> void:
	var seed_v: int = 40 + b.get_index() * 5
	var st: ChalkStyle = chalk_box(Chalk.RED, Color(0, 0, 0, 0), 2.4, seed_v)
	st.mode = ChalkStyle.Mode.NONE
	st.stroke = Color(Chalk.RED, 0.8)
	for k in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(k, st)
	b.add_theme_color_override("font_color", Color(Chalk.WHITE, 0.78))
	b.add_theme_color_override("font_hover_color", Color(Chalk.WHITE, 0.8))
	b.add_theme_color_override("font_disabled_color", Color(Chalk.WHITE, 0.78))
	b.add_theme_font_size_override("font_size", maxi(int(font_size * FS), MIN_FONT))
	if Chalk.title_font != null:
		b.add_theme_font_override("font", Chalk.title_font)
	b.focus_mode = Control.FOCUS_NONE
