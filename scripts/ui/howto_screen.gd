class_name HowToScreen
extends Control
## "¿Cómo se juega?": una pizarra ilustrada de una sola pantalla con el loop del juego.

signal closed


class _ArrowLine:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(46, 90)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c: Vector2 = size / 2.0
		Chalk.line(self, c + Vector2(-16, 0), c + Vector2(16, 0), Chalk.YELLOW, 5.0, 3, 1.4)
		Chalk.line(self, c + Vector2(16, 0), c + Vector2(4, -12), Chalk.YELLOW, 5.0, 4, 1.0)
		Chalk.line(self, c + Vector2(16, 0), c + Vector2(4, 12), Chalk.YELLOW, 5.0, 5, 1.0)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v: VBoxContainer = VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 18)
	add_child(v)
	v.add_child(UIKit.label(tr("howto.title"), 64, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, true))
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	v.add_child(row)
	for i in range(1, 6):
		var card: PanelContainer = UIKit.panel(UIKit.C_PANEL, 10)
		card.custom_minimum_size = Vector2(196, 250)
		var cv: VBoxContainer = VBoxContainer.new()
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		cv.add_theme_constant_override("separation", 8)
		card.add_child(cv)
		var icon_holder: CenterContainer = CenterContainer.new()
		icon_holder.add_child(_icon(i))
		cv.add_child(icon_holder)
		cv.add_child(UIKit.label(tr("howto.%d" % i), 28, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, true))
		var d: Label = UIKit.label(tr("howto.%dd" % i), 15, Chalk.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(d)
		row.add_child(card)
		if i < 5:
			row.add_child(_ArrowLine.new())
	var goal: Label = UIKit.label(tr("howto.goal"), 26, Chalk.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(goal)
	var back: Button = Button.new()
	back.text = tr("ui.back")
	back.custom_minimum_size = Vector2(240, 52)
	UIKit.style_button(back, UIKit.C_BLUE, 20)
	back.pressed.connect(func() -> void: closed.emit())
	var holder: CenterContainer = CenterContainer.new()
	holder.add_child(back)
	v.add_child(holder)


func _icon(i: int) -> Control:
	match i:
		1:
			var e: EmpanadaButton = EmpanadaButton.new()
			e.custom_minimum_size = Vector2(120, 90)
			e.mouse_filter = Control.MOUSE_FILTER_IGNORE
			return e
		2:
			var b: BusinessIcon = BusinessIcon.new("kiosco")
			b.custom_minimum_size = Vector2(90, 90)
			return b
		3:
			var r: RagWipe = RagWipe.new()
			r.custom_minimum_size = Vector2(100, 70)
			return r
		4:
			var bk: BusinessIcon = BusinessIcon.new("banco")
			bk.custom_minimum_size = Vector2(90, 90)
			return bk
	var s: ScissorsView = ScissorsView.new()
	s.custom_minimum_size = Vector2(110, 90)
	s.scale = Vector2(0.7, 0.7)
	return s
