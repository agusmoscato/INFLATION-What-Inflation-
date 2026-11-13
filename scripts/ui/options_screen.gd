class_name OptionsScreen
extends Control
## Opciones: volumen, música, idioma, notación numérica y pantalla completa.

signal closed
signal language_changed


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var p: PanelContainer = UIKit.panel(UIKit.C_PANEL, 14)
	p.custom_minimum_size = Vector2(560, 0)
	center.add_child(p)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	v.add_child(UIKit.label(tr("ui.options"), 34, UIKit.C_GOLD, HORIZONTAL_ALIGNMENT_CENTER))

	v.add_child(UIKit.label(tr("ui.opt.volume"), 16, UIKit.C_DIM))
	v.add_child(_slider(Settings.volume, func(val: float) -> void:
		Settings.volume = val
		Settings.apply()
		Settings.save_settings()))
	v.add_child(UIKit.label(tr("ui.opt.music"), 16, UIKit.C_DIM))
	v.add_child(_slider(Settings.music, func(val: float) -> void:
		Settings.music = val
		Settings.apply()
		Settings.save_settings()))

	v.add_child(UIKit.label(tr("ui.opt.language"), 16, UIKit.C_DIM))
	var lang: OptionButton = OptionButton.new()
	lang.add_item("Español", 0)
	lang.add_item("English", 1)
	lang.selected = 0 if Settings.language == "es" else 1
	lang.item_selected.connect(func(i: int) -> void:
		Settings.language = "es" if i == 0 else "en"
		Settings.apply()
		Settings.save_settings()
		language_changed.emit())
	v.add_child(lang)

	v.add_child(UIKit.label(tr("ui.opt.notation"), 16, UIKit.C_DIM))
	var nota: OptionButton = OptionButton.new()
	nota.add_item(tr("ui.opt.notation.short"), 0)
	nota.add_item(tr("ui.opt.notation.sci"), 1)
	nota.add_item(tr("ui.opt.notation.eng"), 2)
	nota.selected = Settings.notation
	nota.item_selected.connect(func(i: int) -> void:
		Settings.notation = i
		Settings.apply()
		Settings.save_settings())
	v.add_child(nota)

	v.add_child(UIKit.label(tr("ui.opt.quality"), 16, UIKit.C_DIM))
	var qual: OptionButton = OptionButton.new()
	qual.add_item(tr("ui.opt.quality.high"), 0)
	qual.add_item(tr("ui.opt.quality.mid"), 1)
	qual.add_item(tr("ui.opt.quality.low"), 2)
	qual.selected = Settings.quality
	qual.item_selected.connect(func(i: int) -> void:
		Settings.quality = i
		Settings.apply()
		Settings.save_settings())
	v.add_child(qual)

	var fs: CheckBox = CheckBox.new()
	fs.text = tr("ui.opt.fullscreen")
	fs.button_pressed = Settings.fullscreen
	fs.toggled.connect(func(on: bool) -> void:
		Settings.fullscreen = on
		Settings.apply()
		Settings.save_settings())
	v.add_child(fs)

	var back: Button = Button.new()
	back.text = tr("ui.back")
	back.custom_minimum_size = Vector2(0, 46)
	UIKit.style_button(back, UIKit.C_BLUE, 20)
	back.pressed.connect(func() -> void: closed.emit())
	v.add_child(back)


func _slider(value: float, cb: Callable) -> HSlider:
	var s: HSlider = HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(0, 24)
	s.value_changed.connect(cb)
	return s
