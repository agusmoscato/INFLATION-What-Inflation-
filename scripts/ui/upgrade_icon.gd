class_name UpgradeIcon
extends Button
## Ícono de una mejora en la fila de mejoras (estilo Cookie Clicker): dibujo de tiza del negocio (o de la empanada),
## estrellitas según el nivel y apagado si todavía no alcanza la plata. Tocarlo la compra.

var upg: Dictionary = {}
var affordable: bool = false
var _t: float = 0.0


func _init(u: Dictionary = {}) -> void:
	upg = u
	custom_minimum_size = Vector2(58, 58)
	text = ""
	UIKit.style_button(self, UIKit.C_PANEL2, 15)
	tooltip_text = ""


func _process(delta: float) -> void:
	_t += delta
	if affordable:
		queue_redraw()


func set_affordable(v: bool) -> void:
	if v != affordable:
		affordable = v
		queue_redraw()


func _make_custom_tooltip(_for_text: String) -> Object:
	var p: PanelContainer = PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.chalk_box(Chalk.YELLOW, Color(0.08, 0.12, 0.1, 0.97), 2.2))
	var v: VBoxContainer = VBoxContainer.new()
	p.add_child(v)
	v.add_child(UIKit.label(GameData.upgrade_title(upg), 18, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_LEFT, true))
	var d: Label = UIKit.label(UpgradeIcon.describe(upg), 15, Chalk.WHITE)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(300, 0)
	v.add_child(d)
	v.add_child(UIKit.label(tr("ui.upg.cost") % UIKit.money(EconomyLogic.upgrade_cost(GameState.m, upg)), 16, Chalk.GREEN))
	return p


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
	var r: Rect2 = Rect2(Vector2(6, 6), size - Vector2(12, 12))
	var tint: Color = Color(0, 0, 0, 0) if affordable else Color(Chalk.WHITE, 0.35)
	var icon: String = str(upg.get("icon", "empanadas"))
	if icon == "empanada":
		icon = "empanadas"
	if icon == "star":
		Chalk.polygon(self, _star(size / 2.0, size.x * 0.32), Chalk.YELLOW if affordable else Color(Chalk.WHITE, 0.35), 2.4, 7, true, Color(Chalk.YELLOW, 0.3), 6.0)
	else:
		ChalkIcons.draw(self, icon, r, 5 + str(upg.get("id", "")).length(), tint)
	# nivel: 1 a 4 puntitos abajo (o una "C" de clic / "S" de sinergia)
	var f: Font = Chalk.title_font if Chalk.title_font != null else ThemeDB.fallback_font
	var tag: String = ""
	match str(upg.get("kind", "")):
		"biz":
			tag = "I".repeat(int(str(upg["id"]).get_slice("_", str(upg["id"]).get_slice_count("_") - 1)))
		"click":
			tag = "CLIC"
		"syn":
			tag = "+"
	if tag != "":
		draw_string(f, Vector2(0, size.y - 4), tag, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 5, 14, Chalk.YELLOW if affordable else Color(Chalk.WHITE, 0.5))
	if affordable:
		var a: float = 0.35 + 0.25 * sin(_t * 4.0)
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(Chalk.YELLOW, a), false, 2.0)


static func _star(c: Vector2, r: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(10):
		var a: float = -PI / 2.0 + TAU * float(i) / 10.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	return pts
