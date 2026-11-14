extends SceneTree
## Test runner propio, sin dependencias.
## Uso: godot --headless --script tests/run_tests.gd
## (la primera vez, correr antes: godot --headless --import)

var passed: int = 0
var failed: int = 0
var current_suite: String = ""

const SUITES: Array = [
	"res://tests/suites/test_big_number.gd",
	"res://tests/suites/test_economy.gd",
	"res://tests/suites/test_tree.gd",
	"res://tests/suites/test_save.gd",
	"res://tests/suites/test_stickers.gd",
	"res://tests/suites/test_content.gd",
]


func _init() -> void:
	for path in SUITES:
		if not ResourceLoader.exists(path):
			continue
		var script: GDScript = load(path)
		var suite: RefCounted = script.new()
		current_suite = path.get_file().get_basename()
		print("== ", current_suite)
		suite.run(self)
	print("")
	print("Resultado: %d OK, %d fallos" % [passed, failed])
	quit(1 if failed > 0 else 0)


func check(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		printerr("  FALLA [%s] %s" % [current_suite, msg])


func eq(a: Variant, b: Variant, msg: String) -> void:
	check(a == b, "%s (esperado %s, obtenido %s)" % [msg, str(b), str(a)])


func near(a: float, b: float, msg: String, rel: float = 1e-6) -> void:
	var ok: bool = absf(a - b) <= rel * maxf(absf(a), absf(b)) or absf(a - b) < 1e-12
	check(ok, "%s (esperado %s, obtenido %s)" % [msg, str(b), str(a)])
