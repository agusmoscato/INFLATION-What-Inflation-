class_name GameScreen
extends Control
## Pantalla de juego del clicker (diseño v2), construida por código.
## Izquierda: la empanada, el combo y la reforma. Derecha: la fila de mejoras y los negocios. Arriba: la plata, el "+$/s" y
## la inflación con el botón de remarcar. Abajo: árbol, álbum, raspadita, logros y titulares. Todo lo demás son capas
## (árbol, álbum, raspadita, reforma, noticias, billetes voladores, avisos).

signal request_menu
signal request_credits
signal request_demo_end

const QTY: Array = [1, 10, -1]
const TOAST_SECONDS: float = 3.0
const TOAST_SECONDS_SLOW: float = 5.5      ## en las primeras vueltas los avisos duran más (da tiempo a leerlos)
const UPG_BOX_H: float = 2.0 * 80.0 + 6.0   ## dos filas de tarjetas de mejoras

var world: MarginContainer
var body: BoxContainer
var left_col: Control
var fx_layer: Control
var bills_layer: Control
var tint: ColorRect
var toast_box: VBoxContainer

var money_label: Label
var ips_label: Label
var era_label: Label
var rate_label: Label
var price_label: Label
var cred_label: Label
var remark_btn: Button
var remark_bar: ChalkBar
var remark_line: Label
var empanada: EmpanadaButton
var combo_bar: ChalkBar
var barrio: BarrioView
var backdrop: EraBackdrop
var combo_label: Label
var click_label: Label
var reform_btn: Button
var reform_hint: Label
var upg_flow: HFlowContainer
var upg_title: Label
var upg_scroll: ScrollContainer
var upg_detail: PanelContainer
var _upg_hover: UpgradeIcon
var biz_list: VBoxContainer
var biz_scroll: ScrollContainer
var biz_more: Label
var biz_rows: Array = []          # [{def,row,icon,name,info,owned,btn}]
var qty_buttons: Array = []
var nav_tree: Button
var nav_album: Button
var nav_scratch: Button
var nav_ach: Button
var ticker_clip: Control
var ticker_label: Label
var event_panel: PanelContainer
var event_title: Label
var event_buttons: Array = []
var event_bar: ChalkBar
var tutorial_note: PanelContainer
var tutorial_label: Label

var _buy_mode: int = 1
var _clock: float = 0.0
var _upg_sig: String = ""
var _upg_icons: Array = []
var _seen_upgrades: Dictionary = {}
var _overlay: Control                 # capa modal abierta (árbol, álbum, logros, diálogo)
var _tree_view: SkillTreeView
var _tree_info: Dictionary = {}
var _album_page: AlbumPage
var _scratch_overlay: ScratchOverlay
var _pack_overlay: PackOpening
var _busy_overlay: Control
var _bills: Dictionary = {}           # id -> FlyingBill
var _shake_t: float = 0.0
var _shake_amp: float = 0.0
var _money_shown: float = -1.0
var _reform_pulse: float = 0.0
var _tut_step: int = -2
var _headline_i: int = 0
var _fps_watch: FpsWatch = FpsWatch.new(45.0, 5.0)
var _last_era: int = 1
var _last_pct: float = 0.0
var _rate_shake: float = 0.0
var _joke_p: float = 0.0               # ln P del último chiste de aumento
var _joke_t: float = -99.0
var _joke_i: int = 0
var _toast_queue: Array = []          # [[texto, color]] esperando su turno
var _last_toast: float = -99.0


func gm() -> GameModel:
	return GameState.m


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world = MarginContainer.new()
	world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		world.add_theme_constant_override("margin_" + side, 20)
	world.add_theme_constant_override("margin_bottom", 28)
	add_child(world)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	world.add_child(root)
	root.add_child(_build_header())
	body = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)
	body.add_child(_build_left())
	body.add_child(_build_right())
	root.add_child(_build_bottom())

	tint = ColorRect.new()
	tint.color = Color(0.9, 0.05, 0.05, 0.0)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tint)
	bills_layer = Control.new()
	bills_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bills_layer.set_meta("qa_ignore", true)
	bills_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bills_layer)
	fx_layer = Control.new()
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.set_meta("qa_ignore", true)
	fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fx_layer)
	# avisos chicos en la esquina de arriba del panel de la empanada (se van solos en 3 s)
	toast_box = VBoxContainer.new()
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_box.add_theme_constant_override("separation", 4)
	toast_box.offset_left = 30.0
	toast_box.offset_right = 370.0
	toast_box.offset_top = 140.0
	fx_layer.add_child(toast_box)
	_build_event_panel()
	_build_tutorial_note()
	_build_upgrade_detail()

	_connect_bus()
	for u in EconomyLogic.visible_upgrades(gm()):
		_seen_upgrades[u["id"]] = true
	_last_era = EconomyLogic.era_of(gm())
	Economy.running = true
	_refresh_all()
	if GameState.old_save_discarded:
		GameState.old_save_discarded = false
		_toast(tr("ui.old_save"), Chalk.PINK)
	for b in gm().bills_active:
		_spawn_bill(int(b["id"]))


func _connect_bus() -> void:
	EventBus.clicked.connect(_on_clicked)
	EventBus.business_bought.connect(_on_business_bought)
	EventBus.milestone.connect(func(id: String, n: int) -> void:
		_toast(tr("ui.toast.milestone") % [n, tr("biz." + id)], Chalk.GREEN))
	EventBus.upgrade_new.connect(func(id: String) -> void:
		var u: Dictionary = GameData.upgrades[GameData.upgrade_idx[id]]
		_toast(tr("ui.toast.upgrade") % [UpgradeIcon.short_name(u), UpgradeIcon.effect(u)], Chalk.WHITE))
	EventBus.upgrade_bought.connect(func(_id: String) -> void:
		_upg_sig = ""
		_play("buy"))
	EventBus.node_bought.connect(_on_node_bought)
	EventBus.remarked.connect(_on_remarked)
	EventBus.bill_spawn.connect(_spawn_bill)
	EventBus.bill_missed.connect(func(id: int) -> void:
		if _bills.has(id) and is_instance_valid(_bills[id]):
			(_bills[id] as FlyingBill).vanish(false)
		_bills.erase(id))
	EventBus.bill_prize.connect(_on_bill_prize)
	EventBus.event_choice.connect(func(_id: String) -> void: _play("event"))
	EventBus.unlock.connect(func(f: String) -> void:
		_toast(tr("ui.toast.unlock") % tr("unlock." + f), Chalk.YELLOW)
		_play("win"))
	EventBus.collapse.connect(_on_collapse)
	EventBus.page_done.connect(func(page: int) -> void:
		_toast(tr("ui.toast.page") % tr("page." + str(GameData.sticker_pages[page]["id"])), Chalk.PINK)
		_play("gold"))
	EventBus.sticker_won.connect(func(id: String) -> void:
		_toast(tr("ui.toast.sticker") % tr(StickerLogic.def(id)["name_key"]), Chalk.PINK))
	EventBus.secret_end.connect(_show_secret)
	EventBus.scratched.connect(func(res: Dictionary) -> void:
		if bool(res.get("free", false)):
			_toast(tr("ui.toast.auto_scratch") % tr("timba.res." + str(res["outcome"])), Chalk.ORANGE))
	EventBus.achievement_unlocked.connect(func(id: String) -> void:
		_toast(tr("ui.toast.ach") % tr("ach." + id), Chalk.YELLOW)
		_play("win"))
	EventBus.reform_done.connect(_on_reform_done)
	EventBus.victory.connect(_on_victory)
	EventBus.demo_end.connect(func() -> void:
		get_tree().create_timer(2.5).timeout.connect(func() -> void: request_demo_end.emit()))
	EventBus.toast.connect(func(key: String) -> void: _toast(tr(key), UIKit.C_GOLD))


func _play(sound: String, pitch: float = 1.0) -> void:
	if SoundFx.instance != null:
		SoundFx.instance.play(sound, pitch)


# =====================================================================
#  Construcción
# =====================================================================
func _build_header() -> Control:
	var p: PanelContainer = UIKit.panel(UIKit.C_PANEL, 10)
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	p.add_child(h)
	# la plata: lo más grande y brillante
	var left: VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 0)
	h.add_child(left)
	money_label = UIKit.label("$0", 54, Color("#FFE45C"), HORIZONTAL_ALIGNMENT_LEFT, true)
	money_label.add_theme_color_override("font_outline_color", Color("#1c1508"))
	money_label.add_theme_constant_override("outline_size", 9)
	left.add_child(money_label)
	ips_label = UIKit.label("+$0/s", 26, Chalk.GREEN, HORIZONTAL_ALIGNMENT_LEFT, true)
	ips_label.add_theme_color_override("font_outline_color", Color("#0b1a0e"))
	ips_label.add_theme_constant_override("outline_size", 6)
	left.add_child(ips_label)
	# la inflación y remarcar
	var mid: VBoxContainer = VBoxContainer.new()
	mid.custom_minimum_size = Vector2(330, 0)
	mid.add_theme_constant_override("separation", 3)
	h.add_child(mid)
	era_label = UIKit.label("", 22, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, true)
	mid.add_child(era_label)
	rate_label = UIKit.label("", 20, UIKit.C_RED, HORIZONTAL_ALIGNMENT_CENTER, true)
	mid.add_child(rate_label)
	price_label = UIKit.label("", 15, UIKit.C_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	mid.add_child(price_label)
	var rv: VBoxContainer = VBoxContainer.new()
	rv.custom_minimum_size = Vector2(190, 0)
	rv.add_theme_constant_override("separation", 2)
	h.add_child(rv)
	remark_btn = Button.new()
	remark_btn.text = tr("ui.remark")
	remark_btn.custom_minimum_size = Vector2(190, 48)
	UIKit.style_button(remark_btn, UIKit.C_BLUE, 19)
	remark_btn.pressed.connect(func() -> void:
		if Economy.remark():
			_play("stamp")
		else:
			_play("error"))
	rv.add_child(remark_btn)
	remark_bar = ChalkBar.new()
	remark_bar.fill_color = Chalk.BLUE
	remark_bar.custom_minimum_size = Vector2(0, 12)
	rv.add_child(remark_bar)
	remark_line = UIKit.label("", 14, UIKit.C_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	rv.add_child(remark_line)
	# credibilidad
	var right: VBoxContainer = VBoxContainer.new()
	right.custom_minimum_size = Vector2(170, 0)
	h.add_child(right)
	right.add_child(UIKit.label(tr("ui.cred"), 15, UIKit.C_DIM, HORIZONTAL_ALIGNMENT_RIGHT))
	cred_label = UIKit.label("0", 30, Chalk.BLUE, HORIZONTAL_ALIGNMENT_RIGHT, true)
	right.add_child(cred_label)
	return p


func _build_left() -> Control:
	var col: VBoxContainer = VBoxContainer.new()
	col.custom_minimum_size = Vector2(360, 0)
	col.add_theme_constant_override("separation", 8)
	var p: PanelContainer = UIKit.panel(UIKit.C_PANEL, 10)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(p)
	backdrop = EraBackdrop.new()       # dibujos tenues de la capa, detrás de la empanada
	p.add_child(backdrop)
	var v: VBoxContainer = VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	empanada = EmpanadaButton.new()
	empanada.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	empanada.size_flags_vertical = Control.SIZE_EXPAND_FILL
	empanada.custom_minimum_size = Vector2(250, 170)
	empanada.pressed.connect(func(_pos: Vector2) -> void: Economy.click())
	v.add_child(empanada)
	click_label = UIKit.label("", 17, Chalk.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(click_label)
	combo_label = UIKit.label("", 17, Chalk.ORANGE, HORIZONTAL_ALIGNMENT_CENTER, true)
	v.add_child(combo_label)
	combo_bar = ChalkBar.new()
	combo_bar.fill_color = Chalk.ORANGE
	combo_bar.custom_minimum_size = Vector2(220, 12)
	combo_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(combo_bar)
	barrio = BarrioView.new()          # la calle del barrio que se va llenando
	v.add_child(barrio)
	reform_btn = Button.new()
	reform_btn.custom_minimum_size = Vector2(0, 62)
	UIKit.style_button(reform_btn, UIKit.C_GOLD, 19)
	reform_btn.pressed.connect(_open_reform_dialog)
	col.add_child(reform_btn)
	reform_hint = UIKit.label("", 15, UIKit.C_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	reform_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reform_hint.custom_minimum_size = Vector2(300, 0)
	col.add_child(reform_hint)
	left_col = col
	return col


func _build_right() -> Control:
	var col: VBoxContainer = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	# fila de mejoras (íconos)
	var up: PanelContainer = UIKit.panel(UIKit.C_PANEL, 10)
	col.add_child(up)
	var uv: VBoxContainer = VBoxContainer.new()
	uv.add_theme_constant_override("separation", 4)
	up.add_child(uv)
	upg_title = UIKit.label(tr("ui.upgrades"), 18, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT, true)
	uv.add_child(upg_title)
	var usc: ScrollContainer = ScrollContainer.new()
	usc.custom_minimum_size = Vector2(0, UPG_BOX_H)
	upg_scroll = usc
	usc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	uv.add_child(usc)
	upg_flow = HFlowContainer.new()
	upg_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upg_flow.add_theme_constant_override("h_separation", 6)
	upg_flow.add_theme_constant_override("v_separation", 6)
	usc.add_child(upg_flow)
	# negocios
	var bp: PanelContainer = UIKit.panel(UIKit.C_PANEL, 10)
	bp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(bp)
	var bv: VBoxContainer = VBoxContainer.new()
	bv.add_theme_constant_override("separation", 6)
	bp.add_child(bv)
	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	bv.add_child(top)
	var bt: Label = UIKit.label(tr("ui.businesses"), 18, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT, true)
	bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(bt)
	for q in QTY:
		var b: Button = Button.new()
		b.text = tr("ui.qty.max") if q < 0 else "x%d" % q
		b.custom_minimum_size = Vector2(62, 0)
		UIKit.style_button(b, UIKit.C_PANEL2, 15)
		b.pressed.connect(func() -> void:
			_buy_mode = q
			_refresh_qty_buttons())
		top.add_child(b)
		qty_buttons.append({"btn": b, "q": q})
	# lista compacta con scroll; si hay más abajo, una flecha de tiza lo avisa debajo de la lista (fuera de ella)
	var holder: Control = Control.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bv.add_child(holder)
	var sc: ScrollContainer = ScrollContainer.new()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	holder.add_child(sc)
	bv.add_theme_constant_override("separation", 2)
	biz_scroll = sc
	biz_list = VBoxContainer.new()
	biz_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	biz_list.add_theme_constant_override("separation", 3)
	sc.add_child(biz_list)
	biz_more = UIKit.label("▼  " + tr("ui.biz.more") + "  ▼", 15, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, true)
	biz_more.custom_minimum_size = Vector2(0, 20)
	biz_more.mouse_filter = Control.MOUSE_FILTER_STOP
	biz_more.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	biz_more.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			biz_scroll.scroll_vertical += int(biz_scroll.size.y * 0.8))
	bv.add_child(biz_more)
	for def in GameData.businesses:
		var row: PanelContainer = UIKit.panel(UIKit.C_PANEL2, 5)
		var h: HBoxContainer = HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		row.add_child(h)
		var icon: BusinessIcon = BusinessIcon.new(def["id"])
		icon.custom_minimum_size = Vector2(38, 38)
		h.add_child(icon)
		var info: VBoxContainer = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", -4)
		h.add_child(info)
		var name_l: Label = UIKit.label(tr(def["name_key"]), 16)
		name_l.clip_text = true
		info.add_child(name_l)
		var info_l: Label = UIKit.label("", 13, UIKit.C_DIM)
		info_l.clip_text = true
		info.add_child(info_l)
		var owned: Label = UIKit.label("", 20, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER, true)
		owned.custom_minimum_size = Vector2(50, 0)
		h.add_child(owned)
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(160, 36)
		UIKit.style_button(btn, UIKit.C_GREEN.darkened(0.25), 16)
		btn.pressed.connect(_on_buy_business.bind(def["id"]))
		h.add_child(btn)
		biz_list.add_child(row)
		biz_rows.append({"def": def, "row": row, "icon": icon, "name": name_l, "info": info_l, "owned": owned, "btn": btn})
	_refresh_qty_buttons()
	return col


func _build_bottom() -> Control:
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	nav_tree = _nav_button(tr("ui.nav.tree"), UIKit.C_BLUE, _open_tree)
	nav_album = _nav_button(tr("ui.nav.album"), Chalk.PINK, _open_album)
	nav_scratch = _nav_button(tr("ui.nav.scratch"), Chalk.ORANGE, _open_scratch)
	nav_ach = _nav_button(tr("ui.nav.ach"), UIKit.C_GOLD, _open_achievements)
	for b in [nav_tree, nav_album, nav_scratch, nav_ach]:
		h.add_child(b)
	ticker_clip = Control.new()
	ticker_clip.clip_contents = true
	ticker_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ticker_clip.custom_minimum_size = Vector2(0, 40)
	ticker_clip.set_meta("qa_ignore", true)
	h.add_child(ticker_clip)
	ticker_label = UIKit.label("", 16, UIKit.C_DIM)
	ticker_clip.add_child(ticker_label)
	var menu_btn: Button = _nav_button(tr("ui.menu"), UIKit.C_PANEL2, func() -> void: request_menu.emit())
	h.add_child(menu_btn)
	return h


func _nav_button(text: String, col: Color, cb: Callable) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	UIKit.style_button(b, col, 17)
	b.pressed.connect(cb)
	return b


func _build_event_panel() -> void:
	event_panel = PanelContainer.new()
	event_panel.add_theme_stylebox_override("panel", UIKit.chalk_box(Chalk.YELLOW, Color(0.07, 0.11, 0.09, 0.96), 2.8))
	event_panel.anchor_left = 0.5
	event_panel.anchor_right = 0.5
	event_panel.offset_left = -330.0
	event_panel.offset_right = 330.0
	event_panel.offset_top = 110.0
	event_panel.visible = false
	add_child(event_panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	event_panel.add_child(v)
	event_title = UIKit.label("", 20, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, true)
	event_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_title.custom_minimum_size = Vector2(600, 0)
	v.add_child(event_title)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	for i in range(2):
		var b: Button = Button.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 48)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UIKit.style_button(b, UIKit.C_GREEN.darkened(0.2) if i == 0 else UIKit.C_BLUE, 16)
		b.pressed.connect(func() -> void:
			Economy.choose_event(i)
			_play("register"))
		row.add_child(b)
		event_buttons.append(b)
	event_bar = ChalkBar.new()
	event_bar.fill_color = Chalk.YELLOW
	v.add_child(event_bar)


## Detalle de una mejora: aparece al instante al pasar el mouse por la tarjeta (sin la demora del tooltip).
func _build_upgrade_detail() -> void:
	upg_detail = PanelContainer.new()
	upg_detail.add_theme_stylebox_override("panel", UIKit.chalk_box(Chalk.YELLOW, Color(0.08, 0.12, 0.1, 0.97), 2.2))
	upg_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upg_detail.set_meta("qa_ignore", true)
	upg_detail.visible = false
	fx_layer.add_child(upg_detail)
	var v: VBoxContainer = VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upg_detail.add_child(v)
	for i in range(3):
		var l: Label = UIKit.label("", [18, 15, 16][i], [Chalk.YELLOW, Chalk.WHITE, Chalk.GREEN][i], HORIZONTAL_ALIGNMENT_LEFT, i == 0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(300, 0)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)


func _show_upgrade_detail(ic: UpgradeIcon) -> void:
	if not is_instance_valid(ic):
		return
	_upg_hover = ic
	var v: Node = upg_detail.get_child(0)
	var u: Dictionary = ic.upg
	(v.get_child(0) as Label).text = GameData.upgrade_title(u)
	var why: String = tr("ui.upg.locked") if ic.cond_text == "" else tr("ui.upg.locked_cond") % ic.cond_text
	(v.get_child(1) as Label).text = UpgradeIcon.describe(u) + ("\n" + why if ic.locked else "")
	var cost: BigNumber = EconomyLogic.upgrade_cost(gm(), u)
	var line: String = tr("ui.upg.cost") % UIKit.money(cost)
	if cost.gt(gm().money):
		line += "  -  " + tr("ui.upg.missing") % UIKit.money(cost.sub(gm().money))
	(v.get_child(2) as Label).text = line
	upg_detail.visible = true
	upg_detail.size = upg_detail.get_combined_minimum_size()
	var r: Rect2 = ic.get_global_rect()
	var pos: Vector2 = Vector2(r.position.x, r.end.y + 6.0)
	var vr: Vector2 = get_viewport_rect().size
	if pos.y + upg_detail.size.y > vr.y - 8.0:
		pos.y = r.position.y - upg_detail.size.y - 6.0
	pos.x = clampf(pos.x, 8.0, vr.x - upg_detail.size.x - 8.0)
	upg_detail.position = pos


func _hide_upgrade_detail(ic: UpgradeIcon) -> void:
	if _upg_hover == ic:
		_upg_hover = null
		upg_detail.visible = false


func _build_tutorial_note() -> void:
	tutorial_note = PanelContainer.new()
	tutorial_note.add_theme_stylebox_override("panel", UIKit.chalk_box(Chalk.PINK, Color(0.1, 0.06, 0.09, 0.94), 2.6))
	tutorial_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_note.set_meta("qa_ignore", true)
	tutorial_note.visible = false
	fx_layer.add_child(tutorial_note)
	tutorial_label = UIKit.label("", 17, Chalk.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_label.custom_minimum_size = Vector2(270, 0)
	tutorial_note.add_child(tutorial_label)


# =====================================================================
#  Refresco
# =====================================================================
func _process(delta: float) -> void:
	_clock += delta
	if Settings.quality < 2 and _fps_watch.update(Engine.get_frames_per_second(), delta):
		_toast(tr("ui.fps_hint"), Chalk.PINK)
	_refresh_all()
	_update_juice(delta)
	_update_ticker(delta)
	_pump_toasts()


func _refresh_all() -> void:
	var m: GameModel = gm()
	EconomyLogic.ensure_fresh(m)
	_refresh_header(m)
	_refresh_left(m)
	_refresh_biz(m)
	_refresh_upgrades(m)
	_refresh_nav(m)
	_refresh_event(m)
	_refresh_tutorial(m)
	if _tree_view != null and is_instance_valid(_tree_view):
		_refresh_tree_info()
	if _album_page != null and is_instance_valid(_album_page):
		_album_page.refresh(m)


func _refresh_header(m: GameModel) -> void:
	money_label.text = UIKit.money(m.money)
	var ips: BigNumber = EconomyLogic.income_per_sec(m)
	ips_label.text = tr("ui.ips") % ips.format()
	if m.frenzy_left > 0.0:
		ips_label.text += "   " + tr("ui.frenzy_on") % int(ceil(m.frenzy_left))
	var era: int = EconomyLogic.era_of(m)
	era_label.text = tr(GameData.era_def(era)["name_key"])
	era_label.add_theme_color_override("font_color", GameData.era_def(era)["color"])
	if era != _last_era:
		_last_era = era
		Chalk.pop(era_label, 1.3, 0.5)
	var pct: float = EconomyLogic.monthly_pct(m)
	if pct > _last_pct + 0.05 and not EconomyLogic.frozen(m):
		_rate_shake = 0.35
	_last_pct = pct
	_inflation_jokes(m)
	if EconomyLogic.frozen(m):
		rate_label.text = tr("ui.frozen") % int(ceil(m.freeze_left))
		rate_label.add_theme_color_override("font_color", Chalk.BLUE)
	else:
		rate_label.text = tr("ui.rate") % _pct(pct)
		rate_label.add_theme_color_override("font_color", Chalk.GREEN if pct < 10.0 else (Chalk.YELLOW if pct < 50.0 else Chalk.RED))
		# "frenada" solo cuando el freno actúa de verdad: sin él, la inflación sería más de 2 puntos más alta
		if EconomyLogic.raw_monthly_pct(m) - pct > 2.0:
			rate_label.text = tr("ui.rate_braked") % _pct(EconomyLogic.raw_monthly_pct(m))
			rate_label.add_theme_color_override("font_color", Chalk.BLUE)
	price_label.text = tr("ui.prices") % EconomyLogic.price_level(m).format()
	var cd: float = m.remark_cd
	var total: float = maxf(5.0, float(m.mods["remark_cd"]))
	remark_btn.disabled = cd > 0.0
	remark_btn.text = tr("ui.remark") if cd <= 0.0 else tr("ui.remark_cd") % int(ceil(cd))
	remark_bar.value = 1.0 - cd / total
	remark_line.text = tr("ui.remark.line") % int(round(float(m.mods["remark_freeze"]) + float(m.mods["album_remark"])))
	cred_label.text = "%d" % m.credibility


## Avisos graciosos cuando la inflación pega un salto (los precios subieron un 8 % desde el último), como mucho cada 25 s.
const JOKES: int = 14


func _inflation_jokes(m: GameModel) -> void:
	if m.ln_p < _joke_p - 0.5:
		_joke_p = m.ln_p          # empezó otra vuelta (o hubo deflación)
	if m.ln_p - _joke_p >= 0.08 and _clock - _joke_t >= 25.0:
		_joke_p = m.ln_p
		_joke_t = _clock
		_toast(tr("joke.%d" % (_joke_i % JOKES)), Chalk.RED)
		_joke_i += 1 + randi() % 3


func _pct(v: float) -> String:
	if v >= 1000.0:
		return BigNumber.from_float(v).format(1)
	return ("%.1f" % v).replace(".", ",") if v < 10.0 else "%d" % int(v)


func _refresh_left(m: GameModel) -> void:
	empanada.rate = EconomyLogic.monthly_pct(m) / 100.0
	var era: int = EconomyLogic.era_of(m)
	barrio.refresh(m, era)
	backdrop.era = era
	# la empanada evoluciona con el árbol
	var seals: int = 0
	for id in m.tree:
		if bool(GameData.node(id)["seal"]):
			seals += 1
	empanada.hat = m.tree.size() >= 3
	empanada.glasses = m.tree.size() >= 20
	empanada.crown = seals >= 6
	empanada.gold = m.won
	click_label.text = tr("ui.per_click") % EconomyLogic.click_value(m).format()
	var cap: int = int(m.mods["combo_cap"])
	combo_bar.max_value = float(cap)
	empanada.streak = float(m.combo) / float(maxi(1, cap))
	combo_bar.value = float(m.combo)
	combo_label.text = tr("ui.combo") % ("x" + UpgradeIcon._num(EconomyLogic.combo_mult(m))) if m.combo >= 2 else " "
	var gain: int = EconomyLogic.reform_gain(m)
	var can: bool = EconomyLogic.can_reform(m)
	var demo_over: bool = m.demo_mode and m.reforms >= int(EconomyLogic.B("demo_max_reforms"))
	reform_btn.disabled = not can
	if can:
		reform_btn.text = tr("ui.reform.btn") % gain
	elif demo_over:
		reform_btn.text = tr("ui.reform.btn_off")
	else:
		reform_btn.text = tr("ui.reform.btn_at") % [UIKit.money(EconomyLogic.reform_target(m)), UIKit.money(EconomyLogic.reform_missing(m))]
	reform_hint.add_theme_color_override("font_color", UIKit.C_DIM)
	if demo_over:
		reform_hint.text = tr("ui.reform.demo")
	elif can and EconomyLogic.stuck(m):
		reform_hint.text = tr("ui.reform.stuck")
		reform_hint.add_theme_color_override("font_color", Chalk.YELLOW)
	elif EconomyLogic.reform_advised(m):
		reform_hint.text = tr("ui.reform.advice")
		reform_hint.add_theme_color_override("font_color", Chalk.YELLOW)
	elif can:
		reform_hint.text = tr("ui.reform.hint")
	else:
		reform_hint.text = tr("ui.reform.need")


## Cuántos negocios se ven sin haberlos comprado todavía, según la capa de la vuelta (cada capa agrega negocios).
const ERA_SHOW: Array = [0, 3, 5, 7, 10, 10]


func _refresh_biz(m: GameModel) -> void:
	var shown: int = ERA_SHOW[clampi(EconomyLogic.era_of(m), 1, 5)]
	for r in biz_rows:
		if m.owned_count(r["def"]["id"]) > 0:
			shown = maxi(shown, int(r["def"]["idx"]) + 2)
	var mystery_idx: int = -1
	for r in biz_rows:
		var def: Dictionary = r["def"]
		var id: String = def["id"]
		var idx: int = int(def["idx"])
		var avail: bool = EconomyLogic.business_available(m, def)
		var n: int = m.owned_count(id)
		var row: Control = r["row"]
		# se ven todos los desbloqueados hasta donde llega la capa, y el siguiente como "???" con su precio
		var visible_named: bool = n > 0 or (avail and idx < shown)
		var mystery: bool = false
		if not visible_named and mystery_idx < 0:
			mystery_idx = idx
			mystery = true
		row.visible = visible_named or mystery
		if not row.visible:
			continue
		(r["name"] as Label).text = "???" if mystery else tr(def["name_key"])
		(r["owned"] as Label).text = str(n) if n > 0 else ""
		var btn: Button = r["btn"]
		(r["icon"] as Control).modulate.a = 0.3 if mystery else 1.0
		if mystery:
			(r["info"] as Label).text = tr("ui.biz.locked_tree") if not avail else tr("ui.biz.mystery")
			btn.text = UIKit.money(EconomyLogic.business_cost(m, def, 1))
			btn.disabled = not avail or EconomyLogic.business_cost(m, def, 1).gt(m.money)
			continue
		var each: BigNumber = def["base_income"].mul_f(float(m.mods["prod_mult"]))
		if n > 0 and m.biz_income.has(id):
			each = (m.biz_income[id] as BigNumber).div_f(float(n))
		var next_ms: int = -1
		for t in GameData.balance["milestones"]:
			if n < int(t):
				next_ms = int(t)
				break
		var info: String = tr("ui.biz.each") % each.format()
		if next_ms > 0 and n > 0:
			info += "  -  " + tr("ui.biz.next_ms") % next_ms
		(r["info"] as Label).text = info
		var q: int = _buy_mode
		var cost: BigNumber
		if q < 0:
			var k: int = maxi(1, EconomyLogic.max_affordable(m, def))
			cost = EconomyLogic.business_cost(m, def, k)
			btn.text = "x%d  %s" % [k, UIKit.money(cost)]
		else:
			cost = EconomyLogic.business_cost(m, def, q)
			btn.text = UIKit.money(cost) if q == 1 else "x%d  %s" % [q, UIKit.money(cost)]
		btn.disabled = cost.gt(m.money)
		_price_bump(r, n, cost)
	# la fila de la flecha siempre ocupa su lugar (así la lista no salta); solo se ve si hay más abajo
	var vb: VScrollBar = biz_scroll.get_v_scroll_bar()
	var more: bool = vb.max_value - vb.page > float(biz_scroll.scroll_vertical) + 6.0
	biz_more.modulate.a = (0.75 + 0.25 * sin(_clock * 4.0)) if more else 0.0
	biz_more.mouse_filter = Control.MOUSE_FILTER_STOP if more else Control.MOUSE_FILTER_IGNORE


## Si el precio de un negocio subió por la inflación (sin comprar), el viejo se tacha con tiza y cae, y el nuevo salta.
func _price_bump(r: Dictionary, n: int, cost: BigNumber) -> void:
	var last: Variant = r.get("last_cost", null)
	var same_n: bool = int(r.get("last_n", -1)) == n and int(r.get("last_mode", 0)) == _buy_mode
	r["last_n"] = n
	r["last_mode"] = _buy_mode
	if last == null or not same_n:
		r["last_cost"] = cost
		return
	var old: BigNumber = last
	if cost.le(old.mul_f(1.03)):
		if cost.lt(old):
			r["last_cost"] = cost
		return
	r["last_cost"] = cost
	var btn: Button = r["btn"]
	if Settings.quality >= 2 or not btn.is_visible_in_tree() or _clock - float(r.get("bump_t", -99.0)) < 2.0:
		return
	r["bump_t"] = _clock
	var br: Rect2 = btn.get_global_rect()
	var l: Label = UIKit.label(UIKit.money(old), 15, Color(Chalk.WHITE, 0.8), HORIZONTAL_ALIGNMENT_CENTER)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = br.position + Vector2(-br.size.x * 0.62, 4)
	l.size = Vector2(br.size.x, 20)
	var strike: Control = Control.new()
	strike.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strike.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	strike.draw.connect(func() -> void:
		Chalk.line(strike, Vector2(br.size.x * 0.22, 12), Vector2(br.size.x * 0.78, 9), Chalk.RED, 2.4, 77, 1.0))
	l.add_child(strike)
	fx_layer.add_child(l)
	var tw: Tween = create_tween()
	tw.tween_property(l, "position:y", l.position.y + 26.0, 0.9).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(l, "rotation", randf_range(-0.25, 0.25), 0.9)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tw.tween_callback(l.queue_free)
	Chalk.pop(btn, 1.08, 0.3)


func _refresh_qty_buttons() -> void:
	for qb in qty_buttons:
		UIKit.style_button(qb["btn"], UIKit.C_BLUE if qb["q"] == _buy_mode else UIKit.C_PANEL2, 15)


func _refresh_upgrades(m: GameModel) -> void:
	var vis: Array = EconomyLogic.visible_upgrades(m)
	var next: Array = EconomyLogic.upcoming_upgrades(m, 4)
	var sig: String = ""
	for u in vis:
		sig += str(u["id"]) + ","
	sig += "|"
	for u in next:
		sig += str(u["id"]) + ","
	if sig != _upg_sig:
		_upg_sig = sig
		_upg_hover = null
		upg_detail.visible = false
		UIKit.clear_children(upg_flow)
		_upg_icons.clear()
		for u in vis:
			var ic: UpgradeIcon = UpgradeIcon.new(u)
			var uid: String = u["id"]
			ic.pressed.connect(func() -> void:
				if Economy.buy_upgrade(uid):
					_burst(ic.get_global_rect().get_center(), Chalk.YELLOW, 14)
				else:
					_play("error"))
			_add_upgrade_card(ic)
			if not _seen_upgrades.has(uid):
				_seen_upgrades[uid] = true
				Chalk.pop(ic, 1.25, 0.5)
		if not next.is_empty():
			var nl: Label = UIKit.label(tr("ui.upgrades_next"), 15, UIKit.C_DIM)
			nl.custom_minimum_size = Vector2(0, UpgradeIcon.CARD.y)
			nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			upg_flow.add_child(nl)
			for u in next:
				var lk: UpgradeIcon = UpgradeIcon.new(u, true)
				lk.set_cond(EconomyLogic.upgrade_condition_text(m, u), maxf(0.0, EconomyLogic.upgrade_condition_progress(m, u)))
				_add_upgrade_card(lk)
	for ic in _upg_icons:
		var card: UpgradeIcon = ic
		if card.locked and card.cond_text != "":
			card.set_cond(EconomyLogic.upgrade_condition_text(m, card.upg), maxf(0.0, EconomyLogic.upgrade_condition_progress(m, card.upg)))
		var cost: BigNumber = EconomyLogic.upgrade_cost(m, card.upg)
		var can: bool = cost.le(m.money)
		var prog: float = 1.0
		if not can:
			prog = clampf(pow(10.0, m.money.log10() - cost.log10()), 0.0, 1.0) if not m.money.is_zero() else 0.0
		card.set_state(can, prog, UIKit.money(cost))
	if _upg_hover != null and is_instance_valid(_upg_hover):
		_show_upgrade_detail(_upg_hover)
	var empty: bool = vis.is_empty() and next.is_empty()
	upg_title.text = tr("ui.upgrades") if not empty else tr("ui.upgrades_none")
	# si no hay nada para mostrar, la caja se achica y ese espacio va a los negocios
	upg_scroll.visible = not empty
	upg_scroll.custom_minimum_size.y = 0.0 if empty else UPG_BOX_H


func _add_upgrade_card(ic: UpgradeIcon) -> void:
	ic.mouse_entered.connect(_show_upgrade_detail.bind(ic))
	ic.mouse_exited.connect(_hide_upgrade_detail.bind(ic))
	upg_flow.add_child(ic)
	_upg_icons.append(ic)


func _refresh_nav(m: GameModel) -> void:
	nav_tree.text = tr("ui.nav.tree") + (" (%d)" % m.credibility if m.credibility > 0 else "")
	var affordable: bool = TreeLogic.any_affordable(m)
	if affordable:
		nav_tree.modulate = Color(1, 1, 1).lerp(Chalk.YELLOW, 0.5 + 0.5 * sin(_clock * 5.0))
	else:
		nav_tree.modulate = Color.WHITE
	nav_tree.visible = m.reforms > 0 or m.credibility > 0 or not m.tree.is_empty()
	nav_album.visible = bool(m.mods["album"])
	nav_album.text = tr("ui.nav.album") + (" (%d)" % m.free_packs_pending if m.free_packs_pending > 0 else "")
	nav_scratch.visible = bool(m.mods["scratch"])
	nav_scratch.disabled = GambleLogic.price(m).is_zero()
	nav_ach.text = tr("ui.nav.ach") + " %d/%d" % [m.achievements.size(), GameData.achievements.size()]


func _refresh_event(m: GameModel) -> void:
	if m.pending_choice.is_empty():
		event_panel.visible = false
		return
	var id: String = str(m.pending_choice["id"])
	event_panel.visible = _overlay == null
	event_title.text = tr("ev." + id)
	var choices: Array = EconomyLogic.event_def(id)["choices"]
	for i in range(2):
		(event_buttons[i] as Button).text = tr("ev.%s.%s" % [id, choices[i]["id"]])
	event_bar.max_value = float(m.pending_choice["total"])
	event_bar.value = float(m.pending_choice["remaining"])


func _refresh_tutorial(m: GameModel) -> void:
	var step: int = EconomyLogic.tutorial_step(m)
	if step >= EconomyLogic.TUTORIAL_STEPS and not m.tutorial_done:
		m.tutorial_done = true
	var show: bool = step >= 0 and step < EconomyLogic.TUTORIAL_STEPS and _overlay == null
	tutorial_note.visible = show
	if not show:
		_tut_step = step
		return
	if step != _tut_step:
		_tut_step = step
		tutorial_label.text = tr("tut.v2.%d" % step)
		Chalk.pop(tutorial_note, 1.15, 0.4)
	var target: Control = [empanada, biz_list, remark_btn, reform_btn][step]
	var r: Rect2 = target.get_global_rect()
	var ns: Vector2 = tutorial_note.get_combined_minimum_size()
	var pos: Vector2
	match step:
		0:
			pos = Vector2(r.end.x - 40.0, r.position.y + 10.0)
		1:
			pos = Vector2(r.position.x + 40.0, r.position.y + 70.0)
		2:
			pos = Vector2(r.get_center().x - ns.x / 2.0, r.end.y + 26.0)
		_:
			pos = Vector2(r.end.x + 14.0, r.position.y - 10.0)
	var vr: Vector2 = get_viewport_rect().size
	pos.x = clampf(pos.x, 8.0, vr.x - ns.x - 8.0)
	pos.y = clampf(pos.y, 8.0, vr.y - ns.y - 8.0)
	tutorial_note.position = pos + Vector2(0, sin(_clock * 3.0) * 3.0)


# =====================================================================
#  Acciones y reacciones
# =====================================================================
func _on_buy_business(id: String) -> void:
	var n: int = Economy.buy_business(id, _buy_mode)
	if n <= 0:
		_play("error")


func _on_business_bought(id: String, _n: int) -> void:
	_play("buy", randf_range(0.95, 1.1))
	for r in biz_rows:
		if r["def"]["id"] == id:
			(r["icon"] as BusinessIcon).hop()
			Chalk.pop(r["owned"], 1.5, 0.35)
	Chalk.pop(money_label, 1.06, 0.25)


func _on_clicked(res: Dictionary) -> void:
	var v: BigNumber = res["value"]
	var crit: bool = bool(res["crit"])
	var pos: Vector2 = get_global_mouse_position()
	var er: Rect2 = empanada.get_global_rect()
	if not er.has_point(pos):
		pos = er.get_center() + Vector2(randf_range(-60, 60), randf_range(-10, 30))
	empanada.poke()
	_click_float(("¡%s! " % tr("ui.crit") if crit else "") + "+" + UIKit.money(v), pos, Chalk.YELLOW if crit else Chalk.WHITE, 30 if crit else 22)
	_burst(pos, Chalk.ORANGE if crit else Chalk.YELLOW, 10 if crit else 5)
	_play("click", 1.0 + minf(float(res["combo"]), 30.0) * 0.012)
	if crit:
		_shake(5.0, 0.15)


func _on_remarked(seconds: float, manual: bool) -> void:
	if manual:
		_stamp(tr("ui.remarked") % int(seconds), rate_label.get_global_rect().get_center())
	_play("stamp")


func _on_collapse() -> void:
	_play("raise")
	_shake(10.0, 0.4)
	_stamp(tr("ui.collapse"), get_viewport_rect().size / 2.0, Chalk.YELLOW, 34)
	_reform_pulse = 6.0


func _spawn_bill(id: int) -> void:
	if _bills.has(id):
		return
	var secs: float = EconomyLogic.B("bill_flight") * float(gm().mods["bill_slow"])
	for b in gm().bills_active:
		if int(b["id"]) == id:
			secs = float(b["left"])
	var fb: FlyingBill = FlyingBill.new(id, secs)
	fb.caught.connect(func(bid: int) -> void:
		var pos: Vector2 = fb.get_global_rect().get_center()
		var r: Dictionary = Economy.click_bill(bid)
		_bills.erase(bid)
		if not r.is_empty():
			_burst(pos, Chalk.GREEN, 24))
	bills_layer.add_child(fb)
	_bills[id] = fb
	_play("coin", 1.3)


func _on_bill_prize(res: Dictionary) -> void:
	var kind: String = str(res["kind"])
	var text: String = ""
	match kind:
		"money":
			text = tr("bill.money") % UIKit.money(res["amount"])
		"frenzy":
			text = tr("bill.frenzy") + " " + tr("bill.frenzy.d") % [int(gm().mods["frenzy_mult"]), int(res["seconds"])]
		"freeze":
			text = tr("bill.freeze") % int(res["seconds"])
		"clickfrenzy":
			text = tr("bill.clickfrenzy") % int(res["seconds"])
		"sticker":
			text = tr("bill.sticker") % tr(StickerLogic.def(str(res["sticker"]))["name_key"])
	_stamp(text, get_viewport_rect().size * Vector2(0.5, 0.42), Chalk.GREEN, 30)
	_play("jackpot" if kind == "frenzy" else "gold")


func _on_node_bought(id: String) -> void:
	_play("win", 1.2)
	if _tree_view != null and is_instance_valid(_tree_view):
		_tree_view.spark(id)
	_toast(tr("ui.toast.node") % tr(GameData.node(id)["name_key"]), Chalk.BLUE)


func _on_victory() -> void:
	_play("jackpot")
	get_tree().create_timer(1.5).timeout.connect(func() -> void: request_credits.emit())


# =====================================================================
#  Efectos
# =====================================================================
func _update_juice(delta: float) -> void:
	if _shake_t > 0.0:
		_shake_t -= delta
		var k: float = clampf(_shake_t / 0.35, 0.0, 1.0)
		world.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_amp * k * Settings.fx_scale()
		if _shake_t <= 0.0:
			_shake_amp = 0.0
			world.position = Vector2.ZERO
	var pct: float = EconomyLogic.monthly_pct(gm())
	money_label.pivot_offset = money_label.size / 2.0
	if pct > 50.0 and not EconomyLogic.frozen(gm()):
		var a: float = clampf(pct * 0.0002, 0.0, 0.04)
		money_label.rotation = randf_range(-a, a)
	else:
		money_label.rotation = 0.0
	var target: float = clampf((pct - EconomyLogic.B("hyper_month_pct")) / 400.0, 0.0, 0.28)
	# cerca de la pared (final de la vuelta): la pantalla se pone roja y la empanada transpira, aunque el freno evite la traba
	var wall: float = EconomyLogic.wall_closeness(gm())
	target = maxf(target, wall * 0.2)
	empanada.sweat = wall
	tint.color.a = target * (0.75 + 0.25 * sin(_clock * 5.0))
	if _rate_shake > 0.0:
		_rate_shake = maxf(0.0, _rate_shake - delta)
		rate_label.pivot_offset = rate_label.size / 2.0
		rate_label.rotation = randf_range(-0.04, 0.04) * (_rate_shake / 0.35) * Settings.fx_scale()
	else:
		rate_label.rotation = 0.0
	var nudge: bool = EconomyLogic.reform_advised(gm())
	if _reform_pulse > 0.0 or nudge:
		_reform_pulse = maxf(0.0, _reform_pulse - delta)
		reform_btn.pivot_offset = reform_btn.size / 2.0
		reform_btn.scale = Vector2.ONE * (1.0 + 0.05 * sin(_clock * 8.0))
		reform_btn.modulate = Color.WHITE.lerp(Chalk.YELLOW, 0.5 + 0.5 * sin(_clock * 8.0))
	else:
		reform_btn.scale = Vector2.ONE
		reform_btn.modulate = Color.WHITE


func _shake(amp: float, duration: float) -> void:
	_shake_amp = maxf(_shake_amp, amp)
	_shake_t = maxf(_shake_t, duration)


func _floating_text(text: String, pos: Vector2, color: Color, fs: int = 22) -> void:
	if fx_layer.get_child_count() > 60:
		return
	var l: Label = UIKit.label(text, fs, color, HORIZONTAL_ALIGNMENT_LEFT, true)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = pos - Vector2(30, 30)
	fx_layer.add_child(l)
	var tw: Tween = create_tween()
	tw.tween_property(l, "position:y", l.position.y - 80.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tw.tween_callback(l.queue_free)


## El "+$X" de un clic: nace donde tocaste pero nunca arriba del gorrito o la corona (zona prohibida de la empanada) y
## se va en diagonal hacia el costado, así no tapa los accesorios ni la cara.
func _click_float(text: String, pos: Vector2, color: Color, fs: int) -> void:
	if fx_layer.get_child_count() > 60:
		return
	var l: Label = UIKit.label(text, fs, color, HORIZONTAL_ALIGNMENT_LEFT, true)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(l)
	l.size = l.get_combined_minimum_size()
	var path: Array = click_float_path(empanada, pos, l.size)
	l.position = path[0]
	var tw: Tween = create_tween()
	tw.tween_property(l, "position", path[1], 0.75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tw.tween_callback(l.queue_free)


## Recorrido [inicio, fin] (esquina del texto, global) del "+$X": arranca debajo de la zona prohibida (gorrito, corona,
## vapor) y se aleja hacia el costado más cercano y un poco hacia arriba, sin volver a subir a esa zona.
static func click_float_path(emp: EmpanadaButton, pos: Vector2, sz: Vector2) -> Array:
	var keep_out: Rect2 = emp.keep_out_rect()
	var er: Rect2 = emp.get_global_rect()
	var start: Vector2 = pos - Vector2(sz.x / 2.0, sz.y / 2.0)
	start.y = maxf(start.y, keep_out.end.y + 4.0)
	start.y = minf(start.y, er.end.y - sz.y)
	var dir: float = -1.0 if pos.x < er.get_center().x else 1.0
	var end: Vector2 = start + Vector2(dir * 95.0, -24.0)
	end.y = maxf(end.y, keep_out.end.y + 4.0)
	return [start, end]


func _burst(pos: Vector2, color: Color, amount: int) -> void:
	var p: CPUParticles2D = Chalk.particles()
	p.position = pos
	p.emitting = true
	p.one_shot = true
	p.amount = maxi(1, Settings.particles(amount))
	p.lifetime = 0.8
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 80.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 300.0
	p.gravity = Vector2(0, 700)
	p.scale_amount_min = 3.0 / 8.0
	p.scale_amount_max = 6.0 / 8.0
	p.color = color
	fx_layer.add_child(p)
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


## Cartel grande que aparece, late y se va (premios, colapso, remarcado).
func _stamp(text: String, center: Vector2, color: Color = Chalk.YELLOW, fs: int = 34) -> void:
	var l: Label = UIKit.label(text, fs, color, HORIZONTAL_ALIGNMENT_CENTER, true)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(l)
	l.size = l.get_combined_minimum_size()
	l.position = center - l.size / 2.0
	l.pivot_offset = l.size / 2.0
	l.rotation = randf_range(-0.08, 0.08)
	l.scale = Vector2(0.3, 0.3)
	var tw: Tween = create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)


## Aviso chico arriba a la derecha: entra con un pop y se va solo a los 3 s.
## Aviso chico: en las primeras vueltas salen de a uno (con pausa), así da tiempo a leerlos.
func _toast(text: String, color: Color) -> void:
	_toast_queue.append([text, color])


func _pump_toasts() -> void:
	if _toast_queue.is_empty():
		return
	var gap: float = 2.2 if gm().reforms < int(EconomyLogic.B("slow_runs")) else 0.4
	if _clock - _last_toast < gap:
		return
	_last_toast = _clock
	var t: Array = _toast_queue.pop_front()
	_show_toast(str(t[0]), t[1])


func _show_toast(text: String, color: Color) -> void:
	var p: PanelContainer = PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st: ChalkStyle = UIKit.chalk_box(Chalk.nearest(color), Color(0.05, 0.08, 0.06, 0.9), 2.0)
	st.content_margin_top = 3.0
	st.content_margin_bottom = 3.0
	st.content_margin_left = 10.0
	st.content_margin_right = 10.0
	p.add_theme_stylebox_override("panel", st)
	var l: Label = UIKit.label(text, 15, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(310, 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	toast_box.add_child(p)
	while toast_box.get_child_count() > 3:
		var old: Node = toast_box.get_child(0)
		toast_box.remove_child(old)
		old.queue_free()
	p.pivot_offset = Vector2(170, 14)
	p.scale = Vector2(0.6, 0.6)
	var tw: Tween = create_tween()
	tw.tween_property(p, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval((TOAST_SECONDS_SLOW if gm().reforms < int(EconomyLogic.B("slow_runs")) else TOAST_SECONDS) - 0.7)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)
	_play("coin", 1.6)


func _update_ticker(delta: float) -> void:
	if ticker_label.text == "" or ticker_label.position.x + ticker_label.size.x < 0.0:
		var hl: Dictionary = GameData.headlines[_headline_i % GameData.headlines.size()]
		_headline_i += 1 + randi() % 3
		ticker_label.text = "   *   " + tr(hl["key"]) + "   *   "
		ticker_label.size = ticker_label.get_combined_minimum_size()
		ticker_label.position.x = ticker_clip.size.x
	ticker_label.position.x -= (60.0 + EconomyLogic.monthly_pct(gm()) * 0.3) * delta
	ticker_label.position.y = (ticker_clip.size.y - ticker_label.size.y) / 2.0


# =====================================================================
#  Capas: árbol, álbum, raspadita, logros, reforma
# =====================================================================
func _new_overlay(title: String) -> Array:
	_close_overlay()
	var ov: ColorRect = ColorRect.new()
	ov.color = Color(Chalk.BOARD.darkened(0.45), 0.985)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ov)
	_overlay = ov
	world.visible = false      # la capa es opaca: el juego de abajo no se dibuja ni se pisa con ella
	var mc: MarginContainer = MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, 22)
	ov.add_child(mc)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	mc.add_child(v)
	var top: HBoxContainer = HBoxContainer.new()
	v.add_child(top)
	var t: Label = UIKit.label(title, 34, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT, true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	var close: Button = Button.new()
	close.text = tr("ui.close")
	close.custom_minimum_size = Vector2(130, 46)
	UIKit.style_button(close, UIKit.C_PANEL2, 18)
	close.pressed.connect(_close_overlay)
	top.add_child(close)
	return [ov, v, top]


func _close_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null
	world.visible = true
	_tree_view = null
	_album_page = null


func _open_tree() -> void:
	var parts: Array = _new_overlay(tr("ui.tree.title"))
	var v: VBoxContainer = parts[1]
	var top: HBoxContainer = parts[2]
	var cl: Label = UIKit.label("", 26, Chalk.BLUE, HORIZONTAL_ALIGNMENT_RIGHT, true)
	cl.custom_minimum_size = Vector2(200, 0)
	top.add_child(cl)
	top.move_child(cl, 1)
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var board: PanelContainer = UIKit.panel(UIKit.C_PANEL, 10)
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(board)
	_tree_view = SkillTreeView.new()
	board.add_child(_tree_view)
	_tree_view.node_selected.connect(func(_id: String) -> void: _refresh_tree_info())
	var side: PanelContainer = UIKit.panel(UIKit.C_PANEL, 10)
	side.custom_minimum_size = Vector2(330, 0)
	row.add_child(side)
	var sv: VBoxContainer = VBoxContainer.new()
	sv.add_theme_constant_override("separation", 10)
	side.add_child(sv)
	var name_l: Label = UIKit.label("", 24, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT, true)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.custom_minimum_size = Vector2(300, 0)
	sv.add_child(name_l)
	var branch_l: Label = UIKit.label("", 15, UIKit.C_DIM)
	sv.add_child(branch_l)
	var desc_l: Label = UIKit.label("", 17, Chalk.WHITE)
	desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_l.custom_minimum_size = Vector2(300, 0)
	sv.add_child(desc_l)
	var state_l: Label = UIKit.label("", 16, Chalk.PINK)
	state_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	state_l.custom_minimum_size = Vector2(300, 0)
	sv.add_child(state_l)
	var buy: Button = Button.new()
	buy.custom_minimum_size = Vector2(0, 54)
	UIKit.style_button(buy, UIKit.C_GREEN.darkened(0.2), 19)
	buy.pressed.connect(func() -> void:
		if _tree_view != null and Economy.buy_node(_tree_view.selected):
			_refresh_tree_info()
		else:
			_play("error"))
	sv.add_child(buy)
	var sp: Control = Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sv.add_child(sp)
	var help: Label = UIKit.label(tr("ui.tree.help"), 15, UIKit.C_DIM)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.custom_minimum_size = Vector2(300, 0)
	sv.add_child(help)
	var zr: HBoxContainer = HBoxContainer.new()
	zr.add_theme_constant_override("separation", 6)
	sv.add_child(zr)
	for z in [["-", 1.0 / 1.25], ["+", 1.25], [tr("ui.tree.center"), 0.0]]:
		var zb: Button = Button.new()
		zb.text = str(z[0])
		zb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UIKit.style_button(zb, UIKit.C_PANEL2, 18)
		var k: float = float(z[1])
		zb.pressed.connect(func() -> void:
			if k == 0.0:
				_tree_view.zoom = 0.62
				_tree_view.focus("")
			else:
				_tree_view.zoom_by(k))
		zr.add_child(zb)
	_tree_info = {"cred": cl, "name": name_l, "branch": branch_l, "desc": desc_l, "state": state_l, "buy": buy}
	# arranca con el nodo comprable más barato seleccionado (o la meta, en el centro)
	var pick: String = "final"
	var best: int = 1 << 30
	for n in GameData.tree:
		if TreeLogic.can_buy(gm(), n["id"]) and int(n["cost"]) < best:
			best = int(n["cost"])
			pick = n["id"]
	_tree_view.selected = pick
	# en las primeras vueltas, una flecha señala el nodo recomendado
	var rec: String = BotPolicy.recommended_node(gm())
	if gm().reforms <= 3 and rec != "" and TreeLogic.can_buy(gm(), rec):
		_tree_view.selected = rec
		_tree_view.hint_id = rec
		_tree_view.hint_text = tr("ui.tree.recommend")
	_tree_view.focus("")
	_refresh_tree_info()


func _refresh_tree_info() -> void:
	if _tree_info.is_empty() or _tree_view == null:
		return
	var m: GameModel = gm()
	(_tree_info["cred"] as Label).text = tr("ui.tree.cred") % m.credibility
	var id: String = _tree_view.selected
	if id == "" or not GameData.tree_idx.has(id):
		return
	var n: Dictionary = GameData.node(id)
	var known: bool = TreeLogic.visible(m, id)
	(_tree_info["name"] as Label).text = tr(n["name_key"]) if known else "???"
	var br: String = str(n["branch"])
	(_tree_info["branch"] as Label).text = tr("ui.branch." + br) + ("  ·  " + tr("ui.tree.seal") if bool(n["seal"]) else "") + ("  ·  " + tr("ui.tree.cap") if bool(n["cap"]) else "")
	(_tree_info["desc"] as Label).text = tr(n["desc_key"]) if known else tr("ui.tree.fog")
	var buy: Button = _tree_info["buy"]
	var state: Label = _tree_info["state"]
	if m.tree.has(id):
		state.text = tr("ui.tree.owned")
		state.add_theme_color_override("font_color", Chalk.GREEN)
		buy.visible = false
		return
	buy.visible = known
	buy.text = tr("ui.tree.buy") % TreeLogic.cost(id)
	buy.disabled = not TreeLogic.can_buy(m, id)
	state.add_theme_color_override("font_color", Chalk.PINK)
	if TreeLogic.demo_locked(m, id):
		state.text = tr("ui.tree.full_game")
	elif not TreeLogic.requirements_met(m, id):
		var names: Array = []
		for p in n["parents"]:
			if not m.tree.has(p):
				names.append(tr(GameData.node(p)["name_key"]) if TreeLogic.visible(m, p) else "???")
		state.text = tr("ui.tree.needs") % ", ".join(names)
	elif m.credibility < TreeLogic.cost(id):
		state.text = tr("ui.tree.missing") % (TreeLogic.cost(id) - m.credibility)
	else:
		state.text = ""


func _open_album() -> void:
	var parts: Array = _new_overlay(tr("ui.nav.album"))
	var v: VBoxContainer = parts[1]
	_album_page = AlbumPage.new()
	_album_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_album_page.pack_bought.connect(func(res: Array) -> void: _open_pack_overlay(res))
	_album_page.message.connect(func(t: String) -> void: _toast(t, Chalk.PINK))
	v.add_child(_album_page)
	_album_page.refresh(gm())


func _open_pack_overlay(results: Array) -> PackOpening:
	if _pack_overlay != null and is_instance_valid(_pack_overlay):
		_pack_overlay.queue_free()
	_pack_overlay = PackOpening.new(results)
	_pack_overlay.finished.connect(func() -> void:
		_pack_overlay.queue_free()
		_pack_overlay = null)
	add_child(_pack_overlay)
	return _pack_overlay


func _open_scratch(force: String = "") -> ScratchOverlay:
	var res: Dictionary = Economy.play_scratch(force)
	if not bool(res.get("ok", false)):
		_play("error")
		return null
	if _scratch_overlay != null and is_instance_valid(_scratch_overlay):
		_scratch_overlay.queue_free()
	_scratch_overlay = ScratchOverlay.new(res, EconomyLogic.B("scratch_pct"))
	_scratch_overlay.closed.connect(func() -> void:
		_scratch_overlay.queue_free()
		_scratch_overlay = null
		var pk: Array = res.get("pack", [])
		if not pk.is_empty():
			_open_pack_overlay(pk))
	_scratch_overlay.again.connect(func(_p: float) -> void:
		var pk2: Array = res.get("pack", [])
		_scratch_overlay.queue_free()
		_scratch_overlay = null
		if not pk2.is_empty():
			_open_pack_overlay(pk2)
		else:
			_open_scratch())
	add_child(_scratch_overlay)
	return _scratch_overlay


func _open_achievements() -> void:
	var m: GameModel = gm()
	var parts: Array = _new_overlay(tr("ui.nav.ach"))
	var v: VBoxContainer = parts[1]
	v.add_child(UIKit.label(tr("ui.ach.completion") % [_pct(EconomyLogic.completion(m)), TreeLogic.count(m), TreeLogic.total(),
		m.stickers.size(), StickerLogic.total(), m.achievements.size(), GameData.achievements.size()], 18, Chalk.YELLOW))
	var sc: ScrollContainer = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	sc.add_child(grid)
	for a in GameData.achievements:
		var have: bool = m.achievements.has(a["id"])
		var p: PanelContainer = UIKit.panel(UIKit.C_PANEL2 if not have else UIKit.C_PANEL, 8)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var av: VBoxContainer = VBoxContainer.new()
		av.add_theme_constant_override("separation", 0)
		p.add_child(av)
		var hidden: bool = bool(a["secret"]) and not have
		av.add_child(UIKit.label(((tr("ui.ach.done") + " ") if have else "") + (tr("ui.ach.secret") if hidden else tr(a["name_key"])), 18, Chalk.YELLOW if have else UIKit.C_DIM, HORIZONTAL_ALIGNMENT_LEFT, true))
		var d: Label = UIKit.label(tr("ui.ach.secret_d") if hidden else tr(a["desc_key"]), 15, Chalk.WHITE if have else UIKit.C_DIM)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(420, 0)
		av.add_child(d)
		grid.add_child(p)


func _open_reform_dialog() -> void:
	var m: GameModel = gm()
	if not EconomyLogic.can_reform(m):
		_play("error")
		return
	var parts: Array = _new_overlay(tr("ui.reform.title"))
	var v: VBoxContainer = parts[1]
	var cc: CenterContainer = CenterContainer.new()
	cc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(cc)
	var p: PanelContainer = PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.chalk_box(Chalk.YELLOW, Color(0.06, 0.1, 0.08, 0.97), 3.0))
	p.custom_minimum_size = Vector2(640, 0)
	cc.add_child(p)
	var pv: VBoxContainer = VBoxContainer.new()
	pv.add_theme_constant_override("separation", 12)
	p.add_child(pv)
	if m.reforms == 0:
		# la primera vez: qué es la reforma, en cuatro líneas de tiza
		var ex: PanelContainer = PanelContainer.new()
		ex.add_theme_stylebox_override("panel", UIKit.chalk_box(Chalk.PINK, Color(0.1, 0.07, 0.09, 0.9), 2.4))
		pv.add_child(ex)
		var ev: VBoxContainer = VBoxContainer.new()
		ev.add_theme_constant_override("separation", 4)
		ex.add_child(ev)
		ev.add_child(UIKit.label(tr("ui.reform.what"), 22, Chalk.PINK, HORIZONTAL_ALIGNMENT_CENTER, true))
		for i in range(1, 5):
			var el: Label = UIKit.label(tr("ui.reform.what.%d" % i), 18, Chalk.WHITE)
			el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			el.custom_minimum_size = Vector2(580, 0)
			ev.add_child(el)
	pv.add_child(UIKit.label(tr("ui.reform.gain") % EconomyLogic.reform_gain(m), 36, Chalk.BLUE, HORIZONTAL_ALIGNMENT_CENTER, true))
	var d: Label = UIKit.label(tr("ui.reform.desc") % [UIKit.money(m.run_earned), _mmss(m.run_time)], 18, Chalk.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(600, 0)
	pv.add_child(d)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	pv.add_child(row)
	var ok: Button = Button.new()
	ok.text = tr("ui.reform.confirm")
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.custom_minimum_size = Vector2(0, 58)
	UIKit.style_button(ok, UIKit.C_GOLD, 22)
	ok.pressed.connect(func() -> void:
		_close_overlay()
		Economy.reform())
	row.add_child(ok)
	var no: Button = Button.new()
	no.text = tr("ui.cancel")
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.custom_minimum_size = Vector2(0, 58)
	UIKit.style_button(no, UIKit.C_PANEL2, 20)
	no.pressed.connect(_close_overlay)
	row.add_child(no)


func _mmss(s: float) -> String:
	return "%d:%02d" % [int(s) / 60, int(s) % 60]


func _on_reform_done(summary: Dictionary) -> void:
	for id in _bills:
		if is_instance_valid(_bills[id]):
			(_bills[id] as Node).queue_free()
	_bills.clear()
	_upg_sig = ""
	_play_reform_animation(int(summary.get("cut", 3)), summary)


## La tijera corta los ceros del billete y después aparece el resumen de la vuelta.
func _play_reform_animation(cut: int, summary: Dictionary) -> void:
	if _busy_overlay != null and is_instance_valid(_busy_overlay):
		_busy_overlay.queue_free()
	var ov: ColorRect = ColorRect.new()
	ov.color = Color(0, 0, 0, 0.82)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ov)
	_busy_overlay = ov
	var vs: Vector2 = get_viewport_rect().size
	var title: Label = UIKit.label(tr("ui.reform.anim"), 34, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(vs.x / 2.0 - 300, 60)
	title.size = Vector2(600, 50)
	ov.add_child(title)
	var note: BanknoteView = BanknoteView.new()
	note.custom_minimum_size = Vector2(520, 250)
	note.size = Vector2(520, 250)
	note.zeros = clampi(cut + 3, 3, 40)
	note.title = tr("ui.reform.note")
	note.note_color = Color("#b8c4a0")
	note.position = vs / 2.0 - note.size / 2.0
	ov.add_child(note)
	var sc: ScissorsView = ScissorsView.new()
	sc.size = Vector2(150, 130)
	sc.scale = Vector2(1.9, 1.9)
	sc.pivot_offset = Vector2(75, 65)
	sc.position = Vector2(vs.x + 60, note.position.y + 60)
	sc.open = 0.5
	ov.add_child(sc)
	var cut_x: float = note.position.x + note.size.x * 0.62
	var tw: Tween = ov.create_tween()      # si la capa se cierra antes, la animación se corta con ella
	tw.tween_property(sc, "position:x", cut_x, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for i in range(3):
		tw.tween_callback(func() -> void: _play("snip"))
		tw.tween_property(sc, "open", 0.0, 0.07)
		tw.tween_property(sc, "open", 0.5, 0.07)
	tw.tween_callback(func() -> void:
		if not is_instance_valid(ov):
			return
		note.cut_zeros = cut
		note.queue_redraw()
		_shake(14.0, 0.35)
		for k in range(mini(cut, 12)):
			var z: Label = UIKit.label("0", 44, Chalk.WHITE, HORIZONTAL_ALIGNMENT_LEFT, true)
			z.position = Vector2(cut_x + k * 10, note.position.y + 80)
			ov.add_child(z)
			var zt: Tween = create_tween()
			zt.tween_property(z, "position", z.position + Vector2(randf_range(-60, 160), 260), 0.9).set_ease(Tween.EASE_IN)
			zt.parallel().tween_property(z, "rotation", randf_range(-3, 3), 0.9)
			zt.parallel().tween_property(z, "modulate:a", 0.0, 0.9)
			zt.tween_callback(z.queue_free))
	tw.tween_property(sc, "position:x", vs.x + 100.0, 0.5).set_delay(0.4)
	tw.tween_property(note, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(title, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void:
		if is_instance_valid(ov):
			_show_run_summary(ov, summary))


func _show_run_summary(ov: Control, s: Dictionary) -> void:
	var cc: CenterContainer = CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(cc)
	var p: PanelContainer = PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.chalk_box(Chalk.BLUE, Color(0.06, 0.1, 0.08, 0.97), 3.2))
	p.custom_minimum_size = Vector2(660, 0)
	cc.add_child(p)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var earned: BigNumber = BigNumber.from_string(str(s["earned"]))
	var head: Label = UIKit.label(tr("ui.summary.line") % [int(s["n"]), UIKit.money(earned), _mmss(float(s["time"])), int(s["cred"])], 26, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, true)
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.custom_minimum_size = Vector2(620, 0)
	v.add_child(head)
	if str(s.get("prev_earned", "")) != "":
		var pe: BigNumber = BigNumber.from_string(str(s["prev_earned"]))
		var better: bool = earned.gt(pe)
		var faster: bool = float(s["time"]) < float(s["prev_time"])
		var cmp: Label = UIKit.label(tr("ui.summary.cmp") % [("+ " if better else "- ") + UIKit.money(pe), ("+ " if faster else "- ") + _mmss(float(s["prev_time"])), int(s["prev_cred"])], 18, Chalk.GREEN if better else Chalk.PINK, HORIZONTAL_ALIGNMENT_CENTER)
		cmp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cmp.custom_minimum_size = Vector2(620, 0)
		v.add_child(cmp)
	if int(s.get("note", -1)) >= 0:
		v.add_child(UIKit.label(tr("ui.summary.note"), 16, Chalk.PINK, HORIZONTAL_ALIGNMENT_CENTER))
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	var go: Button = Button.new()
	go.text = tr("ui.summary.tree")
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.custom_minimum_size = Vector2(0, 56)
	UIKit.style_button(go, UIKit.C_BLUE, 20)
	go.pressed.connect(func() -> void:
		ov.queue_free()
		_busy_overlay = null
		_open_tree())
	row.add_child(go)
	var first: bool = gm().reforms == 1 and gm().credibility > 0
	if first:
		# la primera vez el juego te lleva al árbol: ahí está lo que hace la próxima vuelta mucho más rápida
		var hint: Label = UIKit.label(tr("ui.summary.first"), 18, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_CENTER)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.custom_minimum_size = Vector2(620, 0)
		v.add_child(hint)
		v.move_child(hint, row.get_index())
	var keep: Button = Button.new()
	keep.text = tr("ui.summary.play")
	keep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keep.custom_minimum_size = Vector2(0, 56)
	UIKit.style_button(keep, UIKit.C_GREEN.darkened(0.2), 20)
	keep.pressed.connect(func() -> void:
		ov.queue_free()
		_busy_overlay = null)
	row.add_child(keep)
	keep.visible = not first
	Chalk.pop(p, 1.1, 0.4)
	_play("win")


func _show_secret() -> void:
	gm().secret_seen = true
	_stamp(tr("secret.title"), get_viewport_rect().size / 2.0, Chalk.YELLOW, 40)
	_play("jackpot")


# ---- informe offline ----
func show_offline_report(report: Dictionary) -> void:
	var parts: Array = _new_overlay(tr("ui.offline.title"))
	var v: VBoxContainer = parts[1]
	var cc: CenterContainer = CenterContainer.new()
	cc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(cc)
	var p: PanelContainer = PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.chalk_box(Chalk.GREEN, Color(0.06, 0.1, 0.08, 0.96), 3.2))
	p.custom_minimum_size = Vector2(600, 0)
	cc.add_child(p)
	var pv: VBoxContainer = VBoxContainer.new()
	pv.add_theme_constant_override("separation", 12)
	p.add_child(pv)
	pv.add_child(UIKit.label(tr("ui.offline.away") % UIKit.duration(float(report["seconds"])), 20, UIKit.C_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	pv.add_child(UIKit.label(tr("ui.offline.gain") % UIKit.money(report["gain"]), 28, Chalk.GREEN, HORIZONTAL_ALIGNMENT_CENTER, true))
	var note: Label = UIKit.label(tr("ui.offline.note") % int(round(float(gm().mods["offline_frac"]) * 100.0)), 15, UIKit.C_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(560, 0)
	pv.add_child(note)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and _overlay != null:
		_close_overlay()
		get_viewport().set_input_as_handled()
