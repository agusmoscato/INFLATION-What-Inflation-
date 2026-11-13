class_name StickerView
extends Control
## Una figurita del álbum, dibujada en tiza. Común = borde blanco, rara = celeste, dorada = brillo de tiza animado.
## Si no la tenés se ve la silueta con un "?".

var sticker_id: String = ""
var count: int = 0                 ## 0 = te falta
var show_name: bool = true
var highlight: bool = false        ## resaltada (por ejemplo, para elegirla en el chupi)
var _t: float = 0.0
var _seed: int = 1


func _init(id: String = "", n: int = 0) -> void:
	sticker_id = id
	count = n
	custom_minimum_size = Vector2(150, 190)
	_seed = 3 + id.hash() % 50
	mouse_filter = Control.MOUSE_FILTER_PASS


func _def() -> Dictionary:
	return StickerLogic.def(sticker_id)


func _process(delta: float) -> void:
	if sticker_id != "" and count > 0 and _def()["rarity"] == "golden":
		_t += delta
		queue_redraw()


func set_count(n: int) -> void:
	count = n
	queue_redraw()


func _rarity_color() -> Color:
	match str(_def()["rarity"]):
		"rare": return Chalk.BLUE
		"golden": return Chalk.YELLOW
	return Chalk.WHITE


func _draw() -> void:
	if sticker_id == "":
		return
	var d: Dictionary = _def()
	var have: bool = count > 0
	var col: Color = _rarity_color()
	var sc: Color = Color(col, 0.95 if have else 0.3)
	var edges: Array = Chalk.rect_edges(size - Vector2(8, 8), _seed, 1.5, 3.0)
	draw_rect(Rect2(4, 4, size.x - 8, size.y - 8), Color(0.05, 0.1, 0.07, 0.55 if have else 0.25))
	for e in edges:
		var moved: PackedVector2Array = PackedVector2Array()
		for p in e:
			moved.append(p + Vector2(4, 4))
		draw_polyline(moved, sc, 3.2 if d["rarity"] != "common" else 2.4, true)
	if highlight:
		draw_rect(Rect2(2, 2, size.x - 4, size.y - 4), Color(Chalk.GREEN, 0.18))
	var art: Rect2 = Rect2(14, 12, size.x - 28, size.y - 66)
	if have:
		_draw_art(d, art)
		if d["rarity"] == "golden":
			_draw_shimmer(art)
		if show_name:
			var f: Font = Chalk.hand_font if Chalk.hand_font != null else ThemeDB.fallback_font
			var nm: String = TranslationServer.translate(d["name_key"])
			draw_string(f, Vector2(8, size.y - 30), nm, HORIZONTAL_ALIGNMENT_CENTER, size.x - 16, 17, Chalk.WHITE)
			draw_string(f, Vector2(8, size.y - 10), TranslationServer.translate("rarity." + str(d["rarity"])), HORIZONTAL_ALIGNMENT_CENTER, size.x - 16, 13, Color(col, 0.9))
		if count > 1:
			draw_circle(Vector2(size.x - 22, 24), 17, Color("#26302B"))
			Chalk.circle(self, Vector2(size.x - 22, 24), 16, Chalk.PINK, 2.4, 5)
			var f2: Font = Chalk.hand_font if Chalk.hand_font != null else ThemeDB.fallback_font
			draw_string(f2, Vector2(size.x - 40, 31), "x%d" % count, HORIZONTAL_ALIGNMENT_CENTER, 36, 18, Chalk.PINK)
	else:
		var f3: Font = Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font
		draw_string(f3, Vector2(0, size.y * 0.5), "?", HORIZONTAL_ALIGNMENT_CENTER, size.x, 70, Color(Chalk.WHITE, 0.22))
		draw_string(f3, Vector2(0, size.y - 14), str(GameData.sticker_idx[sticker_id] + 1), HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, Color(Chalk.WHITE, 0.3))


func _draw_art(d: Dictionary, art: Rect2) -> void:
	var a: String = str(d["art"])
	if a.begins_with("face:"):
		ChalkFaces.draw(self, int(a.get_slice(":", 1)), art, Chalk.YELLOW if d["rarity"] == "golden" else Color(0, 0, 0, 0))
	elif a.begins_with("note:"):
		var nid: int = int(a.get_slice(":", 1))
		var b: Dictionary = GameData.banknotes[nid]
		# billete en miniatura
		var r: Rect2 = Rect2(art.position + Vector2(0, art.size.y * 0.2), Vector2(art.size.x, art.size.x * 0.52))
		var tint: Color = Chalk.nearest(b["color"])
		Chalk.polygon(self, PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y)]), tint, 2.6, 5 + nid, true, Color(tint, 0.3), 7.0, 1.0)
		Chalk.circle(self, r.get_center() + Vector2(-r.size.x * 0.28, 0), r.size.y * 0.24, tint, 2.2, 9 + nid, true, 5.0)
		var f: Font = Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font
		var txt: String = "$" + BanknoteView.denomination(3 + nid * 3)
		var fs: int = 16
		while Chalk.text_width(f, txt, fs) > r.size.x * 0.62 and fs > 8:
			fs -= 1
		draw_string(f, r.get_center() + Vector2(-r.size.x * 0.1, fs * 0.35), txt, HORIZONTAL_ALIGNMENT_LEFT, r.size.x * 0.66, fs, Chalk.WHITE)
	else:
		ChalkIcons.draw(self, a, art, 3 + _seed)


## Brillo de tiza animado de las doradas: una banda diagonal que barre la figurita y destellos que titilan.
func _draw_shimmer(art: Rect2) -> void:
	var phase: float = fmod(_t * 0.7, 1.6) - 0.3
	var x: float = art.position.x + art.size.x * phase
	draw_line(Vector2(x, art.end.y), Vector2(x + art.size.y * 0.4, art.position.y), Color(1, 1, 0.9, 0.35), 14.0, true)
	for i in range(4):
		var pt: Vector2 = art.position + Vector2(Chalk.rnd(_seed, 70 + i) * art.size.x, Chalk.rnd(_seed, 80 + i) * art.size.y)
		var a: float = 0.5 + 0.5 * sin(_t * 4.0 + float(i) * 1.7)
		var s: float = 5.0 + 4.0 * a
		var cc: Color = Color(1, 1, 0.85, a)
		draw_line(pt + Vector2(-s, 0), pt + Vector2(s, 0), cc, 2.2, true)
		draw_line(pt + Vector2(0, -s), pt + Vector2(0, s), cc, 2.2, true)
