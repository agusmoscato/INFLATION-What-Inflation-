class_name PackOpening
extends Control
## Apertura de un sobre de figuritas: se rasga arrastrando el mouse por el borde, las figuritas salen de a una
## dándose vuelta, con sonido; las doradas disparan una lluvia de tiza y las repetidas llevan el sello "¡REPE!".

signal finished

enum State { TEAR, REVEAL, DONE }

var results: Array = []
var state: int = State.TEAR
var tear: float = 0.0            ## 0..1 cuánto se rasgó el sobre
var _t: float = 0.0
var _env: Rect2
var _cards: Array = []           ## [{holder, view, back, result, shown}]
var _next_card: int = 0
var _reveal_timer: float = 0.0
var _strip_gone: float = 0.0
var _dragging: bool = false
var _skip: Button
var _done_btn: Button
var _hint: Label
var _fx: Control
var _auto: bool = false
var _auto_tween: Tween


func _init(res: Array = []) -> void:
	results = res
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vp: Vector2 = get_viewport_rect().size
	_env = Rect2(vp.x / 2.0 - 220.0, vp.y / 2.0 - 150.0, 440.0, 300.0)
	_fx = Control.new()
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_fx)
	_hint = UIKit.label(tr("ui.pack.tear"), 30, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, true)
	_hint.position = Vector2(0, _env.position.y - 80.0)
	_hint.size = Vector2(vp.x, 50)
	add_child(_hint)
	_skip = Button.new()
	_skip.text = tr("ui.pack.skip")
	UIKit.style_button(_skip, UIKit.C_PANEL2, 16)
	_skip.position = Vector2(vp.x - 180.0, vp.y - 80.0)
	_skip.pressed.connect(_reveal_all)
	add_child(_skip)
	# las 5 figuritas, listas pero ocultas hasta rasgar
	var n: int = results.size()
	var cw: float = 170.0
	var gap: float = 14.0
	var x0: float = (vp.x - (cw * float(n) + gap * float(n - 1))) / 2.0
	for i in range(n):
		var holder: Control = Control.new()
		holder.size = Vector2(cw, 220)
		holder.position = Vector2(x0 + float(i) * (cw + gap), vp.y / 2.0 - 120.0)
		holder.pivot_offset = holder.size / 2.0
		holder.visible = false
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(holder)
		var view: StickerView = StickerView.new(results[i]["id"], 1)
		view.custom_minimum_size = holder.size
		view.size = holder.size
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(view)
		_cards.append({"holder": holder, "view": view, "result": results[i], "shown": false})
	_done_btn = Button.new()
	_done_btn.text = tr("ui.pack.done")
	_done_btn.custom_minimum_size = Vector2(220, 56)
	UIKit.style_button(_done_btn, UIKit.C_GREEN.darkened(0.2), 22)
	_done_btn.position = Vector2(vp.x / 2.0 - 110.0, vp.y / 2.0 + 160.0)
	_done_btn.visible = false
	_done_btn.pressed.connect(func() -> void: finished.emit())
	add_child(_done_btn)


## Para clips y pruebas: rasga el sobre solo (simula el arrastre del mouse).
func auto_open(duration: float = 0.9) -> void:
	_auto = true
	if _auto_tween != null and _auto_tween.is_valid():
		_auto_tween.kill()
	_auto_tween = create_tween()
	_auto_tween.tween_method(func(v: float) -> void: _set_tear(v), 0.0, 1.0, duration)


func _gui_input(event: InputEvent) -> void:
	if state != State.TEAR:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed and _near_strip(event.position)
		if event.pressed and _dragging:
			_set_tear(clampf((event.position.x - _env.position.x) / _env.size.x, 0.0, 1.0))
	elif event is InputEventMouseMotion and _dragging:
		if _near_strip(event.position):
			_set_tear(maxf(tear, clampf((event.position.x - _env.position.x) / _env.size.x, 0.0, 1.0)))


func _near_strip(p: Vector2) -> bool:
	return absf(p.y - (_env.position.y + 56.0)) < 46.0 and p.x > _env.position.x - 30.0 and p.x < _env.end.x + 30.0


func _set_tear(v: float) -> void:
	var before: float = tear
	tear = maxf(tear, v)
	if int(tear * 12.0) != int(before * 12.0):
		_play("scratch")
		_chalk_bits(Vector2(_env.position.x + _env.size.x * tear, _env.position.y + 56.0), 3)
	if tear >= 0.97 and state == State.TEAR:
		state = State.REVEAL
		_play("rip")
		_hint.visible = false
		_chalk_bits(Vector2(_env.get_center().x, _env.position.y + 56.0), 24)
		_reveal_timer = 0.55


func _process(delta: float) -> void:
	_t += delta
	if state == State.REVEAL:
		_strip_gone = minf(1.0, _strip_gone + delta * 2.2)
		_reveal_timer -= delta
		if _reveal_timer <= 0.0 and _next_card < _cards.size():
			_flip(_next_card)
			_next_card += 1
			_reveal_timer = 0.75
		if _next_card >= _cards.size() and not _done_btn.visible and _reveal_timer < -0.2:
			state = State.DONE
			_done_btn.visible = true
			_skip.visible = false
			Chalk.pop(_done_btn, 1.2, 0.5)
	queue_redraw()


func _flip(i: int) -> void:
	var c: Dictionary = _cards[i]
	if bool(c["shown"]):
		return
	c["shown"] = true
	var holder: Control = c["holder"]
	var r: Dictionary = c["result"]
	holder.visible = true
	holder.scale = Vector2(0.0, 1.0)
	_play("flip", 0.9 + 0.08 * float(i))
	var tw: Tween = create_tween()
	tw.tween_property(holder, "scale", Vector2(1.12, 1.12), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(holder, "scale", Vector2.ONE, 0.18)
	tw.tween_callback(func() -> void: _after_flip(holder, r))


func _after_flip(holder: Control, r: Dictionary) -> void:
	var center: Vector2 = holder.position + holder.size / 2.0
	if bool(r["golden"]):
		_play("gold")
		_chalk_rain()
		holder.pivot_offset = holder.size / 2.0
		var tw: Tween = create_tween()
		tw.tween_property(holder, "rotation", 0.08, 0.08)
		tw.tween_property(holder, "rotation", -0.08, 0.1)
		tw.tween_property(holder, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_ELASTIC)
		_stamp(center + Vector2(0, -110), tr("ui.pack.golden"), Chalk.YELLOW, 0.0)
	elif bool(r["repe"]):
		_play("stamp")
		_stamp(center + Vector2(0, 20), tr("ui.pack.repe"), Chalk.PINK, -0.28)
	elif bool(r["new"]):
		_stamp(center + Vector2(0, -110), tr("ui.pack.new"), Chalk.GREEN, 0.0)


func _stamp(pos: Vector2, text: String, col: Color, rot: float) -> void:
	var l: Label = UIKit.label(text, 40, col, HORIZONTAL_ALIGNMENT_CENTER, true)
	l.add_theme_color_override("font_outline_color", Color("#1a1a10"))
	l.add_theme_constant_override("outline_size", 8)
	l.size = Vector2(240, 60)
	l.position = pos - l.size / 2.0
	l.pivot_offset = l.size / 2.0
	l.rotation = rot
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	l.scale = Vector2(2.4, 2.4)
	l.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.05)
	tw.parallel().tween_property(l, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _reveal_all() -> void:
	if state == State.TEAR:
		tear = 1.0
		state = State.REVEAL
		_play("rip")
		_hint.visible = false
	for i in range(_cards.size()):
		if not bool(_cards[i]["shown"]):
			_cards[i]["shown"] = true
			var holder: Control = _cards[i]["holder"]
			holder.visible = true
			holder.scale = Vector2.ONE
			_after_flip(holder, _cards[i]["result"])
	_next_card = _cards.size()
	_reveal_timer = -1.0


## Lluvia de tiza para las doradas.
func _chalk_rain() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var p: CPUParticles2D = CPUParticles2D.new()
	p.position = Vector2(vp.x / 2.0, -10.0)
	p.emitting = true
	p.one_shot = true
	p.amount = Settings.particles(140)
	p.lifetime = 2.2
	p.explosiveness = 0.35
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp.x / 2.0, 6.0)
	p.direction = Vector2(0, 1)
	p.spread = 12.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 360.0
	p.gravity = Vector2(0, 260)
	p.angular_velocity_min = -300.0
	p.angular_velocity_max = 300.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 8.0
	p.color = Color(1, 0.95, 0.6)
	_fx.add_child(p)
	get_tree().create_timer(3.2).timeout.connect(p.queue_free)


func _chalk_bits(pos: Vector2, amount: int) -> void:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.position = pos
	p.emitting = true
	p.one_shot = true
	p.amount = Settings.particles(amount)
	p.lifetime = 0.7
	p.explosiveness = 0.9
	p.direction = Vector2(0, -1)
	p.spread = 90.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 220.0
	p.gravity = Vector2(0, 600)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	p.color = Chalk.WHITE
	_fx.add_child(p)
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _play(sound: String, pitch: float = 1.0) -> void:
	if SoundFx.instance != null:
		SoundFx.instance.play(sound, pitch)


func _draw() -> void:
	var vp: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.78))
	if state == State.TEAR or _strip_gone < 1.0:
		_draw_envelope()


func _draw_envelope() -> void:
	var r: Rect2 = _env
	var wob: float = sin(_t * 3.0) * 0.012 if state == State.TEAR else 0.0
	draw_set_transform(r.get_center(), wob, Vector2.ONE)
	var rr: Rect2 = Rect2(-r.size / 2.0, r.size)
	var fade: float = 1.0 - _strip_gone
	var body_col: Color = Color(Chalk.YELLOW, 0.95 * fade)
	# cuerpo del sobre
	var body: PackedVector2Array = PackedVector2Array([rr.position + Vector2(0, 56), rr.position + Vector2(rr.size.x, 56), rr.end, rr.position + Vector2(0, rr.size.y)])
	draw_colored_polygon(body, Color(0.1, 0.16, 0.1, 0.9 * fade))
	Chalk.polygon(self, body, body_col, 4.0, 5, true, Color(Chalk.ORANGE, 0.35 * fade), 9.0, 1.4)
	# el nombre del kiosco
	var f: Font = Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font
	draw_string(f, rr.position + Vector2(0, 150), "FIGURITAS", HORIZONTAL_ALIGNMENT_CENTER, rr.size.x, 48, Color(Chalk.YELLOW, fade))
	draw_string(f, rr.position + Vector2(0, 200), "DEL BARRIO", HORIZONTAL_ALIGNMENT_CENTER, rr.size.x, 34, Color(Chalk.WHITE, fade))
	for k in range(5):
		Chalk.circle(self, rr.position + Vector2(60.0 + 80.0 * float(k), 245), 14, Chalk.PINK if k % 2 == 0 else Chalk.BLUE, 2.4, 10 + k, true, 5.0)
	# solapa superior: la parte rasgada se aparta
	var flap_off: float = _strip_gone * 600.0
	var flap_rot: float = _strip_gone * -0.5
	draw_set_transform(r.get_center() + Vector2(flap_off * 0.3, -flap_off), wob + flap_rot, Vector2.ONE)
	var flap: PackedVector2Array = PackedVector2Array([rr.position, rr.position + Vector2(rr.size.x, 0), rr.position + Vector2(rr.size.x, 56), rr.position + Vector2(0, 56)])
	draw_colored_polygon(flap, Color(0.12, 0.2, 0.12, 0.95 * fade))
	Chalk.polygon(self, flap, body_col, 4.0, 9, true, Color(Chalk.ORANGE, 0.3 * fade), 9.0, 1.2)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# línea de rasgado: punteada hasta donde se rasgó, trazo grueso donde ya se abrió
	if state == State.TEAR:
		var y: float = r.position.y + 56.0
		var x_end: float = r.position.x + r.size.x * tear
		var x: float = r.position.x
		while x < r.end.x:
			var seg_end: float = minf(x + 14.0, r.end.x)
			if x < x_end:
				draw_line(Vector2(x, y + sin(x * 0.4) * 3.0), Vector2(seg_end, y + sin(seg_end * 0.4) * 3.0), Chalk.WHITE, 5.0, true)
			else:
				draw_line(Vector2(x, y), Vector2(seg_end, y), Color(Chalk.WHITE, 0.4), 2.0, true)
			x += 26.0
		# manito de tiza que arrastra
		var hx: float = x_end + sin(_t * 8.0) * 4.0
		draw_circle(Vector2(hx, y), 10.0, Color(Chalk.YELLOW, 0.8))
