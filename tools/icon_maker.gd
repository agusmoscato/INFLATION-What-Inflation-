extends Node
## Genera icon.png (256x256) e icon.ico (16..256) con la empanada de tiza sobre el pizarrón.
## Hay que correrlo con ventana (necesita renderer):
##   godot --rendering-driver opengl3 res://tools/IconMaker.tscn

const SIZES: Array = [16, 24, 32, 48, 64, 128, 256]
const VIEW: int = 256

var _sv: SubViewport
var _frames: int = 0


func _ready() -> void:
	Chalk.load_fonts()
	_sv = SubViewport.new()
	_sv.size = Vector2i(VIEW, VIEW)
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sv)
	var root: Control = Control.new()
	root.theme = ChalkTheme.build()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sv.add_child(root)
	var board: ChalkBoard = ChalkBoard.new()
	root.add_child(board)
	# la empanada, grande y sonriente
	var emp: EmpanadaButton = EmpanadaButton.new()
	emp.custom_minimum_size = Vector2(250, 200)
	emp.size = Vector2(250, 200)
	emp.position = Vector2(3, 48)
	emp.set_process(false)
	root.add_child(emp)
	# un signo de pregunta amarillo, por el nombre
	var q: Label = UIKit.label("?", 120, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, true)
	q.position = Vector2(150, -18)
	q.size = Vector2(100, 130)
	q.rotation = 0.12
	q.add_theme_color_override("font_outline_color", Color("#3a2a05"))
	q.add_theme_constant_override("outline_size", 6)
	root.add_child(q)
	# ceros de tiza cayendo
	var z: Label = UIKit.label("000", 40, Color(Chalk.WHITE, 0.55), HORIZONTAL_ALIGNMENT_LEFT, true)
	z.position = Vector2(22, 18)
	root.add_child(z)
	var post_layer: CanvasLayer = CanvasLayer.new()
	post_layer.layer = 50
	_sv.add_child(post_layer)
	post_layer.add_child(ChalkPost.new())
	var frame_layer: CanvasLayer = CanvasLayer.new()
	frame_layer.layer = 60
	_sv.add_child(frame_layer)
	var wf: WoodFrame = WoodFrame.new()
	frame_layer.add_child(wf)


func _process(_delta: float) -> void:
	_frames += 1
	if _frames < 12:
		return
	var img: Image = _sv.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	var out_dir: String = ProjectSettings.globalize_path("res://")
	img.save_png(out_dir + "icon.png")
	var ico: PackedByteArray = _build_ico(img)
	var f: FileAccess = FileAccess.open(out_dir + "icon.ico", FileAccess.WRITE)
	f.store_buffer(ico)
	f.close()
	print("ICON OK: icon.png (256x256) e icon.ico (%d bytes, tamaños %s)" % [ico.size(), str(SIZES)])
	get_tree().quit(0)


## ICO con una imagen PNG por tamaño (formato válido desde Windows Vista).
static func _build_ico(src: Image) -> PackedByteArray:
	var pngs: Array = []
	for s in SIZES:
		var im: Image = src.duplicate()
		if int(s) != src.get_width():
			im.resize(int(s), int(s), Image.INTERPOLATE_LANCZOS)
		pngs.append(im.save_png_to_buffer())
	var count: int = pngs.size()
	var header: PackedByteArray = PackedByteArray()
	header.resize(6 + 16 * count)
	header.encode_u16(0, 0)
	header.encode_u16(2, 1)
	header.encode_u16(4, count)
	var offset: int = header.size()
	for i in range(count):
		var s2: int = int(SIZES[i])
		var base: int = 6 + 16 * i
		header[base] = 0 if s2 >= 256 else s2
		header[base + 1] = 0 if s2 >= 256 else s2
		header[base + 2] = 0
		header[base + 3] = 0
		header.encode_u16(base + 4, 1)
		header.encode_u16(base + 6, 32)
		header.encode_u32(base + 8, (pngs[i] as PackedByteArray).size())
		header.encode_u32(base + 12, offset)
		offset += (pngs[i] as PackedByteArray).size()
	var out: PackedByteArray = header
	for p in pngs:
		out.append_array(p)
	return out
