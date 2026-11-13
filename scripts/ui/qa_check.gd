class_name QaCheck
extends RefCounted
## Control de calidad de los exportados: detecta textos visibles que son una clave de traducción sin traducir
## (por ejemplo "ui.new_game" o "biz.kiosco") y guarda capturas.

const PREFIXES: Array = ["ui", "biz", "upg", "ev", "ref", "plan", "era", "ach", "note", "hl", "toast", "tut", "demo", "obj", "stk",
	"page", "pageb", "unlock", "tip", "howto", "timba", "secret", "rarity", "prefs", "gmb"]


## ¿El texto parece una clave de traducción ("prefijo.algo.mas")?
static func looks_like_key(text: String) -> bool:
	var t: String = text.strip_edges()
	if t.length() < 4 or t.find(" ") != -1 or t.find("\n") != -1:
		return false
	var parts: PackedStringArray = t.split(".")
	if parts.size() < 2:
		return false
	if not PREFIXES.has(parts[0]):
		return false
	for p in parts:
		if p == "" or not p.is_valid_identifier() and not p.is_valid_int():
			return false
	return true


## Recorre el árbol y devuelve los textos visibles que parecen claves sin traducir.
static func scan(root: Node) -> Array:
	var bad: Array = []
	_walk(root, bad)
	return bad


static func _walk(n: Node, bad: Array) -> void:
	if n is Control and (n as Control).is_inside_tree() and not (n as Control).is_visible_in_tree():
		return
	var text: String = ""
	if n is Label:
		text = (n as Label).text
	elif n is Button:
		text = (n as Button).text
	if text != "" and looks_like_key(text):
		bad.append("%s: %s" % [n.get_path(), text])
	for c in n.get_children():
		_walk(c, bad)
