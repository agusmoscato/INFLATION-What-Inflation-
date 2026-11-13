class_name CreditsScreen
extends Control
## Créditos / pantalla de final. Si viene de ganar, ofrece seguir jugando.

signal back_to_menu
signal keep_playing

var victory: bool = false
var _scroll: Label
var _y: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v: VBoxContainer = VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	add_child(v)
	if victory:
		var t: Label = UIKit.label(tr("ui.credits.win"), 44, UIKit.C_GREEN, HORIZONTAL_ALIGNMENT_CENTER)
		v.add_child(t)
		var m: GameModel = GameState.m
		var stats: Label = UIKit.label(tr("ui.credits.stats") % [UIKit.duration(m.time_played), m.reforms, m.plans_done, m.zeros_cut], 18, UIKit.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		v.add_child(stats)
	var title: Label = UIKit.label("INFLATION?", 64, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(title)
	v.add_child(UIKit.label("What Inflation?", 30, UIKit.C_TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	var body: Label = UIKit.label(tr("ui.credits.body"), 18, UIKit.C_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(700, 0)
	var holder: CenterContainer = CenterContainer.new()
	holder.add_child(body)
	v.add_child(holder)
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	if victory:
		var k: Button = Button.new()
		k.text = tr("ui.credits.continue")
		k.custom_minimum_size = Vector2(240, 48)
		UIKit.style_button(k, UIKit.C_GREEN.darkened(0.2), 18)
		k.pressed.connect(func() -> void: keep_playing.emit())
		row.add_child(k)
	var b: Button = Button.new()
	b.text = tr("ui.credits.menu")
	b.custom_minimum_size = Vector2(240, 48)
	UIKit.style_button(b, UIKit.C_BLUE, 18)
	b.pressed.connect(func() -> void: back_to_menu.emit())
	row.add_child(b)
