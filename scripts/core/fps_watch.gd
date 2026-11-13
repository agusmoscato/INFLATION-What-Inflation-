class_name FpsWatch
extends RefCounted
## Detecta FPS bajos sostenidos (menos de `threshold` durante `seconds`) y avisa una sola vez.

var threshold: float = 45.0
var seconds: float = 5.0
var _low: float = 0.0
var _done: bool = false


func _init(threshold_fps: float = 45.0, hold_seconds: float = 5.0) -> void:
	threshold = threshold_fps
	seconds = hold_seconds


## Llamar cada cuadro con los FPS actuales y el delta. Devuelve true UNA vez cuando hay que sugerir bajar la calidad.
func update(fps: float, delta: float) -> bool:
	if _done:
		return false
	if fps < threshold:
		_low += delta
	else:
		_low = 0.0
	if _low >= seconds:
		_done = true
		return true
	return false
