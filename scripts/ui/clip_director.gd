class_name ClipDirector
extends Node
## Guiones de los clips de marketing (10-20 s, gancho en el primer segundo). Se graban con el Movie Maker de Godot:
##   godot --rendering-driver opengl3 --write-movie out.avi --fixed-fps 30 --resolution 1920x1080 -- --record-clip precio_empanada
## (vertical: --resolution 1080x1920). Clips: precio_empanada, trillon_cafe, tijera, hiperinflacion, sobre_dorada, raspadita, billete, arbol.
## Clips del estudio (23,5 s de acción real, el bot juega con las llamadas de Economy, sin adelantar el tiempo):
## remarcar, imprenta, tijera_larga, sobres, raspaditas, clics, billetes, diez_negocios, noticias, compras.

var main: Node
var clip: String = ""
var _t: float = 0.0
var _events: Array = []        # [{t, fn, done}]
var _duration: float = 14.0
var _captions: Control
var _hikes: int = 0
var _movie: bool = OS.has_feature("movie")      # grabando: el tiempo avanza de a 1/30 s por cuadro


func _init(main_node: Node = null, clip_name: String = "") -> void:
	main = main_node
	clip = clip_name


func _g() -> GameScreen:
	return main._game


func _m() -> GameModel:
	return GameState.m


func at(t: float, fn: Callable) -> void:
	_events.append({"t": t, "fn": fn, "done": false})


func _ready() -> void:
	_captions = Control.new()
	_captions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_captions.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 40
	main.add_child(layer)
	layer.add_child(_captions)
	_m().tutorial_done = true
	_m().reforms = 3
	match clip:
		"precio_empanada": _clip_precio()
		"trillon_cafe": _clip_trillon()
		"tijera": _clip_tijera()
		"hiperinflacion": _clip_hiper()
		"sobre_dorada": _clip_sobre()
		"raspadita": _clip_raspadita()
		"billete": _clip_billete()
		"arbol": _clip_arbol()
		# clips del estudio (>= 23 s de acción real, sin carteles; el gancho lo pone _estudio/tools/clip_tool.py)
		"remarcar": _clip_remarcar()
		"imprenta": _clip_imprenta()
		"tijera_larga": _clip_tijera_larga()
		"sobres": _clip_sobres()
		"raspaditas": _clip_raspaditas()
		"clics": _clip_clics()
		"billetes": _clip_billetes()
		"diez_negocios": _clip_diez_negocios()
		"noticias": _clip_noticias()
		"compras": _clip_compras()
		# sesiones largas reales para montar (el bot del juego juega en vivo; ver _sesion_*)
		"sesion_casi_pierdo": _sesion_casi_pierdo()
		"sesion_progresion": _sesion_progresion()
		"sesion_imprenta": _sesion_imprenta()
		"sesion_vuelta1": _sesion_vuelta1()
		_:
			push_error("Clip desconocido: " + clip)
			get_tree().quit(1)
	_m().notifications.clear()


func _process(delta: float) -> void:
	_t += (1.0 / 30.0) if _movie else delta
	if _movie:
		# algo del sistema minimiza la ventana mientras se graba y Godot deja de dibujar: se la restaura en cada cuadro
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MINIMIZED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_move_to_foreground()
	if _bot != null:
		_sesion_paso()
	if _movie and delta > 0.1 and _t > 1.0 and _bot == null:
		# la PC se trabo: el motor avanzo las animaciones de golpe y el video no queda parejo -> se descarta (el script reintenta)
		print("clip: cuadro lento (delta %.2f s), se descarta esta toma" % delta)
		get_tree().quit(3)
		return
	for e in _events:
		if not bool(e["done"]) and _t >= float(e["t"]):
			e["done"] = true
			e["fn"].call()
	if _t >= _duration:
		print("clip: fin t=%.2f dur=%.1f" % [_t, _duration])
		get_tree().quit(0)


## Cartel garabateado grande arriba (se dibuja rápido y se borra).
func caption(text: String, color: Color = Chalk.YELLOW, hold: float = 2.0, y_frac: float = 0.12) -> void:
	# --clip-sin-carteles: los clips del estudio llevan su propia caja de gancho (_estudio/tools/clip_tool.py)
	if OS.get_cmdline_user_args().has("--clip-sin-carteles"):
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var s: ScribbleText = ScribbleText.new()
	s.color = color
	s.size = Vector2(vp.x, 190)
	s.position = Vector2(0, vp.y * y_frac)
	var fs: int = int(minf(104.0, vp.x / (float(text.length()) * 0.52)))
	s.font_size = maxi(40, fs)
	_captions.add_child(s)
	s.show_text(text, text.length() * 3 + 1, hold)
	get_tree().create_timer(hold + 1.6).timeout.connect(s.queue_free)


func _flush() -> void:
	Economy.flush()


## Adelanta la inflación de la vuelta (para que en un clip corto se vea lo que pasa en minutos).
func _rush(seconds: float) -> void:
	var m: GameModel = _m()
	m.run_time += seconds
	m.ln_p += EconomyLogic.rate_per_sec(m) * seconds
	_flush()


# ---- a) el precio de un carrito en un minuto ----
func _clip_precio() -> void:
	_duration = 16.0
	var m: GameModel = _m()
	m.money = BigNumber.from_float(5000.0)
	m.owned["empanadas"] = 3
	m.dirty = true
	at(0.05, func() -> void: caption("¡UN CARRITO: $%s!" % EconomyLogic.business_cost(_m(), GameData.businesses[0], 1).format(), Chalk.YELLOW, 1.6))
	for i in range(9):
		at(2.0 + 1.2 * float(i), func() -> void: _rush(40.0))
	at(13.0, func() -> void: caption("UN MINUTO DESPUÉS: $%s" % EconomyLogic.business_cost(_m(), GameData.businesses[0], 1).format(), Chalk.RED, 2.5))


# ---- b) de $1 a un trillón y no me alcanza ----
func _clip_trillon() -> void:
	_duration = 14.0
	var m: GameModel = _m()
	m.run_time = 330.0
	m.ln_p = 30.0
	m.money = BigNumber.from_string("1e12")
	m.owned["empanadas"] = 40
	m.owned["kiosco"] = 25
	m.dirty = true
	at(0.05, func() -> void: caption("PASÉ DE $1 A...", Chalk.WHITE, 1.6))
	at(2.0, func() -> void:
		caption("¡$1 TRILLÓN!", Chalk.YELLOW, 2.0)
		_g()._shake(14.0, 0.5))
	at(5.5, func() -> void: caption("...Y UN CARRITO SALE", Chalk.PINK, 2.0))
	at(8.5, func() -> void: caption("$%s" % EconomyLogic.business_cost(_m(), GameData.businesses[0], 1).format(), Chalk.RED, 3.0))
	at(8.6, func() -> void: _g()._shake(10.0, 0.4))


# ---- c) la tijera de la reforma ----
func _clip_tijera() -> void:
	_duration = 13.0
	var m: GameModel = _m()
	m.run_time = 300.0
	m.ln_p = 21.0
	m.collapse_shown = true
	m.money = BigNumber.from_string("3e11")
	m.run_earned = BigNumber.from_string("8e11")
	m.dirty = true
	at(0.05, func() -> void: caption("¿DEMASIADOS CEROS?", Chalk.YELLOW, 1.6))
	at(2.2, func() -> void: Economy.reform())
	at(9.5, func() -> void: caption("¡LE CORTÉ 9 CEROS!", Chalk.GREEN, 2.0))


# ---- d) hiperinflación con la empanada en pánico ----
func _clip_hiper() -> void:
	_duration = 14.0
	var m: GameModel = _m()
	m.money = BigNumber.from_float(80000.0)
	m.owned["empanadas"] = 12
	m.owned["kiosco"] = 7
	m.run_time = 240.0
	m.dirty = true
	at(0.05, func() -> void: caption("HIPERINFLACIÓN", Chalk.RED, 2.0))
	for i in range(10):
		at(1.2 + 1.15 * float(i), func() -> void: _rush(25.0))
	at(8.0, func() -> void: caption("¡LOS NÚMEROS NO ENTRAN!", Chalk.YELLOW, 2.5, 0.2))


# ---- e) abriendo un sobre y sale una dorada ----
func _clip_sobre() -> void:
	_duration = 14.0
	var m: GameModel = _m()
	m.tree["fig_1"] = true
	m.owned["kiosco"] = 3
	m.dirty = true
	for id in ["biz_empanadas", "biz_kiosco", "pj_gato"]:
		StickerLogic.give(m, id)
	m.notifications.clear()
	at(0.05, func() -> void: caption("ABRO UN SOBRE Y SALE...", Chalk.WHITE, 2.4))
	at(1.2, func() -> void:
		var res: Array = StickerLogic.gift_pack(_m(), ["common", "common", "rare", "golden", "common"])
		var ov: PackOpening = _g()._open_pack_overlay(res)
		ov.auto_open(1.2))
	at(9.0, func() -> void: caption("¡¡UNA DORADA!!", Chalk.YELLOW, 2.5, 0.05))


# ---- f) la raspadita que paga x10 ----
func _clip_raspadita() -> void:
	_duration = 14.0
	var m: GameModel = _m()
	m.tree["sue_1"] = true
	m.tree["sue_2"] = true
	m.money = BigNumber.from_string("8e12")
	m.owned["empanadas"] = 10
	m.dirty = true
	at(0.05, func() -> void: caption("¿Y SI RASPO?", Chalk.YELLOW, 2.0))
	at(1.3, func() -> void:
		var ov: ScratchOverlay = _g()._open_scratch("x10")
		if ov != null:
			ov.auto_scratch(3.4))
	at(9.0, func() -> void: caption("¡¡x10!!", Chalk.YELLOW, 2.5, 0.03))


# ---- g) el billete volador y el frenesí ----
func _clip_billete() -> void:
	_duration = 14.0
	var m: GameModel = _m()
	m.money = BigNumber.from_string("2e6")
	m.owned["empanadas"] = 25
	m.owned["kiosco"] = 12
	m.owned["choripan"] = 5
	m.dirty = true
	at(0.05, func() -> void: caption("¡UN BILLETE VOLANDO!", Chalk.GREEN, 2.0))
	at(0.6, func() -> void:
		_m().bill_timer = 0.0)
	at(5.0, func() -> void:
		for b in _m().bills_active.duplicate():
			var id: int = int(b["id"])
			if _g()._bills.has(id):
				(_g()._bills[id] as FlyingBill).vanish(true)
			EconomyLogic.click_bill(_m(), id, "frenzy")
			_flush())
	at(9.0, func() -> void: caption("FRENESÍ x7", Chalk.ORANGE, 3.0))


# ---- h) el árbol de la Credibilidad ----
func _clip_arbol() -> void:
	_duration = 14.0
	var m: GameModel = _m()
	for n in GameData.tree:
		if int(n["ring"]) <= 2:
			m.tree[n["id"]] = true
	m.credibility = 400
	m.dirty = true
	at(0.05, func() -> void: caption("UN ÁRBOL DE 115 NODOS", Chalk.BLUE, 2.2))
	at(0.6, func() -> void: _g()._open_tree())
	for i in range(6):
		at(2.5 + 1.2 * float(i), func() -> void:
			var tv: SkillTreeView = _g()._tree_view
			if tv == null:
				return
			for n in GameData.tree:
				if TreeLogic.can_buy(_m(), n["id"]):
					tv.selected = n["id"]
					Economy.buy_node(n["id"])
					break)
	at(10.0, func() -> void: caption("...Y CADA VUELTA ES MÁS RÁPIDA", Chalk.YELLOW, 3.0))


# =====================================================================
#  Clips del estudio: 23,5 s de acción real. El estado inicial se arma a mano y después el bot juega con las mismas
#  llamadas que un jugador (clics, compras, remarcar, reforma, sobres, raspaditas, noticias). No se adelanta el tiempo.
# =====================================================================
const CLIP_ESTUDIO_S: float = 23.5


## Clics a la empanada entre dos momentos, a `por_seg` clics por segundo.
func _clics(desde: float, hasta: float, por_seg: float) -> void:
	var t: float = desde
	while t < hasta:
		at(t, func() -> void: Economy.click())
		t += 1.0 / por_seg


## Compra un negocio como el botón de la interfaz (con la cantidad elegida: 1, 10...). Con `mostrar`, baja la lista
## hasta esa fila y la siguiente (si no, del 5º negocio en adelante quedan abajo del scroll).
func _comprar(id: String, qty: int = 1, mostrar: bool = false) -> void:
	_g()._buy_mode = qty
	_g()._on_buy_business(id)
	if mostrar:
		var rows: Array = _g().biz_rows
		for i in range(rows.size()):
			if str(rows[i]["def"]["id"]) == id:
				_g().biz_scroll.ensure_control_visible(rows[mini(i + 1, rows.size() - 1)]["row"])
				break


## Partida avanzada de base: negocios hasta la panadería y unas vueltas encima.
func _base_avanzada(reforms: int, best: String, earned: String, money: String) -> void:
	var m: GameModel = _m()
	m.reforms = reforms
	m.best_run = BigNumber.from_string(best)
	m.run_earned = BigNumber.from_string(earned)
	m.money = BigNumber.from_string(money)
	m.owned["empanadas"] = 60
	m.owned["kiosco"] = 40
	m.owned["choripan"] = 30
	m.owned["lavadero"] = 20
	m.owned["panaderia"] = 10
	m.dirty = true


# ---- remarcar: la inflación del mes en rojo, los precios suben solos y el bot remarca justo a tiempo ----
# (medido sin pantalla: ~50 % mensual, el carrito sube ~x1,8 en 23 s; remarcar congela 9 s con inf_2a + inf_5a)
func _clip_remarcar() -> void:
	_duration = CLIP_ESTUDIO_S
	var m: GameModel = _m()
	_base_avanzada(4, "1e9", "5e11", "2e6")
	m.run_time = 200.0
	m.tree["inf_2a"] = true
	m.tree["inf_5a"] = true
	_clics(0.1, 23.4, 6.0)
	at(3.0, func() -> void: _comprar("empanadas"))
	at(5.5, func() -> void: _comprar("kiosco"))
	at(7.0, func() -> void: Economy.remark())
	at(12.0, func() -> void: _comprar("empanadas"))
	at(17.5, func() -> void: _comprar("choripan"))
	at(20.5, func() -> void: _comprar("empanadas"))


# ---- imprenta: compra la imprenta de billetes, la plata se dispara, vuelan billetes y los precios siguen trepando ----
# (medido sin pantalla: el ingreso pasa de ~14 M/s a ~86 M/s; la inflación del mes no cambia por la imprenta)
func _clip_imprenta() -> void:
	_duration = CLIP_ESTUDIO_S
	var m: GameModel = _m()
	_base_avanzada(4, "1e9", "2e10", "1.2e10")
	m.run_time = 300.0
	m.owned["panaderia"] = 20
	m.owned["almacen"] = 10
	m.owned["remiseria"] = 5
	m.owned["fabrica"] = 3
	m.tree["neg_7"] = true
	_clics(0.1, 23.4, 6.0)
	at(0.4, func() -> void: _comprar("imprenta"))
	for t0 in [3.0, 9.5, 16.0]:
		at(t0, func() -> void: _m().bill_timer = 0.0)
		at(t0 + 2.4, func() -> void: _catch_bill("money"))


# ---- tijera larga: el final de una vuelta, la reforma corta los ceros, el resumen y las primeras compras del árbol ----
func _clip_tijera_larga() -> void:
	_duration = CLIP_ESTUDIO_S
	var m: GameModel = _m()
	_base_avanzada(3, "1e11", "8e11", "3e11")
	m.run_time = 300.0
	m.collapse_shown = true
	m.owned["almacen"] = 15
	m.owned["remiseria"] = 8
	_clics(0.1, 6.0, 8.0)
	at(1.5, func() -> void: _comprar("panaderia", 10))
	at(3.5, func() -> void: _comprar("almacen", 10))
	at(6.2, func() -> void: Economy.reform())
	at(13.5, func() -> void:
		_g()._close_overlay()
		_g()._open_tree())
	for i in range(6):
		at(15.0 + 1.3 * float(i), func() -> void: _buy_cheapest_node())


func _buy_cheapest_node() -> void:
	var tv: SkillTreeView = _g()._tree_view
	if tv == null:
		return
	for n in GameData.tree:
		if TreeLogic.can_buy(_m(), n["id"]):
			tv.selected = n["id"]
			Economy.buy_node(n["id"])
			break


# ---- sobres: tres sobres seguidos, el último trae la dorada ----
func _clip_sobres() -> void:
	_duration = CLIP_ESTUDIO_S
	var m: GameModel = _m()
	m.tree["fig_1"] = true
	m.owned["kiosco"] = 3
	m.dirty = true
	var tandas: Array = [["common", "common", "common", "rare", "common"],
		["common", "rare", "common", "common", "rare"],
		["common", "common", "rare", "golden", "common"]]
	for i in range(tandas.size()):
		var forced: Array = tandas[i]
		at(0.2 + 7.2 * float(i), func() -> void:
			var res: Array = StickerLogic.gift_pack(_m(), forced)
			var ov: PackOpening = _g()._open_pack_overlay(res)
			ov.auto_open(1.0))


# ---- raspaditas: nada, nada... y la tercera paga x10 ----
func _clip_raspaditas() -> void:
	_duration = CLIP_ESTUDIO_S
	var m: GameModel = _m()
	m.tree["sue_1"] = true
	m.tree["sue_2"] = true
	m.money = BigNumber.from_string("8e12")
	m.owned["empanadas"] = 10
	m.dirty = true
	var salidas: Array = ["nothing", "nothing", "x10"]
	for i in range(salidas.size()):
		var force: String = salidas[i]
		at(0.2 + 7.0 * float(i), func() -> void:
			var ov: ScratchOverlay = _g()._open_scratch(force)
			if ov != null:
				ov.auto_scratch(2.6 if i < 2 else 3.4))


# ---- clics: 15 clics por segundo a la empanada, el combo sube y caen críticos ----
func _clip_clics() -> void:
	_duration = CLIP_ESTUDIO_S
	var m: GameModel = _m()
	m.owned["empanadas"] = 5
	m.tree["emp_3"] = true
	m.tree["emp_5a"] = true
	m.dirty = true
	_clics(0.1, 22.1, 15.0)


# ---- billetes: tres billetes voladores, cada uno da frenesí x7, y clics a full en el medio ----
func _clip_billetes() -> void:
	_duration = CLIP_ESTUDIO_S
	var m: GameModel = _m()
	m.money = BigNumber.from_string("2e6")
	m.owned["empanadas"] = 25
	m.owned["kiosco"] = 12
	m.owned["choripan"] = 5
	m.dirty = true
	_clics(0.1, 23.4, 8.0)
	for t0 in [0.1, 8.0, 15.5]:
		at(t0, func() -> void: _m().bill_timer = 0.0)
		at(t0 + 2.4, func() -> void: _catch_bill())


func _catch_bill(premio: String = "frenzy") -> void:
	for b in _m().bills_active.duplicate():
		var id: int = int(b["id"])
		if _g()._bills.has(id):
			(_g()._bills[id] as FlyingBill).vanish(true)
		EconomyLogic.click_bill(_m(), id, premio)
		_flush()
		return


# ---- diez negocios: del carrito de empanadas al holding, uno tras otro ----
func _clip_diez_negocios() -> void:
	_duration = CLIP_ESTUDIO_S
	var m: GameModel = _m()
	m.money = BigNumber.from_string("5e12")
	m.tree["neg_3"] = true      # remisería y fábrica
	m.tree["neg_7"] = true      # imprenta y holding
	m.dirty = true
	_clics(0.1, 23.4, 4.0)
	for i in range(GameData.businesses.size()):
		var id: String = GameData.businesses[i]["id"]
		at(0.3 + 2.0 * float(i), func() -> void: _comprar(id, 1, true))
	at(20.5, func() -> void: _comprar("fabrica", 10, true))
	at(22.0, func() -> void: _comprar("remiseria", 10, true))


# ---- noticias: tres noticias con 10 s para elegir (turistas, corrida, tarifazo) ----
func _clip_noticias() -> void:
	_duration = CLIP_ESTUDIO_S
	var m: GameModel = _m()
	_base_avanzada(3, "1e9", "1e9", "5e6")
	m.run_time = 150.0
	_clics(0.1, 23.4, 5.0)
	var plan: Array = [["turistas", 0, 0.1], ["corrida", 0, 7.8], ["tarifazo", 1, 15.5]]
	for p in plan:
		var id: String = p[0]
		var idx: int = p[1]
		var t0: float = p[2]
		at(t0, func() -> void:
			EconomyLogic.start_event(_m(), id)
			_flush())
		at(t0 + 4.2, func() -> void: Economy.choose_event(idx))


# ---- compras: comprando todo de a 10, precios que se reescriben y logros que saltan ----
func _clip_compras() -> void:
	_duration = CLIP_ESTUDIO_S
	var m: GameModel = _m()
	m.money = BigNumber.from_string("2e12")
	m.owned["empanadas"] = 10
	m.owned["kiosco"] = 5
	m.tree["neg_3"] = true
	m.tree["neg_7"] = true
	m.dirty = true
	_clics(0.1, 23.4, 4.0)
	var ids: Array = ["empanadas", "kiosco", "choripan", "lavadero", "panaderia", "almacen", "remiseria", "fabrica"]
	for i in range(48):
		var id: String = ids[i % ids.size()]
		at(0.3 + 0.47 * float(i), func() -> void: _comprar(id, 10, true))


# =====================================================================
#  Sesiones largas para montar (clips "que atrapan"): primero el bot del juego juega SIN pantalla hasta la vuelta
#  pedida (estado real de una partida avanzada, igual que tools/simulate.gd) y después sigue jugando EN VIVO con la
#  interfaz mientras se graba. Todo lo que pasa es juego real: el bot usa las mismas acciones que un jugador.
#  Cada momento importante se imprime como "BEAT <segundo> <qué>" para elegir los tramos del montaje.
# =====================================================================
var _bot: BotPolicy = null
var _bot_reforma: bool = true          ## si el bot puede reformar en vivo
var _overlay_t: float = -1.0
var _beat_prev: Dictionary = {}
var _sesion_extra: Callable            ## lógica propia de cada sesión (se llama en cada cuadro)
var _noticia_manual: bool = false       ## hay una noticia que elige el guion (no el bot)


## Una noticia real del juego que aparece y, `espera` segundos después, se elige la opción `idx` (como un jugador).
func _noticia(t0: float, id: String, idx: int, espera: float = 3.5) -> void:
	at(t0, func() -> void:
		_noticia_manual = true
		EconomyLogic.start_event(_m(), id)
		_flush()
		_beat("NOTICIA: %s" % id))
	at(t0 + espera, func() -> void:
		Economy.choose_event(idx)
		_noticia_manual = false
		_beat("ELIGE opción %d en %s" % [idx, id]))


func _juice_al_maximo() -> void:
	Settings.quality = 0                # calidad de tiza alta: todas las partículas y efectos
	Settings.volume = 1.0               # efectos al máximo
	Settings.apply()


const ESPINA_NEGOCIOS: Array = ["neg_1", "neg_2", "neg_3", "neg_4", "neg_5", "neg_6", "neg_7"]


## Juega sin pantalla con el bot hasta tener `reformas` reformas y vuelve con la vuelta nueva recién empezada.
## Con `hasta_imprenta`, además prioriza la rama central de negocios del árbol (lo que haría un jugador que va por
## la imprenta) y sigue hasta que la imprenta y el holding estén desbloqueados (en la simulación: vuelta ~36).
func _jugar_offline(reformas: int, perfil: String = "activo", seed_value: int = 11, hasta_imprenta: bool = false) -> void:
	var m: GameModel = _m()
	m.reforms = 0
	var bot: BotPolicy = BotPolicy.new(seed_value, perfil)
	var paso: float = 0.25
	var guard: int = 0
	var reformas_al_desbloquear: int = -1
	while guard < 2000000:
		if hasta_imprenta:
			for id in ESPINA_NEGOCIOS:
				if not m.tree.has(id) and TreeLogic.can_buy(m, id):
					TreeLogic.buy(m, id)
			if reformas_al_desbloquear < 0 and bool(m.mods["excl_biz"]):
				reformas_al_desbloquear = m.reforms
		var listo: bool = m.reforms >= reformas
		if hasta_imprenta:
			listo = listo and reformas_al_desbloquear >= 0 and m.reforms > reformas_al_desbloquear
		if listo:
			break
		bot.step(m, paso)
		EconomyLogic.tick(m, paso)
		guard += 1
	m.notifications.clear()
	m.dirty = true
	_flush()
	print("BEAT 0.00 estado: reforma %d, nodos %d, figuritas %d (offline %d pasos)" % [m.reforms, TreeLogic.count(m), m.stickers.size(), guard])


## Arranca al bot en vivo (clics, billetes, compras, remarcar, noticias, árbol y reformas como un jugador).
func _bot_en_vivo(perfil: String, cambios: Dictionary = {}) -> void:
	_bot = BotPolicy.new(23, perfil)
	_bot.cfg = _bot.cfg.duplicate()       # los perfiles son constantes: se copia antes de cambiarlos
	for k in cambios:
		_bot.cfg[k] = cambios[k]
	_bot.on_click = func() -> void: Economy.click()
	_bot.on_bill = func(id: int) -> void:
		var o: Variant = _g()._bills.get(id, null)
		if o != null and is_instance_valid(o):
			var fb: FlyingBill = o as FlyingBill
			fb.caught.emit(id)
			fb.vanish(true)
		else:
			Economy.click_bill(id)
		_beat("billete agarrado")
	_bot.on_reform = func() -> Dictionary:
		if not _bot_reforma:
			return {}
		_g()._close_overlay()
		_beat("REFORMA (tijera)")
		return Economy.reform()


func _beat(que: String) -> void:
	print("BEAT %.2f %s" % [_t, que])


func _sesion_paso() -> void:
	var m: GameModel = _m()
	# un jugador cierra enseguida lo que tapa el juego (resumen de la reforma, árbol)
	if _g()._overlay != null:
		if _overlay_t < 0.0:
			_overlay_t = _t
		elif _t - _overlay_t > 2.5:
			_g()._close_overlay()
			_overlay_t = -1.0
	else:
		_overlay_t = -1.0
	# mientras hay una noticia elegida "a mano" en pantalla, el bot no la contesta (se ve el panel unos segundos)
	if not (_noticia_manual and not m.pending_choice.is_empty()):
		_bot.step(m, 1.0 / 30.0)
	if _sesion_extra.is_valid():
		_sesion_extra.call()
	# beats: negocio nuevo, la plata pasa otro cero, hiperinflación, congelado, frenesí, logros
	var d: Dictionary = {
		"tier": m.max_tier, "ceros": int(floor(m.money.log10())) if not m.money.is_zero() else 0,
		"hiper": EconomyLogic.era_of(m) == 5, "congelado": EconomyLogic.frozen(m), "frenesi": m.frenzy_left > 0.0,
		"logros": m.achievements.size(), "reformas": m.reforms, "imprentas": m.owned_count("imprenta"),
		"tipos": GameData.businesses.filter(func(b: Dictionary) -> bool: return m.owned_count(b["id"]) > 0).size(),
		"holding": m.owned_count("holding")}
	if not _beat_prev.is_empty():
		if d["tipos"] > _beat_prev["tipos"]:
			_beat("negocio nuevo en la vuelta (%d de 10)" % d["tipos"])
			# como un jugador: baja la lista hasta el negocio nuevo (si no, del 5.º en adelante quedan abajo del scroll)
			_mostrar_negocio(mini(int(d["tipos"]), 10) - 1)
		if d["ceros"] > _beat_prev["ceros"]:
			_beat("plata pasa 1e%d ($%s)" % [d["ceros"], m.money.format()])
		if d["hiper"] != _beat_prev["hiper"]:
			_beat("HIPERINFLACIÓN %s (%.0f %% mensual)" % ["empieza" if d["hiper"] else "termina", EconomyLogic.monthly_pct(m)])
		if d["congelado"] and not _beat_prev["congelado"]:
			_beat("REMARCA: precios congelados")
		if d["frenesi"] and not _beat_prev["frenesi"]:
			_beat("FRENESÍ")
		if d["logros"] > _beat_prev["logros"]:
			_beat("logro")
		if d["imprentas"] > _beat_prev["imprentas"]:
			_beat("imprenta #%d" % d["imprentas"])
		if d["holding"] > _beat_prev["holding"]:
			_beat("holding #%d" % d["holding"])
	if int(_t) % 15 == 0 and int(_t) != int(_beat_prev.get("t", -1)):
		print("ESTADO %.0f plata=%s ingreso=%s/s inflacion=%.1f%% P=x%s tier=%d" % [_t, m.money.format(),
			EconomyLogic.income_per_sec(m).format(), EconomyLogic.monthly_pct(m), EconomyLogic.price_level(m).format(), m.max_tier])
	d["t"] = int(_t)
	_beat_prev = d


func _mostrar_negocio(i: int) -> void:
	var rows: Array = _g().biz_rows
	if i >= 0 and i < rows.size():
		_g().biz_scroll.ensure_control_visible(rows[mini(i + 1, rows.size() - 1)]["row"])


# ---- vuelta 1 real, de $0: el bot "activo" juega la primera vuelta entera y reforma (base de A y de C) ----
func _sesion_vuelta1() -> void:
	_duration = 290.0
	_juice_al_maximo()
	_m().reforms = 0
	_m().dirty = true
	_bot_en_vivo("activo")


# ---- B · casi pierdo: no remarca y deja pasar billetes hasta que la inflación lo come; después se salva ----
## El bot juega sin remarcar (remark_pct altísimo) y agarrando pocos billetes; cuando lleva 40 s en hiperinflación,
## "se avivó": remarca y empieza a agarrar todos los billetes (lo mismo que haría un jugador que se da cuenta).
var _hiper_desde: float = -1.0
var _salvado: bool = false


func _sesion_casi_pierdo() -> void:
	_duration = 300.0
	_juice_al_maximo()
	_jugar_offline(3, "activo", 11)          # la vuelta 4 es la de más hiperinflación (simulación: 40 %, 87 s)
	_bot_reforma = false
	_bot_en_vivo("activo", {"remark_pct": 1.0e9, "catch": 0.25})
	# las decisiones que disparan la inflación (opciones reales de las noticias del juego):
	# tarifazo → "colgarse del poste" (inflación x1,5 por 40 s) y corrida → "aguantar" (inflación x2 por 20 s)
	_noticia(110.0, "tarifazo", 1)
	_noticia(125.0, "corrida", 1)
	_sesion_extra = func() -> void:
		var m: GameModel = _m()
		if _salvado:
			return
		if EconomyLogic.era_of(m) == 5:
			if _hiper_desde < 0.0:
				_hiper_desde = _t
			elif _t - _hiper_desde > 10.0:
				_salvado = true
				_bot.cfg["remark_pct"] = 4.0
				_bot.cfg["catch"] = 1.0
				_bot.cfg["react"] = 0.5
				Economy.remark()
				_beat("SE SALVA: remarca y agarra todos los billetes")
		else:
			_hiper_desde = -1.0


# ---- A · progresión: una vuelta avanzada entera, del carrito al holding ----
func _sesion_progresion() -> void:
	_duration = 150.0
	_juice_al_maximo()
	_jugar_offline(0, "activo", 17, true)
	_bot_reforma = false
	_bot_en_vivo("gastador")
	var m: GameModel = _m()
	print("BEAT 0.00 imprenta disponible: %s, holding disponible: %s" % [
		str(EconomyLogic.business_available(m, GameData.businesses[8])), str(EconomyLogic.business_available(m, GameData.businesses[9]))])
	_sesion_extra = func() -> void:
		# termina 60 s después de comprar el holding (para que el final sea lo más grande)
		if _m().owned_count("holding") > 0 and _duration > _t + 60.0:
			_duration = _t + 60.0


# ---- J · imprenta: vuelta avanzada; cada vez que puede, compra otra imprenta de billetes ----
func _sesion_imprenta() -> void:
	_duration = 150.0
	_juice_al_maximo()
	_jugar_offline(0, "activo", 29, true)
	_bot_reforma = false
	_bot_en_vivo("gastador")
	_sesion_extra = func() -> void:
		var m: GameModel = _m()
		# cada medio segundo intenta comprar otra imprenta (como un jugador que va a fondo con la imprenta)
		if EconomyLogic.business_available(m, GameData.businesses[8]) and int(_t * 30.0) % 15 == 0:
			Economy.buy_business("imprenta", 1)
			_mostrar_negocio(7)
