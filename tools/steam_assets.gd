extends Node
## Genera las imagenes de la pagina de Steam en export/steam_assets/ (todo dibujado por codigo, estilo pizarron).
##   godot --rendering-driver opengl3 res://tools/SteamAssets.tscn            # todo
##   godot --rendering-driver opengl3 res://tools/SteamAssets.tscn -- only=header,logo
## Necesita ventana (renderer). Los screenshots 1920x1080 los saca tools/steam_assets.ps1 con el tour de capturas.

const OUT: String = "res://export/steam_assets/"

## [archivo, ancho, alto, tipo]. "tipo" decide la composicion (ver Art._draw).
const ASSETS: Array = [
	["header_capsule_920x430", 920, 430, "wide"],
	["small_capsule_462x174", 462, 174, "small"],
	["main_capsule_1232x706", 1232, 706, "wide"],
	["vertical_capsule_748x896", 748, 896, "tall"],
	["library_capsule_600x900", 600, 900, "tall"],
	["library_hero_3840x1240", 3840, 1240, "hero"],
	["library_logo_1280x720", 1280, 720, "logo"],
]

const GLYPHS: Dictionary = {
	"first_sale": "$1", "clicks_500": "500", "first_remark": "%", "remarks_100": "100", "million_nothing": "1M",
	"googol": "1e100", "buildings_50": "50", "buildings_500": "500", "upgrades_30": "30", "era_2": "II", "era_3": "III",
	"era_4": "IV", "era_5": "V", "first_event": "!", "events_25": "25", "first_refuge": "U$", "hyper": "999%",
	"first_reform": "-000", "reforms_5": "x5", "album_full": "10", "first_plan": "PLAN", "marathon": "8h", "zero_cut_30": "-30",
	"first_pack": "5", "stickers_30": "30", "page_1": "1/6", "golden_first": "*", "trade_1": "2x1", "album_60": "60",
	"timbero": "777", "scratch_50": "50", "pozo": "POZO", "quiniela_hit": "00-99", "dollar_3": "3x", "lost_all": "$0",
	"gold_scratch": "**", "win": "0%",
}

var _queue: Array = []
var _only: PackedStringArray = PackedStringArray()
var _cur: SubViewport
var _cur_name: String = ""
var _cur_w: int = 0
var _cur_h: int = 0
var _cur_transparent: bool = false
var _icon_gray: bool = false
var _wait: int = 0


func _ready() -> void:
	Chalk.load_fonts()
	I18n.load_all()
	GameData.ensure()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			_only = a.substr(5).split(",")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "achievements"))
	for a in ASSETS:
		if _only.is_empty() or _only.has(str(a[0]).get_slice("_", 0)) or _only.has(str(a[0])):
			_queue.append({"name": a[0], "w": a[1], "h": a[2], "kind": a[3]})
	if _only.is_empty() or _only.has("achievements"):
		for a in GameData.achievements:
			_queue.append({"name": "achievements/" + str(a["id"]), "w": 256, "h": 256, "kind": "ach", "id": str(a["id"])})
			_queue.append({"name": "achievements/" + str(a["id"]) + "_locked", "w": 256, "h": 256, "kind": "ach", "id": str(a["id"]), "gray": true})
	_next()


func _next() -> void:
	if _cur != null:
		_cur.queue_free()
		_cur = null
	if _queue.is_empty():
		print("STEAM ASSETS OK -> ", ProjectSettings.globalize_path(OUT))
		get_tree().quit(0)
		return
	var job: Dictionary = _queue.pop_front()
	_cur_name = str(job["name"])
	_cur_w = int(job["w"])
	_cur_h = int(job["h"])
	_icon_gray = bool(job.get("gray", false))
	var kind: String = str(job["kind"])
	_cur_transparent = kind == "logo"
	_cur = SubViewport.new()
	_cur.size = Vector2i(_cur_w, _cur_h)
	_cur.transparent_bg = _cur_transparent
	_cur.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_cur)
	var root: Control = Control.new()
	root.theme = ChalkTheme.build()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cur.add_child(root)
	if not _cur_transparent:
		root.add_child(ChalkBoard.new())
	var art: Art = Art.new(kind, str(job.get("id", "")))
	art.size = Vector2(_cur_w, _cur_h)
	root.add_child(art)
	art.build()
	if not _cur_transparent:
		var post_layer: CanvasLayer = CanvasLayer.new()
		post_layer.layer = 50
		_cur.add_child(post_layer)
		post_layer.add_child(ChalkPost.new())
		if kind != "ach" and kind != "hero":
			var frame_layer: CanvasLayer = CanvasLayer.new()
			frame_layer.layer = 60
			_cur.add_child(frame_layer)
			frame_layer.add_child(WoodFrame.new())
	_wait = 14


func _process(_delta: float) -> void:
	if _cur == null:
		return
	_wait -= 1
	if _wait > 0:
		return
	var img: Image = _cur.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	if _icon_gray:
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var c: Color = img.get_pixel(x, y)
				var l: float = (c.r * 0.3 + c.g * 0.59 + c.b * 0.11) * 0.55
				img.set_pixel(x, y, Color(l, l, l, c.a))
	var path: String = ProjectSettings.globalize_path(OUT + _cur_name + ".png")
	img.save_png(path)
	print("  ", _cur_name, " ", img.get_size())
	_next()


## Composicion de cada imagen.
class Art extends Control:
	var kind: String = ""
	var ach_id: String = ""

	func _init(k: String = "", id: String = "") -> void:
		kind = k
		ach_id = id
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func build() -> void:
		var w: float = size.x
		var h: float = size.y
		match kind:
			"wide":
				_mascot(Vector2(w * 0.65, h * 0.40), Vector2(w * 0.30, h * 0.46), 0.55)
			"small":
				_mascot(Vector2(w * 0.68, h * 0.06), Vector2(w * 0.26, h * 0.74), 0.3)
			"tall":
				_mascot(Vector2(w * 0.22, h * 0.34), Vector2(w * 0.56, h * 0.30), 0.55)
				_stickers(Vector2(w * 0.08, h * 0.70), w * 0.30)
			"hero":
				_mascot(Vector2(w * 0.62, h * 0.12), Vector2(h * 0.95, h * 0.76), 0.6)
				_stickers(Vector2(w * 0.40, h * 0.30), h * 0.40)

	func _mascot(pos: Vector2, sz: Vector2, rate: float) -> void:
		var e: EmpanadaButton = EmpanadaButton.new()
		e.rate = rate
		e.position = pos
		e.size = sz
		e.custom_minimum_size = sz
		e.set_process_input(false)
		add_child(e)

	func _stickers(pos: Vector2, h: float) -> void:
		var ids: Array = ["gold_1", "biz_kiosco", "pj_perro"]
		for i in range(ids.size()):
			var s: StickerView = StickerView.new(str(ids[i]), 1)
			s.show_name = false
			s.size = Vector2(150, 190)
			s.custom_minimum_size = Vector2(150, 190)
			var k: float = h / 190.0
			s.scale = Vector2(k, k)
			s.pivot_offset = Vector2(75, 95)
			s.rotation = (float(i) - 1.0) * 0.22
			s.position = pos + Vector2(float(i) * 150.0 * k * 0.62, absf(float(i) - 1.0) * 14.0 * k)
			add_child(s)

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var tf: Font = Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font
		match kind:
			"wide":
				_bills(0.5)
				_title(tf, Vector2(w * 0.04, h * 0.36), h * 0.27, h * 0.11)
			"small":
				_title(tf, Vector2(w * 0.035, h * 0.50), h * 0.30, h * 0.11)
			"tall":
				_bills(0.4)
				_title_centered(tf, Vector2(w * 0.5, h * 0.20), w * 0.17, w * 0.085)
				_banknote(Vector2(w * 0.5, h * 0.60 + h * 0.26), Vector2(w * 0.9, h * 0.14))
			"hero":
				_bills(0.5)
			"logo":
				_title_centered(tf, Vector2(w * 0.5, h * 0.50), h * 0.26, h * 0.12)
			"ach":
				_medal(tf)
		if kind == "wide":
			_banknote(Vector2(w * 0.34, h * 0.82), Vector2(w * 0.58, h * 0.20))

	# Titulo a la izquierda (dos lineas) con borde oscuro para que se lea en la capsula chica.
	func _title(f: Font, base: Vector2, big: float, small: float) -> void:
		var a: String = "INFLATION?"
		var b: String = "What Inflation?"
		var fs1: int = int(big)
		var fs2: int = int(small * 1.45)
		_outlined(f, a, base, fs1, Chalk.YELLOW, 11)
		_outlined(f, b, base + Vector2(big * 0.12, small * 1.7), fs2, Chalk.WHITE, 12)

	func _title_centered(f: Font, center: Vector2, big: float, small: float) -> void:
		var a: String = "INFLATION?"
		var b: String = "What Inflation?"
		var fs1: int = int(big)
		var fs2: int = int(small * 1.5)
		var w1: float = Chalk.text_width(f, a, fs1, 0.95)
		var w2: float = Chalk.text_width(f, b, fs2, 0.95)
		_outlined(f, a, Vector2(center.x - w1 * 0.5, center.y), fs1, Chalk.YELLOW, 13)
		_outlined(f, b, Vector2(center.x - w2 * 0.5, center.y + small * 1.9), fs2, Chalk.WHITE, 14)

	func _outlined(f: Font, text: String, pos: Vector2, fs: int, col: Color, seed_v: int) -> void:
		var ow: int = maxi(4, int(float(fs) * 0.11))
		draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ow, Color(0.07, 0.10, 0.08, 0.95))
		Chalk.draw_written(self, f, text, pos, fs, col, 1.0, seed_v, 0.0, 0.95)
		# subrayado de tiza
		var wd: float = Chalk.text_width(f, text, fs, 0.95)
		Chalk.line(self, pos + Vector2(0, fs * 0.12), pos + Vector2(wd, fs * 0.16), Color(col, 0.7), maxf(3.0, fs * 0.04), seed_v + 5, 2.5)

	# Billete gigante lleno de ceros (inclinado).
	func _banknote(c: Vector2, sz: Vector2) -> void:
		var f: Font = Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font
		draw_set_transform(c, -0.05, Vector2.ONE)
		var r: Rect2 = Rect2(-sz * 0.5, sz)
		draw_rect(r, Color(0.12, 0.2, 0.15, 0.85))
		var pts: PackedVector2Array = PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position])
		Chalk.polyline(self, pts, Chalk.WHITE, 4.0, 31, 2.0)
		var fs: int = int(sz.y * 0.62)
		var txt: String = "$1.000.000.000.000"
		var tw: float = Chalk.text_width(f, txt, fs, 0.95)
		var k: float = minf(1.0, (sz.x * 0.94) / tw)
		draw_string_outline(f, Vector2(-tw * k * 0.5, fs * k * 0.34), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, int(float(fs) * k), 6, Color(0.05, 0.08, 0.06, 0.9))
		draw_string(f, Vector2(-tw * k * 0.5, fs * k * 0.34), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, int(float(fs) * k), Chalk.WHITE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Ceros de tiza flotando de fondo.
	func _bills(alpha: float) -> void:
		var f: Font = Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font
		var n: int = int(size.x * size.y / 14000.0)
		for i in range(n):
			var x: float = Chalk.rnd(7, i) * size.x
			var y: float = Chalk.rnd(8, i) * size.y
			var fs: int = 18 + int(Chalk.rnd(9, i) * 46.0)
			var cols: Array = [Chalk.WHITE, Chalk.PINK, Chalk.YELLOW, Chalk.BLUE]
			draw_set_transform(Vector2(x, y), Chalk.rnd_s(10, i) * 0.5, Vector2.ONE)
			draw_string(f, Vector2.ZERO, "0" if i % 3 != 0 else "$", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(cols[i % 4], 0.10 + alpha * 0.14))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Medalla para los iconos de logros (256x256).
	func _medal(f: Font) -> void:
		var c: Vector2 = size * 0.5 + Vector2(0, -6)
		var col: Color = Chalk.YELLOW
		var seed_v: int = 3 + ach_id.hash() % 40
		# cintas
		Chalk.polygon(self, PackedVector2Array([c + Vector2(-48, 52), c + Vector2(-74, 112), c + Vector2(-44, 100), c + Vector2(-24, 118), c + Vector2(-14, 62)]), Chalk.RED, 4.0, seed_v, true, Color(Chalk.RED, 0.5), 7.0)
		Chalk.polygon(self, PackedVector2Array([c + Vector2(48, 52), c + Vector2(74, 112), c + Vector2(44, 100), c + Vector2(24, 118), c + Vector2(14, 62)]), Chalk.BLUE, 4.0, seed_v + 1, true, Color(Chalk.BLUE, 0.5), 7.0)
		Chalk.circle(self, c, 82.0, col, 6.0, seed_v + 2, true, 6.0)
		Chalk.circle(self, c, 66.0, Chalk.WHITE, 3.0, seed_v + 3)
		var g: String = str(GLYPHS.get(ach_id, "?"))
		var fs: int = 64 if g.length() <= 2 else (48 if g.length() == 3 else (38 if g.length() == 4 else 30))
		var tw: float = Chalk.text_width(f, g, fs, 0.95)
		draw_string_outline(f, c + Vector2(-tw * 0.5, fs * 0.34), g, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 8, Color(0.07, 0.1, 0.08, 0.9))
		Chalk.draw_written(self, f, g, c + Vector2(-tw * 0.5, fs * 0.34), fs, Chalk.WHITE, 1.0, seed_v + 4, 0.0, 0.95)
