class_name I18n
extends RefCounted
## Carga los archivos de i18n/ (formato CSV con extensión .txt para que Godot los exporte crudos; columnas: keys, es, en) y los registra en el TranslationServer,
## así toda la UI usa tr(). El nombre del juego NO se traduce.

const FILES: Array = ["res://i18n/translations.txt", "res://i18n/content.txt", "res://i18n/gameplay.txt", "res://i18n/collect.txt", "res://i18n/timba.txt", "res://i18n/clarity.txt"]
const LOCALES: Array = ["es", "en"]

static var _tables: Dictionary = {}
static var _loaded: bool = false


static func load_all() -> void:
	if _loaded:
		return
	_loaded = true
	_tables = {}
	for loc in LOCALES:
		_tables[loc] = {}
	for path in FILES:
		var f: FileAccess = FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var header: PackedStringArray = f.get_csv_line()
		var cols: Dictionary = {}
		for i in range(1, header.size()):
			cols[i] = header[i]
		while not f.eof_reached():
			var line: PackedStringArray = f.get_csv_line()
			if line.size() < 2 or line[0].strip_edges() == "":
				continue
			for i in cols:
				if i < line.size() and _tables.has(cols[i]):
					_tables[cols[i]][line[0]] = line[i].replace("\\n", "\n")
	for loc in LOCALES:
		var tr_res: Translation = Translation.new()
		tr_res.locale = loc
		for k in _tables[loc]:
			tr_res.add_message(k, _tables[loc][k])
		TranslationServer.add_translation(tr_res)


static func all_keys() -> Array:
	load_all()
	return _tables["es"].keys()


static func has_key(key: String, locale: String) -> bool:
	load_all()
	return _tables.has(locale) and _tables[locale].has(key) and str(_tables[locale][key]) != ""


static func set_language(code: String) -> void:
	load_all()
	TranslationServer.set_locale(code)


static func current_language() -> String:
	return TranslationServer.get_locale().substr(0, 2)


static func get_text(key: String, locale: String) -> String:
	load_all()
	return str(_tables.get(locale, {}).get(key, ""))
