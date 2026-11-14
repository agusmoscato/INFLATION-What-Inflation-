class_name QaCheck
extends RefCounted
## Control de calidad de los exportados: detecta textos visibles que son una clave de traducción sin traducir
## (por ejemplo "ui.new_game" o "biz.kiosco") y guarda capturas.

const PREFIXES: Array = ["ui", "node", "bill", "biz", "upg", "ev", "ref", "plan", "era", "ach", "note", "hl", "toast", "tut", "demo", "obj", "stk",
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


## Controles visibles que se salen de la ventana o se pisan entre sí, y textos más chicos que el mínimo.
## `vr` = rectángulo visible (coordenadas lógicas). Se ignoran: lo que está dentro de un ScrollContainer (se desplaza,
## solo se revisa el ancho), lo marcado con meta "qa_ignore" (adornos que se mueven a propósito) y las capas de efectos.
static func layout(root: Node, vr: Rect2) -> Array:
	var items: Array = []
	var bad: Array = []
	_collect(root, items, false, Rect2(), bad)
	for c in items:
		var r: Rect2 = (c as Control).get_global_rect()
		if r.position.x < vr.position.x - 1.5 or r.position.y < vr.position.y - 1.5 or r.end.x > vr.end.x + 1.5 or r.end.y > vr.end.y + 1.5:
			bad.append("FUERA DE LA VENTANA: %s %s (ventana %s)" % [(c as Node).get_path(), _fmt(r), _fmt(vr)])
	for i in range(items.size()):
		var a: Control = items[i]
		var ra: Rect2 = a.get_global_rect()
		for j in range(i + 1, items.size()):
			var b: Control = items[j]
			if a.is_ancestor_of(b) or b.is_ancestor_of(a):
				continue
			var inter: Rect2 = ra.intersection(b.get_global_rect())
			if inter.size.x > 3.0 and inter.size.y > 3.0 and inter.get_area() > 40.0:
				bad.append("SE SUPERPONEN: %s y %s (%s)" % [a.get_path(), b.get_path(), _fmt(inter)])
	return bad


static func _fmt(r: Rect2) -> String:
	return "[%d,%d %dx%d]" % [r.position.x, r.position.y, r.size.x, r.size.y]


static func _collect(n: Node, out: Array, in_scroll: bool, sr: Rect2, bad: Array) -> void:
	if n is CanvasLayer and (n as CanvasLayer).layer >= 40:
		return                       # capas de efecto (tiza, marco de madera, carteles flotantes)
	if n is Control:
		var c: Control = n as Control
		if c.is_inside_tree() and not c.is_visible_in_tree():
			return
		if c.has_meta("qa_ignore") or c.modulate.a < 0.05:
			return
		if c is ScrollContainer:
			in_scroll = true
			sr = c.get_global_rect()
		elif c.size.x > 4.0 and c.size.y > 4.0 and (c is Button or (c is Label and (c as Label).text.strip_edges() != "")):
			var fs: int = c.get_theme_font_size("font_size")
			if fs < UIKit.MIN_FONT:
				bad.append("TEXTO CHICO (%d < %d): %s" % [fs, UIKit.MIN_FONT, c.get_path()])
			if not in_scroll:
				out.append(c)
			else:
				# dentro de un scroll solo importa el ancho: lo que se corta a la derecha (los botones de compra)
				var r: Rect2 = c.get_global_rect()
				if r.end.y > sr.position.y and r.position.y < sr.end.y and (r.position.x < sr.position.x - 1.5 or r.end.x > sr.end.x + 1.5):
					bad.append("CORTADO EN LA LISTA: %s %s (lista %s)" % [c.get_path(), _fmt(r), _fmt(sr)])
	for k in n.get_children():
		_collect(k, out, in_scroll, sr, bad)
