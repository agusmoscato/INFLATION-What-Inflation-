class_name BusinessIcon
extends Control
## Ícono de un negocio: usa assets/icons/<id>.png si existe; si no, el dibujo de tiza por código.

var biz_id: String = ""
var _tex: Texture2D
var _bob: float = 0.0


func _init(id: String = "") -> void:
	biz_id = id
	custom_minimum_size = Vector2(60, 60)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_tex = ChalkIcons.custom_texture(biz_id)
	pivot_offset = size / 2.0
	resized.connect(func() -> void: pivot_offset = size / 2.0)


## Salto cómico cuando se compra una unidad.
func hop() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2(1.25, 0.8), 0.06)
	tw.tween_property(self, "scale", Vector2(0.9, 1.2), 0.1)
	tw.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var r: Rect2 = Rect2(Vector2.ZERO, size)
	if _tex != null:
		draw_texture_rect(_tex, r, false)
		return
	ChalkIcons.draw(self, biz_id, r, 3 + biz_id.length())
