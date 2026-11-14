class_name SaveIO
extends RefCounted
## Lectura/escritura de partidas en JSON (sin autoloads, testeable).


static func write(path: String, data: Dictionary) -> bool:
	var tmp: String = path + ".tmp"
	var f: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	var dir: DirAccess = DirAccess.open(path.get_base_dir())
	if dir == null:
		return false
	if dir.file_exists(path.get_file()):
		dir.remove(path.get_file())
	return dir.rename(tmp.get_file(), path.get_file()) == OK


static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.open(path.get_base_dir()).remove(path.get_file())


static func save_model(m: GameModel, path: String) -> bool:
	return write(path, m.to_dict())


## Carga la partida en `m`. Devuelve {} si no hay save, {"old": true} si es de la versión 1 (no se convierte),
## o un reporte offline (posiblemente con seconds = 0).
static func load_into(m: GameModel, path: String, now_unix: float) -> Dictionary:
	var d: Dictionary = read(path)
	if d.is_empty():
		return {}
	if not m.from_dict(d):
		return {"old": true}
	var away: float = now_unix - m.saved_unix
	if m.saved_unix <= 0.0 or away < 0.0:
		away = 0.0
	if away < 30.0:
		return {"seconds": 0.0}
	return EconomyLogic.simulate_offline(m, away)
