class_name TutorialGuide
extends Control
## Tutorial de los primeros 2 minutos: notitas de tiza con una flecha que señala qué tocar.
## Pasos (se deducen del estado de la partida, así que son a prueba de saltos):
##   0 clic en la empanada -> 1 comprar el carrito -> 2 mirar la inflación -> 3 remarcar -> listo.

signal finished(skipped: bool)

const STEPS: int = EconomyLogic.TUTORIAL_STEPS

var _target_fn: Callable            ## (step:int) -> Control a señalar
var _note: PanelContainer
var _label: Label
var _skip: Button
var _step: int = -1
var _t: float = 0.0
var _arrow_from: Vector2 = Vector2.ZERO
var _arrow_to: Vector2 = Vector2.ZERO
var _show_arrow: bool = false




func _init(target_fn: Callable = Callable()) -> void:
	_target_fn = target_fn
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_note = PanelContainer.new()
	_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st: ChalkStyle = UIKit.chalk_box(Chalk.YELLOW, Color(0.1, 0.16, 0.12, 0.92), 2.6)
	st.content_margin_left = 14.0
	st.content_margin_right = 14.0
	st.content_margin_top = 8.0
	st.content_margin_bottom = 8.0
	_note.add_theme_stylebox_override("panel", st)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	_note.add_child(v)
	_label = UIKit.label("", 20, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_CENTER)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(250, 0)
	v.add_child(_label)
	_skip = Button.new()
	_skip.text = tr("tut.skip")
	UIKit.style_button(_skip, UIKit.C_PANEL2, 13)
	_skip.pressed.connect(func() -> void: finished.emit(true))
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(_skip)
	v.add_child(row)
	add_child(_note)


func _process(delta: float) -> void:
	_t += delta
	var step: int = EconomyLogic.tutorial_step(GameState.m)
	if step >= STEPS:
		finished.emit(false)
		return
	if step != _step:
		_step = step
		_label.text = tr("tut.%d" % (step + 1))
		_note.reset_size()
		Chalk.pop(_note, 1.12, 0.4)
	var target: Control = _target_fn.call(step) if _target_fn.is_valid() else null
	if target == null or not target.is_visible_in_tree():
		_note.visible = false
		_show_arrow = false
		queue_redraw()
		return
	_note.visible = true
	var r: Rect2 = target.get_global_rect()
	var ns: Vector2 = _note.size
	var vp: Vector2 = get_viewport_rect().size
	var pos: Vector2
	match step:
		0:
			pos = Vector2(r.get_center().x - ns.x / 2.0, r.position.y - ns.y + 40.0)
		1:
			pos = Vector2(r.position.x - ns.x - 70.0, r.position.y - ns.y - 24.0)
		2:
			pos = Vector2(r.get_center().x - ns.x / 2.0, r.end.y + 56.0)
		_:
			pos = Vector2(r.get_center().x - ns.x / 2.0, r.position.y - ns.y - 56.0)
	pos.x = clampf(pos.x, 8.0, vp.x - ns.x - 8.0)
	pos.y = clampf(pos.y, 8.0, vp.y - ns.y - 8.0)
	_note.position = pos
	# flecha de la nota al objetivo
	var nc: Rect2 = Rect2(pos, ns)
	var tc: Vector2 = r.get_center()
	_arrow_from = Vector2(clampf(tc.x, nc.position.x + 20.0, nc.end.x - 20.0), nc.get_center().y)
	if tc.y > nc.get_center().y:
		_arrow_from.y = nc.end.y
	else:
		_arrow_from.y = nc.position.y
	var bob: float = sin(_t * 6.0) * 5.0
	var dir: Vector2 = (tc - _arrow_from).normalized()
	_arrow_to = tc - dir * (minf(r.size.x, r.size.y) * 0.5 + 8.0) + dir * bob
	_show_arrow = true
	queue_redraw()


func _draw() -> void:
	if not _show_arrow:
		return
	var a: Vector2 = _arrow_from
	var b: Vector2 = _arrow_to
	var mid: Vector2 = (a + b) / 2.0 + Vector2(-(b - a).y, (b - a).x).normalized() * 18.0
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(13):
		var t: float = float(i) / 12.0
		pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
	draw_polyline(pts, Chalk.YELLOW, 4.0, true)
	var d: Vector2 = (b - pts[pts.size() - 2]).normalized()
	var n: Vector2 = Vector2(-d.y, d.x)
	draw_line(b, b - d * 18.0 + n * 10.0, Chalk.YELLOW, 4.0, true)
	draw_line(b, b - d * 18.0 - n * 10.0, Chalk.YELLOW, 4.0, true)
