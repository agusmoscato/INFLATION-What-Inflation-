class_name AchievementTracker
extends RefCounted
## Evalúa las condiciones de data/achievements.json contra las estadísticas del modelo.


static func _holds(stats: Dictionary, cond: Array) -> bool:
	for c in cond:
		var v: float = float(stats.get(c[0], 0.0))
		var t: float = float(c[2])
		match str(c[1]):
			">=":
				if not v >= t:
					return false
			"<":
				if not v < t:
					return false
			">":
				if not v > t:
					return false
			"<=":
				if not v <= t:
					return false
	return true


## Devuelve los ids recién desbloqueados.
static func check(m: GameModel, provider: Achievements) -> Array:
	var stats: Dictionary = EconomyLogic.stats(m)
	var fresh: Array = []
	for a in GameData.achievements:
		if provider.is_unlocked(a["id"]):
			continue
		if _holds(stats, a["cond"]) and provider.unlock(a["id"]):
			fresh.append(a["id"])
	return fresh
