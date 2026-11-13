class_name Achievements
extends RefCounted
## Interfaz de logros. Implementaciones:
##  - LocalAchievements (achievements_local.gd): guarda los logros en el save. Es la que se usa hoy.
##  - SteamAchievements (achievements_steam.gd): esqueleto para GodotSteam (no instalado).
##
## Para conectar Steam: instalar GodotSteam, descomentar achievements_steam.gd y elegirlo en
## Economy._create_achievements() cuando Engine.has_singleton("Steam") sea true.
## Los ids de logro coinciden con los API names de Steamworks (ej. "first_sale").


## Desbloquea un logro. Devuelve true si es nuevo.
func unlock(_id: String) -> bool:
	return false


func is_unlocked(_id: String) -> bool:
	return false


func unlocked_ids() -> Array:
	return []


## Hook opcional para logros con barra de progreso (Steam: setStatInt + storeStats).
func report_progress(_id: String, _current: float, _target: float) -> void:
	pass
