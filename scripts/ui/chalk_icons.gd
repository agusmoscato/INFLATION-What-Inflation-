class_name ChalkIcons
extends RefCounted
## Íconos de los negocios dibujados por código con trazo de tiza (contorno grueso + relleno hachurado).
## Si existe assets/icons/<id>.png se usa ese dibujo; si no, este respaldo.
##
## Formato de cada operación (coordenadas normalizadas 0..1, y hacia abajo):
##   ["P", color, relleno, [x1,y1, x2,y2, ...]]   polígono cerrado
##   ["L", color, [x1,y1, x2,y2, ...]]            polilínea abierta
##   ["C", color, relleno, cx, cy, r]             círculo
##   ["E", color, relleno, cx, cy, rx, ry]        elipse
## Colores: w blanco, y amarillo, p rosa, b celeste, g verde, o naranja.

const ICONS: Dictionary = {
	"empanadas": [  # carrito de empanadas
		["P", "y", true, [0.08, 0.46, 0.20, 0.24, 0.78, 0.24, 0.90, 0.46]],
		["P", "w", false, [0.14, 0.46, 0.84, 0.46, 0.80, 0.70, 0.18, 0.70]],
		["L", "w", [0.50, 0.24, 0.50, 0.46]],
		["C", "o", true, 0.34, 0.58, 0.07],
		["C", "o", true, 0.56, 0.58, 0.07],
		["C", "b", false, 0.30, 0.82, 0.11],
		["C", "b", false, 0.72, 0.82, 0.11],
		["L", "w", [0.84, 0.54, 0.96, 0.40]],
	],
	"kiosco": [
		["P", "w", false, [0.14, 0.40, 0.86, 0.40, 0.86, 0.88, 0.14, 0.88]],
		["P", "p", true, [0.08, 0.40, 0.16, 0.16, 0.84, 0.16, 0.92, 0.40]],
		["L", "w", [0.38, 0.16, 0.34, 0.40]],
		["L", "w", [0.62, 0.16, 0.66, 0.40]],
		["P", "b", true, [0.24, 0.50, 0.76, 0.50, 0.76, 0.68, 0.24, 0.68]],
		["L", "y", [0.20, 0.76, 0.80, 0.76]],
	],
	"choripan": [
		["E", "o", true, 0.50, 0.62, 0.42, 0.16],
		["P", "p", true, [0.14, 0.44, 0.86, 0.44, 0.90, 0.56, 0.10, 0.56]],
		["L", "w", [0.28, 0.30, 0.22, 0.20, 0.30, 0.10]],
		["L", "w", [0.50, 0.30, 0.44, 0.20, 0.52, 0.10]],
		["L", "w", [0.72, 0.30, 0.66, 0.20, 0.74, 0.10]],
	],
	"lavadero": [  # balde con esponja
		["P", "b", true, [0.24, 0.40, 0.76, 0.40, 0.68, 0.88, 0.32, 0.88]],
		["L", "w", [0.24, 0.40, 0.50, 0.12, 0.76, 0.40]],
		["P", "y", true, [0.38, 0.22, 0.64, 0.22, 0.64, 0.40, 0.38, 0.40]],
		["C", "w", false, 0.18, 0.30, 0.06],
		["C", "w", false, 0.86, 0.20, 0.05],
		["C", "w", false, 0.80, 0.50, 0.04],
	],
	"panaderia": [  # medialuna
		["P", "o", true, [0.06, 0.72, 0.16, 0.42, 0.34, 0.24, 0.50, 0.20, 0.66, 0.24, 0.84, 0.42, 0.94, 0.72, 0.78, 0.72, 0.70, 0.52, 0.58, 0.42, 0.42, 0.42, 0.30, 0.52, 0.22, 0.72]],
		["L", "w", [0.34, 0.30, 0.38, 0.44]],
		["L", "w", [0.50, 0.24, 0.50, 0.40]],
		["L", "w", [0.66, 0.30, 0.62, 0.44]],
	],
	"almacen": [
		["P", "y", true, [0.08, 0.52, 0.46, 0.52, 0.46, 0.88, 0.08, 0.88]],
		["P", "o", true, [0.54, 0.52, 0.92, 0.52, 0.92, 0.88, 0.54, 0.88]],
		["P", "y", true, [0.28, 0.16, 0.68, 0.16, 0.68, 0.50, 0.28, 0.50]],
		["L", "w", [0.08, 0.70, 0.46, 0.70]],
		["L", "w", [0.54, 0.70, 0.92, 0.70]],
		["L", "w", [0.48, 0.16, 0.48, 0.50]],
	],
	"remiseria": [  # taxi
		["P", "y", true, [0.06, 0.70, 0.08, 0.56, 0.30, 0.50, 0.38, 0.32, 0.64, 0.32, 0.74, 0.50, 0.92, 0.56, 0.94, 0.70]],
		["P", "w", false, [0.42, 0.14, 0.58, 0.14, 0.58, 0.30, 0.42, 0.30]],
		["L", "w", [0.46, 0.38, 0.46, 0.50]],
		["L", "w", [0.58, 0.38, 0.58, 0.50]],
		["C", "w", true, 0.26, 0.74, 0.10],
		["C", "w", true, 0.74, 0.74, 0.10],
	],
	"verduleria": [  # tomate y zanahoria
		["C", "p", true, 0.34, 0.60, 0.24],
		["P", "g", true, [0.34, 0.32, 0.24, 0.26, 0.28, 0.40, 0.34, 0.36, 0.42, 0.42, 0.44, 0.28]],
		["P", "o", true, [0.60, 0.34, 0.92, 0.46, 0.68, 0.90]],
		["L", "g", [0.60, 0.34, 0.54, 0.20]],
		["L", "g", [0.62, 0.32, 0.68, 0.18]],
	],
	"fabrica": [
		["P", "w", true, [0.08, 0.88, 0.08, 0.46, 0.28, 0.58, 0.28, 0.42, 0.48, 0.58, 0.48, 0.42, 0.68, 0.58, 0.68, 0.88]],
		["P", "p", true, [0.72, 0.30, 0.86, 0.30, 0.86, 0.88, 0.72, 0.88]],
		["C", "b", false, 0.70, 0.16, 0.07],
		["C", "b", false, 0.84, 0.08, 0.06],
		["C", "y", false, 0.20, 0.72, 0.04],
		["C", "y", false, 0.44, 0.72, 0.04],
	],
	"cadena": [  # tres locales en fila
		["P", "y", true, [0.04, 0.86, 0.04, 0.50, 0.18, 0.32, 0.32, 0.50, 0.32, 0.86]],
		["P", "g", true, [0.34, 0.86, 0.34, 0.50, 0.50, 0.28, 0.66, 0.50, 0.66, 0.86]],
		["P", "b", true, [0.68, 0.86, 0.68, 0.50, 0.82, 0.32, 0.96, 0.50, 0.96, 0.86]],
		["P", "w", false, [0.42, 0.62, 0.58, 0.62, 0.58, 0.86, 0.42, 0.86]],
	],
	"banco": [
		["P", "b", true, [0.08, 0.34, 0.50, 0.10, 0.92, 0.34]],
		["L", "w", [0.22, 0.42, 0.22, 0.74]],
		["L", "w", [0.40, 0.42, 0.40, 0.74]],
		["L", "w", [0.60, 0.42, 0.60, 0.74]],
		["L", "w", [0.78, 0.42, 0.78, 0.74]],
		["P", "b", true, [0.08, 0.78, 0.92, 0.78, 0.92, 0.90, 0.08, 0.90]],
	],
	"bolsa": [  # gráfico en alza
		["L", "w", [0.12, 0.12, 0.12, 0.86, 0.92, 0.86]],
		["L", "g", [0.16, 0.72, 0.34, 0.50, 0.50, 0.62, 0.70, 0.30, 0.88, 0.18]],
		["L", "g", [0.74, 0.18, 0.88, 0.18, 0.86, 0.34]],
		["P", "y", true, [0.28, 0.64, 0.34, 0.64, 0.34, 0.82, 0.28, 0.82]],
		["P", "p", true, [0.56, 0.52, 0.62, 0.52, 0.62, 0.80, 0.56, 0.80]],
	],
	"cripto": [  # moneda y pico
		["C", "y", true, 0.52, 0.54, 0.32],
		["C", "y", false, 0.52, 0.54, 0.22],
		["L", "w", [0.46, 0.40, 0.46, 0.68]],
		["L", "w", [0.46, 0.40, 0.58, 0.42, 0.56, 0.52, 0.46, 0.52, 0.60, 0.56, 0.58, 0.68, 0.46, 0.68]],
		["L", "o", [0.06, 0.92, 0.34, 0.20]],
		["L", "o", [0.20, 0.16, 0.44, 0.12]],
	],
	"imprenta": [
		["P", "w", true, [0.08, 0.58, 0.92, 0.58, 0.92, 0.88, 0.08, 0.88]],
		["C", "b", false, 0.30, 0.50, 0.12],
		["P", "g", true, [0.34, 0.22, 0.82, 0.12, 0.88, 0.34, 0.40, 0.46]],
		["C", "w", false, 0.60, 0.28, 0.06],
	],
	"ceros": [  # un cero gigante
		["E", "p", true, 0.50, 0.52, 0.26, 0.40],
		["E", "p", false, 0.50, 0.52, 0.14, 0.26],
		["C", "w", false, 0.12, 0.20, 0.07],
		["C", "w", false, 0.88, 0.80, 0.07],
		["C", "w", false, 0.90, 0.20, 0.05],
	],
	"holding": [  # maletín con palmera
		["P", "w", true, [0.10, 0.40, 0.70, 0.40, 0.70, 0.86, 0.10, 0.86]],
		["L", "w", [0.28, 0.40, 0.28, 0.26, 0.52, 0.26, 0.52, 0.40]],
		["P", "y", true, [0.34, 0.58, 0.46, 0.58, 0.46, 0.68, 0.34, 0.68]],
		["L", "o", [0.84, 0.88, 0.84, 0.46]],
		["P", "g", true, [0.84, 0.46, 0.66, 0.34, 0.78, 0.30, 0.84, 0.38, 0.92, 0.28, 0.98, 0.36]],
	],
}


## Dibuja el ícono `id` dentro de `rect` (llamar desde _draw de un CanvasItem).
static func ops_for(id: String) -> Array:
	if ICONS.has(id):
		return ICONS[id]
	if ChalkDoodles.DOODLES.has(id):
		return ChalkDoodles.DOODLES[id]
	if ChalkDoodles.GOLD_ALIAS.has(id):
		return ops_for(str(ChalkDoodles.GOLD_ALIAS[id]))
	return []


static func draw(ci: CanvasItem, id: String, rect: Rect2, seed_v: int = 1, tint: Color = Color(0, 0, 0, 0)) -> void:
	var ops: Array = ops_for(id)
	if ops.is_empty():
		return
	if ChalkDoodles.GOLD_ALIAS.has(id):
		tint = Chalk.YELLOW
	var pad: float = rect.size.x * 0.06
	var r: Rect2 = rect.grow(-pad)
	var w: float = maxf(2.0, r.size.x * 0.05)
	var i: int = 0
	for op in ops:
		var kind: String = op[0]
		var col: Color = tint if tint.a > 0.0 else Chalk.key(op[1])
		var sv: int = seed_v * 31 + i * 7
		match kind:
			"P":
				var pts: PackedVector2Array = _pts(op[3], r)
				Chalk.polygon(ci, pts, col, w, sv, bool(op[2]), Color(col, 0.5), maxf(4.0, r.size.x * 0.085), 0.8)
			"L":
				Chalk.polyline(ci, _pts(op[2], r), col, w, sv, 0.8)
			"C":
				var c: Vector2 = r.position + Vector2(float(op[3]), float(op[4])) * r.size
				Chalk.circle(ci, c, float(op[5]) * r.size.x, col, w, sv, bool(op[2]), maxf(4.0, r.size.x * 0.085))
			"E":
				var c2: Vector2 = r.position + Vector2(float(op[3]), float(op[4])) * r.size
				var rx: float = float(op[5]) * r.size.x
				var ry: float = float(op[6]) * r.size.y
				Chalk.circle(ci, c2, ry, col, w, sv, bool(op[2]), maxf(4.0, r.size.x * 0.085), rx / maxf(ry, 0.001))
		i += 1


static func _pts(flat: Array, r: Rect2) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var k: int = 0
	while k + 1 < flat.size():
		out.append(r.position + Vector2(float(flat[k]), float(flat[k + 1])) * r.size)
		k += 2
	return out


## Textura personalizada si el usuario puso assets/icons/<id>.png (null si no hay).
static func custom_texture(id: String) -> Texture2D:
	var path: String = "res://assets/icons/%s.png" % id
	if ResourceLoader.exists(path):
		var t: Resource = load(path)
		if t is Texture2D:
			return t
	return null
