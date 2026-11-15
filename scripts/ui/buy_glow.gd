class_name BuyGlow
extends Control
## Capa encima de una fila de negocio (o cualquier caja) que dice de un vistazo si se puede comprar:
##  - comprable: borde grueso verde que late y, cada tanto, una chispa de tiza que salta en el borde;
##  - no alcanza: una barrita de progreso (plata / precio) debajo del botón de compra.
## No recibe el mouse ni cuenta para el QA de layout (es un adorno encima de la fila).

var on: bool = false                  ## se puede comprar ya
var progress: float = -1.0            ## 0..1 hacia el precio (-1: sin barrita)
var bar_rect: Rect2 = Rect2()         ## dónde va la barrita (coordenadas locales), la calcula quien la usa
var _t: float = 0.0
var _spark_t: float = -9.0
var _spark_at: float = 0.0            ## 0..1 alrededor del borde
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_meta("qa_ignore", true)
	_rng.seed = get_instance_id()
	_t = _rng.randf() * 3.0


func set_state(can: bool, prog: float, bar: Rect2) -> void:
	if can != on or absf(prog - progress) > 0.01 or bar != bar_rect:
		on = can
		progress = prog
		bar_rect = bar
		queue_redraw()


func _process(delta: float) -> void:
	if not on:
		return
	_t += delta
	if _t - _spark_t > 1.4 + _rng.randf() * 0.8:
		_spark_t = _t
		_spark_at = _rng.randf()
	queue_redraw()


func _draw() -> void:
	if on:
		draw_pulse_border(self, Rect2(Vector2.ZERO, size), _t)
		var k: float = (_t - _spark_t) / 0.5
		if k >= 0.0 and k <= 1.0:
			draw_spark(self, border_point(Rect2(Vector2.ZERO, size), _spark_at), k)
	elif progress >= 0.0 and bar_rect.size.x > 0.0:
		draw_rect(bar_rect, Color(1, 1, 1, 0.14))
		draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * clampf(progress, 0.0, 1.0), bar_rect.size.y)), Color(Chalk.GREEN, 0.85))


## Borde grueso verde que late (lo usan también las tarjetas de mejoras).
static func draw_pulse_border(ci: CanvasItem, r: Rect2, t: float) -> void:
	var a: float = 0.6 + 0.4 * sin(t * 5.0)
	ci.draw_rect(r.grow(-2.0), Color(Chalk.GREEN, a), false, 4.0)
	ci.draw_rect(r.grow(-6.0), Color(Chalk.GREEN, a * 0.25), false, 2.0)


## Un punto del borde del rectángulo: f en 0..1 recorre el perímetro.
static func border_point(r: Rect2, f: float) -> Vector2:
	var per: float = 2.0 * (r.size.x + r.size.y)
	var d: float = fposmod(f, 1.0) * per
	if d < r.size.x:
		return r.position + Vector2(d, 2.0)
	d -= r.size.x
	if d < r.size.y:
		return r.position + Vector2(r.size.x - 2.0, d)
	d -= r.size.y
	if d < r.size.x:
		return r.position + Vector2(r.size.x - d, r.size.y - 2.0)
	d -= r.size.x
	return r.position + Vector2(2.0, r.size.y - d)


## Chispa de tiza: una estrellita de 4 rayas que crece y se apaga (k: 0..1 de su vida).
static func draw_spark(ci: CanvasItem, p: Vector2, k: float) -> void:
	var len: float = 4.0 + 9.0 * sin(k * PI)
	var col: Color = Color(Chalk.YELLOW, 1.0 - k)
	for i in range(4):
		var a: float = PI / 4.0 * float(i) + k * 0.6
		var d: Vector2 = Vector2(cos(a), sin(a)) * len * (1.0 if i % 2 == 0 else 0.55)
		ci.draw_line(p - d, p + d, col, 2.0, true)
