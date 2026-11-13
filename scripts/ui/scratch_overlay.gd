class_name ScratchOverlay
extends Control
## Raspadita del kiosco: se raspa con el mouse (polvo de tiza, sonido) y se ve el premio. El resultado ya está aplicado
## en el modelo; esto solo lo revela. Pensado para ser lo más satisfactorio del juego.

signal closed
signal again(pct: float)

const COLS: int = 24
const ROWS: int = 13

var result: Dictionary = {}
var pct: float = 0.05
var _cells: PackedByteArray = PackedByteArray()
var _card: Rect2
var _revealed: int = 0
var _done: bool = false
var _cover: _Cover
var _prize: _Prize
var _title: Label
var _hint: Label
var _again_btn: Button
var _close_btn: Button
var _scratch_t: float = 0.0
var _dust_t: float = 0.0
var _dragging: bool = false
var _t: float = 0.0
var _shake: float = 0.0


class _Cover:
	extends Control
	var owner_overlay: ScratchOverlay

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if owner_overlay == null:
			return
		var cw: float = size.x / float(ScratchOverlay.COLS)
		var ch: float = size.y / float(ScratchOverlay.ROWS)
		var base: Color = Color(0.62, 0.66, 0.62, owner_overlay._cover_alpha())
		var hatch: PackedVector2Array = PackedVector2Array()
		for r in range(ScratchOverlay.ROWS):
			for c in range(ScratchOverlay.COLS):
				if owner_overlay._cells[r * ScratchOverlay.COLS + c] != 0:
					continue
				var x: float = float(c) * cw
				var y: float = float(r) * ch
				var jitter: float = Chalk.rnd(r * 31 + c, 5) * 0.12
				draw_rect(Rect2(x, y, cw + 0.6, ch + 0.6), Color(base.r - jitter, base.g - jitter, base.b - jitter, base.a))
				hatch.append(Vector2(x, y + ch))
				hatch.append(Vector2(x + cw, y))
		if hatch.size() >= 2:
			draw_multiline(hatch, Color(0.9, 0.93, 0.9, owner_overlay._cover_alpha() * 0.5), 1.6)
		var f: Font = Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font
		draw_string(f, Vector2(0, size.y * 0.58), "$ $ $", HORIZONTAL_ALIGNMENT_CENTER, size.x, 80, Color(0.35, 0.4, 0.35, owner_overlay._cover_alpha() * 0.45))


class _Prize:
	extends Control
	var owner_overlay: ScratchOverlay
	var sticker: StickerView

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if owner_overlay == null:
			return
		var res: Dictionary = owner_overlay.result
		var outcome: String = str(res.get("outcome", "nothing"))
		var f: Font = Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font
		var c: Vector2 = size / 2.0
		var amount: String = "$" + (res["prize"] as BigNumber).format() if res.has("prize") else ""
		match outcome:
			"nothing":
				Chalk.circle(self, c + Vector2(0, -20), 56, Chalk.WHITE, 4.0, 3)
				draw_circle(c + Vector2(-20, -34), 5, Chalk.WHITE)
				draw_circle(c + Vector2(20, -34), 5, Chalk.WHITE)
				draw_arc(c + Vector2(0, 8), 22, PI + 0.4, TAU - 0.4, 12, Chalk.WHITE, 4.0, true)
				draw_string(f, Vector2(0, c.y + 92), tr("timba.nothing"), HORIZONTAL_ALIGNMENT_CENTER, size.x, 44, Color(Chalk.WHITE, 0.8))
			"x2", "x10", "pity":
				var big: String = {"x2": "x2", "x10": "x10", "pity": "x1,5"}[outcome]
				draw_string(f, Vector2(0, c.y - 10), big, HORIZONTAL_ALIGNMENT_CENTER, size.x, 110, Chalk.YELLOW if outcome != "x2" else Chalk.GREEN)
				draw_string(f, Vector2(0, c.y + 70), amount, HORIZONTAL_ALIGNMENT_CENTER, size.x, 52, Chalk.WHITE)
				if outcome == "pity":
					draw_string(f, Vector2(0, c.y + 112), tr("timba.pity"), HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, Chalk.PINK)
			"pack":
				draw_string(f, Vector2(0, c.y - 20), tr("timba.pack"), HORIZONTAL_ALIGNMENT_CENTER, size.x, 70, Chalk.PINK)
				Chalk.polygon(self, PackedVector2Array([c + Vector2(-70, 10), c + Vector2(70, 10), c + Vector2(70, 100), c + Vector2(-70, 100)]), Chalk.YELLOW, 4.0, 5, true, Color(Chalk.ORANGE, 0.4), 9.0, 1.4)
				draw_string(f, c + Vector2(-70, 72), "x5", HORIZONTAL_ALIGNMENT_CENTER, 140, 44, Chalk.WHITE)
			"golden":
				draw_string(f, Vector2(0, 66), tr("timba.golden"), HORIZONTAL_ALIGNMENT_CENTER, size.x, 54, Chalk.YELLOW)
			"pozo":
				draw_string(f, Vector2(0, c.y - 30), tr("timba.pozo"), HORIZONTAL_ALIGNMENT_CENTER, size.x, 84, Chalk.YELLOW)
				draw_string(f, Vector2(0, c.y + 50), amount, HORIZONTAL_ALIGNMENT_CENTER, size.x, 64, Chalk.WHITE)
				for k in range(8):
					var a: float = TAU * float(k) / 8.0
					Chalk.line(self, c + Vector2(cos(a), sin(a)) * 150.0, c + Vector2(cos(a), sin(a)) * 190.0, Chalk.YELLOW, 4.0, 20 + k)


func _init(res: Dictionary = {}, percent: float = 0.05) -> void:
	result = res
	pct = percent
	mouse_filter = Control.MOUSE_FILTER_STOP
	_cells.resize(COLS * ROWS)
	_cells.fill(0)


func _cover_alpha() -> float:
	return 1.0 if not _done else clampf(1.0 - _fade, 0.0, 1.0)


var _fade: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vp: Vector2 = get_viewport_rect().size
	_card = Rect2(vp.x / 2.0 - 330.0, vp.y / 2.0 - 190.0, 660.0, 380.0)
	_title = UIKit.label(tr("timba.scratch.title"), 38, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, true)
	_title.position = Vector2(0, _card.position.y - 64.0)
	_title.size = Vector2(vp.x, 50)
	add_child(_title)
	_prize = _Prize.new()
	_prize.owner_overlay = self
	_prize.position = _card.position
	_prize.size = _card.size
	add_child(_prize)
	if str(result.get("outcome", "")) == "golden" and str(result.get("sticker", "")) != "":
		var sv: StickerView = StickerView.new(str(result["sticker"]), 1)
		sv.size = Vector2(190, 240)
		sv.custom_minimum_size = sv.size
		sv.position = Vector2(_card.size.x / 2.0 - 95.0, 96.0)
		sv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_prize.add_child(sv)
	_cover = _Cover.new()
	_cover.owner_overlay = self
	_cover.position = _card.position + Vector2(10, 10)
	_cover.size = _card.size - Vector2(20, 20)
	add_child(_cover)
	_hint = UIKit.label(tr("timba.scratch.hint"), 24, Chalk.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_hint.position = Vector2(0, _card.end.y + 14.0)
	_hint.size = Vector2(vp.x, 36)
	add_child(_hint)
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.position = Vector2(0, _card.end.y + 14.0)
	row.size = Vector2(vp.x, 56)
	row.visible = false
	add_child(row)
	_again_btn = Button.new()
	_again_btn.text = tr("timba.again") % ("$" + (result["price"] as BigNumber).format()) if result.has("price") else tr("timba.again") % ""
	_again_btn.custom_minimum_size = Vector2(300, 54)
	UIKit.style_button(_again_btn, UIKit.C_GREEN.darkened(0.2), 20)
	_again_btn.pressed.connect(func() -> void: again.emit(pct))
	row.add_child(_again_btn)
	_close_btn = Button.new()
	_close_btn.text = tr("timba.close")
	_close_btn.custom_minimum_size = Vector2(200, 54)
	UIKit.style_button(_close_btn, UIKit.C_PANEL2, 20)
	_close_btn.pressed.connect(func() -> void: closed.emit())
	row.add_child(_close_btn)
	row.name = "ButtonsRow"


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed:
			_scratch_at(event.position)
	elif event is InputEventMouseMotion and _dragging:
		_scratch_at(event.position)


## Raspa un círculo alrededor de `pos` (coordenadas del overlay).
func _scratch_at(pos: Vector2) -> void:
	var local: Vector2 = pos - _cover.position
	var cw: float = _cover.size.x / float(COLS)
	var ch: float = _cover.size.y / float(ROWS)
	var radius: float = 34.0
	var newly: int = 0
	for r in range(ROWS):
		for c in range(COLS):
			var idx: int = r * COLS + c
			if _cells[idx] != 0:
				continue
			var center: Vector2 = Vector2((float(c) + 0.5) * cw, (float(r) + 0.5) * ch)
			if center.distance_to(local) <= radius:
				_cells[idx] = 1
				newly += 1
	if newly > 0:
		_revealed += newly
		_cover.queue_redraw()
		var now: float = Time.get_ticks_msec() / 1000.0
		if now - _scratch_t > 0.07:
			_scratch_t = now
			if SoundFx.instance != null:
				SoundFx.instance.play("scratch", randf_range(0.85, 1.2))
		if now - _dust_t > 0.04:
			_dust_t = now
			_dust(pos, 3)
		if float(_revealed) / float(COLS * ROWS) >= 0.55:
			_finish()


## Para clips: raspa solo, en zigzag, en `duration` segundos.
func auto_scratch(duration: float = 2.2) -> void:
	var tw: Tween = create_tween()
	tw.tween_method(func(v: float) -> void:
		if _done:
			return
		var x: float = lerpf(_card.position.x + 30.0, _card.end.x - 30.0, fmod(v * 5.0, 1.0))
		if int(v * 5.0) % 2 == 1:
			x = _card.end.x - (x - _card.position.x)
		var y: float = lerpf(_card.position.y + 40.0, _card.end.y - 40.0, v)
		_scratch_at(Vector2(x, y)), 0.0, 1.0, duration)


func _dust(pos: Vector2, amount: int) -> void:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.position = pos
	p.emitting = true
	p.one_shot = true
	p.amount = Settings.particles(amount * 3)
	p.lifetime = 0.6
	p.explosiveness = 0.9
	p.direction = Vector2(0, -1)
	p.spread = 140.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 190.0
	p.gravity = Vector2(0, 420)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 4.0
	p.color = Color(0.85, 0.9, 0.85, 0.85)
	add_child(p)
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


func _finish() -> void:
	if _done:
		return
	_done = true
	_hint.visible = false
	var tw: Tween = create_tween()
	tw.tween_property(self, "_fade", 1.0, 0.35)
	tw.tween_callback(func() -> void: get_node("ButtonsRow").visible = true)
	var outcome: String = str(result.get("outcome", "nothing"))
	match outcome:
		"nothing":
			_snd("lose")
		"x2", "pity":
			_snd("coin")
			_coins(6)
		"x10":
			_snd("win")
			_coins(14)
			_shake = 0.5
		"pack":
			_snd("buy")
			_coins(8)
		"golden":
			_snd("gold")
			_rain(160)
			_shake = 0.5
		"pozo":
			_snd("jackpot")
			_rain(240)
			_coins(40)
			_shake = 1.0
	if _shake > 0.0 and _prize != null:
		pass


func _snd(name: String) -> void:
	if SoundFx.instance != null:
		SoundFx.instance.play(name)


func _coins(n: int) -> void:
	_dust(_card.get_center(), n)


func _rain(amount: int) -> void:
	var vp: Vector2 = get_viewport_rect().size
	var p: CPUParticles2D = CPUParticles2D.new()
	p.position = Vector2(vp.x / 2.0, -10.0)
	p.emitting = true
	p.one_shot = true
	p.amount = Settings.particles(amount)
	p.lifetime = 2.4
	p.explosiveness = 0.3
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp.x / 2.0, 6.0)
	p.direction = Vector2(0, 1)
	p.spread = 12.0
	p.initial_velocity_min = 140.0
	p.initial_velocity_max = 380.0
	p.gravity = Vector2(0, 280)
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 9.0
	p.color = Color(1, 0.93, 0.5)
	add_child(p)
	get_tree().create_timer(3.4).timeout.connect(p.queue_free)


func _process(delta: float) -> void:
	_t += delta
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * 14.0
	else:
		position = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	var vp: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, 0.82))
	# la tarjeta, con borde de tiza
	draw_rect(_card, Color(0.09, 0.15, 0.1, 0.96))
	for e in Chalk.rect_edges(_card.size, 12, 1.8, 4.0):
		var moved: PackedVector2Array = PackedVector2Array()
		for p in e:
			moved.append(p + _card.position)
		draw_polyline(moved, Chalk.YELLOW, 4.0, true)
