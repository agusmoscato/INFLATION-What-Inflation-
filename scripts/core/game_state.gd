extends Node
## Autoload: dueño del estado de la partida actual.

var m: GameModel = GameModel.new()
var achievements: Achievements


func _init() -> void:
	m.demo_mode = DemoMode.is_demo()
	m.intro_grace = true
	achievements = LocalAchievements.new(m.achievements)


func new_game() -> void:
	m = GameModel.new()
	m.demo_mode = DemoMode.is_demo()
	m.intro_grace = true      # sin inflación hasta el cartel "¡La inflación!"
	achievements = LocalAchievements.new(m.achievements)


## Reemplaza el modelo (tras cargar) y rehace el proveedor de logros.
func adopt(model: GameModel) -> void:
	m = model
	m.demo_mode = DemoMode.is_demo()
	# TODO(steam): si Engine.has_singleton("Steam") usar SteamAchievements.new(m.achievements)
	achievements = LocalAchievements.new(m.achievements)
