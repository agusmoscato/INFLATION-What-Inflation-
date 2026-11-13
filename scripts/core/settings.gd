class_name Settings
extends RefCounted
## Opciones del jugador (volumen, idioma, notación). Se guardan en user://settings.cfg.

static var path: String = "user://settings.cfg"

static var volume: float = 0.8
static var music: float = 0.35
static var language: String = ""
static var notation: int = 0
static var fullscreen: bool = false
static var tutorial_done: bool = false
## Calidad de tiza: 0 = Alta, 1 = Media, 2 = Baja (baja el efecto de shader, las partículas y los manchones).
static var quality: int = 0


static func load_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var ok: bool = cfg.load(path) == OK
	volume = float(cfg.get_value("audio", "volume", 0.8)) if ok else 0.8
	music = float(cfg.get_value("audio", "music", 0.35)) if ok else 0.35
	notation = int(cfg.get_value("game", "notation", 0)) if ok else 0
	fullscreen = bool(cfg.get_value("display", "fullscreen", false)) if ok else false
	tutorial_done = bool(cfg.get_value("game", "tutorial_done", false)) if ok else false
	quality = clampi(int(cfg.get_value("display", "quality", 0)), 0, 2) if ok else 0
	language = str(cfg.get_value("game", "language", "")) if ok else ""
	if language == "":
		language = "es" if OS.get_locale_language() == "es" else "en"


static func save_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("audio", "volume", volume)
	cfg.set_value("audio", "music", music)
	cfg.set_value("game", "notation", notation)
	cfg.set_value("game", "language", language)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("game", "tutorial_done", tutorial_done)
	cfg.set_value("display", "quality", quality)
	cfg.save(path)


static func apply() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	I18n.set_language(language)
	BigNumber.notation = notation
	BigNumber.decimal_comma = language == "es"
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_title(UIKit.GAME_NAME)
	if ChalkBoard.instance != null:
		ChalkBoard.instance.apply_quality()
	if ChalkPost.instance != null:
		ChalkPost.instance.apply_quality()
	if SoundFx.instance != null:
		SoundFx.instance.apply_music_volume()


# ---- calidad de tiza ----
## Multiplicador de la cantidad de partículas.
static func fx_scale() -> float:
	return [1.0, 0.55, 0.25][clampi(quality, 0, 2)]


## Intensidad máxima del efecto tiza de pantalla completa (0 = apagado).
static func post_strength() -> float:
	return [1.0, 0.6, 0.0][clampi(quality, 0, 2)]


## Cantidad máxima de manchones de precios viejos por precio.
static func ghost_cap() -> int:
	return [6, 3, 1][clampi(quality, 0, 2)]


static func particles(base: int) -> int:
	return maxi(1, int(round(float(base) * fx_scale())))
