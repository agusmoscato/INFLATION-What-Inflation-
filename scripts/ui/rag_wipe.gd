class_name RagWipe
extends Control
## Trapo caricaturesco que pasa borrando los precios de la pizarra (con manchón y polvo de tiza).

var _t: float = 0.0


func _init() -> void:
	size = Vector2(84, 54)
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size / 2.0
	z_index = 50


func _process(delta: float) -> void:
	_t += delta
	rotation = sin(_t * 26.0) * 0.12
	queue_redraw()


func _draw() -> void:
	var body: PackedVector2Array = PackedVector2Array([
		Vector2(6, 14), Vector2(40, 4), Vector2(78, 12), Vector2(80, 40), Vector2(44, 50), Vector2(10, 42)])
	draw_colored_polygon(body, Color(Chalk.ORANGE, 0.28))
	Chalk.polygon(self, body, Chalk.ORANGE, 3.0, 7, true, Color(Chalk.ORANGE, 0.5), 6.0, 1.2)
	Chalk.line(self, Vector2(22, 12), Vector2(26, 44), Color(Chalk.WHITE, 0.6), 2.0, 3)
	Chalk.line(self, Vector2(52, 8), Vector2(56, 48), Color(Chalk.WHITE, 0.6), 2.0, 5)
	# manchón blanco que va dejando
	draw_colored_polygon(Chalk.ellipse_pts(Vector2(-6, 28), 18.0, 24.0, 3, 4.0, 1.0, 14), Color(1, 1, 1, 0.22))


## Barre las filas (rects globales) una por una. `on_row` se llama al llegar a cada fila (índice).
static func sweep(layer: Control, rects: Array, row_time: float = 0.07, on_row: Callable = Callable()) -> void:
	if rects.is_empty() or layer == null:
		return
	var rag: RagWipe = RagWipe.new()
	layer.add_child(rag)
	var first: Rect2 = rects[0]
	rag.global_position = first.position + Vector2(-60, first.size.y * 0.5 - 27)
	var tw: Tween = rag.create_tween()
	for i in range(rects.size()):
		var r: Rect2 = rects[i]
		var y: float = r.position.y + r.size.y * 0.5 - 27.0
		tw.tween_property(rag, "global_position", Vector2(r.position.x - 40.0, y), row_time * 0.4)
		if on_row.is_valid():
			tw.tween_callback(on_row.bind(i))
		tw.tween_property(rag, "global_position", Vector2(r.end.x - 30.0, y), row_time * 0.9).set_trans(Tween.TRANS_SINE)
	var last: Rect2 = rects[rects.size() - 1]
	tw.tween_property(rag, "global_position", Vector2(last.end.x + 150.0, last.end.y + 60.0), 0.25)
	tw.tween_callback(rag.queue_free)
