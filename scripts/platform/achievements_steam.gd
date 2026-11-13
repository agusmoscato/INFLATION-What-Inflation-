class_name SteamAchievements
extends Achievements
## TODO(steam): esqueleto para GodotSteam. No instalado; esta clase delega en LocalAchievements
## para que el juego siga funcionando sin Steam y para espejar el progreso en el save.
##
## Pasos cuando se instale GodotSteam (https://godotsteam.com):
##  1. Steam.steamInitEx(APP_ID) en un autoload al inicio.
##  2. En unlock(): llamar Steam.setAchievement(id) y Steam.storeStats().
##  3. En is_unlocked(): Steam.getAchievement(id)["achieved"].
##  4. Crear en Steamworks un logro por cada id de data/achievements.json.

var _local: LocalAchievements


func _init(store: Dictionary) -> void:
	_local = LocalAchievements.new(store)


func unlock(id: String) -> bool:
	var is_new: bool = _local.unlock(id)
	# if is_new and Engine.has_singleton("Steam"):
	#	Engine.get_singleton("Steam").setAchievement(id)
	#	Engine.get_singleton("Steam").storeStats()
	return is_new


func is_unlocked(id: String) -> bool:
	return _local.is_unlocked(id)


func unlocked_ids() -> Array:
	return _local.unlocked_ids()
