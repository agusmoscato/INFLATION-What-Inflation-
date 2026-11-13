class_name DemoEndScreen
extends Control
## Pantalla de pizarra que cierra la demo: invita a agregar el juego a la wishlist de Steam.

signal back_to_menu


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v: VBoxContainer = VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	add_child(v)
	var title: Label = UIKit.label(tr("demo.title"), 80, Chalk.YELLOW, HORIZONTAL_ALIGNMENT_CENTER, true)
	title.add_theme_color_override("font_outline_color", Color("#3a2a05"))
	title.add_theme_constant_override("outline_size", 10)
	v.add_child(title)
	v.add_child(UIKit.label(tr("demo.sub"), 40, Chalk.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var m: GameModel = GameState.m
	v.add_child(UIKit.label(tr("demo.stats") % [UIKit.duration(m.time_played), m.zeros_cut], 22, UIKit.C_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	var wish: Button = Button.new()
	wish.text = tr("demo.wishlist")
	wish.custom_minimum_size = Vector2(300, 60)
	UIKit.style_button(wish, UIKit.C_BLUE, 24)
	row.add_child(wish)
	var menu: Button = Button.new()
	menu.text = tr("demo.menu")
	menu.custom_minimum_size = Vector2(240, 60)
	UIKit.style_button(menu, UIKit.C_PANEL2, 20)
	menu.pressed.connect(func() -> void: back_to_menu.emit())
	row.add_child(menu)
	var note: Label = UIKit.label("", 16, UIKit.C_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(note)
	wish.pressed.connect(func() -> void:
		if DemoMode.STEAM_URL != "":
			OS.shell_open(DemoMode.STEAM_URL)
		else:
			note.text = tr("demo.nourl")
			Chalk.wobble(note, 0.06, 0.5))
