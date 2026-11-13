class_name MenuScreen
extends Control
## Menú principal con el logo hecho por código. Horizontal: logo a la izquierda y botones a la derecha (entra en 1280x720);
## en pantallas verticales todo en una columna.

signal continue_game
signal new_game
signal open_options
signal open_credits
signal quit_game
signal open_howto

var _bills: Array = []
var _note: BanknoteView
var _logo: Label
var _clock: float = 0.0
var _zeros: float = 3.0
var _confirm_btn: Button
var _confirm_t: float = 0.0
var _body: BoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# ceros de tiza flotando de fondo: pocos y muy tenues, para que no compitan con el logo ni los botones
	var bills_layer: Control = Control.new()
	bills_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bills_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bills_layer.set_meta("qa_ignore", true)
	bills_layer.clip_contents = true
	add_child(bills_layer)
	for i in range(6):
		var l: Label = UIKit.label("$" + "0".repeat(randi_range(3, 9)), randi_range(18, 30), Color(0.7, 0.85, 0.65, 0.05))
		l.position = Vector2(randf() * 1200.0, randf() * 700.0)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bills_layer.add_child(l)
		_bills.append({"node": l, "speed": randf_range(10.0, 30.0)})

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	add_child(margin)
	_body = BoxContainer.new()
	_body.add_theme_constant_override("separation", 40)
	_body.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(_body)

	# --- columna del logo ---
	var left: VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 10)
	_body.add_child(left)
	_logo = UIKit.label("INFLATION?", 100, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_logo.add_theme_color_override("font_outline_color", Color("#1c1508"))
	_logo.add_theme_constant_override("outline_size", 10)
	_logo.autowrap_mode = TextServer.AUTOWRAP_OFF
	left.add_child(_logo)
	var sub: Label = UIKit.label("What Inflation?", 44, UIKit.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	sub.add_theme_color_override("font_outline_color", Color("#0d1410"))
	sub.add_theme_constant_override("outline_size", 7)
	left.add_child(sub)
	if DemoMode.is_demo():
		left.add_child(UIKit.label(tr("demo.badge"), 40, Chalk.PINK, HORIZONTAL_ALIGNMENT_CENTER, true))
	var note_row: CenterContainer = CenterContainer.new()
	left.add_child(note_row)
	_note = BanknoteView.new()
	_note.custom_minimum_size = Vector2(380, 130)
	_note.title = "1 EMPANADA"
	_note.zeros = 3
	note_row.add_child(_note)
	left.add_child(UIKit.label("v0.1  -  " + tr("ui.tagline"), 14, UIKit.C_DIM, HORIZONTAL_ALIGNMENT_CENTER))

	# --- columna de botones (con aire entre ellos) ---
	var right: VBoxContainer = VBoxContainer.new()
	right.custom_minimum_size = Vector2(340, 0)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 16)
	_body.add_child(right)
	if SaveSystem.has_save():
		right.add_child(_button(tr("ui.continue"), UIKit.C_GREEN.darkened(0.2), func() -> void: continue_game.emit()))
	_confirm_btn = _button(tr("ui.new_game"), UIKit.C_BLUE, _on_new_pressed)
	right.add_child(_confirm_btn)
	right.add_child(_button(tr("ui.howto"), UIKit.C_PANEL2, func() -> void: open_howto.emit()))
	right.add_child(_button(tr("ui.options"), UIKit.C_PANEL2, func() -> void: open_options.emit()))
	right.add_child(_button(tr("ui.credits"), UIKit.C_PANEL2, func() -> void: open_credits.emit()))
	if not OS.has_feature("web"):
		right.add_child(_button(tr("ui.quit"), UIKit.C_RED.darkened(0.3), func() -> void: quit_game.emit()))
	_update_layout()
	resized.connect(_update_layout)


func _update_layout() -> void:
	# apaisado: dos columnas; vertical (o muy angosto): todo apilado
	_body.vertical = size.x < size.y * 1.15 or size.x < 900.0
	_logo.add_theme_font_size_override("font_size", int((70 if _body.vertical else 100) * UIKit.FS))


func _button(text: String, color: Color, cb: Callable) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 56)
	UIKit.style_button(b, color, 22)
	b.pressed.connect(cb)
	return b


func _on_new_pressed() -> void:
	if SaveSystem.has_save() and _confirm_t <= 0.0:
		_confirm_t = 3.0
		_confirm_btn.text = tr("ui.confirm_new")
		return
	new_game.emit()


func _process(delta: float) -> void:
	_clock += delta
	if _confirm_t > 0.0:
		_confirm_t -= delta
		if _confirm_t <= 0.0:
			_confirm_btn.text = tr("ui.new_game")
	for b in _bills:
		var n: Label = b["node"]
		n.position.y -= float(b["speed"]) * delta
		if n.position.y < -60.0:
			n.position.y = size.y + 20.0
			n.position.x = randf() * maxf(100.0, size.x - 200.0)
	# el billete va sumando ceros hasta no entrar... y se reinicia (a partir de cierto tamaño se abrevia)
	_zeros += delta * 2.5
	if _zeros > 34.0:
		_zeros = 3.0
	_note.zeros = int(_zeros)
	_note.queue_redraw()
	_logo.pivot_offset = _logo.size / 2.0
	_logo.rotation = sin(_clock * 2.0) * 0.012
