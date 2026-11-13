class_name GameScreen
extends Control
## Pantalla de juego completa, construida por código.

signal request_menu
signal request_credits
signal request_demo_end

const TABS: Array = ["ui.tab.biz", "ui.tab.upg", "ui.tab.ref", "ui.tab.reform", "ui.tab.album", "ui.tab.timba", "ui.tab.ach"]
## Mecánica que desbloquea cada pestaña ("" = siempre disponible).
const TAB_FEATURE: Array = ["", "upgrades", "refuges", "reform", "album", "timba", ""]

var world: MarginContainer
var fx_layer: Control
var tint: ColorRect
var toast_box: VBoxContainer
var raise_sign: ScribbleText

var money_label: Label
var power_label: Label
var rate_label: Label
var month_bar: ChalkBar
var month_label: Label
var era_label: Label
var empanada: EmpanadaButton
var remark_btn: Button
var remark_info: Label
var remark_bar: ChalkBar
var click_label: Label

var tab_buttons: Array = []
var pages: Array = []
var biz_rows: Array = []          # [{def,row,owned,income,btn}]
var qty_buttons: Array = []
var upg_list: VBoxContainer
var upg_buttons: Array = []       # [{btn, cost}]
var ref_rows: Dictionary = {}
var ref_note: Label
var reform_labels: Dictionary = {}
var plan_buttons: Dictionary = {}
var body: BoxContainer
var header_grid: GridContainer
var rate_box: Control
var remark_panel: Control
var _seen_tabs: Array = [0]
var _advice: Dictionary = {}
var _highlight: ActionHighlight
var _idle: float = 0.0
var _override: Dictionary = {}
var _override_t: float = 0.0
var left_col: Control

var portrait: bool = false
var album_page: AlbumPage
var timba_page: TimbaPage
var ach_list: VBoxContainer
var ach_info: Label
var event_panel: PanelContainer
var event_label: Label
var decision_panel: PanelContainer
var decision_title: Label
var decision_buttons: Array = []
var decision_bar: ChalkBar
var decision_default: Label
var ticker_clip: Control
var ticker_label: Label

var _tab: int = 0
var _buy_mode: int = 1
var _fast: float = 0.0
var _clock: float = 0.0
var _rate: float = 0.03
var _upg_dirty: bool = true
var _album_dirty: bool = true
var race_meter: RaceMeter
var objective_note: ObjectiveNote
var _ach_dirty: bool = true
var _reform_armed: float = 0.0
var _shake_t: float = 0.0
var _shake_amp: float = 0.0
var _headline_queue: Array = []
var _last_era: int = 1
var _busy_overlay: Control
var _fps_watch: FpsWatch = FpsWatch.new(45.0, 5.0)
var _screen_age: float = 0.0


## Candadito de tiza que se dibuja a la izquierda del nombre de una pestaña bloqueada.
class LockIcon:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(22, 26)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c: Color = Chalk.YELLOW
		Chalk.polyline(self, PackedVector2Array([Vector2(5, 12), Vector2(5, 7), Vector2(8, 3), Vector2(14, 3), Vector2(17, 7), Vector2(17, 12)]), c, 2.6, 71, 0.5)
		Chalk.polygon(self, PackedVector2Array([Vector2(2, 12), Vector2(20, 12), Vector2(20, 24), Vector2(2, 24)]), c, 2.6, 72, true, Color(c, 0.5), 4.0, 0.5)
		draw_circle(Vector2(11, 17.5), 2.2, Color(0.1, 0.16, 0.12))


func gm() -> GameModel:
	return GameState.m


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world = MarginContainer.new()
	world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		world.add_theme_constant_override("margin_" + side, 24)
	world.add_theme_constant_override("margin_bottom", 34)
	add_child(world)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	world.add_child(root)
	root.add_child(_build_header())
	body = BoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	root.add_child(body)
	body.add_child(_build_left())
	body.add_child(_build_right())
	root.add_child(_build_event_banner())
	root.add_child(_build_ticker())

	tint = ColorRect.new()
	tint.color = Color(0.9, 0.05, 0.05, 0.0)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tint)
	fx_layer = Control.new()
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.set_meta("qa_ignore", true)
	fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fx_layer)
	raise_sign = ScribbleText.new()
	fx_layer.add_child(raise_sign)
	# notitas de aviso: abajo a la derecha, sobre la cinta de titulares (no tapan la plata ni la empanada)
	toast_box = VBoxContainer.new()
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_box.add_theme_constant_override("separation", 4)
	toast_box.anchor_left = 1.0
	toast_box.anchor_right = 1.0
	toast_box.anchor_top = 1.0
	toast_box.anchor_bottom = 1.0
	toast_box.offset_left = -400.0
	toast_box.offset_right = -24.0
	toast_box.offset_bottom = -70.0
	toast_box.offset_top = -70.0
	toast_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	fx_layer.add_child(toast_box)
	# la acción recomendada: una sola cosa brilla y late, con una flecha de tiza
	_highlight = ActionHighlight.new()
	fx_layer.add_child(_highlight)

	_connect_bus()
	_last_era = gm().era
	_select_tab(0)
	_next_headline()
	_apply_layout()
	resized.connect(_apply_layout)
	_silent_catchup()
	_start_tutorial()
	Economy.running = true
	_refresh_all()




func _connect_bus() -> void:
	EventBus.clicked.connect(_on_clicked)
	EventBus.business_bought.connect(_on_business_bought)
	EventBus.upgrade_bought.connect(func(_id: String) -> void:
		_upg_dirty = true
		_play("buy"))
	EventBus.month_passed.connect(_on_month_passed)
	EventBus.remarked.connect(_on_remarked)
	EventBus.era_changed.connect(_on_era_changed)
	EventBus.event_started.connect(_on_event_started)
	EventBus.event_ended.connect(func(_id: String) -> void: pass)
	EventBus.event_choice.connect(func(_id: String) -> void: _play("event"))
	EventBus.objective_done.connect(_on_objective_done)
	EventBus.unlock.connect(func(f: String) -> void: _unlock_queue.append(f))
	EventBus.page_done.connect(_on_page_done)
	EventBus.quiniela_drawn.connect(_on_quiniela_drawn)
	EventBus.dollar_settled.connect(_on_dollar_settled)
	EventBus.sticker_won.connect(_on_sticker_won)
	EventBus.secret_end.connect(_show_secret)
	EventBus.achievement_unlocked.connect(_on_achievement)
	EventBus.reform_done.connect(_on_reform_done)
	EventBus.plan_done.connect(_on_plan_done)
	EventBus.victory.connect(_on_victory)
	EventBus.demo_end.connect(_on_demo_end)
	EventBus.toast.connect(func(key: String) -> void: _toast(tr(key), UIKit.C_GOLD))
	EventBus.headline.connect(func(key: String) -> void: _headline_queue.push_front(key))


func _play(sound: String, pitch: float = 1.0) -> void:
	if SoundFx.instance != null:
		SoundFx.instance.play(sound, pitch)


# =====================================================================
#  Construcción de la interfaz
# =====================================================================
func _build_header() -> Control:
	var p: PanelContainer = UIKit.panel(UIKit.C_PANEL, 10)
	header_grid = GridContainer.new()
	header_grid.columns = 3
	header_grid.add_theme_constant_override("h_separation", 24)
	header_grid.add_theme_constant_override("v_separation", 8)
	var h: GridContainer = header_grid
	p.add_child(h)
	# 1) la plata: lo más grande y brillante de la pantalla
	var left: VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 0)
	h.add_child(left)
	money_label = UIKit.label("$0", 64, Color("#FFE45C"), HORIZONTAL_ALIGNMENT_LEFT, true)
	money_label.add_theme_color_override("font_outline_color", Color("#1c1508"))
	money_label.add_theme_constant_override("outline_size", 9)
	left.add_child(money_label)
	power_label = UIKit.label("", 15, UIKit.C_DIM)
	left.add_child(power_label)
	# 2) el semáforo de la inflación
	race_meter = RaceMeter.new()
	race_meter.custom_minimum_size = Vector2(380, 92)
	h.add_child(race_meter)
	# 3) la tasa exacta: recién aparece cuando el tutorial la presenta
	var mid: VBoxContainer = VBoxContainer.new()
	mid.custom_minimum_size = Vector2(190, 0)
	rate_box = mid
	h.add_child(mid)
	mid.add_child(UIKit.label(tr("ui.inflation"), 13, UIKit.C_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	rate_label = UIKit.label("3 %", 36, UIKit.C_RED, HORIZONTAL_ALIGNMENT_CENTER, true)
	mid.add_child(rate_label)
	month_bar = ChalkBar.new()
	month_bar.show_percentage = false
	month_bar.custom_minimum_size = Vector2(0, 8)
	month_bar.max_value = 1.0
	month_bar.add_theme_stylebox_override("background", UIKit.box(Color("#0f1820"), 4))
	month_bar.add_theme_stylebox_override("fill", UIKit.box(UIKit.C_RED, 4))
	mid.add_child(month_bar)
	month_label = UIKit.label("", 13, UIKit.C_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	mid.add_child(month_label)
	return p


func _build_left() -> Control:
	var col: VBoxContainer = VBoxContainer.new()
	col.custom_minimum_size = Vector2(340, 0)
	col.add_theme_constant_override("separation", 12)
	var p: PanelContainer = UIKit.panel(UIKit.C_PANEL, 10)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(p)
	var v: VBoxContainer = VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var top_row: HBoxContainer = HBoxContainer.new()
	v.add_child(top_row)
	era_label = UIKit.label("", 20, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT, true)
	era_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(era_label)
	var menu_btn: Button = Button.new()
	menu_btn.text = tr("ui.menu")
	UIKit.style_button(menu_btn, UIKit.C_PANEL2, 15)
	menu_btn.pressed.connect(func() -> void: request_menu.emit())
	top_row.add_child(menu_btn)
	empanada = EmpanadaButton.new()
	empanada.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	empanada.custom_minimum_size = Vector2(250, 160)
	empanada.pressed.connect(func(_pos: Vector2) -> void: Economy.click())
	v.add_child(empanada)
	click_label = UIKit.label("", 15, UIKit.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(click_label)
	objective_note = ObjectiveNote.new()
	objective_note.go_pressed.connect(_on_objective_go)
	col.add_child(objective_note)
	# remarcar: recién aparece cuando el tutorial lo presenta (o desde la Era 3)
	var rp: PanelContainer = UIKit.panel(UIKit.C_PANEL, 10)
	remark_panel = rp
	col.add_child(rp)
	var rv: VBoxContainer = VBoxContainer.new()
	rp.add_child(rv)
	remark_btn = Button.new()
	remark_btn.text = tr("ui.remark")
	remark_btn.custom_minimum_size = Vector2(0, 50)
	UIKit.style_button(remark_btn, UIKit.C_BLUE, 20)
	remark_btn.pressed.connect(_on_remark_pressed)
	rv.add_child(remark_btn)
	remark_bar = ChalkBar.new()
	remark_bar.fill_color = UIKit.C_GREEN
	remark_bar.show_percentage = false
	remark_bar.custom_minimum_size = Vector2(0, 8)
	remark_bar.max_value = 1.0
	remark_bar.add_theme_stylebox_override("background", UIKit.box(Color("#0f1820"), 4))
	remark_bar.add_theme_stylebox_override("fill", UIKit.box(UIKit.C_GREEN, 4))
	rv.add_child(remark_bar)
	remark_info = UIKit.label("", 15, UIKit.C_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	remark_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rv.add_child(remark_info)
	left_col = col
	return col


func _build_right() -> Control:
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	var bar: HBoxContainer = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)
	col.add_child(bar)
	for i in range(TABS.size()):
		var b: Button = Button.new()
		b.text = tr(TABS[i])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.toggle_mode = false
		UIKit.style_tab(b, false)
		b.pressed.connect(_select_tab.bind(i))
		bar.add_child(b)
		tab_buttons.append(b)
	var holder: PanelContainer = UIKit.panel(UIKit.C_PANEL, 10)
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(holder)
	var stack: Control = Control.new()
	holder.add_child(stack)
	pages = [_build_biz_page(), _build_upg_page(), _build_refuge_page(), _build_reform_page(), _build_album_page(), _build_timba_page(), _build_ach_page()]
	for pg in pages:
		stack.add_child(pg)
		pg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return col


func _scroll_page() -> Array:
	var sc: ScrollContainer = ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v: VBoxContainer = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	sc.add_child(v)
	return [sc, v]


func _build_biz_page() -> Control:
	var pr: Array = _scroll_page()
	var v: VBoxContainer = pr[1]
	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	v.add_child(top)
	top.add_child(UIKit.label(tr("ui.buy_qty"), 14, UIKit.C_DIM))
	for q in [1, 10, 100, -1]:
		var b: Button = Button.new()
		b.text = tr("ui.qty.max") if q < 0 else "x%d" % q
		b.custom_minimum_size = Vector2(64, 0)
		UIKit.style_button(b, UIKit.C_PANEL2, 14)
		b.pressed.connect(func() -> void:
			_buy_mode = q
			_refresh_qty_buttons())
		top.add_child(b)
		qty_buttons.append({"btn": b, "q": q})
	for def in GameData.businesses:
		var row: PanelContainer = UIKit.panel(UIKit.C_PANEL2, 8)
		var h: HBoxContainer = HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		row.add_child(h)
		var icon: BusinessIcon = BusinessIcon.new(def["id"])
		icon.custom_minimum_size = Vector2(58, 58)
		h.add_child(icon)
		var info: VBoxContainer = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(info)
		info.add_child(UIKit.label(tr(def["name_key"]), 17))
		var desc: Label = UIKit.label(tr(def["desc_key"]), 12, UIKit.C_DIM)
		desc.clip_text = true
		info.add_child(desc)
		var owned: Label = UIKit.label("", 20, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		owned.custom_minimum_size = Vector2(60, 0)
		h.add_child(owned)
		var income: ChalkPrice = ChalkPrice.new()
		income.color = UIKit.C_GREEN
		income.font_size = int(21 * UIKit.FS)
		income.custom_minimum_size = Vector2(150, 40)
		income.seed_v = 5 + int(def["idx"]) * 3
		h.add_child(income)
		var cost_price: ChalkPrice = ChalkPrice.new()
		cost_price.color = UIKit.C_GOLD
		cost_price.font_size = int(22 * UIKit.FS)
		cost_price.custom_minimum_size = Vector2(150, 40)
		cost_price.seed_v = 9 + int(def["idx"]) * 3
		h.add_child(cost_price)
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(116, 44)
		UIKit.style_button(btn, UIKit.C_GREEN.darkened(0.25), 17)
		btn.pressed.connect(_on_buy_business.bind(def["id"]))
		h.add_child(btn)
		v.add_child(row)
		biz_rows.append({"def": def, "row": row, "owned": owned, "income": income, "cost": cost_price, "btn": btn, "icon": icon, "desc": desc})
	_refresh_qty_buttons()
	return pr[0]


func _build_upg_page() -> Control:
	var pr: Array = _scroll_page()
	upg_list = pr[1]
	return pr[0]


func _build_refuge_page() -> Control:
	var pr: Array = _scroll_page()
	var v: VBoxContainer = pr[1]
	ref_note = UIKit.label("", 14, UIKit.C_DIM)
	ref_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(ref_note)
	for r in GameData.refuges:
		var id: String = r["id"]
		var row: PanelContainer = UIKit.panel(UIKit.C_PANEL2, 8)
		var h: HBoxContainer = HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		row.add_child(h)
		var icon: PanelContainer = UIKit.panel(r["color"], 10)
		icon.custom_minimum_size = Vector2(40, 40)
		h.add_child(icon)
		var info: VBoxContainer = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(info)
		info.add_child(UIKit.label(tr(r["name_key"]), 17))
		var d: Label = UIKit.label(tr(r["desc_key"]), 12, UIKit.C_DIM)
		d.clip_text = true
		info.add_child(d)
		var val: Label = UIKit.label("", 14, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
		val.custom_minimum_size = Vector2(190, 0)
		h.add_child(val)
		var b25: Button = Button.new()
		b25.text = tr("ui.ref.buy25")
		UIKit.style_button(b25, UIKit.C_GREEN.darkened(0.25), 14)
		b25.pressed.connect(func() -> void: _on_refuge_buy(id, 0.25))
		h.add_child(b25)
		var b100: Button = Button.new()
		b100.text = tr("ui.ref.buyall")
		UIKit.style_button(b100, UIKit.C_GREEN.darkened(0.25), 14)
		b100.pressed.connect(func() -> void: _on_refuge_buy(id, 1.0))
		h.add_child(b100)
		var sell: Button = Button.new()
		sell.text = tr("ui.ref.sell")
		UIKit.style_button(sell, UIKit.C_RED.darkened(0.3), 14)
		sell.pressed.connect(func() -> void: _on_refuge_sell(id))
		h.add_child(sell)
		v.add_child(row)
		ref_rows[id] = {"value": val, "b25": b25, "b100": b100, "sell": sell}
	return pr[0]


func _section(v: VBoxContainer, title: String) -> VBoxContainer:
	var p: PanelContainer = UIKit.panel(UIKit.C_PANEL2, 10)
	v.add_child(p)
	var inner: VBoxContainer = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	p.add_child(inner)
	inner.add_child(UIKit.label(title, 20, UIKit.C_GOLD))
	return inner


func _wrap_label(text: String, size: int = 14, color: Color = UIKit.C_TEXT) -> Label:
	var l: Label = UIKit.label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _build_reform_page() -> Control:
	var pr: Array = _scroll_page()
	var v: VBoxContainer = pr[1]
	# Reforma
	var s1: VBoxContainer = _section(v, tr("ui.reform.title"))
	s1.add_child(_wrap_label(tr("ui.reform.desc"), 14, UIKit.C_DIM))
	reform_labels["cred"] = _wrap_label("", 15)
	s1.add_child(reform_labels["cred"])
	reform_labels["gain"] = _wrap_label("", 15, UIKit.C_GREEN)
	s1.add_child(reform_labels["gain"])
	var rb: Button = Button.new()
	rb.custom_minimum_size = Vector2(0, 48)
	UIKit.style_button(rb, UIKit.C_RED.darkened(0.2), 18)
	rb.pressed.connect(_on_reform_pressed)
	s1.add_child(rb)
	reform_labels["btn"] = rb
	# Plan económico
	var s2: VBoxContainer = _section(v, tr("ui.plan.title"))
	s2.add_child(_wrap_label(tr("ui.plan.desc"), 14, UIKit.C_DIM))
	reform_labels["plan_info"] = _wrap_label("", 14, UIKit.C_TEXT)
	s2.add_child(reform_labels["plan_info"])
	for pd in GameData.plans:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		s2.add_child(row)
		var col: VBoxContainer = VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		col.add_child(UIKit.label(tr(pd["name_key"]), 16))
		col.add_child(_wrap_label(tr(pd["desc_key"]), 12, UIKit.C_DIM))
		var b: Button = Button.new()
		b.custom_minimum_size = Vector2(170, 40)
		UIKit.style_button(b, UIKit.C_BLUE, 14)
		b.pressed.connect(_on_plan_pressed.bind(pd["id"]))
		row.add_child(b)
		plan_buttons[pd["id"]] = b
	# Cruzada
	var s3: VBoxContainer = _section(v, tr("ui.cruz.title"))
	s3.add_child(_wrap_label(tr("ui.cruz.desc"), 14, UIKit.C_DIM))
	reform_labels["cruz_info"] = _wrap_label("", 15)
	s3.add_child(reform_labels["cruz_info"])
	var cb: Button = Button.new()
	cb.custom_minimum_size = Vector2(0, 46)
	UIKit.style_button(cb, UIKit.C_GREEN.darkened(0.2), 16)
	cb.pressed.connect(_on_measure_pressed)
	s3.add_child(cb)
	reform_labels["cruz_btn"] = cb
	return pr[0]


func _build_album_page() -> Control:
	album_page = AlbumPage.new()
	album_page.pack_bought.connect(_open_pack_overlay)
	album_page.message.connect(func(text: String) -> void: _toast(text, UIKit.C_GOLD))
	return album_page


func _build_timba_page() -> Control:
	timba_page = TimbaPage.new()
	timba_page.scratch_requested.connect(_open_scratch)
	timba_page.message.connect(func(text: String) -> void: _toast(text, UIKit.C_GOLD))
	return timba_page



func _build_ach_page() -> Control:
	var pr: Array = _scroll_page()
	var v: VBoxContainer = pr[1]
	ach_info = UIKit.label("", 15, UIKit.C_DIM)
	v.add_child(ach_info)
	ach_list = VBoxContainer.new()
	ach_list.add_theme_constant_override("separation", 4)
	v.add_child(ach_list)
	return pr[0]


func _build_event_banner() -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	# decisión del evento: notita de tiza con 2 opciones y un timer de 10 s
	decision_panel = PanelContainer.new()
	decision_panel.add_theme_stylebox_override("panel", UIKit.chalk_box(Chalk.YELLOW, Color(0, 0, 0, 0.28), 2.8))
	decision_panel.visible = false
	var dv: VBoxContainer = VBoxContainer.new()
	dv.add_theme_constant_override("separation", 4)
	decision_panel.add_child(dv)
	decision_title = UIKit.label("", 22, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT, true)
	dv.add_child(decision_title)
	var drow: HBoxContainer = HBoxContainer.new()
	drow.add_theme_constant_override("separation", 12)
	dv.add_child(drow)
	for i in range(2):
		var b: Button = Button.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 58)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UIKit.style_button(b, UIKit.C_GREEN if i == 0 else UIKit.C_BLUE, 17)
		var idx: int = i
		b.pressed.connect(func() -> void: Economy.choose_event(idx))
		drow.add_child(b)
		decision_buttons.append(b)
	var bar_row: HBoxContainer = HBoxContainer.new()
	dv.add_child(bar_row)
	decision_bar = ChalkBar.new()
	decision_bar.fill_color = UIKit.C_GOLD
	decision_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_row.add_child(decision_bar)
	decision_default = UIKit.label("", 13, UIKit.C_DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	bar_row.add_child(decision_default)
	box.add_child(decision_panel)
	event_panel = UIKit.panel(Color("#5a3a1a"), 8)
	event_panel.visible = false
	var h: HBoxContainer = HBoxContainer.new()
	event_panel.add_child(h)
	event_label = UIKit.label("", 16, UIKit.C_GOLD)
	event_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(event_label)
	box.add_child(event_panel)
	return box
func _build_ticker() -> Control:
	var p: PanelContainer = UIKit.panel(Color("#0d141b"), 6)
	var h: HBoxContainer = HBoxContainer.new()
	p.add_child(h)
	var tag: ChalkTag = ChalkTag.new(tr("ui.news"))
	h.add_child(tag)
	ticker_clip = Control.new()
	ticker_clip.clip_contents = true
	ticker_clip.set_meta("qa_ignore", true)
	ticker_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ticker_clip.custom_minimum_size = Vector2(0, 24)
	h.add_child(ticker_clip)
	ticker_label = UIKit.label("", 15, UIKit.C_TEXT)
	ticker_clip.add_child(ticker_label)
	return p


# =====================================================================
#  Pestañas
# =====================================================================
func _select_tab(i: int) -> void:
	_tab = i
	if not _seen_tabs.has(i):
		_seen_tabs.append(i)
	for k in range(pages.size()):
		pages[k].visible = (k == i)

		if not _tab_locked[k]:
			UIKit.style_tab(tab_buttons[k], k == i)
	_upg_dirty = true
	_refresh_page()


func _refresh_qty_buttons() -> void:
	for e in qty_buttons:
		UIKit.style_button(e["btn"], UIKit.C_BLUE if e["q"] == _buy_mode else UIKit.C_PANEL, 14)


# =====================================================================
#  Refresco
# =====================================================================
func _process(delta: float) -> void:
	_clock += delta
	_screen_age += delta
	if _screen_age > 8.0 and Settings.quality < 2 and DisplayServer.get_name() != "headless":
		if _fps_watch.update(Engine.get_frames_per_second(), delta):
			_toast(tr("ui.fps_hint"), UIKit.C_GOLD)
	_fast += delta
	_reform_armed = maxf(0.0, _reform_armed - delta)
	if _fast >= 0.1:
		_fast = 0.0
		_refresh_all()
	_update_juice(delta)
	_update_advice(delta)
	_update_ticker(delta)


func _refresh_all() -> void:
	var m: GameModel = gm()
	_rate = EconomyLogic.inflation_rate(m)
	if SoundFx.instance != null:
		SoundFx.instance.set_tempo_from_inflation(_rate)
	money_label.text = UIKit.money(m.money)
	power_label.text = tr("ui.power") % EconomyLogic.purchasing_power(m).format()
	rate_label.text = "%s %%" % BigNumber.from_float(_rate * 100.0).format(1)
	var ms: float = EconomyLogic.B("month_seconds")
	month_bar.value = m.month_progress / ms
	month_label.text = tr("ui.month") % int(ceilf(ms - m.month_progress))
	var era_def: Dictionary = GameData.era_def(m.era)
	era_label.text = tr(era_def["name_key"])
	era_label.add_theme_color_override("font_color", era_def["color"])
	empanada.rate = _rate
	if ChalkBoard.instance != null:
		var smudge: float = clampf((_rate - 0.03) * 1.2, 0.0, 1.0)
		ChalkBoard.instance.set_smudge(smudge)
		if ChalkPost.instance != null:
			ChalkPost.instance.set_strength(1.0 - smudge * 0.3)
	click_label.text = tr("ui.click_hint") + "  +" + UIKit.money(EconomyLogic.click_value(m))
	_refresh_hud_extras(m)
	_refresh_remark()
	_refresh_events()
	_refresh_page()


func _refresh_page() -> void:
	match _tab:
		0: _refresh_biz()
		1: _refresh_upg()
		2: _refresh_refuges()
		3: _refresh_reform()
		4: _refresh_album()
		5: timba_page.refresh(gm())
		6: _refresh_ach()


func _refresh_remark() -> void:
	var m: GameModel = gm()
	var lag: float = 0.0
	if EconomyLogic.needs_remark(m):
		lag = 1.0 - clampf(m.my_prices.div(m.price_level).to_float(), 0.0, 1.0)
	if lag > 0.0005:
		remark_info.text = tr("ui.remark_lag") % mini(999, int(round((1.0 / maxf(0.01, 1.0 - lag) - 1.0) * 100.0)))      # cuánto más ganarías al remarcar
		remark_info.add_theme_color_override("font_color", UIKit.C_RED if lag > 0.2 else UIKit.C_GOLD)
	else:
		remark_info.text = tr("ui.remark_ok")
		remark_info.add_theme_color_override("font_color", UIKit.C_GREEN)
	remark_bar.value = m.remark_window / EconomyLogic.B("remark_window")
	if m.remark_window > 0.0 and lag > 0.0005:
		remark_info.text = tr("ui.remark_now")
		remark_info.add_theme_color_override("font_color", UIKit.C_GREEN)
	remark_btn.disabled = lag <= 0.0005 or m.remark_cd > 0.0
	if m.auto_remark_interval > 0.0:
		remark_btn.text = tr("ui.remark") + "  (auto %ds)" % int(m.auto_remark_interval)
	else:
		remark_btn.text = tr("ui.remark")


func _refresh_events() -> void:
	var m: GameModel = gm()
	# decisión pendiente
	if m.pending_choice.is_empty():
		decision_panel.visible = false
	else:
		var id: String = str(m.pending_choice["id"])
		decision_panel.visible = true
		decision_title.text = tr("ev.%s.q" % id)
		decision_buttons[0].text = tr("ev.%s.a" % id) + "\n" + tr("ev.%s.ad" % id)
		decision_buttons[1].text = tr("ev.%s.b" % id) + "\n" + tr("ev.%s.bd" % id)
		decision_bar.max_value = EconomyLogic.CHOICE_SECONDS
		decision_bar.value = float(m.pending_choice["remaining"])
		var di: int = EconomyLogic.default_choice(id)
		decision_default.text = tr("ui.decision.default") % tr("ev.%s.%s" % [id, "a" if di == 0 else "b"])
	# efectos activos
	if m.active_events.is_empty():
		event_panel.visible = false
		return
	event_panel.visible = true
	var parts: Array = []
	for ev in m.active_events:
		var d: Dictionary = GameData.events[GameData.event_idx[ev["id"]]]
		parts.append("%s (%d s)" % [tr(d["name_key"]), int(ceilf(float(ev["remaining"])))])
	event_label.text = "  |  ".join(parts)


func _refresh_biz() -> void:
	var m: GameModel = gm()
	var shown_next: bool = false
	for e in biz_rows:
		var def: Dictionary = e["def"]
		var unlocked: bool = EconomyLogic.is_unlocked(m, def)
		e["row"].visible = unlocked
		if not unlocked:
			continue
		var n: int = m.owned_count(def["id"])
		e["owned"].text = "x%d" % n
		var bm: float = float(m.biz_up_mult.get(def["id"], 1.0)) * EconomyLogic.milestone_mult(n)
		var per_sec: BigNumber = def["base_income"].mul_f(float(n) * bm * m.global_mult).mul(m.my_prices).mul_f(EconomyLogic.event_income_mult(m))
		e["income"].rate = _rate
		e["cost"].rate = _rate
		e["income"].set_text("+%s%s" % [UIKit.money(per_sec), tr("ui.per_sec")])
		var qty: int = _buy_mode
		if qty < 0:
			qty = maxi(1, EconomyLogic.max_affordable(m, def))
		var cost: BigNumber = EconomyLogic.business_cost(m, def, qty)
		e["cost"].set_text(UIKit.money(cost))
		var ug: BigNumber = EconomyLogic.unit_gain(m, def).mul(m.my_prices).mul_f(EconomyLogic.event_income_mult(m) * m.refuge_mult)
		var lost: BigNumber = EconomyLogic.lag_loss(m, ug)
		var tip: String = (tr("tip.biz") % [UIKit.money(ug), UIKit.money(lost)]) if not lost.is_zero() else (tr("tip.biz_ok") % UIKit.money(ug))
		e["btn"].tooltip_text = tip
		e["row"].tooltip_text = tip
		e["btn"].text = "%s x%d" % [tr("ui.buy"), qty]
		e["btn"].disabled = cost.gt(m.money)


func _refresh_upg() -> void:
	var m: GameModel = gm()
	_upg_timer_tick()
	for e in upg_buttons:
		e["btn"].disabled = (e["cost_fn"].call() as BigNumber).gt(m.money)
		e["btn"].text = UIKit.money(e["cost_fn"].call())


var _upg_acc: float = 0.0


func _upg_timer_tick() -> void:
	_upg_acc += 0.1
	if not (_upg_dirty and _upg_acc >= 0.3):
		return
	_upg_dirty = false
	_upg_acc = 0.0
	_rebuild_upgrades()


func _rebuild_upgrades() -> void:
	var m: GameModel = gm()
	UIKit.clear_children(upg_list)
	upg_buttons.clear()
	var list: Array = []
	for u in GameData.upgrades:
		if EconomyLogic.upgrade_visible(m, u):
			list.append(u)
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["cost"].lt(b["cost"]))
	if list.is_empty():
		upg_list.add_child(UIKit.label(tr("ui.upg.none"), 15, UIKit.C_DIM))
		return
	var shown: int = 0
	for u in list:
		if shown >= 14:
			break
		shown += 1
		var row: PanelContainer = UIKit.panel(UIKit.C_PANEL2, 8)
		var h: HBoxContainer = HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		row.add_child(h)
		var info: VBoxContainer = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(info)
		info.add_child(UIKit.label(GameData.upgrade_title(u), 16))
		info.add_child(UIKit.label(tr(u["desc_key"]), 12, UIKit.C_DIM))
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(170, 40)
		UIKit.style_button(btn, UIKit.C_GOLD.darkened(0.45), 15)
		btn.tooltip_text = _upgrade_tip(u)
		var uid: String = u["id"]
		btn.pressed.connect(func() -> void: Economy.buy_upgrade(uid))
		h.add_child(btn)
		upg_list.add_child(row)
		upg_buttons.append({"btn": btn, "id": uid, "cost_fn": func() -> BigNumber: return EconomyLogic.upgrade_cost(gm(), u)})
	if list.size() > shown:
		upg_list.add_child(UIKit.label(tr("ui.upg.more") % (list.size() - shown), 13, UIKit.C_DIM))


func _refresh_refuges() -> void:
	var m: GameModel = gm()
	var unlocked: bool = EconomyLogic.refuges_unlocked(m)
	var blocked: bool = EconomyLogic.refuges_blocked(m)
	if not unlocked:
		ref_note.text = tr("ui.ref.locked")
	elif blocked:
		ref_note.text = tr("ui.ref.blocked")
	else:
		ref_note.text = tr("ui.ref.note") + "
" + tr("ui.ref.bonus") % [EconomyLogic.refuge_diversified_count(m), GameData.refuges.size(), int(round(EconomyLogic.B("refuge_bonus") * EconomyLogic.refuge_diversified_count(m) * 100.0))]
	for r in GameData.refuges:
		var id: String = r["id"]
		var e: Dictionary = ref_rows[id]
		var value: BigNumber = EconomyLogic.refuge_value(m, id)
		e["value"].text = "%s: %s  (x%.2f)" % [tr("ui.ref.have"), UIKit.money(value), float(m.refuge_price[id])]
		var real_have: BigNumber = m.refuge_units[id].mul_f(float(m.refuge_price[id]))
		e["value"].add_theme_color_override("font_color", UIKit.C_GREEN if (not real_have.is_zero() and real_have.ge(m.base_income.mul_f(EconomyLogic.B("refuge_bonus_seconds")))) else UIKit.C_GOLD)
		var can: bool = unlocked and not blocked
		e["b25"].disabled = not can or m.money.is_zero()
		var rtip: String = tr("tip.refuge") % ["%d %%" % int(round(EconomyLogic.refuge_fee(m, id) * 100.0)), BigNumber.from_float(float(m.refuge_price[id])).format(2)]
		e["b25"].tooltip_text = rtip
		e["b100"].tooltip_text = rtip
		e["b100"].disabled = not can or m.money.is_zero()
		e["sell"].disabled = not can or value.is_zero()


func _refresh_reform() -> void:
	var m: GameModel = gm()
	var cred_total: float = float(m.credibility) + m.legacy_cred
	var bonus_pct: int = int(round(EconomyLogic.B("cred_bonus") * cred_total * 100.0))
	var infl_pct: int = int(round((1.0 - maxf(0.5, 1.0 / (1.0 + EconomyLogic.B("cred_inflation_reduction") * cred_total))) * 100.0))
	reform_labels["cred"].text = tr("ui.reform.cred") % [m.credibility, bonus_pct, infl_pct]
	var gain: int = EconomyLogic.reform_gain(m)
	var rb: Button = reform_labels["btn"]
	if m.era < int(EconomyLogic.B("reform_min_era")):
		reform_labels["gain"].text = tr("ui.reform.locked")
		rb.disabled = true
	elif gain < 1:
		reform_labels["gain"].text = tr("ui.reform.need")
		rb.disabled = true
	else:
		reform_labels["gain"].text = tr("ui.reform.gain") % gain
		rb.disabled = false
	rb.text = tr("ui.reform.confirm") if _reform_armed > 0.0 else tr("ui.reform.btn")
	rb.tooltip_text = tr("tip.reform") % [str(maxi(0, floori(m.price_level.log10()))), str(gain), "%d %%" % int(round(float(gain) * EconomyLogic.B("cred_bonus") * 100.0))]
	# plan
	var plan_name: String = tr("plan." + m.plan_id) if m.plan_id != "" else "-"
	if m.era < int(EconomyLogic.B("plan_min_era")):
		reform_labels["plan_info"].text = tr("ui.plan.locked")
	else:
		reform_labels["plan_info"].text = (tr("ui.plan.active") % plan_name) + "   " + (tr("ui.plan.need") % EconomyLogic.plan_min_cred(m))
	for pd in GameData.plans:
		var b: Button = plan_buttons[pd["id"]]
		var used: bool = m.plans_used.has(pd["id"])
		b.text = tr("ui.plan.used") if used else tr("ui.plan.btn")
		b.disabled = used or not EconomyLogic.can_plan(m)
	# cruzada
	var cb: Button = reform_labels["cruz_btn"]
	var total: int = EconomyLogic.measure_count_total()
	if m.era < 5:
		reform_labels["cruz_info"].text = tr("ui.cruz.locked")
		cb.disabled = true
		cb.text = "-"
	elif m.measures >= total:
		reform_labels["cruz_info"].text = tr("ui.cruz.done")
		cb.disabled = true
		cb.text = "5/5"
	else:
		reform_labels["cruz_info"].text = tr("ui.cruz.status") % [m.measures, total, UIKit.money(BigNumber.from_float(_rate * 100.0)).substr(1)]
		var cost: BigNumber = EconomyLogic.measure_cost(m)
		cb.text = tr("ui.cruz.btn") % [m.measures + 1, total, UIKit.money(cost)]
		cb.disabled = cost.gt(m.money)


func _refresh_album() -> void:
	album_page.refresh(gm())


func _refresh_ach() -> void:
	if not _ach_dirty:
		return
	_ach_dirty = false
	var m: GameModel = gm()
	UIKit.clear_children(ach_list)
	var got: int = 0
	for a in GameData.achievements:
		var done: bool = GameState.achievements.is_unlocked(a["id"])
		if done:
			got += 1
		var row: PanelContainer = UIKit.panel(UIKit.C_PANEL2 if done else UIKit.C_PANEL, 6)
		var h: HBoxContainer = HBoxContainer.new()
		row.add_child(h)
		var mark: Label = UIKit.label("[X]" if done else "[ ]", 15, UIKit.C_GREEN if done else UIKit.C_DIM)
		h.add_child(mark)
		var col: VBoxContainer = VBoxContainer.new()
		h.add_child(col)
		col.add_child(UIKit.label(tr(a["name_key"]), 15, UIKit.C_TEXT if done else UIKit.C_DIM))
		col.add_child(UIKit.label(tr(a["desc_key"]), 12, UIKit.C_DIM))
		ach_list.add_child(row)
	ach_info.text = tr("ui.ach.info") % [got, GameData.achievements.size()]
	if m == null:
		return


# =====================================================================
#  Acciones del jugador
# =====================================================================
func _on_buy_business(id: String) -> void:
	if Economy.buy_business(id, _buy_mode) <= 0:
		_play("error")


func _on_remark_pressed() -> void:
	Economy.remark()


func _on_refuge_buy(id: String, fraction: float) -> void:
	if Economy.refuge_buy(id, fraction):
		_play("coin")
	else:
		_play("error")


func _on_refuge_sell(id: String) -> void:
	if Economy.refuge_sell(id):
		_play("coin")
	else:
		_play("error")


func _on_reform_pressed() -> void:
	if _reform_armed <= 0.0:
		_reform_armed = 3.0
		return
	_reform_armed = 0.0
	Economy.reform()


func _on_plan_pressed(id: String) -> void:
	Economy.plan(id)


func _on_measure_pressed() -> void:
	if Economy.buy_measure():
		_play("buy")
		_shake(8.0, 0.3)


# =====================================================================
#  Eventos del bus
# =====================================================================
func _on_clicked(amount: BigNumber) -> void:
	_play("click", randf_range(0.9, 1.15))
	var pos: Vector2 = get_global_mouse_position()
	_floating_text("+" + UIKit.money(amount), pos, UIKit.C_GOLD)


func _on_business_bought(_id: String, _n: int) -> void:
	_play("buy")
	_upg_dirty = true
	_burst(get_global_mouse_position(), UIKit.C_GOLD, 10)


func _on_month_passed(rate: float) -> void:
	_scratch_costs()
	_play("raise", clampf(1.0 - rate * 0.3, 0.6, 1.0))
	_shake(clampf(4.0 + rate * 14.0, 4.0, 22.0), 0.35)
	# garabato gigante que se dibuja rápido y se borra; abajo del HUD, nunca encima
	var hud_bottom: float = 150.0
	if money_label != null:
		hud_bottom = money_label.get_global_rect().end.y + 70.0
	raise_sign.size = Vector2(size.x, 170.0)
	raise_sign.position = Vector2(0.0, hud_bottom + (size.y - hud_bottom) * 0.22)
	raise_sign.font_size = 104 if size.x > 900.0 else 70
	raise_sign.show_text(tr("ui.raise") % BigNumber.from_float(rate * 100.0).format(1), int(rate * 1000.0) + 1)
	Chalk.wobble(rate_label, 0.12, 0.6)
	_upg_dirty = true


func _on_remarked(bonus: BigNumber, on_time: bool) -> void:
	_remark_wipe()
	_play("register")
	if on_time and not bonus.is_zero():
		_toast(tr("ui.remark_bonus") % UIKit.money(bonus), UIKit.C_GREEN)

func _on_era_changed(era: int) -> void:
	_play("win")
	_toast(tr("ui.era_reached") % tr(GameData.era_def(era)["name_key"]), UIKit.C_GOLD)
	_upg_dirty = true
	_burst(size / 2.0, UIKit.C_GOLD, 40)
	_last_era = era


func _on_event_started(id: String) -> void:
	_play("event")
	var d: Dictionary = GameData.events[GameData.event_idx[id]]
	_toast(tr(d["name_key"]), UIKit.C_GOLD)


func _on_achievement(id: String) -> void:
	_play("coin", 1.3)
	_ach_dirty = true
	var a: Dictionary = GameData.achievements[0]
	for x in GameData.achievements:
		if x["id"] == id:
			a = x
	_toast(tr("ui.toast_ach") % tr(a["name_key"]), UIKit.C_GREEN)


func _on_plan_done(plan_id: String) -> void:
	_play("win")
	_toast(tr("ui.plan_done") % tr("plan." + plan_id), UIKit.C_GOLD)
	_upg_dirty = true
	_burst(size / 2.0, UIKit.C_BLUE, 40)


func _on_victory() -> void:
	_play("win")
	_burst(size / 2.0, UIKit.C_GREEN, 80)
	await get_tree().create_timer(2.0).timeout
	if is_inside_tree():
		request_credits.emit()


func _on_reform_done(_note: int, cut: int) -> void:
	_album_dirty = true
	_upg_dirty = true
	_play_reform_animation(maxi(cut, 3))


# =====================================================================
#  Juice
# =====================================================================
func _shake(amp: float, duration: float) -> void:
	_shake_amp = maxf(_shake_amp, amp)
	_shake_t = maxf(_shake_t, duration)


func _update_juice(delta: float) -> void:
	# sacudida de cámara
	if _shake_t > 0.0:
		_shake_t -= delta
		var k: float = clampf(_shake_t / 0.35, 0.0, 1.0)
		world.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_amp * k
		if _shake_t <= 0.0:
			_shake_amp = 0.0
			world.position = Vector2.ZERO
	# el número de plata tiembla con la inflación alta
	money_label.pivot_offset = money_label.size / 2.0
	if _rate > 0.12:
		var a: float = clampf(_rate * 0.02, 0.0, 0.05)
		money_label.rotation = randf_range(-a, a)
		rate_label.rotation = randf_range(-a, a) * 1.5
		rate_label.pivot_offset = rate_label.size / 2.0
	else:
		money_label.rotation = 0.0
		rate_label.rotation = 0.0
	# tinte rojo en la hiperinflación
	var hyper: float = EconomyLogic.B("hyper_tint_rate")
	var target: float = clampf((_rate - hyper) * 0.4, 0.0, 0.32)
	tint.color.a = target * (0.75 + 0.25 * sin(_clock * 5.0))


func _floating_text(text: String, pos: Vector2, color: Color) -> void:
	var l: Label = UIKit.label(text, 22, color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = pos - Vector2(30, 30)
	fx_layer.add_child(l)
	var tw: Tween = create_tween()
	tw.tween_property(l, "position:y", l.position.y - 70.0, 0.7)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.7)
	tw.tween_callback(l.queue_free)


func _burst(pos: Vector2, color: Color, amount: int) -> void:
	if fx_layer == null:
		return
	var p: CPUParticles2D = CPUParticles2D.new()
	p.position = pos
	p.emitting = true
	p.one_shot = true
	p.amount = Settings.particles(amount)
	p.lifetime = 0.8
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 80.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 320.0
	p.gravity = Vector2(0, 700)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = color
	fx_layer.add_child(p)
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _toast(text: String, color: Color) -> void:
	if toast_box == null:
		return
	# notita de tiza: la más nueva arriba; solo entran 3
	var p: PanelContainer = PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st: ChalkStyle = UIKit.chalk_box(Chalk.nearest(color), Color(0, 0, 0, 0.3), 2.0)
	st.content_margin_top = 2.0
	st.content_margin_bottom = 2.0
	st.content_margin_left = 8.0
	st.content_margin_right = 8.0
	p.add_theme_stylebox_override("panel", st)
	var l: Label = UIKit.label(text, 14, color, HORIZONTAL_ALIGNMENT_CENTER)
	l.clip_text = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	toast_box.add_child(p)
	toast_box.move_child(p, 0)
	while toast_box.get_child_count() > 3:
		var old: Node = toast_box.get_child(toast_box.get_child_count() - 1)
		toast_box.remove_child(old)
		old.queue_free()
	p.pivot_offset = Vector2(170, 12)
	p.scale = Vector2(0.6, 0.6)
	var tw: Tween = create_tween()
	tw.tween_property(p, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(3.2)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)


# ---- cinta de titulares ----
func _next_headline() -> void:
	var key: String = ""
	if not _headline_queue.is_empty():
		key = _headline_queue.pop_front()
	else:
		var pool: Array = []
		for h in GameData.headlines:
			if int(h["min_era"]) <= gm().era:
				pool.append(h["key"])
		key = pool[randi() % pool.size()]
	ticker_label.text = "   *   " + tr(key) + "   *   "
	ticker_label.position.x = ticker_clip.size.x


func _update_ticker(delta: float) -> void:
	if ticker_label == null:
		return
	ticker_label.position.x -= (70.0 + _rate * 60.0) * delta
	ticker_label.position.y = (ticker_clip.size.y - ticker_label.size.y) / 2.0
	if ticker_label.position.x + ticker_label.size.x < 0.0:
		_next_headline()


# ---- tijera cortando ceros ----
func _play_reform_animation(cut: int) -> void:
	if _busy_overlay != null:
		_busy_overlay.queue_free()
	var ov: ColorRect = ColorRect.new()
	ov.color = Color(0, 0, 0, 0.82)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ov)
	_busy_overlay = ov
	var title: Label = UIKit.label(tr("ui.reform.anim"), 34, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(size.x / 2.0 - 300, 90)
	title.size = Vector2(600, 50)
	ov.add_child(title)
	var note: BanknoteView = BanknoteView.new()
	note.custom_minimum_size = Vector2(520, 250)
	note.size = Vector2(520, 250)
	note.zeros = clampi(cut + 3, 3, 40)
	note.title = tr("ui.reform.note")
	note.note_color = Color("#b8c4a0")
	note.position = size / 2.0 - note.size / 2.0
	ov.add_child(note)
	var sc: ScissorsView = ScissorsView.new()
	sc.size = Vector2(150, 130)
	sc.scale = Vector2(1.9, 1.9)
	sc.pivot_offset = Vector2(75, 65)
	sc.position = Vector2(size.x + 60, note.position.y + 60)
	sc.open = 0.5
	ov.add_child(sc)
	var cut_x: float = note.position.x + note.size.x * 0.62
	var tw: Tween = create_tween()
	tw.tween_property(sc, "position:x", cut_x, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for i in range(3):
		tw.tween_callback(func() -> void: _play("snip"))
		tw.tween_property(sc, "open", 0.0, 0.08)
		tw.tween_property(sc, "open", 0.5, 0.08)
	tw.tween_callback(func() -> void:
		note.cut_zeros = cut
		note.queue_redraw()
		_shake(14.0, 0.35)
		_chalk_chips(Vector2(cut_x, note.position.y + 110.0), ov)
		for k in range(mini(cut, 12)):
			var z: Label = UIKit.label("0", 44, Chalk.WHITE, HORIZONTAL_ALIGNMENT_LEFT, true)
			z.position = Vector2(cut_x + k * 10, note.position.y + 80)
			ov.add_child(z)
			var zt: Tween = create_tween()
			zt.tween_property(z, "position", z.position + Vector2(randf_range(-60, 160), 260), 0.9).set_ease(Tween.EASE_IN)
			zt.parallel().tween_property(z, "rotation", randf_range(-3, 3), 0.9)
			zt.parallel().tween_property(z, "modulate:a", 0.0, 0.9)
			zt.tween_callback(z.queue_free))
	tw.tween_property(sc, "position:x", size.x + 100.0, 0.6).set_delay(0.5)
	tw.tween_interval(0.7)
	tw.tween_property(ov, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void:
		ov.queue_free()
		_busy_overlay = null)


# ---- informe offline ----
func show_offline_report(report: Dictionary) -> void:
	var ov: ColorRect = ColorRect.new()
	ov.color = Color(0, 0, 0, 0.78)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ov)
	var cc: CenterContainer = CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(cc)
	var gained: BigNumber = (report["money_after"] as BigNumber).sub(report["money_before"])
	if gained.is_negative():
		gained = BigNumber.zero()
	var p_after: BigNumber = report.get("price_after", BigNumber.one())
	var p_before: BigNumber = report.get("price_before", BigNumber.one())
	var price_up: BigNumber = p_after.div(p_before).sub(BigNumber.one()).mul_f(100.0)
	var won: bool = (report["power_after"] as BigNumber).ge(report["power_before"])
	var col: Color = Chalk.GREEN if won else Chalk.RED
	var p: PanelContainer = PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.chalk_box(col, Color(0.06, 0.1, 0.08, 0.96), 3.2))
	p.custom_minimum_size = Vector2(620, 0)
	cc.add_child(p)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(UIKit.label(tr("ui.offline.title"), 38, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, true))
	v.add_child(UIKit.label(tr("ui.offline.away") % UIKit.duration(float(report["seconds"])), 18, UIKit.C_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var money_line: Label = _wrap_label(tr("ui.offline.gain") % UIKit.money(gained) + " " + tr("ui.offline.prices") % (price_up.format(1) + " %"), 22, Chalk.WHITE)
	money_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(money_line)
	# resultado: flecha verde (ganaste poder de compra) o roja (perdiste)
	var res_row: HBoxContainer = HBoxContainer.new()
	res_row.alignment = BoxContainer.ALIGNMENT_CENTER
	res_row.add_theme_constant_override("separation", 14)
	v.add_child(res_row)
	var arrow: RaceMeter._Arrow = RaceMeter._Arrow.new()
	arrow.up = won
	arrow.custom_minimum_size = Vector2(80, 80)
	res_row.add_child(arrow)
	var res: Label = _wrap_label(tr("ui.offline.win") if won else tr("ui.offline.lose"), 24, col)
	res.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	res_row.add_child(res)
	var pw: Label = UIKit.label(tr("ui.offline.power") % [(report["power_before"] as BigNumber).format(), (report["power_after"] as BigNumber).format()], 16, UIKit.C_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(pw)
	if int(report["months"]) >= int(EconomyLogic.B("offline_max_months")) or bool(report.get("capped", false)):
		var cap: Label = _wrap_label(tr("ui.offline.cap"), 15, UIKit.C_DIM)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(cap)
	var ok: Button = Button.new()
	ok.text = tr("ui.ok")
	ok.custom_minimum_size = Vector2(0, 54)
	UIKit.style_button(ok, UIKit.C_GREEN.darkened(0.2), 22)
	ok.pressed.connect(ov.queue_free)
	v.add_child(ok)


# ---- remarcar: el trapo borra los precios y se reescriben a mano ----
func _visible_price_rects(field: String) -> Array:
	var out: Array = []
	if _tab != 0:
		return out
	var view: Rect2 = pages[0].get_global_rect()
	for e in biz_rows:
		if e["row"].visible:
			var p: ChalkPrice = e[field]
			var r: Rect2 = p.get_global_rect()
			if view.has_point(r.get_center()):
				out.append({"price": p, "rect": r})
	return out


func _remark_wipe() -> void:
	var items: Array = _visible_price_rects("income")
	if items.is_empty():
		return
	var rects: Array = []
	var row_time: float = 0.075
	for i in range(items.size()):
		var p: ChalkPrice = items[i]["price"]
		p.request_rewrite(1, float(i) * row_time + 0.05)
		rects.append(items[i]["rect"])
	RagWipe.sweep(fx_layer, rects, row_time)
	_burst(money_label.global_position + Vector2(80, 30), UIKit.C_TEXT, 14)


## Cada aumento tacha los costos viejos y los escribe de nuevo (tachón rosa).
func _scratch_costs() -> void:
	var i: int = 0
	for it in _visible_price_rects("cost"):
		var p: ChalkPrice = it["price"]
		p.request_rewrite(2, randf() * 0.45 + float(i % 3) * 0.05)
		i += 1


## Pedacitos de tiza que saltan y caen cuando la tijera corta los ceros.
func _chalk_chips(pos: Vector2, parent: Control) -> void:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.position = pos
	p.emitting = true
	p.one_shot = true
	p.amount = Settings.particles(34)
	p.lifetime = 1.1
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 100.0
	p.initial_velocity_min = 140.0
	p.initial_velocity_max = 380.0
	p.gravity = Vector2(0, 1100)
	p.angular_velocity_min = -540.0
	p.angular_velocity_max = 540.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 7.0
	p.color = Chalk.WHITE
	parent.add_child(p)
	get_tree().create_timer(1.6).timeout.connect(p.queue_free)


# ---- tutorial de los primeros 2 minutos ----
var _guide: TutorialGuide


func _start_tutorial() -> void:
	if Settings.tutorial_done:
		return
	if EconomyLogic.tutorial_step(gm()) >= EconomyLogic.TUTORIAL_STEPS or gm().era > 1:
		Settings.tutorial_done = true
		Settings.save_settings()
		return
	_guide = TutorialGuide.new(_tutorial_target)
	_guide.finished.connect(_on_tutorial_finished)
	fx_layer.add_child(_guide)


func _tutorial_target(step: int) -> Control:
	match step:
		0:
			return empanada
		1:
			return biz_rows[0]["btn"] if _tab == 0 else tab_buttons[0]
		2:
			return rate_label
		_:
			return remark_btn


func _on_tutorial_finished(skipped: bool) -> void:
	Settings.tutorial_done = true
	Settings.save_settings()
	if _guide != null:
		_guide.queue_free()
		_guide = null
	if not skipped:
		_toast(tr("tut.done"), UIKit.C_GOLD)


## La demo llegó a su límite (primera reforma): se deja ver la animación y se muestra la pantalla final.
func _on_demo_end() -> void:
	await get_tree().create_timer(3.4).timeout
	if is_inside_tree():
		request_demo_end.emit()


# =====================================================================
#  Parte A: objetivo, "¿le ganás a la inflación?", pestañas bloqueadas, tooltips y carteles de desbloqueo
# =====================================================================
const TAB_TIPS: Array = ["tip.tab_biz", "tip.tab_upgrades", "tip.tab_refuges", "tip.tab_reform", "tip.tab_album", "tip.tab_timba", "tip.tab_ach"]

var _unlock_queue: Array = []
var _unlock_sign: UnlockSign
var _tab_locked: Array = [false, false, false, false, false, false, false]


## Al cargar una partida avanzada no se anuncia todo de golpe.
func _silent_catchup() -> void:
	var m: GameModel = gm()
	if m.obj_index > 0 or m.era > 1 or m.reforms > 0:
		Unlocks.sync_silent(m)
		ObjectiveLogic.update(m)
		m.notifications = m.notifications.filter(func(n: Dictionary) -> bool: return n["sig"] != "objective_done" and n["sig"] != "unlock")


func _on_objective_done(_id: String) -> void:
	_play("coin", 1.2)
	_toast(tr("ui.obj.done"), UIKit.C_GOLD)
	_burst(objective_note.global_position + Vector2(120, 20), UIKit.C_GOLD, 16)


func _refresh_hud_extras(m: GameModel) -> void:
	_apply_detail(m)
	# semáforo de la inflación, con palabras simples y UNA razón accionable
	var race: Dictionary = EconomyLogic.race(m)
	var is_winning: bool = bool(race["winning"])
	race_meter.set_state(is_winning)
	if is_winning:
		race_meter.set_reason(tr("ui.race.why.ok"))
	elif EconomyLogic.needs_remark(m) and Advisor.lag(m) >= 0.05:
		race_meter.set_reason(tr("ui.race.why.remark"))
	else:
		race_meter.set_reason(tr("ui.race.why.buy"))
	var rn: String = UIKit.money(race["real_now"])
	var rr: String = UIKit.money(race["real_ref"])
	race_meter.tooltip_text = tr("tip.race") % [rn, rr]
	# objetivo
	objective_note.refresh(m)
	# tooltips generales
	var r: float = _rate
	money_label.tooltip_text = tr("tip.money") % UIKit.money(m.money.mul_f(r / (1.0 + r)))
	money_label.mouse_filter = Control.MOUSE_FILTER_STOP
	rate_label.tooltip_text = tr("tip.rate")
	rate_label.mouse_filter = Control.MOUSE_FILTER_STOP
	empanada.tooltip_text = tr("tip.empanada") % UIKit.money(EconomyLogic.click_value(m))
	var inc: BigNumber = EconomyLogic.income_per_sec(m)
	if EconomyLogic.needs_remark(m):
		remark_btn.tooltip_text = tr("tip.remark") % [UIKit.money(inc), UIKit.money(inc.mul(m.price_level.div(m.my_prices)))]
	else:
		remark_btn.tooltip_text = tr("tip.remark_ok")
	# pestañas: bloqueadas (candado de tiza + nombre; el "próximamente" va en el tooltip) o abiertas
	for i in range(TABS.size()):
		var feat: String = TAB_FEATURE[i]
		var locked: bool = feat != "" and not Unlocks.has(m, feat)
		var b: Button = tab_buttons[i]
		if locked != _tab_locked[i] or b.text == "":
			_tab_locked[i] = locked
			b.text = tr(TABS[i])
			var old_lock: Node = b.get_node_or_null("Lock")
			if old_lock != null:
				old_lock.queue_free()
			if locked:
				UIKit.style_tab_locked(b)
				var li: LockIcon = LockIcon.new()
				li.name = "Lock"
				b.add_child(li)
				_place_lock(b, li)
				b.resized.connect(func() -> void: _place_lock(b, li))
			else:
				UIKit.style_tab(b, i == _tab)
		b.tooltip_text = (tr("tip.tab_locked") % tr("tip.locked_" + feat)) if locked else tr(TAB_TIPS[i])
	_pump_unlock_queue()
	_demo_gift(m)


func _pump_unlock_queue() -> void:
	if (_unlock_sign != null and is_instance_valid(_unlock_sign)) or _unlock_queue.is_empty():
		return
	var f: String = _unlock_queue.pop_front()
	var target: Control = tab_buttons[0]
	if Unlocks.TAB_OF.has(f):
		target = tab_buttons[int(Unlocks.TAB_OF[f])]
	elif f == "events":
		target = rate_label
	_unlock_sign = UnlockSign.new()
	fx_layer.add_child(_unlock_sign)
	_unlock_sign.show_for(f, target)
	_play("win")


func _upgrade_tip(u: Dictionary) -> String:
	var m: GameModel = gm()
	var ef: Dictionary = u["effect"]
	var v: float = float(ef["value"])
	var vs: String = BigNumber.from_float(v).format(2)
	var base_inc: BigNumber = m.base_income
	match str(ef["type"]):
		"business_mult":
			var bid: String = str(ef["biz"])
			var bdef: Dictionary = GameData.businesses[GameData.business_idx[bid]]
			var n: int = m.owned_count(bid)
			var contrib: BigNumber = bdef["base_income"].mul_f(float(n) * float(m.biz_up_mult.get(bid, 1.0)) * EconomyLogic.milestone_mult(n) * m.global_mult).mul(m.my_prices)
			return tr("tip.upg_biz") % [tr(bdef["name_key"]), vs, UIKit.money(contrib.mul_f(v - 1.0))]
		"all_mult":
			return tr("tip.upg_all") % [vs, UIKit.money(base_inc.mul(m.my_prices).mul_f(v - 1.0))]
		"click_mult":
			return tr("tip.upg_click_mult") % [vs, UIKit.money(EconomyLogic.click_value(m).mul_f(v))]
		"click_pct":
			return tr("tip.upg_click_pct") % ("%d %%" % int(round(v * 100.0)))
		"auto_remark":
			return tr("tip.upg_auto_remark") % str(int(v))
		"auto_buy":
			return tr("tip.upg_auto_buy") % str(int(v))
		"inflation_mult":
			return tr("tip.upg_inflation") % ("%d %%" % int(round((1.0 - v) * 100.0)))
		"fee_mult":
			return tr("tip.upg_fee")
		"remark_bonus":
			return tr("tip.upg_remark") % vs
	return ""


# =====================================================================
#  Parte B: figuritas (sobres, páginas completas, final secreto)
# =====================================================================
var _pack_overlay: PackOpening


func _open_pack_overlay(results: Array) -> PackOpening:
	if _pack_overlay != null and is_instance_valid(_pack_overlay):
		_pack_overlay.queue_free()
	_pack_overlay = PackOpening.new(results)
	_pack_overlay.finished.connect(func() -> void:
		_pack_overlay.queue_free()
		_pack_overlay = null)
	add_child(_pack_overlay)
	return _pack_overlay


func _on_page_done(page: int) -> void:
	_play("win")
	_toast(tr("toast.page_done") % tr("page." + str(GameData.sticker_pages[page]["id"])), UIKit.C_GREEN)
	_burst(size / 2.0, UIKit.C_GREEN, 40)


func _on_sticker_won(id: String) -> void:
	_play("coin", 1.4)
	_toast(tr("toast.sticker") % tr(StickerLogic.def(id)["name_key"]), UIKit.C_GOLD)


## Final secreto: álbum de 60 figuritas completo.
func _show_secret() -> void:
	var m: GameModel = gm()
	if m.secret_seen:
		return
	m.secret_seen = true
	_play("win")
	var ov: ColorRect = ColorRect.new()
	ov.color = Color(0, 0, 0, 0.88)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ov)
	var v: VBoxContainer = VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 18)
	ov.add_child(v)
	v.add_child(UIKit.label(tr("secret.title"), 70, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, true))
	var body: Label = UIKit.label(tr("secret.body"), 24, Chalk.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(760, 0)
	var holder: CenterContainer = CenterContainer.new()
	holder.add_child(body)
	v.add_child(holder)
	var ok: Button = Button.new()
	ok.text = tr("secret.ok")
	ok.custom_minimum_size = Vector2(280, 56)
	UIKit.style_button(ok, UIKit.C_GREEN.darkened(0.2), 22)
	ok.pressed.connect(ov.queue_free)
	var bh: CenterContainer = CenterContainer.new()
	bh.add_child(ok)
	v.add_child(bh)
	_burst(size / 2.0, UIKit.C_GOLD, 80)


## La demo regala un sobre de figuritas (una sola vez) apenas se desbloquea el álbum.
func _demo_gift(m: GameModel) -> void:
	if not m.demo_mode or m.gift_given or not Unlocks.has(m, "album") or not _unlock_queue.is_empty():
		return
	if _unlock_sign != null and is_instance_valid(_unlock_sign):
		return
	if _pack_overlay != null and is_instance_valid(_pack_overlay):
		return
	m.gift_given = true
	var res: Array = StickerLogic.gift_pack(m)
	_toast(tr("toast.gift_pack"), UIKit.C_GOLD)
	_open_pack_overlay(res)


# =====================================================================
#  Parte C: timba (raspadita, quiniela, timba del dólar)
# =====================================================================
var _scratch_overlay: ScratchOverlay
var _bolillero: BolilleroOverlay


func _open_scratch(pct: float, force: String = "") -> ScratchOverlay:
	var res: Dictionary = Economy.play_scratch(pct, force)
	if not bool(res.get("ok", false)):
		_toast(tr("timba.nomoney"), UIKit.C_GOLD)
		_play("error")
		return null
	if _scratch_overlay != null and is_instance_valid(_scratch_overlay):
		_scratch_overlay.queue_free()
	_scratch_overlay = ScratchOverlay.new(res, pct)
	add_child(_scratch_overlay)
	_scratch_overlay.closed.connect(func() -> void:
		var pack: Array = res.get("pack", [])
		_scratch_overlay.queue_free()
		_scratch_overlay = null
		if not pack.is_empty():
			_open_pack_overlay(pack))
	_scratch_overlay.again.connect(func(p: float) -> void:
		_scratch_overlay.queue_free()
		_scratch_overlay = null
		_open_scratch(p))
	return _scratch_overlay


func _on_quiniela_drawn(res: Dictionary) -> void:
	if _bolillero != null and is_instance_valid(_bolillero):
		_bolillero.queue_free()
	_bolillero = BolilleroOverlay.new(res)
	add_child(_bolillero)
	_bolillero.closed.connect(func() -> void:
		_bolillero.queue_free()
		_bolillero = null)


func _on_dollar_settled(res: Dictionary) -> void:
	if bool(res["won"]):
		_play("coin")
		_toast(tr("timba.d.win") % UIKit.money(res["payout"]), UIKit.C_GREEN)
	else:
		_play("lose")
		_toast(tr("timba.d.lose") % BigNumber.from_float(float(res["official"]) * 100.0).format(1), UIKit.C_RED)


# =====================================================================
#  Layout vertical (1080x1920) para clips y pantallas verticales
# =====================================================================
func _apply_layout() -> void:
	var is_portrait: bool = size.y > size.x * 1.15
	if body == null or (is_portrait == portrait and left_col.custom_minimum_size.x == (0.0 if portrait else 340.0)):
		return
	portrait = is_portrait
	header_grid.columns = 1 if portrait else 3
	race_meter.custom_minimum_size = Vector2(290 if portrait else 380, 92)
	body.vertical = portrait
	left_col.custom_minimum_size = Vector2(0, 0) if portrait else Vector2(340, 0)
	left_col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if portrait else Control.SIZE_FILL
	empanada.custom_minimum_size = Vector2(240, 150) if portrait else Vector2(250, 160)
	for i in range(tab_buttons.size()):
		var b: Button = tab_buttons[i]
		b.add_theme_font_size_override("font_size", maxi(int((14 if portrait else 20) * UIKit.FS), UIKit.MIN_FONT))
		b.clip_text = portrait
		b.custom_minimum_size = Vector2(0, 0)
	for e in biz_rows:
		e["owned"].visible = not portrait
		e["income"].visible = not portrait
		e["desc"].visible = not portrait
		e["cost"].custom_minimum_size = Vector2(120 if portrait else 150, 40)
		e["btn"].custom_minimum_size = Vector2(100 if portrait else 116, 44)
	world.add_theme_constant_override("margin_left", 16 if portrait else 24)
	world.add_theme_constant_override("margin_right", 16 if portrait else 24)


## El candado va pegado a la izquierda del nombre de la pestaña.
func _place_lock(b: Button, li: Node) -> void:
	if not is_instance_valid(li):
		return
	var font: Font = b.get_theme_font("font")
	var fs: int = b.get_theme_font_size("font_size")
	var tw: float = font.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	(li as Control).position = Vector2(maxf(2.0, (b.size.x - tw) * 0.5 - 40.0), (b.size.y - 26.0) * 0.5)


# =====================================================================
#  Claridad: detalles progresivos y una sola acción destacada
# =====================================================================
## Las primeras 2 eras muestran solo la plata, el semáforo, la empanada y los negocios. La tasa exacta y el poder
## adquisitivo aparecen cuando el tutorial los presenta (paso 3), y remarcar cuando presenta el paso 4. Desde la Era 3 todo.
func _apply_detail(m: GameModel) -> void:
	var step: int = EconomyLogic.tutorial_step(m)
	var full: bool = m.era >= 3 or m.reforms > 0
	var show_rate: bool = full or step >= 2
	var show_remark: bool = full or step >= 3
	rate_box.visible = show_rate
	power_label.visible = show_rate
	remark_panel.visible = show_remark


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenTouch:
		_idle = 0.0


## Control que corresponde a la recomendación del asesor (y de qué lado viene la flecha).
func _advice_target(a: Dictionary) -> Dictionary:
	match str(a["kind"]):
		"click":
			return {"ctl": empanada, "side": "right"}
		"remark":
			return {"ctl": remark_btn, "side": "right"}
		"decision":
			if decision_panel.visible:
				return {"ctl": decision_buttons[EconomyLogic.default_choice(str(gm().pending_choice.get("id", ""))) ], "side": "top"}
		"tab":
			var ti: int = int(a["id"])
			if ti >= 0 and ti < tab_buttons.size():
				return {"ctl": tab_buttons[ti], "side": "bottom"}
		"buy":
			if _tab != 0:
				return {"ctl": tab_buttons[0], "side": "bottom"}
			for e in biz_rows:
				if e["def"]["id"] == str(a["id"]) and e["row"].visible:
					return {"ctl": e["btn"], "side": "left"}
		"upgrade":
			if _tab != 1:
				return {"ctl": tab_buttons[1], "side": "bottom"}
			for ub in upg_buttons:
				if ub.get("id", "") == str(a["id"]):
					return {"ctl": ub["btn"], "side": "left"}
	return {}


func _update_advice(delta: float) -> void:
	_idle += delta
	_override_t = maxf(0.0, _override_t - delta)
	var m: GameModel = gm()
	var rec: Dictionary = _override if _override_t > 0.0 else Advisor.recommend(m, _seen_tabs)
	_advice = rec
	var tgt: Dictionary = {}
	# durante el tutorial mandan sus propias flechas
	if (_guide == null or not is_instance_valid(_guide)) and not _blocking_overlay() and str(rec.get("kind", "")) != "":
		tgt = _advice_target(rec)
	if tgt.is_empty():
		_highlight.set_target(null, "", "left")
		_highlight.visible = false
	else:
		_highlight.idle = _idle
		_highlight.set_target(tgt["ctl"], tr("ui." + str(rec["why"])) if str(rec["why"]) != "" else "", str(tgt["side"]))
	# el botón de remarcar late cuando conviene
	var pulse: bool = str(rec.get("kind", "")) == "remark"
	remark_btn.scale = Vector2.ONE * (1.0 + (0.035 * sin(_clock * 6.0) if pulse else 0.0))
	remark_btn.pivot_offset = remark_btn.size / 2.0


func _blocking_overlay() -> bool:
	for n in [_pack_overlay, _scratch_overlay, _bolillero, _busy_overlay]:
		if n != null and is_instance_valid(n):
			return true
	return false


## Botón [IR] del objetivo: lleva directo a donde hay que tocar y lo destaca unos segundos.
func _on_objective_go(go: Dictionary) -> void:
	if go.is_empty():
		return
	_idle = 0.0
	var kind: String = str(go["kind"])
	_override = {"kind": kind, "id": go.get("id", ""), "why": "ui.adv.obj"}
	_override_t = 8.0
	match kind:
		"buy":
			_select_tab(0)
		"upgrade":
			_select_tab(1)
		"tab":
			_select_tab(int(go["id"]))
			_override_t = 0.0
		"remark":
			_override_t = 0.0
			_on_remark_pressed()
		"click":
			pass
