extends Node
## Autoload: avanza la economía cada frame y traduce las notificaciones del modelo a señales del EventBus.

var running: bool = false        ## true mientras se juega (no en menú)
var time_scale: float = 1.0
var _ach_timer: float = 0.0


func _process(delta: float) -> void:
	if not running:
		return
	var m: GameModel = GameState.m
	EconomyLogic.tick(m, minf(delta, 2.0) * time_scale)
	_ach_timer += delta
	if _ach_timer >= 1.0:
		_ach_timer = 0.0
		check_achievements()
	flush()


func check_achievements() -> void:
	for id in AchievementTracker.check(GameState.m, GameState.achievements):
		EventBus.achievement_unlocked.emit(id)


func flush() -> void:
	var m: GameModel = GameState.m
	if m.notifications.is_empty():
		return
	var queue: Array = m.notifications
	m.notifications = []
	for n in queue:
		var a: Array = n["args"]
		match str(n["sig"]):
			"business_bought": EventBus.business_bought.emit(a[0], a[1])
			"milestone": EventBus.milestone.emit(a[0], a[1])
			"upgrade_bought": EventBus.upgrade_bought.emit(a[0])
			"node_bought": EventBus.node_bought.emit(a[0])
			"remarked": EventBus.remarked.emit(a[0], a[1])
			"bill_spawn": EventBus.bill_spawn.emit(a[0])
			"bill_missed": EventBus.bill_missed.emit(a[0])
			"bill_prize": EventBus.bill_prize.emit(a[0])
			"event_choice": EventBus.event_choice.emit(a[0])
			"event_choice_done": EventBus.event_choice_done.emit(a[0], a[1])
			"event_ended": EventBus.event_ended.emit(a[0])
			"unlock": EventBus.unlock.emit(a[0])
			"collapse": EventBus.collapse.emit()
			"page_done": EventBus.page_done.emit(a[0])
			"pack_opened": EventBus.pack_opened.emit()
			"sticker_won": EventBus.sticker_won.emit(a[0])
			"secret_end": EventBus.secret_end.emit()
			"scratched": EventBus.scratched.emit(a[0])
			"reform_done": EventBus.reform_done.emit(a[0])
			"victory": EventBus.victory.emit()
			"demo_end": EventBus.demo_end.emit()
			"toast": EventBus.toast.emit(a[0])


# ---- acciones del jugador (envuelven la lógica y emiten señales) ----
func click() -> Dictionary:
	var r: Dictionary = EconomyLogic.do_click(GameState.m, true)
	EventBus.clicked.emit(r)
	flush()
	return r


func buy_business(id: String, qty: int) -> int:
	var n: int = EconomyLogic.buy_business(GameState.m, id, qty)
	flush()
	return n


func buy_upgrade(id: String) -> bool:
	var ok: bool = EconomyLogic.buy_upgrade(GameState.m, id)
	flush()
	return ok


func buy_node(id: String) -> bool:
	var ok: bool = TreeLogic.buy(GameState.m, id)
	flush()
	return ok


func remark() -> bool:
	var ok: bool = EconomyLogic.remark(GameState.m, true)
	flush()
	return ok


func click_bill(bill_id: int) -> Dictionary:
	var r: Dictionary = EconomyLogic.click_bill(GameState.m, bill_id)
	flush()
	return r


func choose_event(idx: int) -> bool:
	var ok: bool = EconomyLogic.choose(GameState.m, idx)
	flush()
	return ok


func reform() -> Dictionary:
	var s: Dictionary = EconomyLogic.do_reform(GameState.m)
	flush()
	return s


# ---- figuritas ----
## Compra y abre un sobre. Devuelve las figuritas ([] si no alcanza la plata).
func buy_pack() -> Array:
	var res: Array = StickerLogic.buy_pack(GameState.m)
	flush()
	return res


## Abre uno de los sobres de regalo pendientes (reformas, desbloqueo del álbum).
func open_free_pack() -> Array:
	var m: GameModel = GameState.m
	if m.free_packs_pending <= 0:
		return []
	m.free_packs_pending -= 1
	var res: Array = StickerLogic.gift_pack(m)
	flush()
	return res


func trade_sticker(id: String) -> bool:
	var ok: bool = StickerLogic.trade(GameState.m, id)
	flush()
	return ok


# ---- raspadita ----
func play_scratch(force: String = "") -> Dictionary:
	var res: Dictionary = GambleLogic.play_scratch(GameState.m, false, force)
	flush()
	return res
