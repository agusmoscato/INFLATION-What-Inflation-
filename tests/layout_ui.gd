extends Control
## Prueba de layout (headless): godot --headless res://tests/LayoutUI.tscn
##  1. Textos de tarjetas: todas las mejoras, en español e inglés, con el precio más largo y con su condición, entran en
##     la tarjeta sin cortarse (la letra se achica; el nombre puede ir en dos líneas).
## Termina con código 1 si algo falla (y lo lista).

var failures: Array = []


func _ready() -> void:
	SaveSystem.save_path = "user://test_layout_save.json"
	Settings.path = "user://test_layout_settings.cfg"
	I18n.load_all()
	Chalk.load_fonts()
	_check_cards()
	_finish()


func _check_cards() -> void:
	var m: GameModel = GameModel.new(5)
	var n: int = 0
	for lang in ["es", "en"]:
		TranslationServer.set_locale(lang)
		for u in GameData.upgrades:
			for locked in [false, true]:
				var ic: UpgradeIcon = UpgradeIcon.new(u, locked)
				ic.price_text = "$888,88 Qad"
				ic.cond_text = EconomyLogic.upgrade_condition_text(m, u) if locked else ""
				add_child(ic)
				for p in ic.text_layout()["problems"]:
					failures.append("[%s] %s: %s" % [lang, str(u["id"]), p])
				ic.queue_free()
				n += 1
	TranslationServer.set_locale("es")
	var sample: UpgradeIcon = UpgradeIcon.new(GameData.upgrades[GameData.upgrade_idx["syn_1"]])
	print("tarjetas revisadas: %d (ejemplo syn_1: %s / %s)" % [n, str(sample.text_layout()["name"]), UpgradeIcon.effect(sample.upg)])
	sample.free()


func _finish() -> void:
	SaveSystem.delete_save()
	DirAccess.remove_absolute(Settings.path)
	for f in failures:
		printerr("LAYOUT FALLA: ", f)
	print("LAYOUT %s (%d problemas)" % ["OK" if failures.is_empty() else "FALLA", failures.size()])
	get_tree().quit(1 if not failures.is_empty() else 0)
