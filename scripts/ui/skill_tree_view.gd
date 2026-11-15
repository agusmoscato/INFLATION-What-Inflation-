class_name SkillTreeView
extends Control
## El árbol de habilidades dibujado con tiza: se arrastra (cualquier botón del mouse), se hace zoom con la rueda
## (o pellizcando) y se toca un nodo para verlo. Cuatro estados que se distinguen de un vistazo:
##  - comprable ya: brillante, latiendo con un aro amarillo y una chispa;
##  - visible pero no te alcanza (o le falta el nodo anterior): apagado al 45 % con su costo;
##  - comprado: relleno y con la línea al padre marcada en amarillo;
##  - desconocido: niebla gris con "?".

signal node_selected(id: String)

const NODE_R: float = 30.0
const FINAL_R: float = 50.0
const ZOOM_MIN: float = 0.3
const ZOOM_MAX: float = 1.6
const BRANCH_ICON: Dictionary = {"emp": "empanadas", "neg": "kiosco", "inf": "ceros", "sue": "cripto", "fig": "banco",
	"ren": "imprenta", "bridge": "holding", "final": "empanadas"}

var offset: Vector2 = Vector2.ZERO
var zoom: float = 0.62
var selected: String = ""
var hint_id: String = ""              ## nodo recomendado: se dibuja una flecha de tiza que lo señala
var hint_text: String = ""
var _drag: bool = false
var _drag_moved: float = 0.0
var _t: float = 0.0
var _sparks: Array = []          # [{pos, t}]
var _touches: Dictionary = {}
var _pinch_d: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	set_meta("qa_ignore", true)


func m() -> GameModel:
	return GameState.m


func _process(delta: float) -> void:
	_t += delta
	var i: int = _sparks.size() - 1
	while i >= 0:
		_sparks[i]["t"] = float(_sparks[i]["t"]) + delta
		if float(_sparks[i]["t"]) > 0.8:
			_sparks.remove_at(i)
		i -= 1
	queue_redraw()


func to_screen(p: Vector2) -> Vector2:
	return size / 2.0 + offset + p * zoom


func to_world(p: Vector2) -> Vector2:
	return (p - size / 2.0 - offset) / zoom


## Centra la vista en un nodo (o en el centro).
func focus(id: String = "") -> void:
	var p: Vector2 = Vector2.ZERO
	if id != "" and GameData.tree_idx.has(id):
		p = GameData.node(id)["pos"]
	offset = -p * zoom


func zoom_by(k: float, at: Vector2 = Vector2(-1, -1)) -> void:
	var pivot: Vector2 = at if at.x >= 0.0 else size / 2.0
	var w: Vector2 = to_world(pivot)
	zoom = clampf(zoom * k, ZOOM_MIN, ZOOM_MAX)
	offset = pivot - size / 2.0 - w * zoom


func spark(id: String) -> void:
	_sparks.append({"pos": GameData.node(id)["pos"], "t": 0.0})


func node_at(screen: Vector2) -> String:
	var best: String = ""
	var best_d: float = INF
	for n in GameData.tree:
		var id: String = n["id"]
		if not (TreeLogic.visible(m(), id) or TreeLogic.fog(m(), id)):
			continue
		var r: float = (FINAL_R if bool(n["final"]) else NODE_R) * zoom + 6.0
		var d: float = to_screen(n["pos"]).distance_to(screen)
		if d <= r and d < best_d:
			best_d = d
			best = id
	return best


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom_by(1.12, mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom_by(1.0 / 1.12, mb.position)
		elif mb.pressed:
			_drag = true
			_drag_moved = 0.0
		else:
			if _drag and _drag_moved < 8.0 and mb.button_index == MOUSE_BUTTON_LEFT:
				var id: String = node_at(mb.position)
				if id != "":
					selected = id
					node_selected.emit(id)
			_drag = false
		accept_event()
	elif event is InputEventMouseMotion and _drag:
		var mm: InputEventMouseMotion = event
		offset += mm.relative
		_drag_moved += mm.relative.length()
		accept_event()
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		if st.pressed:
			_touches[st.index] = st.position
		else:
			_touches.erase(st.index)
			_pinch_d = 0.0
	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event
		_touches[sd.index] = sd.position
		if _touches.size() == 2:
			var ks: Array = _touches.keys()
			var d: float = (_touches[ks[0]] as Vector2).distance_to(_touches[ks[1]])
			if _pinch_d > 0.0:
				zoom_by(d / _pinch_d, ((_touches[ks[0]] as Vector2) + (_touches[ks[1]] as Vector2)) / 2.0)
			_pinch_d = d
	elif event is InputEventMagnifyGesture:
		zoom_by((event as InputEventMagnifyGesture).factor, (event as InputEventMagnifyGesture).position)


func _state_color(id: String, n: Dictionary) -> Color:
	var bc: Color = GameData.branch_color(str(n["branch"])) if not bool(n["final"]) else Chalk.YELLOW
	if bool(n["bridge"]):
		bc = Chalk.WHITE
	return bc


func _draw() -> void:
	var gm: GameModel = m()
	# anillos tenues
	for r in range(1, 9):
		Chalk.circle(self, to_screen(Vector2.ZERO), GameData.TREE_RING_PX * float(r) * zoom, Color(Chalk.WHITE, 0.06), 1.5, 900 + r)
	# conexiones
	for n in GameData.tree:
		var id: String = n["id"]
		if not (TreeLogic.visible(gm, id) or TreeLogic.fog(gm, id)):
			continue
		for p in n["parents"]:
			if not (TreeLogic.visible(gm, p) or TreeLogic.fog(gm, p)):
				continue
			var a: Vector2 = to_screen(GameData.node(p)["pos"])
			var b: Vector2 = to_screen(n["pos"])
			var owned: bool = gm.tree.has(id) and gm.tree.has(p)
			var col: Color = Color(Chalk.YELLOW, 0.85) if owned else Color(Chalk.WHITE, 0.28 if TreeLogic.visible(gm, id) else 0.12)
			Chalk.line(self, a, b, col, (3.2 if owned else 2.0) * clampf(zoom * 1.4, 0.6, 1.4), id.hash() % 997)
	var f: Font = Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font
	var body: Font = Chalk.hand_font if Chalk.hand_font != null else ThemeDB.fallback_font
	for n in GameData.tree:
		var id: String = n["id"]
		var vis: bool = TreeLogic.visible(gm, id)
		var fogged: bool = not vis and TreeLogic.fog(gm, id)
		if not vis and not fogged:
			continue
		var c: Vector2 = to_screen(n["pos"])
		var r: float = (FINAL_R if bool(n["final"]) else NODE_R) * zoom
		if c.x < -r * 2 or c.y < -r * 2 or c.x > size.x + r * 2 or c.y > size.y + r * 2:
			continue
		var sv: int = absi(id.hash()) % 9973
		if fogged:
			# niebla: nubecita de tiza con "?"
			for k in range(5):
				var a: float = TAU * float(k) / 5.0 + 0.4
				draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.55, r * 0.55, Color(Chalk.WHITE, 0.07))
			Chalk.circle(self, c, r * 0.9, Color(Chalk.WHITE, 0.22), 1.6, sv)
			draw_string(f, c + Vector2(-r, r * 0.35), "?", HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, int(maxf(12.0, r * 1.1)), Color(Chalk.WHITE, 0.45))
			continue
		var col: Color = _state_color(id, n)
		var owned: bool = gm.tree.has(id)
		var can: bool = TreeLogic.can_buy(gm, id)
		var open: bool = TreeLogic.requirements_met(gm, id) and not TreeLogic.demo_locked(gm, id)
		var alpha: float = 1.0 if (owned or can) else 0.45
		if can:
			var pulse: float = 0.5 + 0.5 * sin(_t * 5.0)
			draw_circle(c, r + 10.0 + pulse * 5.0, Color(Chalk.YELLOW, 0.08 + 0.08 * pulse))
			Chalk.circle(self, c, r + 6.0 + pulse * 5.0, Color(Chalk.YELLOW, 0.6 + 0.4 * pulse), 3.4, sv + 1)
			var sk: float = fmod(_t * 0.8 + float(sv % 7) * 0.13, 1.0)
			if sk < 0.4:
				var ang: float = float(sv % 360) * 0.0174 + floor(_t * 0.8 + float(sv % 7) * 0.13) * 2.4
				BuyGlow.draw_spark(self, c + Vector2(cos(ang), sin(ang)) * (r + 8.0), sk / 0.4)
		if owned:
			draw_circle(c, r, Color(col, 0.62))
		else:
			draw_circle(c, r, Color(0.02, 0.05, 0.04, 0.85))
		Chalk.circle(self, c, r, Color(col, alpha), (3.4 if owned else 2.4) * clampf(zoom * 1.5, 0.7, 1.5), sv)
		if bool(n["seal"]) or bool(n["cap"]):
			Chalk.circle(self, c, r + 4.0 * zoom + 2.0, Color(col, alpha * 0.8), 1.6, sv + 2)
		if id == selected:
			Chalk.circle(self, c, r + 12.0 * zoom + 4.0, Chalk.WHITE, 2.0, sv + 3)
		var icon: String = str(BRANCH_ICON.get(str(n["branch"]), "empanadas"))
		var ir: float = r * 1.15
		ChalkIcons.draw(self, icon, Rect2(c - Vector2(ir, ir) / 2.0, Vector2(ir, ir)), sv, Chalk.WHITE if owned else Color(col, alpha * 0.85))
		if owned:
			# tilde de comprado
			Chalk.polyline(self, PackedVector2Array([c + Vector2(r * 0.35, r * 0.55), c + Vector2(r * 0.55, r * 0.78), c + Vector2(r * 0.95, r * 0.3)]), Chalk.GREEN, 3.0, sv + 5)
		if TreeLogic.demo_locked(gm, id) and not owned:
			draw_string(body, c + Vector2(-r * 2.0, r + 16.0), tr("ui.tree.full_game"), HORIZONTAL_ALIGNMENT_CENTER, r * 4.0, 13, Color(Chalk.PINK, 0.8))
		else:
			var yoff: float = r + 17.0
			if zoom >= 0.55:
				var name: String = tr(n["name_key"])
				draw_string(body, c + Vector2(-90.0, yoff), name, HORIZONTAL_ALIGNMENT_CENTER, 180.0, int(clampf(15.0 * zoom, 11.0, 20.0)), Color(Chalk.WHITE, 0.85 * alpha))
				yoff = r + 34.0 * clampf(zoom, 0.8, 1.2)
			if not owned:
				# el costo siempre (con cualquier zoom): amarillo si te alcanza, apagado si no
				draw_string(body, c + Vector2(-90.0, yoff), tr("ui.tree.cost") % TreeLogic.cost(id), HORIZONTAL_ALIGNMENT_CENTER, 180.0, int(clampf(14.0 * zoom, 12.0, 18.0)), Color(Chalk.YELLOW, 1.0) if can else Color(Chalk.WHITE, 0.6 * alpha))
	# flecha al nodo recomendado (después de las primeras reformas)
	if hint_id != "" and GameData.tree_idx.has(hint_id) and not gm.tree.has(hint_id):
		var hc: Vector2 = to_screen(GameData.node(hint_id)["pos"])
		var bob: float = sin(_t * 5.0) * 6.0
		var tip: Vector2 = hc + Vector2(0, -(NODE_R * zoom + 14.0) + bob)
		var tail: Vector2 = tip + Vector2(0, -70.0)
		draw_line(tail, tip, Chalk.YELLOW, 5.0, true)
		draw_colored_polygon(PackedVector2Array([tip + Vector2(0, 4), tip + Vector2(-14, -16), tip + Vector2(14, -16)]), Chalk.YELLOW)
		if hint_text != "":
			var tw: float = 300.0
			var tp: Vector2 = tail + Vector2(-tw / 2.0, -12.0)
			tp.x = clampf(tp.x, 6.0, maxf(6.0, size.x - tw - 6.0))
			tp.y = maxf(tp.y, 40.0)
			draw_rect(Rect2(tp + Vector2(-6, -26), Vector2(tw + 12, 60)), Color(0.04, 0.07, 0.05, 0.9))
			draw_multiline_string(body, tp, hint_text, HORIZONTAL_ALIGNMENT_CENTER, tw, 17, 2, Chalk.YELLOW)
	# chispazos de compra
	for s in _sparks:
		var k: float = float(s["t"]) / 0.8
		var c2: Vector2 = to_screen(s["pos"])
		for j in range(10):
			var a2: float = TAU * float(j) / 10.0
			var d0: float = (NODE_R + 6.0) * zoom
			var d1: float = d0 + 60.0 * k * zoom
			draw_line(c2 + Vector2(cos(a2), sin(a2)) * d0, c2 + Vector2(cos(a2), sin(a2)) * d1, Color(Chalk.YELLOW, 1.0 - k), 3.0, true)
