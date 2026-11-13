class_name BigNumber
extends RefCounted
## Número grande: mantisa (float, 1 <= |m| < 10) + exponente entero.
## Inmutable por convención: todas las operaciones devuelven una instancia nueva.

const LN10: float = 2.302585092994046
const SUFFIXES: Array = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

## 0 = abreviado ("1,23 M"), 1 = científico ("1,23e6"), 2 = ingeniería ("1,23e6" con exp. múltiplo de 3)
static var notation: int = 0
static var decimal_comma: bool = true

var m: float = 0.0
var e: int = 0


func _init(mantissa: float = 0.0, exponent: int = 0) -> void:
	m = mantissa
	e = exponent
	_normalize()


func _normalize() -> void:
	if m == 0.0 or is_nan(m):
		m = 0.0
		e = 0
		return
	if is_inf(m):
		m = 9.999999999 * signf(m)
		e += 308
		return
	var a: float = absf(m)
	if a >= 10.0 or a < 1.0:
		var d: int = floori(log(a) / LN10)
		m = m / pow(10.0, d)
		e += d
		a = absf(m)
		if a >= 10.0:
			m /= 10.0
			e += 1
		elif a < 1.0:
			m *= 10.0
			e -= 1


# ---------- construcción ----------
static func zero() -> BigNumber:
	return BigNumber.new(0.0, 0)


static func one() -> BigNumber:
	return BigNumber.new(1.0, 0)


static func from_float(x: float) -> BigNumber:
	return BigNumber.new(x, 0)


static func from_string(s: String) -> BigNumber:
	var t: String = s.strip_edges().to_lower().replace(",", ".")
	if t == "" or t == "0":
		return BigNumber.new(0.0, 0)
	var idx: int = t.find("e")
	if idx == -1:
		return BigNumber.new(t.to_float(), 0)
	var mant: float = t.substr(0, idx).to_float()
	var ex: int = t.substr(idx + 1).to_int()
	return BigNumber.new(mant, ex)


func copy() -> BigNumber:
	var b := BigNumber.new()
	b.m = m
	b.e = e
	return b


# ---------- consultas ----------
func is_zero() -> bool:
	return m == 0.0


func is_negative() -> bool:
	return m < 0.0


func sign_of() -> int:
	return 0 if m == 0.0 else (1 if m > 0.0 else -1)


func log10() -> float:
	if m <= 0.0:
		return -INF
	return log(m) / LN10 + float(e)


func to_float() -> float:
	if m == 0.0:
		return 0.0
	if e > 308:
		return INF * signf(m)
	if e < -320:
		return 0.0
	return m * pow(10.0, e)


func cmp(o: BigNumber) -> int:
	var sa: int = sign_of()
	var sb: int = o.sign_of()
	if sa != sb:
		return -1 if sa < sb else 1
	if sa == 0:
		return 0
	var r: int = 0
	if e != o.e:
		r = -1 if e < o.e else 1
	elif m != o.m:
		r = -1 if m < o.m else 1
	return r * sa


func lt(o: BigNumber) -> bool:
	return cmp(o) < 0


func le(o: BigNumber) -> bool:
	return cmp(o) <= 0


func gt(o: BigNumber) -> bool:
	return cmp(o) > 0


func ge(o: BigNumber) -> bool:
	return cmp(o) >= 0


func eq(o: BigNumber) -> bool:
	return cmp(o) == 0


func approx_eq(o: BigNumber, rel: float = 1e-9) -> bool:
	if m == 0.0 or o.m == 0.0:
		return m == o.m
	if e != o.e:
		# puede diferir por redondeo en el borde (9,9999… vs 1,0000…)
		var d: BigNumber = sub(o).abs_()
		return d.is_zero() or d.log10() - maxf(log10(), o.log10()) < log10_of_rel(rel)
	return absf(m - o.m) <= rel * absf(m)


static func log10_of_rel(rel: float) -> float:
	return log(rel) / LN10


# ---------- aritmética ----------
func abs_() -> BigNumber:
	return BigNumber.new(absf(m), e)


func neg() -> BigNumber:
	return BigNumber.new(-m, e)


func add(o: BigNumber) -> BigNumber:
	if o.m == 0.0:
		return self
	if m == 0.0:
		return o
	var d: int = e - o.e
	if d >= 16:
		return self
	if d <= -16:
		return o
	if d >= 0:
		return BigNumber.new(m + o.m * pow(10.0, -d), e)
	return BigNumber.new(m * pow(10.0, d) + o.m, o.e)


func sub(o: BigNumber) -> BigNumber:
	return add(o.neg())


func mul(o: BigNumber) -> BigNumber:
	return BigNumber.new(m * o.m, e + o.e)


func div(o: BigNumber) -> BigNumber:
	if o.m == 0.0:
		return BigNumber.new(0.0, 0) if m == 0.0 else BigNumber.new(9.999999999 * signf(m), 308)
	return BigNumber.new(m / o.m, e - o.e)


func mul_f(x: float) -> BigNumber:
	return BigNumber.new(m * x, e)


func add_f(x: float) -> BigNumber:
	return add(BigNumber.new(x, 0))


func div_f(x: float) -> BigNumber:
	return BigNumber.new(m / x, e)


## Potencia con exponente real. Solo definida para base positiva (0^p = 0 si p > 0).
func pow_f(p: float) -> BigNumber:
	if m <= 0.0:
		return BigNumber.new(0.0, 0) if p > 0.0 else BigNumber.new(1.0, 0)
	var l: float = log10() * p
	var ei: int = floori(l)
	return BigNumber.new(pow(10.0, l - float(ei)), ei)


func sqrt_() -> BigNumber:
	return pow_f(0.5)


## Piso para valores enteros "chicos"; devuelve int (satura en 2^62).
func floor_to_int() -> int:
	if m <= 0.0:
		return 0
	if e >= 18:
		return 4611686018427387904
	return int(floorf(to_float()))


static func max_of(a: BigNumber, b: BigNumber) -> BigNumber:
	return a if a.cmp(b) >= 0 else b


static func min_of(a: BigNumber, b: BigNumber) -> BigNumber:
	return a if a.cmp(b) <= 0 else b


# ---------- serialización ----------
func to_save() -> String:
	return String.num(m, 14) + "e" + str(e)


# ---------- formato ----------
static func _trim(v: float, decimals: int) -> String:
	var s: String = ("%." + str(decimals) + "f") % v
	if s.find(".") != -1:
		s = s.rstrip("0").rstrip(".")
	if decimal_comma:
		s = s.replace(".", ",")
	return s


func format(decimals: int = 2) -> String:
	if m == 0.0:
		return "0"
	var prefix: String = "-" if m < 0.0 else ""
	var a: float = absf(m)
	if e < 3:
		var v: float = a * pow(10.0, e)
		var d: int = decimals
		if v >= 100.0:
			d = 0
		elif v >= 10.0:
			d = mini(decimals, 1)
		return prefix + _trim(v, d)
	match notation:
		1:
			return prefix + _trim(a, decimals) + "e" + str(e)
		2:
			var r: int = posmod(e, 3)
			return prefix + _trim(a * pow(10.0, r), decimals) + "e" + str(e - r)
		_:
			var idx: int = e / 3
			if idx < SUFFIXES.size():
				var r2: int = e % 3
				return prefix + _trim(a * pow(10.0, r2), decimals) + " " + str(SUFFIXES[idx])
			return prefix + _trim(a, decimals) + "e" + str(e)


func _to_string() -> String:
	return format()
