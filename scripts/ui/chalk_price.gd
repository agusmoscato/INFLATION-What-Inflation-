class_name ChalkPrice
extends Control
## Un precio "escrito en la pizarra". Al remarcar, el trapo borra el precio viejo con un manchón y polvo,
## y el nuevo se escribe letra a letra. Con más inflación quedan manchones de precios viejos debajo,
## tachones y números más apretados y torcidos; en la hiperinflación se escribe chiquito, en el borde y con flecha.

var text: String = ""
var color: Color = Chalk.WHITE
var font_size: int = 24
var align_right: bool = true
var seed_v: int = 1
## Tasa de inflación mensual: la actualiza el dueño. Define manchones, torcido y tamaño.
var rate: float = 0.03

var _ghosts: Array = []
var _progress: float = 1.0
var _wipe: float = 0.0
var _strike: float = 0.0
var _old: String = ""
var _target: String = ""
var _busy: bool = false
var _force_anim: int = 0
var _force_delay: float = 0.0
var _tween: Tween


func _init() -> void:
	custom_minimum_size = Vector2(130, 36)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _font() -> Font:
	return Chalk.hand_font if Chalk.hand_font != null else ThemeDB.fallback_font


## anim: 0 = cambio directo, 1 = trapo + reescritura, 2 = tachón + reescritura.
func set_text(t: String, anim: int = 0, delay: float = 0.0) -> void:
	if _force_anim > 0:
		anim = _force_anim
		delay = _force_delay
		_force_anim = 0
	elif t == text and not _busy:
		return
	_target = t
	if _busy:
		return
	if anim == 0 or not is_inside_tree() or text == "":
		text = t
		_progress = 1.0
		queue_redraw()
		return
	_start(anim, delay)


## Pide que el próximo set_text se anime aunque el texto no cambie (lo usa el trapo al remarcar).
func request_rewrite(anim: int, delay: float) -> void:
	_force_anim = anim
	_force_delay = delay


func _start(anim: int, delay: float) -> void:
	_busy = true
	_old = text
	_ghosts.push_front({"text": _old, "off": Vector2(Chalk.rnd_s(seed_v, _ghosts.size() + 1) * 12.0, Chalk.rnd_s(seed_v, _ghosts.size() + 7) * 7.0),
		"rot": Chalk.rnd_s(seed_v, _ghosts.size() + 13) * 0.14})
	if _ghosts.size() > 6:
		_ghosts.pop_back()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	if delay > 0.0:
		_tween.tween_interval(delay)
	if anim == 1:
		_tween.tween_callback(_dust)
		_tween.tween_property(self, "_wipe", 1.0, 0.24)
	else:
		_tween.tween_property(self, "_strike", 1.0, 0.18)
	_tween.tween_callback(func() -> void:
		text = _target
		_old = ""
		_wipe = 0.0
		_strike = 0.0
		_progress = 0.0)
	_tween.tween_property(self, "_progress", 1.0, clampf(0.12 + 0.05 * float(_target.length()), 0.3, 0.75))
	_tween.tween_callback(func() -> void:
		text = _target
		_busy = false
		queue_redraw())


func _dust() -> void:
	if not is_inside_tree():
		return
	var p: CPUParticles2D = CPUParticles2D.new()
	p.position = Vector2(size.x - 40.0, size.y * 0.5) if align_right else Vector2(40.0, size.y * 0.5)
	p.emitting = true
	p.one_shot = true
	p.amount = Settings.particles(9)
	p.lifetime = 0.55
	p.explosiveness = 0.9
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 90.0
	p.gravity = Vector2(0, 120)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(Chalk.WHITE, 0.7)
	add_child(p)
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


func _process(_delta: float) -> void:
	if _busy:
		queue_redraw()


func _draw() -> void:
	var font: Font = _font()
	var hyper: bool = rate > 0.6
	var fs: int = int(font_size * (0.62 if hyper else 1.0))
	var tilt: float = clampf(rate * 0.28, 0.0, 0.16)
	var tight: float = 1.0 - clampf(rate, 0.0, 1.0) * 0.12
	var base_y: float = size.y * 0.5 + float(fs) * 0.32
	var cur: String = text if _old == "" else _old
	var w_main: float = Chalk.text_width(font, text, fs, tight)
	var x0: float = (size.x - w_main - 6.0) if align_right else 6.0
	if hyper:
		x0 = size.x - w_main - 2.0          # pegado al borde
	# manchones de precios viejos (cuanta más inflación, más)
	var shown: int = mini(_ghosts.size(), clampi(int(rate * 9.0), 0, Settings.ghost_cap()))
	for i in range(shown):
		var g: Dictionary = _ghosts[i]
		var gw: float = Chalk.text_width(font, g["text"], fs, tight)
		var gc: Vector2 = Vector2(x0 + gw * 0.5, size.y * 0.5) + g["off"]
		draw_colored_polygon(Chalk.ellipse_pts(gc, gw * 0.62 + 6.0, float(fs) * 0.5, seed_v + i * 3, 3.0, 1.0, 14), Color(1, 1, 1, 0.05))
		draw_set_transform(Vector2(x0, base_y) + g["off"], g["rot"], Vector2.ONE)
		draw_string(font, Vector2.ZERO, g["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(color, 0.2 + 0.05 * float(i % 2)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# flecha de "no entra": en la hiperinflación el número se escribe chiquito al borde
	if hyper:
		var ay: float = size.y * 0.5 - 2.0
		var ax1: float = maxf(2.0, x0 - 46.0)
		var ax2: float = x0 - 6.0
		if ax2 > ax1 + 8.0:
			Chalk.line(self, Vector2(ax1, ay - 6.0), Vector2(ax2, ay), Chalk.PINK, 2.4, seed_v + 4)
			draw_line(Vector2(ax2, ay), Vector2(ax2 - 7.0, ay - 6.0), Chalk.PINK, 2.4, true)
			draw_line(Vector2(ax2, ay), Vector2(ax2 - 8.0, ay + 3.0), Chalk.PINK, 2.4, true)
	if _old != "":
		# texto viejo: se borra con la pasada del trapo (a la derecha de la pasada todavía se lee)
		var ow: float = Chalk.text_width(font, _old, fs, tight)
		var ox: float = (size.x - ow - 6.0) if align_right else 6.0
		if hyper:
			ox = size.x - ow - 2.0
		var cx: float = 0.0
		for i in range(_old.length()):
			var ch: String = _old[i]
			var adv: float = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * tight
			if cx / maxf(ow, 1.0) >= _wipe:
				draw_string(font, Vector2(ox + cx, base_y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(color, 0.95))
			cx += adv
		if _wipe > 0.0:
			var wc: Vector2 = Vector2(ox + ow * _wipe, size.y * 0.5)
			draw_colored_polygon(Chalk.ellipse_pts(wc, 22.0, size.y * 0.55, seed_v + 9, 4.0, 1.0, 16), Color(1, 1, 1, 0.32))
			draw_colored_polygon(Chalk.ellipse_pts(wc - Vector2(ow * _wipe * 0.4, 0), ow * _wipe * 0.5 + 6.0, size.y * 0.42, seed_v + 11, 4.0, 1.0, 16), Color(1, 1, 1, 0.10))
		if _strike > 0.0:
			var pts: PackedVector2Array = PackedVector2Array()
			var steps: int = int(maxf(ow, 20.0) * _strike / 7.0)
			for k in range(steps + 1):
				pts.append(Vector2(ox + float(k) * 7.0, size.y * 0.5 + (7.0 if k % 2 == 0 else -7.0)))
			if pts.size() >= 2:
				draw_polyline(pts, Chalk.PINK, 2.6, true)
		return
	Chalk.draw_written(self, font, text, Vector2(x0, base_y), fs, color, _progress, seed_v, tilt, tight)
