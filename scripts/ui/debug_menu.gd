class_name DebugMenu
extends PanelContainer
## Menú de prueba (para el desarrollador, no para los jugadores): se abre con F10 y SOLO si existe un archivo "debug.txt"
## al lado del ejecutable (en el editor, en la carpeta del proyecto). Sumar Credibilidad, plata x10, saltar 5 minutos y
## desbloquear todo, para probar el final sin jugar una hora.

signal changed


## ¿Está habilitado? (existe debug.txt al lado del ejecutable o, corriendo desde el editor, en la carpeta del proyecto)
static func enabled() -> bool:
	var dirs: Array = [OS.get_executable_path().get_base_dir()]
	if OS.has_feature("editor") or not OS.has_feature("template"):
		dirs.append(ProjectSettings.globalize_path("res://"))
	for d in dirs:
		if FileAccess.file_exists(str(d).path_join("debug.txt")):
			return true
	return false


func _init() -> void:
	add_theme_stylebox_override("panel", UIKit.chalk_box(Chalk.PINK, Color(0.08, 0.04, 0.07, 0.96), 2.6))
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_meta("qa_ignore", true)
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -170.0
	offset_right = 170.0
	offset_top = 90.0


func _ready() -> void:
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	v.add_child(UIKit.label("DEBUG (F10)", 20, Chalk.PINK, HORIZONTAL_ALIGNMENT_CENTER, true))
	for item in [["+100 de Credibilidad", func() -> void: add_cred(100)], ["+1.000 de Credibilidad", func() -> void: add_cred(1000)],
			["Plata x10", money_x10], ["Saltar 5 minutos", func() -> void: skip(300.0)], ["Desbloquear todo", unlock_all],
			["Cerrar", queue_free]]:
		var b: Button = Button.new()
		b.text = str(item[0])
		b.custom_minimum_size = Vector2(300, 40)
		UIKit.style_button(b, UIKit.C_PANEL2, 16)
		b.pressed.connect(item[1])
		v.add_child(b)


static func add_cred(n: int) -> void:
	GameState.m.credibility += n
	GameState.m.cred_total += n


static func money_x10() -> void:
	var m: GameModel = GameState.m
	var extra: BigNumber = m.money.mul_f(9.0) if not m.money.is_zero() else BigNumber.from_float(1000.0)
	EconomyLogic.earn(m, extra)


## Avanza la economía 5 minutos (producción, inflación, eventos), de a 1 segundo.
static func skip(seconds: float) -> void:
	var m: GameModel = GameState.m
	var t: float = 0.0
	while t < seconds:
		EconomyLogic.tick(m, 1.0)
		t += 1.0
	m.notifications.clear()


## Todo el árbol menos el centro (así se puede probar comprar el final).
static func unlock_all() -> void:
	var m: GameModel = GameState.m
	for n in GameData.tree:
		if not bool(n["final"]):
			m.tree[n["id"]] = true
	m.dirty = true
