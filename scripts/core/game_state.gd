extends Node
## Autoload: dueño del estado de la partida actual.

var m: GameModel = GameModel.new()
var achievements: Achievements


func _init() -> void:
	achievements = LocalAchievements.new(m.achievements)


func new_game() -> void:
	m = GameModel.new()
	achievements = LocalAchievements.new(m.achievements)


## Reemplaza el modelo (tras cargar) y rehace el proveedor de logros.
func adopt(model: GameModel) -> void:
	m = model
	# TODO(steam): si Engine.has_singleton("Steam") usar SteamAchievements.new(m.achievements)
	achievements = LocalAchievements.new(m.achievements)
