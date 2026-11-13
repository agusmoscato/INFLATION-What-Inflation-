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
	_note.add_to_group("attention")      # el QA verifica que nunca haya dos notas o flechas a la vez
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


## Lo apaga GameScreen mientras hay un cartel de desbloqueo abierto (nunca dos carteles o notas a la vez).
var suppressed: bool = false
var _step_t: float = 0.0          ## segundos que la nota del paso actual lleva a la vista
var _hand_on: bool = false
var shown_text: String = ""       ## texto actual de la nota (para el QA: ninguna nota puede quedar igual más de 30 s)
const VARIANT_SECONDS: float = 15.0
const HAND_AFTER: float = 12.0


func _process(delta: float) -> void:
	_t += delta
	var m: GameModel = GameState.m
	var step: int = EconomyLogic.tutorial_step(m)
	if step >= STEPS:
		finished.emit(false)
		return
	if step != _step:
		_step = step
		_step_t = 0.0
		shown_text = ""
	var hidden: bool = suppressed or EconomyLogic.tutorial_waiting(m)
	var target: Control = _target_fn.call(step) if _target_fn.is_valid() else null
	if hidden or target == null or not target.is_visible_in_tree():
		_note.visible = false
		_show_arrow = false
		_hand_on = false
		shown_text = ""
		queue_redraw()
		return
	# la orden va cambiando de palabras cada 15 s (nunca la misma más de 30 s) y a los 12 s aparece una manito haciendo clic
	_step_t += delta
	var variant: int = int(_step_t / VARIANT_SECONDS) % 3
	var key: String = "tut.%d%s" % [step + 1, ["", ".b", ".c"][variant]]
	var text: String = tr(key)
	if text != shown_text:
		shown_text = text
		_label.text = text
		_note.reset_size()
		Chalk.pop(_note, 1.12 if variant == 0 else 1.06, 0.4)
	_hand_on = _step_t >= HAND_AFTER
	_note.visible = true
	var r: Rect2 = target.get_global_rect()
	var ns: Vector2 = _note.size
	var vp: Vector2 = get_viewport_rect().size
	var pos: Vector2
	match step:
		0:
			pos = Vector2(r.get_center().x - ns.x / 2.0, r.end.y + 4.0)      # debajo de la empanada: no le tapa la cara
		1, 2:
			pos = Vector2(r.position.x - ns.x - 70.0, r.position.y - ns.y - 24.0)
		3:
			pos = Vector2(r.get_center().x - ns.x / 2.0, r.end.y + 56.0)
		_:
			pos = Vector2(r.get_center().x - ns.x / 2.0, r.position.y - ns.y - 56.0)
	pos.x = clampf(pos.x, 8.0, vp.x - ns.x - 8.0)
	pos.y = clampf(pos.y, 8.0, vp.y - ns.y - 8.0)
	_note.position = pos
	# flecha de la nota al objetivo (cuando aparece la manito, la manito ocupa su lugar: una sola señal)
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
	_hand_pos = tc
	_show_arrow = not _hand_on
	queue_redraw()


var _hand_pos: Vector2 = Vector2.ZERO


func _draw() -> void:
	if _hand_on:
		_draw_hand()
		return
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


## Manito de tiza que hace clic sobre el objetivo: baja, "aprieta" y suelta ondas.
func _draw_hand() -> void:
	var cycle: float = fmod(_t, 1.4) / 1.4
	var press: float = 1.0 - absf(cycle * 2.0 - 1.0)           # 0 -> 1 -> 0
	var tip: Vector2 = _hand_pos + Vector2(10.0, 12.0) + Vector2(0, -26.0 * (1.0 - press))
	var pts: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(0, 38), Vector2(10, 29), Vector2(17, 44), Vector2(25, 40), Vector2(18, 26), Vector2(30, 26)])
	var moved: PackedVector2Array = PackedVector2Array()
	for p in pts:
		moved.append(tip + p)
	draw_colored_polygon(moved, Color(Chalk.WHITE, 0.95))
	var outline: PackedVector2Array = moved.duplicate()
	outline.append(moved[0])
	draw_polyline(outline, Color("#1c1508"), 3.0, true)
	if press > 0.8:
		for k in range(2):
			var rr: float = 14.0 + float(k) * 12.0 + (press - 0.8) * 60.0
			draw_arc(_hand_pos, rr, 0.0, TAU, 28, Color(Chalk.YELLOW, 0.8 - float(k) * 0.3), 3.0, true)
