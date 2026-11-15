class_name RoadView
extends PanelContainer
## "Camino al final": los 6 sellos (uno por rama) y el centro del árbol.
##  - compacto (en el juego): una sola línea junto al botón de Reformar: los 6 circulitos (rellenos con tilde si los
##    tenés) y "Próximo: Empanada de oro" (con los 6, "¡Estabilizá la economía!"). El detalle va en el tooltip y tocarlo
##    abre el árbol. Se dibuja a mano: el texto usa la letra más grande que entra (nunca se corta ni ensancha la columna).
##  - completo (en el árbol): una fila por sello con qué nodo de qué rama lo da y cuánta Credibilidad falta, el centro y
##    el total aproximado.

signal open_tree

var full: bool = false
var _sig: String = ""
var _medals: Array = []
var _rows: Array = []                 # completo: [Label] uno por sello
var _final_l: Label
var _total_l: Label
var _t: float = 0.0
var _compact_text: String = ""
var _ready_now: bool = false          # los 6 sellos y falta el centro (el aviso late)
var allow_pulse: bool = true          ## la pantalla decide si puede latir (como mucho 2 cosas a la vez)
var _owned: Array = []
const LINE_H: float = 24.0
const MEDAL: float = 18.0


func _init(full_mode: bool = false) -> void:
	full = full_mode
	if full:
		add_theme_stylebox_override("panel", UIKit.chalk_box(Chalk.YELLOW, Color(0.06, 0.1, 0.08, 0.92), 2.2))
	else:
		add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		custom_minimum_size = Vector2(0, LINE_H)
	mouse_filter = Control.MOUSE_FILTER_STOP if not full else Control.MOUSE_FILTER_PASS
	if not full:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				open_tree.emit())
	_build()


func _build() -> void:
	if not full:
		return                  # el compacto se dibuja en _draw
	var title: Label = UIKit.label(tr("ui.road.title"), 17, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT, true)
	var medals: HBoxContainer = HBoxContainer.new()
	medals.add_theme_constant_override("separation", 4)
	for i in range(TreeLogic.SEAL_BRANCHES.size()):
		var md: _Medal = _Medal.new(str(TreeLogic.SEAL_BRANCHES[i]))
		medals.add_child(md)
		_medals.append(md)
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
	if not full and _compact_text != "" and _ready_now and allow_pulse:
		queue_redraw()          # el aviso late


## Lo llama quien lo muestra (cada frame): solo rearma los textos si cambió algo.
func refresh(m: GameModel) -> void:
	var r: Dictionary = TreeLogic.road(m)
	_ready_now = bool(r["ready"])
	var sig: String = "%d|%d|%s|%s" % [m.credibility, int(r["have"]), str(r["final_owned"]), TranslationServer.get_locale()]
	for row in r["seals"]:
		sig += str(row["nodes"]) + ","
	if sig == _sig:
		return
	_sig = sig
	var seals: Array = r["seals"]
	if not full:
		_owned = []
		var tip: PackedStringArray = PackedStringArray([tr("ui.road.title")])
		for row in seals:
			_owned.append(bool(row["owned"]))
			tip.append(_seal_text(row))
		tip.append(_summary(r, m))
		tooltip_text = "\n".join(tip)
		_compact_text = _compact(r, m)
		queue_redraw()
		return
	for i in range(seals.size()):
		var row: Dictionary = seals[i]
		var md: _Medal = _medals[i]
		md.owned = bool(row["owned"])
		md.tooltip_text = _seal_text(row)
		md.queue_redraw()
	for i in range(seals.size()):
		var row2: Dictionary = seals[i]
		(_rows[i] as Label).text = _seal_text(row2)
		(_rows[i] as Label).add_theme_color_override("font_color", Chalk.GREEN if bool(row2["owned"]) else Chalk.WHITE)
	if bool(r["final_owned"]):
		_final_l.text = tr("ui.road.done")
	elif bool(r["ready"]):
		_final_l.text = tr("ui.road.ready") % int(r["final_cost"])
	else:
		_final_l.text = tr("ui.road.final") % [int(r["final_cost"]), int(r["need"])]
	_total_l.text = ""
	_total_l.visible = false


## "Negocios: Cadena de locales ✔" o "Negocios: Cadena de locales, ~110".
static func _seal_text(row: Dictionary) -> String:
	var name: String = TranslationServer.translate(GameData.node(str(row["id"]))["name_key"])
	var br: String = TranslationServer.translate("ui.branch_s." + str(row["branch"]))
	if bool(row["owned"]):
		return TranslationServer.translate("ui.road.seal_owned") % [br, name]
	return TranslationServer.translate("ui.road.seal_missing") % [br, name, int(row["cost"])]


## La línea compacta: "Próximo: Empanada de oro", "¡Estabilizá la economía! Faltan 1200" o "Economía estabilizada".
static func _compact(r: Dictionary, m: GameModel) -> String:
	if bool(r["final_owned"]):
		return TranslationServer.translate("ui.road.done")
	if bool(r["ready"]):
		var left: int = maxi(0, int(r["final_cost"]) - m.credibility)
		return TranslationServer.translate("ui.road.c_ready_now") if left == 0 else TranslationServer.translate("ui.road.c_ready") % left
	return TranslationServer.translate("ui.road.c_next") % TranslationServer.translate(GameData.node(str(r["next_seal"]["id"]))["name_key"])


## El tamaño de letra de la línea compacta y si entra (para el QA).
func compact_fit() -> int:
	var w: float = size.x - (MEDAL + 3.0) * 6.0 - 8.0
	return UpgradeIcon.fit_size(UpgradeIcon._fonts()[1], _compact_text, w, [16, 11])


func _draw() -> void:
	if full or _compact_text == "":
		return
	var y: float = size.y / 2.0
	for i in range(_owned.size()):
		var c: Vector2 = Vector2(MEDAL / 2.0 + 1.0 + float(i) * (MEDAL + 3.0), y)
		var col: Color = GameData.branch_color(str(TreeLogic.SEAL_BRANCHES[i]))
		var rr: float = MEDAL / 2.0 - 1.0
		if bool(_owned[i]):
			draw_circle(c, rr, Color(col, 0.9))
			draw_polyline(PackedVector2Array([c + Vector2(-rr * 0.45, 0), c + Vector2(-rr * 0.1, rr * 0.4), c + Vector2(rr * 0.5, -rr * 0.4)]), Chalk.BOARD.darkened(0.5), 2.5, true)
		else:
			draw_arc(c, rr, 0.0, TAU, 20, Color(col, 0.8), 2.0, true)
	var x0: float = (MEDAL + 3.0) * 6.0 + 6.0
	var fs: int = compact_fit()
	if fs < 0:
		fs = 11
	var col2: Color = Chalk.WHITE
	if _ready_now and allow_pulse:
		col2 = Chalk.WHITE.lerp(Chalk.YELLOW, 0.5 + 0.5 * sin(_t * 5.0))
	var font: Font = UpgradeIcon._fonts()[1]
	draw_string(font, Vector2(x0, y + float(fs) * 0.35), _compact_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col2)


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
