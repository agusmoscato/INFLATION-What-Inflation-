class_name BarrioView
extends Control
## La "calle del barrio": cada negocio comprado agrega su dibujito de tiza (carritos en fila, kioscos, la parrilla con
## humo...), una fila por tipo como los edificios de Cookie Clicker, con un tope visual por tipo según la calidad de
## tiza. Abajo, la vereda cambia con la capa de la vuelta (tierra, vereda con faroles, ciudad, finanzas, hiperinflación).
## Rendimiento: los dibujos se rehacen solo cuando cambia algo (cantidades o capa); el humo es una capa aparte, liviana.

## Alto fijo: la calle nunca empuja a la empanada. Con muchos tipos de negocio pasa a 3 columnas y las filas se achican.
const HEIGHT: float = 92.0
const ROW_H_MAX: float = 27.0
const CAPS: Array = [7, 6, 4]            ## dibujitos por tipo según la calidad (alta, media, baja)

var _sig: String = ""
var _rows: Array = []                   ## [{id, n}]
var _era: int = 1
var _smoke: Control
var _cols: int = 2
var _row_h: float = ROW_H_MAX


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_meta("qa_ignore", true)
	_smoke = Control.new()
	_smoke.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_smoke.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_smoke.draw.connect(_draw_smoke)
	add_child(_smoke)


func cap() -> int:
	return int(CAPS[clampi(Settings.quality, 0, 2)])


## La llama GameScreen cada frame: solo redibuja si cambió algo.
func refresh(m: GameModel, era: int) -> void:
	var c: int = cap()
	var sig: String = "%d|%d|" % [era, c]
	var rows: Array = []
	for def in GameData.businesses:
		var n: int = m.owned_count(def["id"])
		if n > 0:
			rows.append({"id": def["id"], "n": mini(n, c)})
			sig += "%s:%d," % [def["id"], mini(n, c)]
	custom_minimum_size = Vector2(0, HEIGHT)
	if sig != _sig:
		_sig = sig
		_rows = rows
		_era = era
		_cols = 2 if rows.size() <= 6 else 3
		var lines: int = maxi(1, int(ceil(float(rows.size()) / float(_cols))))
		_row_h = minf(ROW_H_MAX, (HEIGHT - 10.0) / float(lines))
		queue_redraw()
	if Settings.quality < 2 and _has("choripan"):
		_smoke.queue_redraw()


func _has(id: String) -> bool:
	for r in _rows:
		if r["id"] == id:
			return true
	return false


func _cell(i: int) -> Rect2:
	var w: float = size.x / float(_cols)
	return Rect2(Vector2(w * float(i % _cols), 4.0 + _row_h * float(i / _cols)), Vector2(w, _row_h))


func _icon() -> float:
	return _row_h - 2.0


func _draw() -> void:
	if _rows.is_empty():
		return
	_draw_street()
	var c: int = cap()
	var ic: float = _icon()
	for i in range(_rows.size()):
		var r: Rect2 = _cell(i)
		var id: String = _rows[i]["id"]
		var n: int = int(_rows[i]["n"])
		var step: float = minf(ic * 0.98, (r.size.x - ic - 6.0) / float(maxi(1, c - 1)))
		for k in range(n):
			var p: Vector2 = r.position + Vector2(4.0 + step * float(k), 1.0)
			ChalkIcons.draw(self, id, Rect2(p, Vector2(ic, ic)), k * 13 + i)


## La vereda de abajo y los detalles de cada capa (una línea de tiza, faroles, edificios, signos de $, llamas).
func _draw_street() -> void:
	var y: float = size.y - 2.0
	var col: Color = Color(GameData.era_def(_era)["color"], 0.45)
	Chalk.line(self, Vector2(2, y), Vector2(size.x - 2, y), col, 2.0, 7 + _era, 1.0)
	match _era:
		2:
			for x in range(30, int(size.x), 90):
				Chalk.line(self, Vector2(x, y), Vector2(x, y - 12), Color(col, 0.35), 1.6, x, 0.6)
				draw_circle(Vector2(x, y - 13), 2.5, Color(Chalk.YELLOW, 0.35))
		3, 4:
			for x in range(10, int(size.x) - 20, 46):
				var h: float = 8.0 + float((x * 7) % 9)
				Chalk.polygon(self, PackedVector2Array([Vector2(x, y), Vector2(x, y - h), Vector2(x + 18, y - h), Vector2(x + 18, y)]), Color(col, 0.3), 1.4, x)
		5:
			for x in range(12, int(size.x), 40):
				Chalk.polyline(self, PackedVector2Array([Vector2(x, y), Vector2(x + 4, y - 9), Vector2(x + 8, y)]), Color(Chalk.RED, 0.4), 1.6, x)


## Humo de la parrilla (choripán): unas bocanadas que suben, baratas de dibujar.
func _draw_smoke() -> void:
	var t: float = float(Time.get_ticks_msec()) / 1000.0
	for i in range(_rows.size()):
		if _rows[i]["id"] != "choripan":
			continue
		var r: Rect2 = _cell(i)
		var n: int = int(_rows[i]["n"])
		var ic: float = _icon()
		var step: float = minf(ic * 0.98, (r.size.x - ic - 6.0) / float(maxi(1, cap() - 1)))
		for k in range(0, n, 3):
			var f: float = fmod(t * 0.6 + float(k) * 0.37, 1.0)
			var p: Vector2 = r.position + Vector2(4.0 + step * float(k) + ic * 0.5 + sin(t * 2.0 + k) * 2.0, 2.0 - f * 10.0)
			_smoke.draw_circle(p, 1.5 + f * 2.5, Color(Chalk.WHITE, 0.3 * (1.0 - f)))
