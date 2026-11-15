extends Control
## Prueba del menú de pausa (headless): godot --headless res://tests/PauseUI.tscn
## Abre la pausa con Esc y comprueba que guarda la partida y que mientras está abierta se frena TODO: plata, producción,
## inflación, tiempo de la vuelta, billetes voladores, noticias y avisos. Después la cierra con Esc y el juego sigue.
## Este nodo corre siempre (process_mode ALWAYS) para poder medir mientras el resto está en pausa.

var failures: Array = []


func _ready() -> void:
	SaveSystem.save_path = "user://test_pause_save.json"
	Settings.path = "user://test_pause_settings.cfg"
	SaveSystem.delete_save()
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	main.process_mode = Node.PROCESS_MODE_PAUSABLE      # como en el juego real (cuelga de la raíz, que se pausa)
	add_child(main)
	await _frames(3)
	main.start_game(false)
	await _frames(5)
	var g: GameScreen = main._game
	var m: GameModel = GameState.m
	m.tutorial_done = true
	m.owned = {"empanadas": 30, "kiosco": 10}
	m.dirty = true
	m.run_earned = BigNumber.from_float(5e5)
	Unlocks.unlock_all(m)
	m.bill_timer = 0.0
	EconomyLogic.start_event(m, "feriado")
	g._toast("aviso de prueba", Chalk.YELLOW)
	await _frames(20)
	if m.bills_active.is_empty():
		failures.append("no apareció el billete volador de prueba")
	# Esc abre la pausa
	_esc()
	await _frames(3)
	if not g.is_paused() or not get_tree().paused:
		failures.append("Esc no abrió la pausa")
	if not FileAccess.file_exists(SaveSystem.save_path):
		failures.append("la pausa no guardó la partida")
	var before: Dictionary = _snapshot(g, m)
	await get_tree().create_timer(1.5).timeout       # 1,5 s reales con el juego en pausa
	var after: Dictionary = _snapshot(g, m)
	for k in before:
		if str(before[k]) != str(after[k]):
			failures.append("en pausa cambió %s: %s -> %s" % [k, str(before[k]), str(after[k])])
	# Esc la cierra y el juego sigue
	_esc()
	await _frames(3)
	if g.is_paused() or get_tree().paused:
		failures.append("Esc no cerró la pausa")
	await get_tree().create_timer(0.6).timeout
	if m.run_time <= float(after["tiempo de la vuelta"]):
		failures.append("al continuar el juego no siguió")
	# menú de prueba (F10): solo con debug.txt
	var dbg_path: String = ProjectSettings.globalize_path("res://").path_join("debug.txt")
	var had_dbg: bool = FileAccess.file_exists(dbg_path)
	if not had_dbg and DebugMenu.enabled():
		failures.append("el menú de prueba está habilitado sin debug.txt")
	var fdbg: FileAccess = FileAccess.open(dbg_path, FileAccess.WRITE)
	fdbg.store_string("test")
	fdbg.close()
	if not DebugMenu.enabled():
		failures.append("con debug.txt el menú de prueba no se habilita")
	var c0: int = m.credibility
	DebugMenu.add_cred(1000)
	var money0: BigNumber = m.money
	DebugMenu.money_x10()
	var t0: float = m.run_time
	DebugMenu.skip(300.0)
	if m.credibility != c0 + 1000 or m.money.lt(money0.mul_f(9.9)) or m.run_time < t0 + 299.0:
		failures.append("el menú de prueba no suma Credibilidad, plata o tiempo como debe")
	m.tree = {}
	DebugMenu.unlock_all()
	if m.tree.has("final") or m.tree.size() != TreeLogic.total() - 1:
		failures.append("desbloquear todo tiene que comprar todo el árbol menos el centro")
	_esc_f10()
	await _frames(2)
	if g._debug == null:
		failures.append("F10 no abrió el menú de prueba")
	if not had_dbg:
		DirAccess.remove_absolute(dbg_path)
	SaveSystem.delete_save()
	DirAccess.remove_absolute(Settings.path)
	for f in failures:
		printerr("PAUSA FALLA: ", f)
	print("PAUSA %s (%d problemas)" % ["OK" if failures.is_empty() else "FALLA", failures.size()])
	get_tree().quit(1 if not failures.is_empty() else 0)


func _snapshot(g: GameScreen, m: GameModel) -> Dictionary:
	var bills: Array = []
	for b in m.bills_active:
		bills.append([int(b["id"]), snappedf(float(b["left"]), 0.0001)])
	var bill_pos: Array = []
	for id in g._bills:
		if is_instance_valid(g._bills[id]):
			bill_pos.append((g._bills[id] as Control).position.round())
	return {"plata": m.money.to_save(), "ganado": m.run_earned.to_save(), "precios (ln P)": snappedf(m.ln_p, 0.000001),
		"tiempo de la vuelta": m.run_time, "billetes": bills, "billetes en pantalla": bill_pos,
		"noticia": str(m.pending_choice.get("remaining", "")), "avisos en cola": g._toast_queue.size(),
		"reloj de la pantalla": g._clock, "próximo billete": m.bill_timer, "próxima noticia": m.event_timer}


func _esc() -> void:
	var ev: InputEventKey = InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.pressed = true
	Input.parse_input_event(ev)
	var up: InputEventKey = InputEventKey.new()
	up.keycode = KEY_ESCAPE
	up.pressed = false
	Input.parse_input_event(up)


func _esc_f10() -> void:
	var ev: InputEventKey = InputEventKey.new()
	ev.keycode = KEY_F10
	ev.pressed = true
	Input.parse_input_event(ev)


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame
