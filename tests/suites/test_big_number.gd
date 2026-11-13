extends RefCounted


func run(t) -> void:
	var BN = BigNumber
	# normalización
	var a: BigNumber = BN.from_float(1234.5)
	t.eq(a.e, 3, "exponente de 1234,5")
	t.near(a.m, 1.2345, "mantisa de 1234,5")
	t.check(BN.from_float(0.0).is_zero(), "cero")
	t.eq(BN.from_float(0.05).e, -2, "0,05 -> e=-2")
	# parseo
	t.eq(BN.from_string("1e100").e, 100, "parse 1e100")
	t.near(BN.from_string("4.5e42").m, 4.5, "parse mantisa 4.5e42")
	t.eq(BN.from_string("1500").e, 3, "parse 1500")
	t.eq(BN.from_string("1e500").e, 500, "parse más allá de float")
	# suma / resta
	t.near(BN.from_float(1.5).add(BN.from_float(2.25)).to_float(), 3.75, "1,5+2,25")
	t.near(BN.from_float(1000.0).sub(BN.from_float(1.0)).to_float(), 999.0, "1000-1")
	t.check(BN.from_float(5.0).sub(BN.from_float(5.0)).is_zero(), "5-5=0")
	t.check(BN.from_float(3.0).sub(BN.from_float(5.0)).is_negative(), "3-5<0")
	var big: BigNumber = BN.from_string("1e50")
	t.check(big.add(BN.one()).eq(big), "1e50 + 1 absorbe el 1")
	t.check(BN.one().add(big).eq(big), "1 + 1e50 absorbe el 1")
	t.eq(BN.from_string("9.99e5").add(BN.from_string("9.99e5")).e, 6, "acarreo de exponente")
	# producto / división
	var p: BigNumber = BN.from_string("3e200").mul(BN.from_string("4e200"))
	t.eq(p.e, 401, "3e200*4e200 exponente")
	t.near(p.m, 1.2, "3e200*4e200 mantisa")
	var d: BigNumber = BN.from_string("1e300").div(BN.from_string("1e-10"))
	t.eq(d.e, 310, "división con exponentes negativos")
	t.check(BN.zero().mul(big).is_zero(), "0 * grande = 0")
	t.check(BN.zero().div(big).is_zero(), "0 / grande = 0")
	# potencia
	t.near(BN.from_float(2.0).pow_f(10.0).to_float(), 1024.0, "2^10")
	t.near(BN.from_float(1.15).pow_f(100.0).to_float(), pow(1.15, 100.0), "1,15^100", 1e-9)
	t.eq(BN.from_string("1e100").pow_f(0.5).e, 50, "sqrt(1e100)")
	t.near(BN.from_float(16.0).sqrt_().to_float(), 4.0, "sqrt(16)")
	t.near(BN.from_float(10.0).pow_f(2.0).to_float(), 100.0, "10^2")
	# comparación
	t.check(BN.from_float(5.0).lt(BN.from_float(6.0)), "5<6")
	t.check(BN.from_string("1e20").gt(BN.from_string("9.9e19")), "1e20>9.9e19")
	t.check(BN.from_float(-1.0).lt(BN.zero()), "-1<0")
	t.check(BN.from_float(-1e5).lt(BN.from_float(-1e4)), "-1e5<-1e4")
	t.check(BN.from_float(2.0).ge(BN.from_float(2.0)), "2>=2")
	t.check(BN.from_string("1e-5").gt(BN.zero()), "1e-5>0")
	t.eq(BN.from_float(7.0).cmp(BN.from_float(7.0)), 0, "cmp igual")
	# log y conversión
	t.near(BN.from_string("1e100").log10(), 100.0, "log10(1e100)")
	t.near(BN.from_float(1000.0).log10(), 3.0, "log10(1000)")
	t.check(is_inf(BN.from_string("1e400").to_float()), "to_float satura")
	t.eq(BN.from_float(12345.0).floor_to_int(), 12345, "floor_to_int")
	# formato
	BN.notation = 0
	BN.decimal_comma = true
	t.eq(BN.from_float(0.0).format(), "0", "formato 0")
	t.eq(BN.from_float(12.0).format(), "12", "formato 12")
	t.eq(BN.from_float(1.5).format(), "1,5", "formato 1,5")
	t.eq(BN.from_float(999.0).format(), "999", "formato 999")
	t.eq(BN.from_float(1230000.0).format(), "1,23 M", "formato 1,23 M")
	t.eq(BN.from_float(1500.0).format(), "1,5 K", "formato 1,5 K")
	t.eq(BN.from_float(45000.0).format(), "45 K", "formato 45 K")
	t.eq(BN.from_string("4.5e42").format(), "4,5e42", "formato 4,5e42")
	t.eq(BN.from_string("2e9").format(), "2 B", "formato 2 B")
	BN.decimal_comma = false
	t.eq(BN.from_float(1230000.0).format(), "1.23 M", "formato con punto")
	BN.decimal_comma = true
	BN.notation = 1
	t.eq(BN.from_float(1230000.0).format(), "1,23e6", "formato científico")
	BN.notation = 2
	t.eq(BN.from_float(12300000.0).format(), "12,3e6", "formato ingeniería")
	BN.notation = 0
	# serialización
	var s: BigNumber = BN.from_string("1.234567890123e77")
	t.check(BN.from_string(s.to_save()).approx_eq(s, 1e-12), "ida y vuelta to_save/from_string")
	var neg: BigNumber = BN.from_float(-250.0)
	t.check(BN.from_string(neg.to_save()).eq(neg), "ida y vuelta negativo")
	# estrés: suma repetida no se desvía
	var acc: BigNumber = BN.zero()
	for i in range(1000):
		acc = acc.add(BN.from_float(0.1))
	t.near(acc.to_float(), 100.0, "1000 x 0,1", 1e-9)
