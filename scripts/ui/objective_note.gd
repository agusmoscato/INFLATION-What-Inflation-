class_name ObjectiveNote
extends PanelContainer
## Notita de tiza fija con el próximo objetivo y su progreso.

var _title: Label
var _text: Label
var _bar: ChalkBar
var _last_id: String = ""
var _micro: Label
var _micro_t: float = 99.0
var _micro_text: String = ""


func _init() -> void:
	add_theme_stylebox_override("panel", UIKit.chalk_box(Chalk.YELLOW, Color(0, 0, 0, 0.2), 2.6))
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	add_child(v)
	_title = UIKit.label(tr("ui.obj.title"), 14, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_LEFT, true)
	v.add_child(_title)
	_text = UIKit.label("", 16, Chalk.WHITE)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(250, 0)
	v.add_child(_text)
	_bar = ChalkBar.new()
	_bar.fill_color = Chalk.YELLOW
	_bar.custom_minimum_size = Vector2(0, 12)
	v.add_child(_bar)
	_micro = UIKit.label("", 14, Chalk.GREEN)
	_micro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_micro.custom_minimum_size = Vector2(250, 0)
	_micro.visible = false
	v.add_child(_micro)


func refresh(m: GameModel) -> void:
	var cur: Dictionary = ObjectiveLogic.current(m)
	if cur["done"]:
		_text.text = tr("ui.obj.end")
		_bar.value = 1.0
		return
	var id: String = str(cur["id"])
	_update_micro(m, ObjectiveLogic.LIST[m.obj_index])
	_text.text = tr("obj." + id) % [cur["cur_s"], cur["tgt_s"]]
	_bar.max_value = 1.0
	_bar.value = float(cur["frac"])
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
