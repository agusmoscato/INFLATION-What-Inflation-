class_name UnlockSign
extends Control
## Cartel de tiza animado que anuncia una mecánica nueva (1-2 líneas) con una flecha a su pestaña.

var _panel: PanelContainer
var _target: Control
var _life: float = 0.0
var _arrow_from: Vector2
var _arrow_to: Vector2
var _t: float = 0.0
var _tw: Tween
var _closing: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## feature: id de la mecánica; target: control a señalar (la pestaña).
func show_for(feature: String, target: Control) -> void:
	_target = target
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = PanelContainer.new()
	var st: ChalkStyle = UIKit.chalk_box(Chalk.YELLOW, Color(0.08, 0.14, 0.1, 0.95), 3.0)
	st.content_margin_left = 20.0
	st.content_margin_right = 20.0
	st.content_margin_top = 12.0
	st.content_margin_bottom = 14.0
	_panel.add_theme_stylebox_override("panel", st)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	_panel.add_child(v)
	v.add_child(UIKit.label(tr("unlock.%s.t" % feature), 34, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, true))
	var d: Label = UIKit.label(tr("unlock.%s.d" % feature), 19, Chalk.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(360, 0)
	v.add_child(d)
	add_child(_panel)
	_panel.add_to_group("attention")      # el QA verifica que nunca haya dos notas o carteles a la vez
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_panel.gui_input.connect(_on_panel_input)
	_panel.reset_size()
	var vp: Vector2 = get_viewport_rect().size
	_panel.position = Vector2((vp.x - _panel.size.x) / 2.0, vp.y * 0.28)
	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2(0.4, 0.4)
	_panel.rotation = -0.08
	_tw = create_tween()
	_tw.tween_property(_panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_tw.parallel().tween_property(_panel, "rotation", 0.0, 0.5)
	_tw.tween_interval(6.0)
	_tw.tween_callback(func() -> void: _panel.remove_from_group("attention"))
	_tw.tween_property(self, "modulate:a", 0.0, 0.4)
	_tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	_t += delta
	if _target != null and is_instance_valid(_target) and _panel != null:
		var r: Rect2 = _target.get_global_rect()
		_arrow_to = r.get_center() + Vector2(0, r.size.y * 0.5 + 6.0 + sin(_t * 7.0) * 5.0)
		_arrow_from = _panel.position + Vector2(_panel.size.x * clampf((r.get_center().x - _panel.position.x) / _panel.size.x, 0.1, 0.9), _panel.size.y)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	pass


func _draw() -> void:
	if _panel == null or _target == null:
		return
	var a: Vector2 = _arrow_from
	var b: Vector2 = _arrow_to
	var mid: Vector2 = (a + b) / 2.0 + Vector2(40, 0)
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(15):
		var t: float = float(i) / 14.0
		pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
	draw_polyline(pts, Chalk.YELLOW, 5.0, true)
	var d: Vector2 = (b - pts[pts.size() - 2]).normalized()
	var n: Vector2 = Vector2(-d.y, d.x)
	draw_line(b, b - d * 22.0 + n * 12.0, Chalk.YELLOW, 5.0, true)
	draw_line(b, b - d * 22.0 - n * 12.0, Chalk.YELLOW, 5.0, true)


## Un clic sobre el cartel lo cierra enseguida (si no, se cierra solo a los 6 s).
func _on_panel_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()


func close() -> void:
	if _closing:
		return
	_closing = true
	if _tw != null and _tw.is_valid():
		_tw.kill()
	_panel.remove_from_group("attention")
	_tw = create_tween()
	_tw.tween_property(self, "modulate:a", 0.0, 0.25)
	_tw.tween_callback(queue_free)
