class_name UpgradeIcon
extends Button
## Tarjeta de una mejora en la fila de mejoras. Se entiende de un vistazo, sin hacer clic ni pasar el mouse:
## ícono, nombre corto, efecto ("Carritos x2") y precio. Si te alcanza, borde verde que late; si no, el precio en rojo y
## una barrita que muestra cuánto te falta. Las "Próximas" (todavía lejos) se ven apagadas y con candado.
## Tocarla la compra; el detalle aparece al instante al pasar el mouse (lo dibuja GameScreen).

const CARD: Vector2 = Vector2(186, 74)

var upg: Dictionary = {}
var affordable: bool = false
var locked: bool = false
var progress: float = 0.0          ## plata / precio (0..1) para la barrita
var price_text: String = ""
var _t: float = 0.0


func _init(u: Dictionary = {}, is_locked: bool = false) -> void:
	upg = u
	locked = is_locked
	custom_minimum_size = CARD
	text = ""
	UIKit.style_button(self, UIKit.C_PANEL2.darkened(0.25) if locked else UIKit.C_PANEL2, 15)
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_ARROW if locked else Control.CURSOR_POINTING_HAND


func _process(delta: float) -> void:
	_t += delta
	if affordable and not locked:
		queue_redraw()


func set_state(can: bool, prog: float, price: String) -> void:
	if can != affordable or absf(prog - progress) > 0.01 or price != price_text:
		affordable = can
		progress = prog
		price_text = price
		queue_redraw()


## Nombre corto (cabe en la tarjeta).
static func short_name(u: Dictionary) -> String:
	if str(u["kind"]) == "biz":
		return TranslationServer.translate("upg.short.biz_" + str(u["id"]).get_slice("_", str(u["id"]).get_slice_count("_") - 1))
	return TranslationServer.translate(u["name_key"])


## Efecto en pocas palabras: "Carritos x2", "Clic x2", "Todo x1,5", "Kioscos +2 % por carrito".
static func effect(u: Dictionary) -> String:
	var fx: Dictionary = u["fx"]
	var v: float = float(fx["value"])
	match str(fx["type"]):
		"biz_mult":
			return TranslationServer.translate("upg.fx.biz") % [TranslationServer.translate("biz.%s.pl" % fx["biz"]), _num(v)]
		"click_mult":
			return TranslationServer.translate("upg.fx.click") % _num(v)
		"click_pct":
			return TranslationServer.translate("upg.fx.click_pct") % int(round(v * 100.0))
		"all_mult":
			return TranslationServer.translate("upg.fx.all") % _num(v)
		"synergy":
			return TranslationServer.translate("upg.fx.syn") % [TranslationServer.translate("biz.%s.pl" % fx["biz"]), int(round(v * 100.0)), TranslationServer.translate("biz.%s.sh" % fx["other"])]
	return ""


static func describe(u: Dictionary) -> String:
	var fx: Dictionary = u["fx"]
	match str(u["kind"]):
		"biz":
			return TranslationServer.translate("upg.biz.d") % [TranslationServer.translate("biz." + str(u["biz"])), "x" + _num(float(fx["value"]))]
		"syn":
			return TranslationServer.translate("upg.syn.d") % [TranslationServer.translate("biz." + str(u["biz"])), int(round(float(fx["value"]) * 100.0)), TranslationServer.translate("biz." + str(u["other"]))]
		"global":
			return TranslationServer.translate("upg.glob.d") % ("x" + _num(float(fx["value"])))
	return TranslationServer.translate(u["desc_key"])


static func _num(v: float) -> String:
	return ("%.1f" % v).rstrip("0").rstrip(".").replace(".", ",")


func _draw() -> void:
	var f: Font = Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font
	var body: Font = Chalk.hand_font if Chalk.hand_font != null else ThemeDB.fallback_font
	var dim: float = 0.45 if locked else 1.0
	# ícono
	var ir: Rect2 = Rect2(Vector2(7, 9), Vector2(44, 44))
	var icon: String = str(upg.get("icon", "empanadas"))
	if icon == "empanada":
		icon = "empanadas"
	if icon == "star":
		Chalk.polygon(self, _star(ir.get_center(), 19.0), Color(Chalk.YELLOW, dim), 2.4, 7, true, Color(Chalk.YELLOW, 0.3 * dim), 6.0)
	else:
		ChalkIcons.draw(self, icon, ir, 5 + str(upg.get("id", "")).length(), Color(Chalk.WHITE, 0.55) if locked else Color(0, 0, 0, 0))
	if locked:
		_padlock(Vector2(ir.end.x - 6, ir.end.y - 4))
	# textos
	var x: float = 58.0
	var w: float = size.x - x - 6.0
	draw_string(f, Vector2(x, 21), short_name(upg), HORIZONTAL_ALIGNMENT_LEFT, w, 15, Color(Chalk.WHITE, 0.95 * dim))
	draw_string(body, Vector2(x, 41), effect(upg), HORIZONTAL_ALIGNMENT_LEFT, w, 16, Color(Chalk.YELLOW, dim))
	var pc: Color = Chalk.GREEN if affordable and not locked else (Color(Chalk.WHITE, 0.5) if locked else Chalk.RED)
	draw_string(f, Vector2(x, 61), price_text, HORIZONTAL_ALIGNMENT_LEFT, w, 15, pc)
	# barrita hacia el precio
	if not affordable and not locked:
		var br: Rect2 = Rect2(Vector2(8, size.y - 9), Vector2(size.x - 16, 5))
		draw_rect(br, Color(1, 1, 1, 0.12))
		draw_rect(Rect2(br.position, Vector2(br.size.x * clampf(progress, 0.0, 1.0), br.size.y)), Color(Chalk.GREEN, 0.7))
	# borde verde que late si te alcanza
	if affordable and not locked:
		var a: float = 0.55 + 0.4 * sin(_t * 5.0)
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(Chalk.GREEN, a), false, 3.0)


func _padlock(c: Vector2) -> void:
	var col: Color = Color(Chalk.YELLOW, 0.8)
	draw_rect(Rect2(c + Vector2(-8, -6), Vector2(16, 12)), col)
	draw_arc(c + Vector2(0, -6), 5.0, PI, TAU, 10, col, 2.0)


static func _star(c: Vector2, r: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(10):
		var a: float = -PI / 2.0 + TAU * float(i) / 10.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	return pts
