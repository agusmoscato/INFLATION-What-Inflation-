extends Node
## Autoload: guardado en user://, autosave cada 30 s y progreso offline al cargar.

const SAVE_PATH: String = "user://save.json"

var _timer: float = 0.0


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)


func _process(delta: float) -> void:
	if not Economy.running:
		return
	_timer += delta
	if _timer >= float(GameData.balance["autosave_seconds"]):
		_timer = 0.0
		save_game()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	return SaveIO.save_model(GameState.m, SAVE_PATH)


## Carga la partida y simula el tiempo offline. Devuelve false si no hay save.
func load_game() -> bool:
	var model: GameModel = GameModel.new()
	var report: Dictionary = SaveIO.load_into(model, SAVE_PATH, Time.get_unix_time_from_system())
	if report.is_empty():
		return false
	GameState.adopt(model)
	EventBus.game_loaded.emit()
	if float(report.get("seconds", 0.0)) > 0.0:
		EventBus.offline_report.emit(report)
	return true


func delete_save() -> void:
	SaveIO.remove(SAVE_PATH)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if Economy.running:
			save_game()
		get_tree().quit()
