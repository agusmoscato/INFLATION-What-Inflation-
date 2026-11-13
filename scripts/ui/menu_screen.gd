class_name MenuScreen
extends Control
## Menú principal con el logo hecho por código.

signal continue_game
signal new_game
signal open_options
signal open_credits
signal quit_game

var _bills: Array = []
var _note: BanknoteView
var _logo: Label
var _clock: float = 0.0
var _zeros: float = 3.0
var _confirm_btn: Button
var _confirm_t: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg: ColorRect = ColorRect.new()
	bg.color = UIKit.C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var bills_layer: Control = Control.new()
	bills_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bills_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bills_layer)
	for i in range(14):
		var l: Label = UIKit.label("$" + "0".repeat(randi_range(3, 12)), randi_range(18, 40), Color(0.5, 0.75, 0.45, 0.12))
		l.position = Vector2(randf() * 1280.0, randf() * 720.0)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bills_layer.add_child(l)
		_bills.append({"node": l, "speed": randf_range(15.0, 60.0)})

	var center: VBoxContainer = VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 6)
	add_child(center)

	# Logo: "INFLATION?" grande arriba, "What Inflation?" más chico abajo
	_logo = UIKit.label("INFLATION?", 120, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_logo.add_theme_color_override("font_outline_color", Color("#3a2a05"))
	_logo.add_theme_constant_override("outline_size", 14)
	center.add_child(_logo)
	var sub: Label = UIKit.label("What Inflation?", 46, UIKit.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	sub.add_theme_color_override("font_outline_color", Color.BLACK)
	sub.add_theme_constant_override("outline_size", 8)
	center.add_child(sub)

	var note_row: CenterContainer = CenterContainer.new()
	center.add_child(note_row)
	_note = BanknoteView.new()
	_note.custom_minimum_size = Vector2(380, 130)
	_note.title = "1 EMPANADA"
	_note.zeros = 3
	note_row.add_child(_note)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	center.add_child(spacer)

	var btns: VBoxContainer = VBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	btns.custom_minimum_size = Vector2(320, 0)
	var holder: CenterContainer = CenterContainer.new()
	holder.add_child(btns)
	center.add_child(holder)
	var has_save: bool = SaveSystem.has_save()
	if has_save:
		btns.add_child(_button(tr("ui.continue"), UIKit.C_GREEN.darkened(0.2), func() -> void: continue_game.emit()))
	_confirm_btn = _button(tr("ui.new_game"), UIKit.C_BLUE, _on_new_pressed)
	btns.add_child(_confirm_btn)
	btns.add_child(_button(tr("ui.options"), UIKit.C_PANEL2, func() -> void: open_options.emit()))
	btns.add_child(_button(tr("ui.credits"), UIKit.C_PANEL2, func() -> void: open_credits.emit()))
	if not OS.has_feature("web"):
		btns.add_child(_button(tr("ui.quit"), UIKit.C_RED.darkened(0.3), func() -> void: quit_game.emit()))
	var ver: Label = UIKit.label("v0.1  -  " + tr("ui.tagline"), 13, UIKit.C_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	center.add_child(ver)


func _button(text: String, color: Color, cb: Callable) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 48)
	UIKit.style_button(b, color, 20)
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
			n.position.y = 740.0
			n.position.x = randf() * 1280.0
	# el billete va sumando ceros hasta no entrar... y se reinicia
	_zeros += delta * 2.5
	if _zeros > 34.0:
		_zeros = 3.0
	_note.zeros = int(_zeros)
	_note.queue_redraw()
	_logo.pivot_offset = _logo.size / 2.0
	_logo.rotation = sin(_clock * 2.0) * 0.012
