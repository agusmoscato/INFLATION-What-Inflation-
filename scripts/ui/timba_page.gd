class_name TimbaPage
extends ScrollContainer
## Pestaña Timba: raspadita del kiosco, quiniela del mes y timba del dólar. Solo plata del juego.

signal scratch_requested(pct: float)
signal message(text: String)

var _vbox: VBoxContainer
var _pozo: Label
var _scratch_btns: Array = []
var _stake_btns: Array = []
var _q_number: int = 37
var _q_label: Label
var _q_ticket: Label
var _q_play: Button
var _d_info: Label
var _d_hint: Label
var _d_up: Button
var _d_down: Button
var _d_ticket: Label
var _quiniela_box: VBoxContainer
var _dollar_box: VBoxContainer
var _quiniela_lock: Label
var _dollar_lock: Label
var _stake_idx: int = 1


func _init() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 10)
	add_child(_vbox)
	_vbox.add_child(_wrap(UIKit.label(tr("timba.disclaimer"), 15, Chalk.PINK)))
	# ---- raspadita ----
	var s1: VBoxContainer = _section(tr("timba.scratch.title"))
	s1.add_child(_wrap(UIKit.label(tr("timba.scratch.desc"), 15, UIKit.C_DIM)))
	_pozo = UIKit.label("", 22, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_LEFT, true)
	s1.add_child(_pozo)
	var r1: HBoxContainer = HBoxContainer.new()
	r1.add_theme_constant_override("separation", 10)
	s1.add_child(r1)
	for i in range(GambleLogic.STAKE_PCTS.size()):
		var b: Button = Button.new()
		b.custom_minimum_size = Vector2(0, 54)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UIKit.style_button(b, UIKit.C_GREEN.darkened(0.2), 17)
		var pct: float = float(GambleLogic.STAKE_PCTS[i])
		b.pressed.connect(func() -> void: scratch_requested.emit(pct))
		r1.add_child(b)
		_scratch_btns.append(b)
	# ---- selector de apuesta (compartido por quiniela y dólar) ----
	var sel: VBoxContainer = _section(tr("timba.stake.title"))
	var r2: HBoxContainer = HBoxContainer.new()
	r2.add_theme_constant_override("separation", 8)
	sel.add_child(r2)
	for i in range(GambleLogic.STAKE_PCTS.size()):
		var sb: Button = Button.new()
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var idx: int = i
		sb.pressed.connect(func() -> void: _stake_idx = idx)
		r2.add_child(sb)
		_stake_btns.append(sb)
	# ---- quiniela ----
	_quiniela_box = _section(tr("timba.q.title"))
	_quiniela_box.add_child(_wrap(UIKit.label(tr("timba.q.desc"), 15, UIKit.C_DIM)))
	var qr: HBoxContainer = HBoxContainer.new()
	qr.add_theme_constant_override("separation", 10)
	_quiniela_box.add_child(qr)
	var minus: Button = Button.new()
	minus.text = "-"
	minus.custom_minimum_size = Vector2(54, 54)
	UIKit.style_button(minus, UIKit.C_PANEL2, 24)
	minus.pressed.connect(func() -> void: _q_number = posmod(_q_number - 1, 100))
	qr.add_child(minus)
	_q_label = UIKit.label("37", 44, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, true)
	_q_label.custom_minimum_size = Vector2(90, 0)
	qr.add_child(_q_label)
	var plus: Button = Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(54, 54)
	UIKit.style_button(plus, UIKit.C_PANEL2, 24)
	plus.pressed.connect(func() -> void: _q_number = posmod(_q_number + 1, 100))
	qr.add_child(plus)
	var minus10: Button = Button.new()
	minus10.text = "-10"
	UIKit.style_button(minus10, UIKit.C_PANEL2, 16)
	minus10.pressed.connect(func() -> void: _q_number = posmod(_q_number - 10, 100))
	qr.add_child(minus10)
	var plus10: Button = Button.new()
	plus10.text = "+10"
	UIKit.style_button(plus10, UIKit.C_PANEL2, 16)
	plus10.pressed.connect(func() -> void: _q_number = posmod(_q_number + 10, 100))
	qr.add_child(plus10)
	_q_play = Button.new()
	_q_play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_q_play.custom_minimum_size = Vector2(0, 54)
	UIKit.style_button(_q_play, UIKit.C_BLUE, 18)
	_q_play.pressed.connect(_on_quiniela)
	qr.add_child(_q_play)
	_q_ticket = UIKit.label("", 16, Chalk.GREEN)
	_quiniela_box.add_child(_q_ticket)
	_quiniela_lock = _wrap(UIKit.label("", 16, Chalk.PINK))
	_vbox.add_child(_quiniela_lock)
	# ---- timba del dólar ----
	_dollar_box = _section(tr("timba.d.title"))
	_dollar_box.add_child(_wrap(UIKit.label(tr("timba.d.desc"), 15, UIKit.C_DIM)))
	_d_info = UIKit.label("", 22, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_LEFT, true)
	_dollar_box.add_child(_d_info)
	_d_hint = _wrap(UIKit.label("", 15, Chalk.GREEN))
	_dollar_box.add_child(_d_hint)
	var dr: HBoxContainer = HBoxContainer.new()
	dr.add_theme_constant_override("separation", 10)
	_dollar_box.add_child(dr)
	_d_up = Button.new()
	_d_up.text = tr("timba.d.up")
	_d_up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_d_up.custom_minimum_size = Vector2(0, 54)
	UIKit.style_button(_d_up, UIKit.C_RED, 20)
	_d_up.pressed.connect(func() -> void: _on_dollar("up"))
	dr.add_child(_d_up)
	_d_down = Button.new()
	_d_down.text = tr("timba.d.down")
	_d_down.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_d_down.custom_minimum_size = Vector2(0, 54)
	UIKit.style_button(_d_down, UIKit.C_GREEN, 20)
	_d_down.pressed.connect(func() -> void: _on_dollar("down"))
	dr.add_child(_d_down)
	_d_ticket = UIKit.label("", 16, Chalk.GREEN)
	_dollar_box.add_child(_d_ticket)
	_dollar_lock = _wrap(UIKit.label("", 16, Chalk.PINK))
	_vbox.add_child(_dollar_lock)


func _wrap(l: Label) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _section(title: String) -> VBoxContainer:
	var p: PanelContainer = UIKit.panel(UIKit.C_PANEL2, 10)
	_vbox.add_child(p)
	var inner: VBoxContainer = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	p.add_child(inner)
	inner.add_child(UIKit.label(title, 22, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_LEFT, true))
	inner.set_meta("panel", p)
	return inner


func _stake(m: GameModel, max_stake: BigNumber) -> BigNumber:
	return GambleLogic.stake_for(m, float(GambleLogic.STAKE_PCTS[_stake_idx]), max_stake)


func _on_quiniela() -> void:
	var m: GameModel = GameState.m
	if Economy.place_quiniela(_q_number, float(GambleLogic.STAKE_PCTS[_stake_idx])):
		message.emit(tr("timba.q.placed") % [("%02d" % _q_number)])
	else:
		message.emit(tr("timba.nomoney"))


func _on_dollar(dir: String) -> void:
	if Economy.place_dollar(dir, float(GambleLogic.STAKE_PCTS[_stake_idx])):
		message.emit(tr("timba.d.placed"))
	else:
		message.emit(tr("timba.nomoney"))


func refresh(m: GameModel) -> void:
	var open: bool = Unlocks.has(m, "timba")
	_pozo.text = tr("timba.pozo_now") % UIKit.money(m.pool_real.mul(m.price_level))
	for i in range(_scratch_btns.size()):
		var price: BigNumber = GambleLogic.stake_for(m, float(GambleLogic.STAKE_PCTS[i]), GambleLogic.scratch_stake_max(m))
		var b: Button = _scratch_btns[i]
		b.text = tr("timba.scratch.btn") % ["%d %%" % int(round(float(GambleLogic.STAKE_PCTS[i]) * 100.0)), UIKit.money(price)]
		b.disabled = not open or price.is_zero()
		b.tooltip_text = tr("timba.scratch.tip") % [UIKit.money(price), UIKit.money(GambleLogic.cap(m))]
	for i in range(_stake_btns.size()):
		var sb: Button = _stake_btns[i]
		sb.text = "%d %%" % int(round(float(GambleLogic.STAKE_PCTS[i]) * 100.0))
		UIKit.style_button(sb, UIKit.C_BLUE if i == _stake_idx else UIKit.C_PANEL2, 16)
	# quiniela
	var q_open: bool = Unlocks.has(m, "quiniela")
	_quiniela_box.get_meta("panel").visible = q_open
	_quiniela_lock.visible = not q_open
	_quiniela_lock.text = (tr("timba.demo_locked") if m.demo_mode else tr("timba.q.locked"))
	var qstake: BigNumber = _stake(m, GambleLogic.quiniela_stake_max(m))
	_q_label.text = "%02d" % _q_number
	_q_play.text = tr("timba.q.play") % UIKit.money(qstake)
	_q_play.tooltip_text = tr("timba.q.tip") % [UIKit.money(GambleLogic.quiniela_stake_max(m).mul_f(GambleLogic.QUINIELA_EXACT * (1.0 - GambleLogic.QUINIELA_COMMISSION)))]
	if m.quiniela.is_empty():
		_q_ticket.text = ""
	else:
		_q_ticket.text = tr("timba.q.ticket_now") % [("%02d" % int(m.quiniela["number"])), UIKit.money(BigNumber.from_string(str(m.quiniela["stake"]))), int(ceil(EconomyLogic.B("month_seconds") - m.month_progress))]
	# dólar
	var d_open: bool = Unlocks.has(m, "dollar")
	_dollar_box.get_meta("panel").visible = d_open
	_dollar_lock.visible = not d_open
	_dollar_lock.text = (tr("timba.demo_locked") if m.demo_mode else tr("timba.d.locked"))
	_d_info.text = tr("timba.d.info") % BigNumber.from_float(GambleLogic.dollar_threshold(m) * 100.0).format(1)
	var hint: Dictionary = GambleLogic.dollar_hint(m)
	if hint.is_empty():
		_d_hint.text = tr("timba.d.hint_none")
	else:
		var ename: String = tr("ev." + str(hint["event"]))
		_d_hint.text = (tr("timba.d.hint_ends") if bool(hint["ends_before_close"]) else tr("timba.d.hint_stays")) % [ename, int(ceil(float(hint["left"])))]
	var dstake: BigNumber = _stake(m, GambleLogic.dollar_stake_max(m))
	_d_up.text = tr("timba.d.up") + " (" + UIKit.money(dstake) + ")"
	_d_down.text = tr("timba.d.down") + " (" + UIKit.money(dstake) + ")"
	if m.dollar_bet.is_empty():
		_d_ticket.text = ""
	else:
		_d_ticket.text = tr("timba.d.ticket_now") % [tr("timba.d.up") if str(m.dollar_bet["dir"]) == "up" else tr("timba.d.down"), BigNumber.from_float(float(m.dollar_bet["threshold"]) * 100.0).format(1), UIKit.money(BigNumber.from_string(str(m.dollar_bet["stake"])))]
