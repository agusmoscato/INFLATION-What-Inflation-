class_name PauseMenu
extends Control
## Menú de pausa (Esc o el botón "Pausa"): Continuar, Opciones, ¿Cómo se juega?, Guardar y volver al menú, Salir del juego.
## Al abrirse guarda la partida y pone el árbol de escenas en pausa: se frena TODO (producción, inflación, billetes
## voladores, noticias, temporizadores y animaciones del juego). Solo este menú sigue andando (process_mode ALWAYS).
## Estilo pizarra, con la pantalla de fondo oscurecida.

signal resumed
signal to_menu
signal quit_game

var _panel: CenterContainer
var _sub: Control                 # Opciones o "¿Cómo se juega?" abiertos encima
var _lang_changed: bool = false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_meta("qa_pause", true)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0, 0.02, 0.01, 0.72)          # la pantalla de fondo, oscurecida
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_build()
	SaveSystem.save_game()
	get_tree().paused = true


## true si el idioma cambió desde Opciones (quien la abrió tiene que rearmar la pantalla de juego al continuar).
func language_changed() -> bool:
	return _lang_changed


func _build() -> void:
	if _panel != null:
		_panel.queue_free()
	_panel = CenterContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)
	var p: PanelContainer = PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.chalk_box(Chalk.YELLOW, Color(0.07, 0.12, 0.09, 0.97), 3.0))
	p.custom_minimum_size = Vector2(440, 0)
	_panel.add_child(p)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(UIKit.label(tr("ui.pause.title"), 40, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, true))
	var saved: Label = UIKit.label(tr("ui.pause.saved"), 15, UIKit.C_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(saved)
	for item in [["ui.pause.continue", UIKit.C_GREEN.darkened(0.2), _resume], ["ui.options", UIKit.C_BLUE, _open_options],
			["ui.pause.howto", UIKit.C_PANEL2, _open_howto], ["ui.pause.save_menu", UIKit.C_PANEL2, _save_menu],
			["ui.pause.quit", Chalk.RED.darkened(0.35), _quit]]:
		var b: Button = Button.new()
		b.text = tr(str(item[0]))
		b.custom_minimum_size = Vector2(0, 52)
		UIKit.style_button(b, item[1], 20)
		b.pressed.connect(item[2])
		v.add_child(b)
	Chalk.pop(p, 1.06, 0.25)


func _resume() -> void:
	if _sub != null:
		_close_sub()
		return
	get_tree().paused = false
	resumed.emit()
	queue_free()


func _open_options() -> void:
	var s: OptionsScreen = OptionsScreen.new()
	s.closed.connect(_close_sub)
	s.language_changed.connect(func() -> void:
		_lang_changed = true
		_close_sub()
		_build()
		_open_options())
	_open_sub(s)


func _open_howto() -> void:
	var s: HowToScreen = HowToScreen.new()
	s.closed.connect(_close_sub)
	_open_sub(s)


func _open_sub(s: Control) -> void:
	_close_sub()
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(Chalk.BOARD.darkened(0.3), 0.98)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	bg.add_child(s)
	_sub = bg
	_panel.visible = false


func _close_sub() -> void:
	if _sub != null and is_instance_valid(_sub):
		_sub.queue_free()
	_sub = null
	if _panel != null:
		_panel.visible = true


func _save_menu() -> void:
	SaveSystem.save_game()
	get_tree().paused = false
	to_menu.emit()
	queue_free()


func _quit() -> void:
	SaveSystem.save_game()
	quit_game.emit()
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_resume()
		get_viewport().set_input_as_handled()
