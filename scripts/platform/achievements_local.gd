class_name LocalAchievements
extends Achievements
## Logros guardados dentro del save (Dictionary id -> true compartido con GameModel.achievements).

var _store: Dictionary


func _init(store: Dictionary) -> void:
	_store = store


func unlock(id: String) -> bool:
	if _store.has(id):
		return false
	_store[id] = true
	return true


func is_unlocked(id: String) -> bool:
	return _store.has(id)


func unlocked_ids() -> Array:
	return _store.keys()
