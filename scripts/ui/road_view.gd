class_name RoadView
extends PanelContainer
## "Camino al final": los 6 sellos (uno por rama) y el centro del árbol.
##  - compacto (en el juego): título, los 6 sellos (rellenos con tilde si los tenés) y una línea con lo próximo o, con
##    los 6, el aviso grande de que ya se puede estabilizar la economía. Tocarlo abre el árbol.
##  - completo (en el árbol): una fila por sello con qué nodo de qué rama lo da y cuánta Credibilidad falta, el centro y
##    el total aproximado.

signal open_tree

var full: bool = false
var _sig: String = ""
var _medals: Array = []
var _line: Label
var _rows: Array = []                 # completo: [Label] uno por sello
var _final_l: Label
var _total_l: Label
var _t: float = 0.0


func _init(full_mode: bool = false) -> void:
	full = full_mode
	add_theme_stylebox_override("panel", UIKit.chalk_box(Chalk.YELLOW, Color(0.06, 0.1, 0.08, 0.92), 2.2))
	mouse_filter = Control.MOUSE_FILTER_STOP if not full else Control.MOUSE_FILTER_PASS
	if not full:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				open_tree.emit())
	_build()


func _build() -> void:
	var title: Label = UIKit.label(tr("ui.road.title"), 17, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT, true)
	var medals: HBoxContainer = HBoxContainer.new()
	medals.add_theme_constant_override("separation", 4)
	for i in range(TreeLogic.SEAL_BRANCHES.size()):
		var md: _Medal = _Medal.new(str(TreeLogic.SEAL_BRANCHES[i]))
		medals.add_child(md)
		_medals.append(md)
	if not full:
		var h: HBoxContainer = HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		add_child(h)
		h.add_child(title)
		h.add_child(medals)
		_line = UIKit.label("", 15, Chalk.WHITE)
		_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_line.custom_minimum_size = Vector2(240, 0)
		_line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(_line)
		return
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	add_child(v)
	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	top.add_child(title)
	top.add_child(medals)
	v.add_child(top)
	for i in range(TreeLogic.SEAL_BRANCHES.size()):
		var l: Label = UIKit.label("", 15, Chalk.WHITE)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(280, 0)
		v.add_child(l)
		_rows.append(l)
	_final_l = UIKit.label("", 15, Chalk.YELLOW)
	_final_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_final_l.custom_minimum_size = Vector2(280, 0)
	v.add_child(_final_l)
	_total_l = UIKit.label("", 15, Chalk.BLUE, HORIZONTAL_ALIGNMENT_LEFT, true)
	_total_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_total_l.custom_minimum_size = Vector2(280, 0)
	v.add_child(_total_l)


func _process(delta: float) -> void:
	_t += delta
	if not full and _line != null:
		var r: Dictionary = TreeLogic.road(GameState.m)
		if bool(r["ready"]):
			_line.modulate = Color.WHITE.lerp(Chalk.YELLOW, 0.5 + 0.5 * sin(_t * 5.0))     # el aviso late
		else:
			_line.modulate = Color.WHITE


## Lo llama quien lo muestra (cada frame): solo rearma los textos si cambió algo.
func refresh(m: GameModel) -> void:
	var r: Dictionary = TreeLogic.road(m)
	var sig: String = "%d|%d|%s|%s" % [m.credibility, int(r["have"]), str(r["final_owned"]), TranslationServer.get_locale()]
	for row in r["seals"]:
		sig += str(row["nodes"]) + ","
	if sig == _sig:
		return
	_sig = sig
	var seals: Array = r["seals"]
	for i in range(seals.size()):
		var row: Dictionary = seals[i]
		var md: _Medal = _medals[i]
		md.owned = bool(row["owned"])
		md.tooltip_text = _seal_text(row)
		md.queue_redraw()
	if not full:
		_line.text = _summary(r, m)
		return
	for i in range(seals.size()):
		var row2: Dictionary = seals[i]
		(_rows[i] as Label).text = _seal_text(row2)
		(_rows[i] as Label).add_theme_color_override("font_color", Chalk.GREEN if bool(row2["owned"]) else Chalk.WHITE)
	if bool(r["final_owned"]):
		_final_l.text = tr("ui.road.done")
	elif bool(r["ready"]):
		_final_l.text = tr("ui.road.ready") % int(r["final_cost"])
	else:
		_final_l.text = tr("ui.road.final") % int(r["final_cost"])
	_total_l.text = tr("ui.road.total") % int(r["need"]) if not bool(r["final_owned"]) else ""
	_total_l.visible = _total_l.text != ""


## "Negocios: Cadena de locales ✔" o "Negocios: Cadena de locales, ~110".
static func _seal_text(row: Dictionary) -> String:
	var name: String = TranslationServer.translate(GameData.node(str(row["id"]))["name_key"])
	var br: String = TranslationServer.translate("ui.branch_s." + str(row["branch"]))
	if bool(row["owned"]):
		return TranslationServer.translate("ui.road.seal_owned") % [br, name]
	return TranslationServer.translate("ui.road.seal_missing") % [br, name, int(row["cost"])]


static func _summary(r: Dictionary, m: GameModel) -> String:
	if bool(r["final_owned"]):
		return TranslationServer.translate("ui.road.done")
	if bool(r["ready"]):
		var left: int = maxi(0, int(r["final_cost"]) - m.credibility)
		if left == 0:
			return TranslationServer.translate("ui.road.ready_now")
		return TranslationServer.translate("ui.road.ready_left") % [int(r["final_cost"]), left]
	var ns: Dictionary = r["next_seal"]
	var name: String = TranslationServer.translate(GameData.node(str(ns["id"]))["name_key"])
	var br: String = TranslationServer.translate("ui.branch." + str(ns["branch"]))
	return TranslationServer.translate("ui.road.next") % [int(r["have"]), name, br, int(r["need"])]


## Un sello: círculo del color de la rama; relleno y con tilde si lo tenés, solo el contorno si falta.
class _Medal:
	extends Control
	var branch: String = ""
	var owned: bool = false

	func _init(br: String) -> void:
		branch = br
		custom_minimum_size = Vector2(24, 24)
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _draw() -> void:
		var c: Vector2 = size / 2.0
		var col: Color = GameData.branch_color(branch)
		var r: float = minf(size.x, size.y) / 2.0 - 2.0
		if owned:
			draw_circle(c, r, Color(col, 0.85))
			draw_polyline(PackedVector2Array([c + Vector2(-r * 0.45, 0), c + Vector2(-r * 0.1, r * 0.4), c + Vector2(r * 0.5, -r * 0.4)]), Chalk.BOARD.darkened(0.5), 3.0, true)
		else:
			draw_arc(c, r, 0.0, TAU, 24, Color(col, 0.75), 2.0, true)
			draw_string(Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font, c + Vector2(-r, r * 0.45), "?", HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, int(r * 1.2), Color(col, 0.6))
