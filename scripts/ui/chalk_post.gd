class_name ChalkPost
extends ColorRect
## Efecto tiza sobre todo lo dibujado (bordes granulados, opacidad irregular, huecos).
## Es una sola pasada de pantalla completa; set_strength() lo atenúa (p. ej. en la hiperinflación)
## y la opción "Calidad de tiza" fija el máximo (Baja = apagado).

static var instance: ChalkPost

var _mat: ShaderMaterial
var _dyn: float = 1.0


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
	apply_quality()


## v = atenuación dinámica (0..1); se combina con la calidad elegida.
func set_strength(v: float) -> void:
	_dyn = clampf(v, 0.0, 1.0)
	apply_quality()


func apply_quality() -> void:
	var s: float = Settings.post_strength()
	visible = s > 0.0
	if _mat != null:
		_mat.set_shader_parameter("strength", _dyn * s)
