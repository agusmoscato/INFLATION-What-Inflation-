class_name ObjectiveNote
extends PanelContainer
## Notita de tiza fija con el objetivo escrito como ORDEN concreta, lo que falta ("Te falta $X" / "¡YA PODÉS!") y un botón
## [IR] que lleva directo a donde hay que tocar. Si ya alcanza, la nota se pone verde.

signal go_pressed(go: Dictionary)

var _title: Label
var _text: Label
var _status: Label
var _bar: ChalkBar
var _go_btn: Button
var _last_id: String = ""
var _micro: Label
var _micro_t: float = 99.0
var _go: Dictionary = {}
var _ready_state: bool = false


func _init() -> void:
	add_theme_stylebox_override("panel", UIKit.chalk_box(Chalk.YELLOW, Color(0, 0, 0, 0.2), 2.6))
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	add_child(v)
	_title = UIKit.label(tr("ui.obj.title"), 15, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_LEFT, true)
	v.add_child(_title)
	_text = UIKit.label("", 18, Chalk.WHITE)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(250, 0)
	v.add_child(_text)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	_status = UIKit.label("", 20, Chalk.WHITE, HORIZONTAL_ALIGNMENT_LEFT, true)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(_status)
	_go_btn = Button.new()
	_go_btn.text = tr("ui.obj.go")
	_go_btn.custom_minimum_size = Vector2(76, 44)
	UIKit.style_button(_go_btn, UIKit.C_GREEN.darkened(0.2), 20)
	_go_btn.pressed.connect(func() -> void: go_pressed.emit(_go))
	row.add_child(_go_btn)
	_bar = ChalkBar.new()
	_bar.fill_color = Chalk.YELLOW
	_bar.custom_minimum_size = Vector2(0, 12)
	v.add_child(_bar)
	_micro = UIKit.label("", 15, Chalk.GREEN)
	_micro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_micro.custom_minimum_size = Vector2(250, 0)
	_micro.visible = false
	v.add_child(_micro)


## El texto del objetivo sin el contador "…: %s/%s" del final (ahora el estado va en su propia línea).
static func order_text(id: String) -> String:
	return str(TranslationServer.translate("obj." + id)).replace(": %s/%s", "")


func refresh(m: GameModel) -> void:
	var cur: Dictionary = ObjectiveLogic.current(m)
	if cur["done"]:
		_text.text = tr("ui.obj.end")
		_status.text = ""
		_go_btn.visible = false
		_bar.value = 1.0
		return
	var o: Dictionary = ObjectiveLogic.LIST[m.obj_index]
	var id: String = str(cur["id"])
	_update_micro(m, o)
	_text.text = order_text(id)
	_bar.max_value = 1.0
	_bar.value = float(cur["frac"])
	var st: Dictionary = ObjectiveLogic.status(m, o)
	_go = st["go"]
	_go_btn.visible = not _go.is_empty()
	var ready_now: bool = bool(st["ready"]) and str(st["need"]) != "wait"
	if ready_now:
		_status.text = tr("ui.obj.ready")
		_status.add_theme_color_override("font_color", Chalk.GREEN)
	else:
		_status.add_theme_color_override("font_color", Chalk.WHITE)
		match str(st["need"]):
			"money":
				_status.text = tr("ui.obj.missing_money") % ("$" + (st["money"] as BigNumber).format())
			"count":
				_status.text = tr("ui.obj.missing_n") % str(int(st["n"]))
			_:
				_status.text = tr("ui.obj.wait")
	if ready_now != _ready_state:
		_ready_state = ready_now
		var col: Color = Chalk.GREEN if ready_now else Chalk.YELLOW
		add_theme_stylebox_override("panel", UIKit.chalk_box(col, Color(col, 0.12) if ready_now else Color(0, 0, 0, 0.2), 3.0 if ready_now else 2.6))
		_title.add_theme_color_override("font_color", col)
		if ready_now:
			Chalk.pop(self, 1.06, 0.4)
	if id != _last_id:
		if _last_id != "":
			Chalk.pop(self, 1.08, 0.5)
		_last_id = id


func _process(delta: float) -> void:
	_micro_t += delta


## Si el objetivo tarda más de 60 s, muestra una "meta chica" alcanzable ya (se recalcula cada medio segundo).
func _update_micro(m: GameModel, o: Dictionary) -> void:
	if _micro_t < 0.5:
		return
	_micro_t = 0.0
	if ObjectiveLogic.eta(m, o) <= 60.0:
		_micro.visible = false
		return
	var mi: Dictionary = ObjectiveLogic.micro(m)
	if mi.is_empty():
		_micro.visible = false
		return
	var name: String = ""
	if mi["kind"] == "biz":
		name = tr(GameData.businesses[GameData.business_idx[mi["id"]]]["name_key"])
	else:
		name = GameData.upgrade_title(GameData.upgrades[GameData.upgrade_idx[mi["id"]]])
	_micro.text = tr("obj.micro") % [name, "$" + (mi["cost"] as BigNumber).format(), str(int(ceil(float(mi["eta"]))))]
	_micro.visible = true
