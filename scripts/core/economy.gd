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
		for id in AchievementTracker.check(m, GameState.achievements):
			EventBus.achievement_unlocked.emit(id)
	flush()


func flush() -> void:
	var m: GameModel = GameState.m
	if m.notifications.is_empty():
		return
	var queue: Array = m.notifications
	m.notifications = []
	for n in queue:
		var sig: String = n["sig"]
		match sig:
			"business_bought": EventBus.business_bought.emit(n["args"][0], n["args"][1])
			"upgrade_bought": EventBus.upgrade_bought.emit(n["args"][0])
			"month_passed": EventBus.month_passed.emit(n["args"][0])
			"remarked": EventBus.remarked.emit(n["args"][0], n["args"][1])
			"era_changed": EventBus.era_changed.emit(n["args"][0])
			"event_started":
				EventBus.event_started.emit(n["args"][0])
				EventBus.headline.emit(GameData.events[GameData.event_idx[n["args"][0]]]["headline_key"])
			"event_ended": EventBus.event_ended.emit(n["args"][0])
			"refuge_changed": EventBus.refuge_changed.emit()
			"reform_done": EventBus.reform_done.emit(n["args"][0], n["args"][1])
			"plan_done": EventBus.plan_done.emit(n["args"][0])
			"victory": EventBus.victory.emit()
			"toast": EventBus.toast.emit(n["args"][0])


# ---- acciones del jugador (envuelven la lógica y emiten señales) ----
func click() -> BigNumber:
	var v: BigNumber = EconomyLogic.do_click(GameState.m)
	EventBus.clicked.emit(v)
	return v


func buy_business(id: String, qty: int) -> int:
	var n: int = EconomyLogic.buy_business(GameState.m, id, qty)
	flush()
	return n


func buy_upgrade(id: String) -> bool:
	var ok: bool = EconomyLogic.buy_upgrade(GameState.m, id)
	flush()
	return ok


func remark() -> void:
	EconomyLogic.remark(GameState.m, true)
	flush()


func refuge_buy(id: String, fraction_of_money: float) -> bool:
	var m: GameModel = GameState.m
	var ok: bool = EconomyLogic.refuge_buy(m, id, m.money.mul_f(fraction_of_money))
	flush()
	return ok


func refuge_sell(id: String) -> bool:
	var ok: bool = EconomyLogic.refuge_sell(GameState.m, id, 1.0)
	flush()
	return ok


func settle_strike() -> bool:
	var ok: bool = EconomyLogic.settle_strike(GameState.m)
	flush()
	return ok


func buy_measure() -> bool:
	var ok: bool = EconomyLogic.buy_measure(GameState.m)
	flush()
	return ok


func reform() -> bool:
	var ok: bool = EconomyLogic.do_reform(GameState.m)
	flush()
	return ok


func plan(id: String) -> bool:
	var ok: bool = EconomyLogic.do_plan(GameState.m, id)
	flush()
	return ok
