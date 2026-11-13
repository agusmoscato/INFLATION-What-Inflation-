extends RefCounted


func _m(money: float = 1e6) -> GameModel:
	var m: GameModel = GameModel.new(33)
	m.era = 3
	m.money = BigNumber.from_float(money)
	m.unlocked["timba"] = true
	m.unlocked["quiniela"] = true
	m.unlocked["dollar"] = true
	return m


func run(t) -> void:
	# la tabla de la raspadita suma 1
	var sum_p: float = 0.0
	for row in GambleLogic.SCRATCH_TABLE:
		sum_p += float(row[1])
	t.near(sum_p, 1.0, "las probabilidades de la raspadita suman 1")
	# valor esperado levemente negativo (-5 % a -10 %), con la racha de mala suerte incluida
	var ev: float = GambleLogic.scratch_expected_value(600000, 0.0)
	t.check(ev > 0.90 and ev < 0.95, "EV de la raspadita sin bonus entre -10 %% y -5 %% (%.3f)" % ev)
	# con todas las páginas del álbum (+7,5 %) se acerca a 0 pero sigue sin ser positivo
	var ev_luck: float = GambleLogic.scratch_expected_value(600000, 0.075)
	t.check(ev_luck > 0.95 and ev_luck < 1.0, "con el álbum completo el EV se acerca a 0 sin ser positivo (%.3f)" % ev_luck)
	# quiniela: valor esperado exacto por enumeración (después de la comisión del 30 %)
	var ev_q: float = (0.01 * GambleLogic.QUINIELA_EXACT + 0.09 * GambleLogic.QUINIELA_LAST) * (1.0 - GambleLogic.QUINIELA_COMMISSION)
	t.check(ev_q > 0.90 and ev_q < 0.95, "EV de la quiniela entre -10 %% y -5 %% (%.3f)" % ev_q)
	# timba del dólar: 50/50 pagando x1,9 => 0,95
	var md: GameModel = _m()
	var wins: int = 0
	for i in range(20000):
		md.dollar_bet = {"dir": "up", "threshold": 0.08, "stake": "1e0"}
		var r: Dictionary = GambleLogic.settle_dollar(md, 0.08)
		if r["won"]:
			wins += 1
		md.money = BigNumber.from_float(1e6)
	var ev_d: float = float(wins) / 20000.0 * GambleLogic.DOLLAR_PAYOUT
	t.check(ev_d > 0.90 and ev_d < 0.99, "EV de la timba del dólar levemente negativo (%.3f)" % ev_d)

	# ---- raspadita ----
	var m: GameModel = _m()
	m.owned["kiosco"] = 1
	m.base_income = BigNumber.from_float(100.0)
	m.dirty = false
	var cap: BigNumber = GambleLogic.cap(m)
	t.near(cap.to_float(), 100.0 * 600.0, "el tope es 10 minutos de ingresos")
	var before: float = m.money.to_float()
	var r2: Dictionary = GambleLogic.play_scratch(m, 0.05, "x2")
	t.check(r2["ok"], "se puede jugar")
	t.near((r2["price"] as BigNumber).to_float(), minf(before * 0.05, cap.to_float() / 10.0), "el precio es 5 %% de la plata, acotado")
	t.near(m.money.to_float(), before - (r2["price"] as BigNumber).to_float() + (r2["prize"] as BigNumber).to_float(), "se descuenta y se cobra el premio")
	t.near((r2["prize"] as BigNumber).to_float(), 2.0 * (r2["price"] as BigNumber).to_float(), "x2 paga el doble de lo apostado")
	# ningún premio supera el tope, ni siquiera x10 con apuesta máxima y suerte
	var mc: GameModel = _m(1e12)
	mc.base_income = BigNumber.from_float(10.0)
	mc.dirty = false
	for p in range(6):
		StickerLogic.give(mc, StickerLogic.page_ids(p)[0])
	for id in StickerLogic.page_ids(0):
		StickerLogic.give(mc, id)
	var big: Dictionary = GambleLogic.play_scratch(mc, 0.10, "x10")
	t.check((big["prize"] as BigNumber).le(GambleLogic.cap(mc)), "el premio x10 no supera el tope de 10 minutos")
	# el pozo crece con cada raspadita y se cobra de una vez
	var mp: GameModel = _m()
	mp.base_income = BigNumber.from_float(1000.0)
	mp.dirty = false
	for i in range(30):
		GambleLogic.play_scratch(mp, 0.01, "nothing")
	t.check(mp.pool_real.gt(BigNumber.zero()), "el pozo crece")
	var pool_before: float = mp.pool_real.to_float()
	var pz: Dictionary = GambleLogic.play_scratch(mp, 0.01, "pozo")
	t.check(pz["pozo"] and (pz["prize"] as BigNumber).to_float() >= pool_before * 0.9, "el pozo paga lo acumulado")
	t.eq(mp.pozo_wins, 1, "pozo contado")
	# sobre y dorada como premio
	var mk: GameModel = _m()
	var pk: Dictionary = GambleLogic.play_scratch(mk, 0.05, "pack")
	t.eq((pk["pack"] as Array).size(), 5, "el premio sobre trae 5 figuritas")
	var gd: Dictionary = GambleLogic.play_scratch(mk, 0.05, "golden")
	t.check(gd["sticker"] != "" and StickerLogic.def(gd["sticker"])["rarity"] == "golden", "el premio dorada da una figurita dorada")
	t.eq(mk.gold_scratches, 1, "dorada de raspadita contada")
	# racha de mala suerte: tras 5 pérdidas seguidas, premio asegurado (chico)
	var ms: GameModel = _m()
	for i in range(5):
		GambleLogic.play_scratch(ms, 0.01, "nothing")
	t.eq(ms.loss_streak, 5, "5 pérdidas seguidas")
	t.eq(GambleLogic.roll_outcome(ms), "pity", "la próxima raspadita tiene premio asegurado")
	var pr: Dictionary = GambleLogic.play_scratch(ms, 0.01)
	t.eq(pr["outcome"], "pity", "se juega el premio asegurado")
	t.check(not (pr["prize"] as BigNumber).is_zero(), "el premio asegurado paga algo")
	t.eq(ms.loss_streak, 0, "la racha se reinicia")
	t.check(ms.loss_streak_max >= 5, "se recuerda la peor racha")
	# estadísticas de timba
	t.check(ms.gamble_lost.gt(BigNumber.zero()), "se registra lo perdido")
	t.check(ms.gamble_best.gt(BigNumber.zero()), "se registra el mejor premio")
	# la timba no acelera las eras: el premio no cuenta como ganancia real
	var ml: GameModel = _m()
	var life: BigNumber = ml.lifetime_real
	GambleLogic.play_scratch(ml, 0.10, "x10")
	t.check(ml.lifetime_real.eq(life), "ganar en la timba no suma ganancia real del juego")
	# sin plata o bloqueada no se puede
	var mz: GameModel = _m(0.0)
	t.check(not GambleLogic.play_scratch(mz, 0.05)["ok"], "sin plata no hay raspadita")
	var mb: GameModel = GameModel.new(1)
	mb.money = BigNumber.from_float(100.0)
	t.check(not GambleLogic.play_scratch(mb, 0.05)["ok"], "la timba está bloqueada al inicio")

	# ---- quiniela ----
	var mq: GameModel = _m()
	mq.base_income = BigNumber.from_float(1000.0)
	mq.dirty = false
	var m0: float = mq.money.to_float()
	t.check(GambleLogic.place_quiniela(mq, 37, BigNumber.from_float(100.0)), "se juega a la quiniela")
	t.near(mq.money.to_float(), m0 - 100.0, "la apuesta se descuenta")
	var d1: Dictionary = GambleLogic.draw_quiniela(mq, 37)
	t.eq(d1["kind"], "exact", "2 cifras")
	t.near((d1["payout"] as BigNumber).to_float(), 100.0 * 0.7 * 70.0, "2 cifras pagan x70 sobre lo que juega tras la comisión")
	t.eq(mq.quiniela_wins, 1, "quiniela acertada contada")
	GambleLogic.place_quiniela(mq, 37, BigNumber.from_float(100.0))
	var d2: Dictionary = GambleLogic.draw_quiniela(mq, 57)
	t.eq(d2["kind"], "last", "última cifra")
	t.near((d2["payout"] as BigNumber).to_float(), 100.0 * 0.7 * 7.0, "la última cifra paga x7")
	GambleLogic.place_quiniela(mq, 37, BigNumber.from_float(100.0))
	var d3: Dictionary = GambleLogic.draw_quiniela(mq, 12)
	t.eq(d3["kind"], "none", "sin acierto")
	t.check((d3["payout"] as BigNumber).is_zero(), "sin acierto no se cobra")
	t.check(GambleLogic.draw_quiniela(mq).is_empty(), "sin boleta no hay sorteo")
	t.check(not GambleLogic.place_quiniela(mq, 100, BigNumber.from_float(1.0)), "el número va de 00 a 99")
	# el sorteo ocurre solo al cerrar el mes
	var mm: GameModel = _m()
	GambleLogic.place_quiniela(mm, 5, BigNumber.from_float(50.0))
	EconomyLogic.month_end(mm)
	t.check(mm.quiniela.is_empty(), "al cerrar el mes se sortea la boleta")
	# tope: una apuesta enorme se recorta para que ningún premio supere 10 minutos de ingresos
	var mt: GameModel = _m(1e12)
	mt.base_income = BigNumber.from_float(10.0)
	mt.dirty = false
	GambleLogic.place_quiniela(mt, 1, BigNumber.from_float(1e10))
	var dt: Dictionary = GambleLogic.draw_quiniela(mt, 1)
	t.check((dt["payout"] as BigNumber).le(GambleLogic.cap(mt)), "el premio de la quiniela respeta el tope")

	# ---- timba del dólar ----
	var mdo: GameModel = _m()
	mdo.base_income = BigNumber.from_float(1000.0)
	mdo.dirty = false
	var thr: float = GambleLogic.dollar_threshold(mdo)
	t.near(thr, 0.15, "el umbral es la tasa vigente (Era 3 = 15 %)")
	var md0: float = mdo.money.to_float()
	t.check(GambleLogic.place_dollar(mdo, "up", BigNumber.from_float(100.0)), "se apuesta a que sube")
	var s1: Dictionary = GambleLogic.settle_dollar(mdo, 0.15, 0.30)
	t.check(s1["won"], "el dato oficial quedó arriba: gana")
	t.near(mdo.money.to_float(), md0 - 100.0 + 190.0, "paga x1,9")
	GambleLogic.place_dollar(mdo, "down", BigNumber.from_float(100.0))
	var s2: Dictionary = GambleLogic.settle_dollar(mdo, 0.15, 0.30)
	t.check(not s2["won"], "apostó abajo y quedó arriba: pierde")
	t.eq(mdo.dollar_wins, 1, "victorias de dólar contadas")
	# pistas reales de los eventos activos
	var mh: GameModel = _m()
	t.check(GambleLogic.dollar_hint(mh).is_empty(), "sin eventos no hay pista")
	EconomyLogic.start_event(mh, "corrida", 0)
	var hint: Dictionary = GambleLogic.dollar_hint(mh)
	t.eq(hint["event"], "corrida", "la corrida cambiaria es una pista")
	t.near(float(hint["mult"]), 2.0, "la corrida duplica la inflación")
	# se guarda y se carga
	var m2: GameModel = GameModel.new(1)
	m2.from_dict(JSON.parse_string(JSON.stringify(mq.to_dict())))
	t.eq(m2.quiniela_wins, mq.quiniela_wins, "las estadísticas de timba se guardan")
	t.check(m2.gamble_best.approx_eq(mq.gamble_best), "el mejor premio se guarda")
