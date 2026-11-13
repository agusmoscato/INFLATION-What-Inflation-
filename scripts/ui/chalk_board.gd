class_name ChalkBoard
extends ColorRect
## Fondo: pizarrón verde oscuro con textura por shader (ruido, polvo y borrones viejos).
## En calidad Baja queda un fondo liso.

static var instance: ChalkBoard

var _mat: ShaderMaterial
var _target: float = 0.0
var _smudge: float = 0.0


func _ready() -> void:
	instance = self
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Chalk.BOARD
	var sh: Shader = load("res://assets/shaders/board.gdshader")
	if sh != null:
		_mat = ShaderMaterial.new()
		_mat.shader = sh
	apply_quality()


func apply_quality() -> void:
	material = _mat if Settings.quality < 2 else null


## 0 = pizarra limpia, 1 = hiperinflación (casi toda manchada).
func set_smudge(v: float) -> void:
	_target = clampf(v, 0.0, 1.0)


func _process(delta: float) -> void:
	_smudge = lerpf(_smudge, _target, clampf(delta * 1.5, 0.0, 1.0))
	if _mat != null and material != null:
		_mat.set_shader_parameter("smudge", _smudge)
