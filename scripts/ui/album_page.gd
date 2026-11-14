class_name AlbumPage
extends ScrollContainer
## Álbum (se desbloquea en el árbol): 6 páginas de 10 figuritas, sobres (comprados y de regalo) y repetidas (chupi).

signal pack_bought(results: Array)
signal message(text: String)

var _vbox: VBoxContainer
var _stats: Label
var _buy_btn: Button
var _chupi_btn: Button
var _free_btn: Button
var _hint: Label
var _page_btns: Array = []
var _bonus: Label
var _grid: GridContainer
var _gamble: Label
var _page: int = 0
var _chupi_mode: bool = false
var _sig: String = ""


func _init() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 8)
	add_child(_vbox)
	_stats = UIKit.label("", 18, Chalk.WHITE)
	_vbox.add_child(_stats)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_vbox.add_child(row)
	_buy_btn = Button.new()
	_buy_btn.custom_minimum_size = Vector2(250, 48)
	UIKit.style_button(_buy_btn, UIKit.C_GREEN.darkened(0.2), 18)
	_buy_btn.pressed.connect(_on_buy)
	row.add_child(_buy_btn)
	_chupi_btn = Button.new()
	_chupi_btn.text = tr("ui.chupi.btn")
	_chupi_btn.custom_minimum_size = Vector2(300, 48)
	UIKit.style_button(_chupi_btn, UIKit.C_BLUE, 17)
	_chupi_btn.pressed.connect(_on_chupi)
	row.add_child(_chupi_btn)
	_free_btn = Button.new()
	_free_btn.custom_minimum_size = Vector2(220, 48)
	UIKit.style_button(_free_btn, UIKit.C_GOLD, 17)
	_free_btn.pressed.connect(_on_free)
	row.add_child(_free_btn)
	_hint = UIKit.label("", 15, Chalk.PINK)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vbox.add_child(_hint)
	var pr: HBoxContainer = HBoxContainer.new()
	pr.add_theme_constant_override("separation", 6)
	_vbox.add_child(pr)
	for p in range(GameData.sticker_pages.size()):
		var b: Button = Button.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UIKit.style_button(b, UIKit.C_PANEL2, 14)
		b.pressed.connect(func() -> void:
			_page = p
			_sig = "")
		pr.add_child(b)
		_page_btns.append(b)
	_bonus = UIKit.label("", 16, Chalk.YELLOW)
	_vbox.add_child(_bonus)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	_vbox.add_child(_grid)
	_gamble = UIKit.label("", 15, UIKit.C_DIM)
	_gamble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vbox.add_child(_gamble)


func _on_buy() -> void:
	var res: Array = Economy.buy_pack()
	if res.is_empty():
		message.emit(tr("ui.pack.nomoney"))
		return
	_sig = ""
	pack_bought.emit(res)


func _on_free() -> void:
	var res: Array = Economy.open_free_pack()
	if res.is_empty():
		return
	_sig = ""
	pack_bought.emit(res)


func _on_chupi() -> void:
	var m: GameModel = GameState.m
	var tc: int = StickerLogic.trade_cost(m, "biz_empanadas")
	if not _chupi_mode and StickerLogic.repes(m) < tc:
		message.emit(tr("ui.chupi.need") % [tc, StickerLogic.repes(m)])
		return
	_chupi_mode = not _chupi_mode
	_sig = ""


func _on_sticker_input(event: InputEvent, id: String) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var m: GameModel = GameState.m
	if not _chupi_mode or StickerLogic.owned(m, id) > 0:
		return
	var cost: int = StickerLogic.trade_cost(m, id)
	if StickerLogic.repes(m) < cost:
		message.emit(tr("ui.chupi.need") % [cost, StickerLogic.repes(m)])
		return
	if Economy.trade_sticker(id):
		message.emit(tr("ui.chupi.done") % tr(StickerLogic.def(id)["name_key"]))
		_chupi_mode = false
		_sig = ""


func refresh(m: GameModel) -> void:
	var have: int = StickerLogic.unique(m)
	var rp: int = StickerLogic.repes(m)
	_stats.text = "%s    %s    %s" % [tr("ui.album.have") % [have, StickerLogic.total()], tr("ui.album.missing") % (StickerLogic.total() - have), tr("ui.album.repes") % rp]
	var cost: BigNumber = StickerLogic.pack_cost(m)
	_buy_btn.text = tr("ui.pack.buy") % UIKit.money(cost)
	_buy_btn.disabled = cost.gt(m.money)
	_buy_btn.tooltip_text = tr("ui.pack.tip") % UIKit.money(cost)
	var tc: int = StickerLogic.trade_cost(m, "biz_empanadas")
	_chupi_btn.disabled = rp < tc and not _chupi_mode
	_chupi_btn.tooltip_text = tr("ui.chupi.btn")
	_free_btn.text = tr("ui.pack.free") % m.free_packs_pending
	_free_btn.visible = m.free_packs_pending > 0
	_hint.text = (tr("ui.chupi.on") % tc) if _chupi_mode else ""
	for p in range(_page_btns.size()):
		var b: Button = _page_btns[p]
		var n: int = StickerLogic.page_count(m, p)
		var done: bool = StickerLogic.page_complete(m, p)
		b.text = "%s %d/10%s" % [tr("page." + str(GameData.sticker_pages[p]["id"])), n, (" OK" if done else "")]
		UIKit.style_button(b, UIKit.C_BLUE if p == _page else (UIKit.C_GOLD if done else UIKit.C_PANEL2), 14)
	var pid: String = str(GameData.sticker_pages[_page]["id"])
	_bonus.text = tr("pageb." + pid)
	_bonus.add_theme_color_override("font_color", Chalk.GREEN if StickerLogic.page_complete(m, _page) else UIKit.C_DIM)
	var sig: String = "%d|%s|" % [_page, str(_chupi_mode)]
	for id in StickerLogic.page_ids(_page):
		sig += str(StickerLogic.owned(m, id)) + ","
	if sig != _sig:
		_sig = sig
		_rebuild_grid(m)
	_gamble.text = tr("ui.album.howto")


func _rebuild_grid(m: GameModel) -> void:
	UIKit.clear_children(_grid)
	for id in StickerLogic.page_ids(_page):
		var n: int = StickerLogic.owned(m, id)
		var v: StickerView = StickerView.new(id, n)
		v.highlight = _chupi_mode and n == 0
		if n > 0:
			v.tooltip_text = tr(StickerLogic.def(id)["name_key"]) + " - " + tr(StickerLogic.def(id)["joke_key"])
		else:
			v.tooltip_text = "???"
		v.gui_input.connect(_on_sticker_input.bind(id))
		_grid.add_child(v)
