class_name FlyingBill
extends Control
## Billete volador (el "golden cookie"): cruza la pantalla ondulando; si lo tocás, premio al azar.

signal caught(bill_id: int)

var bill_id: int = 0
var total: float = 12.0
var _t: float = 0.0
var _from: Vector2
var _to: Vector2
var _amp: float = 40.0
var _note: BanknoteView
var _gone: bool = false


func _init(id: int = 0, seconds: float = 12.0) -> void:
	bill_id = id
	total = seconds
	size = Vector2(150, 72)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	set_meta("qa_ignore", true)
	pivot_offset = size / 2.0


func _ready() -> void:
	_note = BanknoteView.new()
	_note.size = size
	_note.custom_minimum_size = size
	_note.zeros = 3 + (bill_id % 4)
	_note.note_color = Color("#d8e6a8")
	_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_note)
	var area: Vector2 = get_parent().size if get_parent() is Control else get_viewport_rect().size
	var left_to_right: bool = bill_id % 2 == 0
	var y0: float = randf_range(area.y * 0.2, area.y * 0.7)
	var y1: float = clampf(y0 + randf_range(-120.0, 120.0), 80.0, area.y - 120.0)
	_from = Vector2(-170.0 if left_to_right else area.x + 20.0, y0)
	_to = Vector2(area.x + 20.0 if left_to_right else -170.0, y1)
	_amp = randf_range(25.0, 60.0)
	position = _from


func _process(delta: float) -> void:
	if _gone:
		return
	_t += delta
	var k: float = clampf(_t / total, 0.0, 1.0)
	position = _from.lerp(_to, k) + Vector2(0, sin(_t * 2.6) * _amp)
	rotation = sin(_t * 3.1) * 0.25
	scale = Vector2(1.0 + 0.06 * sin(_t * 9.0), 1.0)
	if k >= 1.0:
		vanish(false)


func _gui_input(event: InputEvent) -> void:
	if _gone:
		return
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		accept_event()
		caught.emit(bill_id)
		vanish(true)


## Se va: atrapado (salta y se achica) o perdido (se desvanece).
func vanish(was_caught: bool) -> void:
	if _gone:
		return
	_gone = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw: Tween = create_tween()
	if was_caught:
		tw.tween_property(self, "scale", Vector2(1.5, 1.5), 0.12)
		tw.tween_property(self, "scale", Vector2(0.05, 0.05), 0.25)
	else:
		tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)
