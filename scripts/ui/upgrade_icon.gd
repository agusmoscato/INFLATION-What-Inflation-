class_name UpgradeIcon
extends Button
## Tarjeta de una mejora en la fila de mejoras. Se entiende de un vistazo, sin hacer clic ni pasar el mouse:
## ícono, nombre corto, efecto ("Carritos x2") y precio. Tres estados bien distintos:
##  - te alcanza: brillante, borde grueso verde que late y una chispa de tiza cada tanto;
##  - no te alcanza: apagada (45 %), con el precio en rojo y una barrita de cuánto te falta;
##  - "Próximas" (bloqueadas): candado, tiza tenue y la condición con su barrita.
## Tocarla la compra; el detalle aparece al instante al pasar el mouse (lo dibuja GameScreen).

const CARD: Vector2 = Vector2(200, 80)
const TEXT_X: float = 58.0
## Tamaños de letra: se achica hasta que entra (nunca se corta); el nombre puede ir en dos líneas.
const NAME_FS: Array = [15, 12]
const EFFECT_FS: Array = [16, 11]
const LOW_FS: Array = [15, 11]

var upg: Dictionary = {}
var affordable: bool = false
var locked: bool = false
var progress: float = 0.0          ## plata / precio (0..1) para la barrita
var price_text: String = ""
var cond_text: String = ""           ## "Próximas" que todavía no se desbloquean: la condición en lugar del precio
var cond_progress: float = 0.0
var _t: float = 0.0
var _spark_t: float = -9.0
var _spark_at: float = 0.0
var pulse: bool = false              ## late (solo la que elige la pantalla: como mucho 2 cosas laten a la vez)


func _init(u: Dictionary = {}, is_locked: bool = false) -> void:
	upg = u
	locked = is_locked
	custom_minimum_size = CARD
	text = ""
	_restyle()
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_ARROW if locked else Control.CURSOR_POINTING_HAND


func _process(delta: float) -> void:
	_t += delta
	if affordable and not locked and pulse:
		if _t - _spark_t > 1.3 + fmod(float(get_instance_id() % 97) * 0.013 + _t * 0.37, 0.8):
			_spark_t = _t
			_spark_at = fmod(_t * 0.618 + float(get_instance_id() % 13) * 0.1, 1.0)
		queue_redraw()


## Estilo del fondo según el estado: brillante si te alcanza, oscuro si no, más oscuro si está bloqueada.
func _restyle() -> void:
	var base: Color = UIKit.C_PANEL2
	if locked:
		base = UIKit.C_PANEL2.darkened(0.35)
	elif affordable:
		base = UIKit.C_PANEL2.lightened(0.18)
	else:
		base = UIKit.C_PANEL2.darkened(0.2)
	UIKit.style_button(self, base, 15)


func set_cond(text: String, prog: float) -> void:
	if text != cond_text or absf(prog - cond_progress) > 0.005:
		cond_text = text
		cond_progress = prog
		queue_redraw()


func set_pulse(p: bool) -> void:
	if p != pulse:
		pulse = p
		queue_redraw()


func set_state(can: bool, prog: float, price: String) -> void:
	if can != affordable or absf(prog - progress) > 0.01 or price != price_text:
		if can != affordable:
			affordable = can
			_restyle()
		affordable = can
		progress = prog
		price_text = price
		queue_redraw()


## Nombre corto (cabe en la tarjeta).
static func short_name(u: Dictionary) -> String:
	if str(u["kind"]) == "biz":
		return TranslationServer.translate("upg.short.biz_" + str(u["id"]).get_slice("_", str(u["id"]).get_slice_count("_") - 1))
	if str(u["kind"]) == "promo":
		return GameData.upgrade_title(u)
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
		"global", "promo":
			return TranslationServer.translate("upg.glob.d") % ("x" + _num(float(fx["value"])))
	return TranslationServer.translate(u["desc_key"])


## "2", "1,5", "1,03": los decimales que hagan falta (con uno solo, la promo x1,03 se leía "x1" y parecía no hacer nada).
static func _num(v: float) -> String:
	return ("%.2f" % v).rstrip("0").rstrip(".").replace(".", ",")


func _draw() -> void:
	var f: Font = Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font
	var body: Font = Chalk.hand_font if Chalk.hand_font != null else ThemeDB.fallback_font
	# apagada al 45 % si no te alcanza o está bloqueada (el precio en rojo y la barrita quedan bien visibles)
	var dim: float = 1.0 if affordable and not locked else 0.45
	# ícono
	var ir: Rect2 = Rect2(Vector2(7, 12), Vector2(44, 44))
	var icon: String = str(upg.get("icon", "empanadas"))
	if icon == "empanada":
		icon = "empanadas"
	if icon == "star":
		Chalk.polygon(self, _star(ir.get_center(), 19.0), Color(Chalk.YELLOW, dim), 2.4, 7, true, Color(Chalk.YELLOW, 0.3 * dim), 6.0)
	else:
		ChalkIcons.draw(self, icon, ir, 5 + str(upg.get("id", "")).length(), Color(Chalk.WHITE, 0.55) if locked else Color(0, 0, 0, 0))
	if locked:
		_padlock(Vector2(ir.end.x - 6, ir.end.y - 4))
	# textos (cada uno con la letra más grande que entra: nunca se cortan)
	var x: float = TEXT_X
	var lay: Dictionary = text_layout()
	var names: Array = lay["name"]
	var y0: float = 22.0 if names.size() == 1 else 17.0
	for i in range(names.size()):
		draw_string(f, Vector2(x, y0 + 14.0 * float(i)), str(names[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(lay["name_fs"]), Color(Chalk.WHITE, 0.95 * dim))
	var ye: float = 44.0 if names.size() == 1 else 49.0
	var yl: float = 64.0 if names.size() == 1 else 66.0
	draw_string(body, Vector2(x, ye), effect(upg), HORIZONTAL_ALIGNMENT_LEFT, -1, int(lay["effect_fs"]), Color(Chalk.YELLOW, dim))
	var pc: Color = Chalk.GREEN if affordable and not locked else (Color(Chalk.WHITE, 0.5) if locked else Chalk.RED)
	if locked and cond_text != "":
		draw_string(body, Vector2(x, yl), cond_text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(lay["low_fs"]), Color(Chalk.PINK, 0.8))
		# barra de progreso hacia la condición
		var cb: Rect2 = Rect2(Vector2(8, size.y - 9), Vector2(size.x - 16, 5))
		draw_rect(cb, Color(1, 1, 1, 0.12))
		draw_rect(Rect2(cb.position, Vector2(cb.size.x * clampf(cond_progress, 0.0, 1.0), cb.size.y)), Color(Chalk.PINK, 0.75))
	else:
		draw_string(f, Vector2(x, yl), price_text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(lay["low_fs"]), pc)
	# barrita hacia el precio
	if not affordable and not locked:
		var br: Rect2 = Rect2(Vector2(8, size.y - 9), Vector2(size.x - 16, 5))
		draw_rect(br, Color(1, 1, 1, 0.12))
		draw_rect(Rect2(br.position, Vector2(br.size.x * clampf(progress, 0.0, 1.0), br.size.y)), Color(Chalk.GREEN, 0.85))
	if locked:
		# tiza tenue: un borde punteado
		var r: Rect2 = Rect2(Vector2(3, 3), size - Vector2(6, 6))
		for i in range(0, int(r.size.x), 10):
			draw_line(r.position + Vector2(i, 0), r.position + Vector2(mini(i + 5, int(r.size.x)), 0), Color(Chalk.WHITE, 0.18), 1.5)
			draw_line(Vector2(r.position.x + i, r.end.y), Vector2(r.position.x + mini(i + 5, int(r.size.x)), r.end.y), Color(Chalk.WHITE, 0.18), 1.5)
	# te alcanza: borde grueso verde (fijo); si es la elegida para latir, late y tira una chispa de tiza cada tanto
	if affordable and not locked:
		if pulse:
			BuyGlow.draw_pulse_border(self, Rect2(Vector2.ZERO, size), _t)
			var k: float = (_t - _spark_t) / 0.5
			if k >= 0.0 and k <= 1.0:
				BuyGlow.draw_spark(self, BuyGlow.border_point(Rect2(Vector2.ZERO, size), _spark_at), k)
		else:
			BuyGlow.draw_static_border(self, Rect2(Vector2.ZERO, size))


static func _fonts() -> Array:
	return [Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font, Chalk.hand_font if Chalk.hand_font != null else ThemeDB.fallback_font]


## El tamaño más grande (de `fs[0]` a `fs[1]`) con el que `text` entra en `w`; -1 si ni con el más chico.
static func fit_size(font: Font, text: String, w: float, fs: Array) -> int:
	for size_i in range(int(fs[0]), int(fs[1]) - 1, -1):
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_i).x <= w:
			return size_i
	return -1


## Cómo entran los textos en la tarjeta: {name: [1 o 2 líneas], name_fs, effect_fs, low_fs, problems: [...]}. Si algo no
## entra ni con la letra más chica, queda en `problems` (el QA falla) y se dibuja igual con la letra mínima.
func text_layout() -> Dictionary:
	var fonts: Array = _fonts()
	var w: float = maxf(size.x, CARD.x) - TEXT_X - 6.0
	var problems: Array = []
	var nm: String = short_name(upg)
	var lines: Array = [nm]
	var nfs: int = fit_size(fonts[0], nm, w, NAME_FS)
	if nfs < 0:
		# en dos líneas, cortando entre palabras donde quede más parejo
		var words: PackedStringArray = nm.split(" ")
		var best: Array = []
		var best_fs: int = -1
		for cut in range(1, words.size()):
			var a: String = " ".join(words.slice(0, cut))
			var b: String = " ".join(words.slice(cut))
			var fs2: int = mini(fit_size(fonts[0], a, w, [14, NAME_FS[1]]), fit_size(fonts[0], b, w, [14, NAME_FS[1]]))
			if fs2 > best_fs:
				best_fs = fs2
				best = [a, b]
		if best_fs > 0:
			lines = best
			nfs = best_fs
		else:
			nfs = int(NAME_FS[1])
			problems.append("nombre cortado: " + nm)
	var efs: int = fit_size(fonts[1], effect(upg), w, EFFECT_FS)
	if efs < 0:
		efs = int(EFFECT_FS[1])
		problems.append("efecto cortado: " + effect(upg))
	var low: String = cond_text if locked and cond_text != "" else price_text
	var lfs: int = fit_size(fonts[1] if locked and cond_text != "" else fonts[0], low, w, LOW_FS)
	if lfs < 0:
		lfs = int(LOW_FS[1])
		problems.append("precio o condición cortados: " + low)
	return {"name": lines, "name_fs": nfs, "effect_fs": efs, "low_fs": lfs, "problems": problems}


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
