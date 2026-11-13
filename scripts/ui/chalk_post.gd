class_name ChalkPost
extends ColorRect
## Efecto tiza sobre todo lo dibujado (bordes granulados, opacidad irregular, huecos).
## Es una sola pasada de pantalla completa; se puede atenuar con set_strength().

static var instance: ChalkPost

var _mat: ShaderMaterial


func _ready() -> void:
	instance = self
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color.WHITE
	var sh: Shader = load("res://assets/shaders/chalk_post.gdshader")
	if sh != null:
		_mat = ShaderMaterial.new()
		_mat.shader = sh
		material = _mat


func set_strength(v: float) -> void:
	if _mat != null:
		_mat.set_shader_parameter("strength", clampf(v, 0.0, 1.0))
