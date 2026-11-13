class_name BolilleroOverlay
extends Control
## Sorteo de la quiniela con una animación de bolillero en tiza: las bolillas giran en el bombo y salen de a una.

signal closed

var res: Dictionary = {}
var _t: float = 0.0
var _phase: int = 0            # 0 gira, 1 sale la primera bolilla, 2 sale la segunda, 3 resultado
var _phase_t: float = 0.0
var _tick: float = 0.0
var _balls: Array = []
var _drum_c: Vector2
var _close_btn: Button
var _result_label: Label
var _shake: float = 0.0


func _init(result: Dictionary = {}) -> void:
	res = result
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vp: Vector2 = get_viewport_rect().size
	_drum_c = Vector2(vp.x / 2.0, vp.y / 2.0 - 40.0)
	for i in range(18):
		_balls.append({"a": randf() * TAU, "r": randf_range(20.0, 95.0), "w": randf_range(1.4, 3.6), "n": randi() % 10})
	var title: Label = UIKit.label(tr("timba.bolillero.title"), 40, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, true)
	title.position = Vector2(0, 40)
	title.size = Vector2(vp.x, 56)
	add_child(title)
	_result_label = UIKit.label("", 34, Chalk.WHITE, HORIZONTAL_ALIGNMENT_CENTER, true)
	_result_label.position = Vector2(60, vp.y - 170.0)
	_result_label.size = Vector2(vp.x - 120.0, 120)
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_result_label)
	_close_btn = Button.new()
	_close_btn.text = tr("timba.close")
	_close_btn.custom_minimum_size = Vector2(220, 54)
	UIKit.style_button(_close_btn, UIKit.C_GREEN.darkened(0.2), 20)
	_close_btn.position = Vector2(vp.x / 2.0 - 110.0, vp.y - 70.0)
	_close_btn.visible = false
	_close_btn.pressed.connect(func() -> void: closed.emit())
	add_child(_close_btn)


func _process(delta: float) -> void:
	_t += delta
	_phase_t += delta
	_tick -= delta
	if _phase == 0 and _tick <= 0.0:
		_tick = 0.16
		_snd("drum", randf_range(0.8, 1.3))
	if _phase == 0 and _phase_t > 2.2:
		_next_phase()
	elif _phase == 1 and _phase_t > 1.3:
		_next_phase()
	elif _phase == 2 and _phase_t > 1.3:
		_next_phase()
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * 12.0
	else:
		position = Vector2.ZERO
	queue_redraw()


func _next_phase() -> void:
	_phase += 1
	_phase_t = 0.0
	if _phase == 1 or _phase == 2:
		_snd("flip")
		_snd("drum", 1.6)
	if _phase == 3:
		_show_result()


func _show_result() -> void:
	var kind: String = str(res.get("kind", "none"))
	var payout: String = "$" + (res["payout"] as BigNumber).format() if res.has("payout") else ""
	match kind:
		"exact":
			_result_label.text = tr("timba.q.exact") % payout
			_result_label.add_theme_color_override("font_color", Chalk.YELLOW)
			_snd("jackpot")
			_shake = 0.8
			_rain()
		"last":
			_result_label.text = tr("timba.q.last") % payout
			_result_label.add_theme_color_override("font_color", Chalk.GREEN)
			_snd("coin")
		_:
			_result_label.text = tr("timba.q.none") % [int(res.get("winning", 0)), int(res.get("number", 0))]
			_result_label.add_theme_color_override("font_color", Color(Chalk.WHITE, 0.8))
			_snd("lose")
	_close_btn.visible = true
	Chalk.pop(_result_label, 1.15, 0.5)


func _rain() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var p: CPUParticles2D = CPUParticles2D.new()
	p.position = Vector2(vp.x / 2.0, -10.0)
	p.emitting = true
	p.one_shot = true
	p.amount = Settings.particles(200)
	p.lifetime = 2.4
	p.explosiveness = 0.3
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp.x / 2.0, 6.0)
	p.direction = Vector2(0, 1)
	p.spread = 12.0
	p.initial_velocity_min = 140.0
	p.initial_velocity_max = 380.0
	p.gravity = Vector2(0, 280)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 9.0
	p.color = Color(1, 0.93, 0.5)
	add_child(p)
	get_tree().create_timer(3.4).timeout.connect(p.queue_free)


func _snd(name: String, pitch: float = 1.0) -> void:
	if SoundFx.instance != null:
		SoundFx.instance.play(name, pitch)


func _draw() -> void:
	var vp: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.84))
	var f: Font = Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font
	# bombo
	var spin: float = _t * (6.0 if _phase == 0 else 1.2)
	Chalk.circle(self, _drum_c, 130.0, Chalk.WHITE, 5.0, 3)
	Chalk.circle(self, _drum_c, 118.0, Color(Chalk.WHITE, 0.4), 2.0, 5)
	for k in range(6):
		var a: float = spin * 0.3 + TAU * float(k) / 6.0
		draw_line(_drum_c + Vector2(cos(a), sin(a)) * 118.0, _drum_c + Vector2(cos(a), sin(a)) * 130.0, Chalk.WHITE, 4.0, true)
	for b in _balls:
		var a2: float = float(b["a"]) + spin * float(b["w"]) * 0.4
		var p: Vector2 = _drum_c + Vector2(cos(a2), sin(a2)) * float(b["r"])
		draw_circle(p, 15.0, Color(Chalk.PINK, 0.85) if int(b["n"]) % 2 == 0 else Color(Chalk.BLUE, 0.85))
		draw_string(f, p + Vector2(-7, 7), str(b["n"]), HORIZONTAL_ALIGNMENT_CENTER, 14, 18, Color("#26302B"))
	# patas del bombo y bandeja
	Chalk.line(self, _drum_c + Vector2(-90, 125), _drum_c + Vector2(-120, 190), Chalk.WHITE, 5.0, 8)
	Chalk.line(self, _drum_c + Vector2(90, 125), _drum_c + Vector2(120, 190), Chalk.WHITE, 5.0, 9)
	# boleta del jugador
	draw_string(f, Vector2(0, vp.y - 210.0), tr("timba.q.ticket") % ("%02d" % int(res.get("number", 0))), HORIZONTAL_ALIGNMENT_CENTER, vp.x, 26, Color(Chalk.WHITE, 0.8))
	# bolillas que salen
	var win: int = int(res.get("winning", 0))
	if _phase >= 1:
		_ball(Vector2(vp.x / 2.0 - 70.0, _drum_c.y + 230.0), win / 10, minf(1.0, _phase_t / 0.5) if _phase == 1 else 1.0)
	if _phase >= 2:
		_ball(Vector2(vp.x / 2.0 + 70.0, _drum_c.y + 230.0), win % 10, minf(1.0, _phase_t / 0.5) if _phase == 2 else 1.0)


func _ball(pos: Vector2, digit: int, k: float) -> void:
	var f: Font = Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font
	var y_off: float = (1.0 - k) * -120.0
	var r: float = 52.0 * (0.6 + 0.4 * k)
	var p: Vector2 = pos + Vector2(0, y_off)
	draw_circle(p, r, Color(Chalk.YELLOW, 0.9))
	Chalk.circle(self, p, r, Chalk.ORANGE, 4.0, 11 + digit)
	draw_string(f, p + Vector2(-r, r * 0.42), str(digit), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, int(r * 1.5), Color("#26302B"))
