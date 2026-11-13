class_name DemoMode
extends RefCounted
## Modo demo: limita el juego a la Era 1, la Era 2 y la primera reforma.
## Se activa con el feature tag "demo" (presets "Windows Demo" y "Web Demo") o con el argumento --demo.
## El progreso de la demo NO se transfiere al juego completo (usa otro archivo de guardado).

## URL de la página de Steam para la wishlist. Vacía hasta tener el AppID.
const STEAM_URL: String = ""
const MAX_ERA: int = 2
const SAVE_PATH: String = "user://save_demo.json"


static func is_demo() -> bool:
	return OS.has_feature("demo") or OS.get_cmdline_user_args().has("--demo")
