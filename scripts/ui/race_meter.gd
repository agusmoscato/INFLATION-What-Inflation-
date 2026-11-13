class_name RaceMeter
extends PanelContainer
## "¿Le ganás a la inflación?": indicador grande y simple. Flecha verde y cartel verde, o flecha roja y cartel rojo.

var winning: bool = true
var _arrow: _Arrow
var _title: Label
var _sub: Label
var _t: float = 0.0


class _Arrow:
	extends Control
	var up: bool = true
	var t: float = 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(64, 64)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var col: Color = Chalk.GREEN if up else Chalk.RED
		var bob: float = sin(t * (4.0 if up else 9.0)) * (3.0 if up else 2.0)
		var c: Vector2 = size / 2.0 + Vector2(0, bob)
		var dir: float = -1.0 if up else 1.0
		var tail: Vector2 = c + Vector2(-20, dir * -18)
		var tip: Vector2 = c + Vector2(20, dir * 18)
		Chalk.line(self, tail, tip, col, 7.0, 3 if up else 4, 1.6)
		Chalk.line(self, tip, tip + Vector2(-20, 2), col, 7.0, 5, 1.2)
		Chalk.line(self, tip, tip + Vector2(0, -dir * 22), col, 7.0, 6, 1.2)


func _init() -> void:
	custom_minimum_size = Vector2(330, 84)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	add_child(h)
	_arrow = _Arrow.new()
	h.add_child(_arrow)
	var v: VBoxContainer = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	h.add_child(v)
	_title = UIKit.label("", 17, Chalk.GREEN, HORIZONTAL_ALIGNMENT_LEFT, true)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_title)
	_sub = UIKit.label("", 13, UIKit.C_DIM)
	_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_sub)
	set_state(true, true)


func set_state(is_winning: bool, force: bool = false) -> void:
	if is_winning == winning and not force:
		return
	winning = is_winning
	var col: Color = Chalk.GREEN if winning else Chalk.RED
	add_theme_stylebox_override("panel", UIKit.chalk_box(col, Color(col, 0.08), 3.0))
	_title.add_theme_color_override("font_color", col)
	_title.text = tr("ui.race.win") if winning else tr("ui.race.lose")
	_arrow.up = winning
	if is_inside_tree():
		Chalk.pop(self, 1.06, 0.4)


func set_numbers(real_now: String, real_ref: String) -> void:
	_sub.text = tr("ui.race.sub") % [real_now, real_ref]
