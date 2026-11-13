class_name GambleLogic
extends RefCounted
## Timba del kiosco: raspadita, quiniela del mes y timba del dólar. SIEMPRE con plata del juego: no hay dinero real
## ni microtransacciones. Valor esperado levemente negativo; ningún premio supera 10 minutos de ingresos actuales.

const CAP_SECONDS: float = 600.0          ## tope de cualquier premio: 10 min de ingresos
const CAP_FLOOR_P: float = 50.0           ## piso del tope (en niveles de precios) para el inicio del juego
const STAKE_PCTS: Array = [0.01, 0.05, 0.10]

# ---- raspadita ----
## Probabilidades de la raspadita (suman 1). Valor esperado ~0,93 de lo apostado con la racha de mala suerte incluida.
const SCRATCH_TABLE: Array = [
	["nothing", 0.765],
	["x2", 0.17],
	["x10", 0.025],
	["pack", 0.035],
	["golden", 0.0045],
	["pozo", 0.0005],
]
const POZO_FEED: float = 0.10             ## el 10 % de cada raspadita alimenta el pozo
const PITY_STREAK: int = 5                ## tras 5 pérdidas seguidas, la próxima raspadita paga seguro
const PITY_MULT: float = 1.5
const LUCK_PER_PAGE: float = 0.0125       ## cada página completa del álbum mejora un poco los premios en plata (6 páginas: +7,5 %)
const VALUE_PACK: float = 3.0             ## para el valor esperado: un sobre equivale a 3 veces lo apostado...
const VALUE_GOLDEN: float = 20.0          ## ...y una dorada a 20

# ---- quiniela ----
const QUINIELA_COMMISSION: float = 0.30   ## el quinielero se queda el 30 % de la apuesta
const QUINIELA_EXACT: float = 70.0        ## 2 cifras
const QUINIELA_LAST: float = 7.0          ## última cifra

# ---- timba del dólar ----
const DOLLAR_PAYOUT: float = 1.9
const DOLLAR_NOISE: float = 0.25          ## dispersión del "dato oficial" respecto de la tasa real


# =====================================================================
#  Topes y apuestas
# =====================================================================
## Mayor premio posible (nominal): 10 minutos de ingresos actuales (con un piso al inicio).
static func cap(m: GameModel) -> BigNumber:
	return BigNumber.max_of(EconomyLogic.income_per_sec(m).mul_f(CAP_SECONDS), m.price_level.mul_f(CAP_FLOOR_P))


static func luck(m: GameModel) -> float:
	return LUCK_PER_PAGE * float(StickerLogic.pages_done(m))


static func scratch_stake_max(m: GameModel) -> BigNumber:
	return cap(m).div_f(10.0)


static func quiniela_stake_max(m: GameModel) -> BigNumber:
	return cap(m).div_f(QUINIELA_EXACT * (1.0 - QUINIELA_COMMISSION))


static func dollar_stake_max(m: GameModel) -> BigNumber:
	return cap(m).div_f(DOLLAR_PAYOUT)


## Apuesta como % de tu plata, acotada por el máximo permitido.
static func stake_for(m: GameModel, pct: float, max_stake: BigNumber) -> BigNumber:
	return BigNumber.min_of(m.money.mul_f(pct), max_stake)


# =====================================================================
#  Estadísticas (en pesos reales)
# =====================================================================
static func _record(m: GameModel, price: BigNumber, prize: BigNumber, win_for_streak: bool) -> void:
	var pr: BigNumber = price.div(m.price_level)
	var zr: BigNumber = prize.div(m.price_level)
	if zr.gt(pr):
		m.gamble_won = m.gamble_won.add(zr.sub(pr))
	else:
		m.gamble_lost = m.gamble_lost.add(pr.sub(zr))
	if zr.gt(m.gamble_best):
		m.gamble_best = zr
	if win_for_streak:
		m.loss_streak = 0
	else:
		m.loss_streak += 1
		m.loss_streak_max = maxi(m.loss_streak_max, m.loss_streak)


# =====================================================================
#  Raspadita
# =====================================================================
static func roll_outcome(m: GameModel, force: String = "") -> String:
	if force != "":
		return force
	if m.loss_streak >= PITY_STREAK:
		return "pity"
	var r: float = m.rng.randf()
	for row in SCRATCH_TABLE:
		r -= float(row[1])
		if r <= 0.0:
			return str(row[0])
	return "nothing"


## Compra y juega una raspadita. El resultado ya queda aplicado; la UI solo lo revela.
## Devuelve {ok, price, outcome, prize (nominal), pack (figuritas), sticker (id), pozo}.
static func play_scratch(m: GameModel, pct: float, force: String = "") -> Dictionary:
	if not Unlocks.has(m, "timba"):
		return {"ok": false}
	var price: BigNumber = stake_for(m, pct, scratch_stake_max(m))
	if price.is_zero() or price.gt(m.money):
		return {"ok": false}
	m.money = m.money.sub(price)
	m.scratches += 1
	m.pool_real = m.pool_real.add(price.div(m.price_level).mul_f(POZO_FEED))
	var outcome: String = roll_outcome(m, force)
	var lk: float = 1.0 + luck(m)
	var limit: BigNumber = cap(m)
	var prize: BigNumber = BigNumber.zero()
	var res: Dictionary = {"ok": true, "price": price, "outcome": outcome, "prize": prize, "pack": [], "sticker": "", "pozo": false}
	var win: bool = true
	match outcome:
		"nothing":
			win = false
		"x2":
			prize = BigNumber.min_of(price.mul_f(2.0 * lk), limit)
		"x10":
			prize = BigNumber.min_of(price.mul_f(10.0 * lk), limit)
		"pity":
			prize = BigNumber.min_of(price.mul_f(PITY_MULT * lk), limit)
		"pack":
			res["pack"] = StickerLogic.gift_pack(m)
		"golden":
			var g: Dictionary = StickerLogic.award(m, "golden")
			res["sticker"] = g["id"]
			m.gold_scratches += 1
		"pozo":
			var pool_nominal: BigNumber = m.pool_real.mul(m.price_level)
			prize = BigNumber.min_of(BigNumber.max_of(pool_nominal, price.mul_f(10.0)), limit)
			m.pool_real = BigNumber.max_of(m.pool_real.sub(prize.div(m.price_level)), BigNumber.zero())
			m.pozo_wins += 1
			res["pozo"] = true
	m.money = m.money.add(prize)
	res["prize"] = prize
	_record(m, price, prize, win)
	m.push("scratched", [outcome])
	return res


# =====================================================================
#  Quiniela del mes
# =====================================================================
static func place_quiniela(m: GameModel, number: int, stake: BigNumber) -> bool:
	if not Unlocks.has(m, "quiniela") or number < 0 or number > 99 or stake.is_zero():
		return false
	if stake.gt(quiniela_stake_max(m)):
		stake = quiniela_stake_max(m)
	# si ya había boleta se devuelve y se reemplaza
	if not m.quiniela.is_empty():
		m.money = m.money.add(BigNumber.from_string(str(m.quiniela["stake"])))
		m.quiniela = {}
	if stake.gt(m.money):
		return false
	m.money = m.money.sub(stake)
	m.quiniela = {"number": number, "stake": stake.to_save()}
	return true


## Sorteo de fin de mes. Devuelve {} si no había boleta.
static func draw_quiniela(m: GameModel, forced: int = -1) -> Dictionary:
	if m.quiniela.is_empty():
		return {}
	var number: int = int(m.quiniela["number"])
	var stake: BigNumber = BigNumber.from_string(str(m.quiniela["stake"]))
	m.quiniela = {}
	var winning: int = forced if forced >= 0 else m.rng.randi_range(0, 99)
	var net: BigNumber = stake.mul_f(1.0 - QUINIELA_COMMISSION)
	var kind: String = "none"
	var payout: BigNumber = BigNumber.zero()
	if winning == number:
		kind = "exact"
		payout = BigNumber.min_of(net.mul_f(QUINIELA_EXACT * (1.0 + luck(m))), cap(m))
		m.quiniela_wins += 1
	elif winning % 10 == number % 10:
		kind = "last"
		payout = BigNumber.min_of(net.mul_f(QUINIELA_LAST * (1.0 + luck(m))), cap(m))
	m.money = m.money.add(payout)
	_record(m, stake, payout, not payout.is_zero())
	var res: Dictionary = {"number": number, "winning": winning, "stake": stake, "payout": payout, "kind": kind}
	m.push("quiniela_drawn", [res])
	return res


# =====================================================================
#  Timba del dólar
# =====================================================================
## Tasa mensual propuesta como umbral (la vigente ahora, con los eventos activos).
static func dollar_threshold(m: GameModel) -> float:
	return EconomyLogic.inflation_rate(m)


static func place_dollar(m: GameModel, dir: String, stake: BigNumber) -> bool:
	if not Unlocks.has(m, "dollar") or (dir != "up" and dir != "down") or stake.is_zero():
		return false
	if stake.gt(dollar_stake_max(m)):
		stake = dollar_stake_max(m)
	if not m.dollar_bet.is_empty():
		m.money = m.money.add(BigNumber.from_string(str(m.dollar_bet["stake"])))
		m.dollar_bet = {}
	if stake.gt(m.money):
		return false
	m.money = m.money.sub(stake)
	m.dollar_bet = {"dir": dir, "threshold": dollar_threshold(m), "stake": stake.to_save()}
	return true


## Se resuelve al cierre del mes con "el dato oficial": la tasa real de ese mes con algo de ruido.
static func settle_dollar(m: GameModel, rate_now: float, forced_official: float = -1.0) -> Dictionary:
	if m.dollar_bet.is_empty():
		return {}
	var dir: String = str(m.dollar_bet["dir"])
	var threshold: float = float(m.dollar_bet["threshold"])
	var stake: BigNumber = BigNumber.from_string(str(m.dollar_bet["stake"]))
	m.dollar_bet = {}
	var official: float = forced_official if forced_official >= 0.0 else rate_now * exp(m.rng.randfn(0.0, DOLLAR_NOISE))
	var won: bool = official > threshold if dir == "up" else official < threshold
	var payout: BigNumber = BigNumber.zero()
	if won:
		payout = BigNumber.min_of(stake.mul_f(DOLLAR_PAYOUT * (1.0 + luck(m))), cap(m))
		m.dollar_wins += 1
	m.money = m.money.add(payout)
	_record(m, stake, payout, won)
	var res: Dictionary = {"dir": dir, "threshold": threshold, "official": official, "stake": stake, "payout": payout, "won": won}
	m.push("dollar_settled", [res])
	return res


## Pista real para la timba del dólar según los eventos activos: {"event": id, "left": segundos, "mult": x, "ends_before_close": bool}.
static func dollar_hint(m: GameModel) -> Dictionary:
	var left_month: float = EconomyLogic.B("month_seconds") - m.month_progress
	for ev in m.active_events:
		var fx: Dictionary = EconomyLogic._fx(ev)
		var mult: float = float(fx.get("inflation_mult", 1.0))
		if mult != 1.0:
			return {"event": ev["id"], "left": float(ev["remaining"]), "mult": mult, "ends_before_close": float(ev["remaining"]) < left_month}
	return {}


# =====================================================================
#  Valor esperado (para tests y balance)
# =====================================================================
## Simula `n` raspaditas de apuesta 1 y devuelve el valor esperado (premios / apuestas), valorando sobres y doradas.
static func scratch_expected_value(n: int, luck_value: float = 0.0, seed_value: int = 7) -> float:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var pool: float = 0.0
	var streak: int = 0
	var won_total: float = 0.0
	for i in range(n):
		pool += POZO_FEED
		var outcome: String = "pity" if streak >= PITY_STREAK else "nothing"
		if outcome != "pity":
			var r: float = rng.randf()
			for row in SCRATCH_TABLE:
				r -= float(row[1])
				if r <= 0.0:
					outcome = str(row[0])
					break
		var prize: float = 0.0
		var lk: float = 1.0 + luck_value
		match outcome:
			"x2": prize = 2.0 * lk
			"x10": prize = 10.0 * lk
			"pity": prize = PITY_MULT * lk
			"pack": prize = VALUE_PACK
			"golden": prize = VALUE_GOLDEN
			"pozo":
				prize = maxf(pool, 10.0)
				pool = maxf(pool - prize, 0.0)
		won_total += prize
		streak = 0 if prize > 0.0 else streak + 1
	return won_total / float(n)
