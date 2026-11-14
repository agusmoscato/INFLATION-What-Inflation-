class_name GambleLogic
extends RefCounted
## Raspadita del kiosco (la timba del juego, se desbloquea en el árbol). SIEMPRE con plata del juego: no hay dinero real
## ni microtransacciones. Valor esperado levemente negativo salvo con la rama SUERTE.

## Probabilidades base (las que no son "nothing" se multiplican por la suerte del árbol).
const SCRATCH_TABLE: Array = [
	["x2", 0.17],
	["x10", 0.025],
	["pack", 0.035],
	["frenzy", 0.02],
	["golden", 0.004],
]
const PITY_MULT: float = 1.5
const FREE_STAKE_SECONDS: float = 30.0      ## la raspadita automática "apuesta" 30 s de producción


static func unlocked(m: GameModel) -> bool:
	return TreeLogic.has(m, "scratch")


static func price(m: GameModel) -> BigNumber:
	return m.money.mul_f(GameData.B("scratch_pct"))


static func roll_outcome(m: GameModel, force: String = "") -> String:
	if force != "":
		return force
	if m.loss_streak >= int(m.mods["scratch_pity"]):
		return "pity"
	var luck: float = float(m.mods["scratch_luck"])
	var r: float = m.rng.randf()
	for row in SCRATCH_TABLE:
		var p: float = float(row[1]) * luck
		if row[0] == "golden":
			p *= float(m.mods["scratch_gold"])
		r -= p
		if r < 0.0:
			return str(row[0])
	return "nothing"


## Juega una raspadita (paga el 5 % de tu plata, o es gratis con la automática). El resultado ya queda aplicado.
## Devuelve {ok, price, outcome, prize (nominal), pack: [] (figuritas, si salió sobre), sticker (id)}.
static func play_scratch(m: GameModel, free: bool = false, force: String = "") -> Dictionary:
	EconomyLogic.ensure_fresh(m)
	if not unlocked(m):
		return {"ok": false}
	var stake: BigNumber = EconomyLogic.income_per_sec(m).mul_f(FREE_STAKE_SECONDS) if free else price(m)
	if stake.is_zero() or (not free and stake.gt(m.money)):
		return {"ok": false}
	if not free:
		m.money = m.money.sub(stake)
	m.scratches += 1
	var outcome: String = roll_outcome(m, force)
	var prize: BigNumber = BigNumber.zero()
	var res: Dictionary = {"ok": true, "price": stake, "outcome": outcome, "prize": prize, "pack": [], "sticker": "", "free": free}
	var win: bool = true
	match outcome:
		"nothing":
			win = false
		"x2":
			prize = stake.mul_f(2.0)
		"x10":
			prize = stake.mul_f(10.0)
			m.scratch_big += 1
		"pity":
			prize = stake.mul_f(PITY_MULT)
		"pack":
			if bool(m.mods["album"]):
				res["pack"] = StickerLogic.gift_pack(m)
			else:
				prize = stake.mul_f(3.0)
		"frenzy":
			m.frenzy_left = maxf(m.frenzy_left, float(m.mods["frenzy_dur"]))
			m.frenzies += 1
		"golden":
			if bool(m.mods["album"]):
				res["sticker"] = StickerLogic.award(m, "golden")["id"]
			else:
				prize = stake.mul_f(10.0)
	if not prize.is_zero():
		EconomyLogic.earn(m, prize)
	res["prize"] = prize
	if free:
		pass
	elif prize.gt(stake):
		m.gamble_won = m.gamble_won.add(prize.sub(stake))
	else:
		m.gamble_lost = m.gamble_lost.add(stake.sub(prize))
	if win:
		m.loss_streak = 0
	else:
		m.loss_streak += 1
		m.loss_streak_max = maxi(m.loss_streak_max, m.loss_streak)
	m.push("scratched", [res])
	return res
