class_name GameModel
extends RefCounted
## Estado completo de una partida (datos puros, sin nodos). Serializable a diccionario/JSON.

const SAVE_VERSION: int = 1

var money: BigNumber = BigNumber.zero()
var price_level: BigNumber = BigNumber.one()   # P: nivel de precios de la economía
var my_prices: BigNumber = BigNumber.one()     # M: tus precios (se actualizan al remarcar)
var owned: Dictionary = {}                     # id -> int
var upgrades: Dictionary = {}                  # id -> true
var refuge_units: Dictionary = {}              # id -> BigNumber (unidades, en pesos reales a precio 1)
var refuge_price: Dictionary = {}              # id -> float (precio actual relativo)

var lifetime_real: BigNumber = BigNumber.zero()  # ganancia real histórica (define la era)
var cycle_real: BigNumber = BigNumber.zero()     # ganancia real desde el último plan (define Credibilidad)
var run_real: BigNumber = BigNumber.zero()       # ganancia real desde la última reforma

var era: int = 1
var credibility: int = 0
var legacy_cred: float = 0.0
var reforms: int = 0
var plans_done: int = 0
var plan_id: String = ""
var plans_used: Array = []
var album: Array = []
var zeros_cut: int = 0
var measures: int = 0
var won: bool = false
var won_notified: bool = false
var demo_finished: bool = false                 # la demo llegó a su límite (primera reforma hecha)
var demo_mode: bool = false                     # no se guarda: lo decide el build

var clicks: int = 0
var remarks: int = 0
var events_seen: int = 0
var time_played: float = 0.0
var run_time: float = 0.0
var month_progress: float = 0.0
var month_count: int = 0
var offline_months_left: int = -1        ## solo durante la simulación offline: cuántos aumentos más pueden pasar (-1 = sin límite)
var remark_window: float = 0.0
var remark_cd: float = 0.0
var auto_timer: float = 0.0
var auto_buy_timer: float = 0.0
var event_timer: float = 120.0
var active_events: Array = []                  # [{id, remaining, fx}]
var pending_choice: Dictionary = {}            # decisión abierta: {id, remaining} (no se guarda)
var achievements: Dictionary = {}
var saved_unix: float = 0.0

# ---- objetivos, desbloqueos y coleccionables ----
var obj_index: int = 0                          # objetivo actual de la cadena (solo avanza)
var unlocked: Dictionary = {}                   # mecánicas ya anunciadas: id -> true
var real_ref: BigNumber = BigNumber.zero()      # ingreso real/s al cierre del mes anterior (para "¿le ganás a la inflación?")
var stickers: Dictionary = {}                   # id de figurita -> cantidad (más de 1 = repetidas)
var packs_opened: int = 0
var trades: int = 0
var gift_given: bool = false                    # sobre de regalo de la demo
var secret_seen: bool = false                   # final secreto del álbum completo

# ---- timba (siempre con plata del juego) ----
var pool_real: BigNumber = BigNumber.zero()     # "pozo" de la raspadita, en pesos reales (se ajusta con la inflación)
var gamble_won: BigNumber = BigNumber.zero()    # ganado/perdido/mejor premio, en pesos reales
var gamble_lost: BigNumber = BigNumber.zero()
var gamble_best: BigNumber = BigNumber.zero()
var scratches: int = 0
var loss_streak: int = 0
var loss_streak_max: int = 0
var quiniela_wins: int = 0
var dollar_wins: int = 0
var pozo_wins: int = 0
var gold_scratches: int = 0
var quiniela: Dictionary = {}                   # boleta: {number:int, stake:String}
var dollar_bet: Dictionary = {}                 # apuesta: {dir:"up"/"down", threshold:float, stake:String}

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# ---- derivados (no se guardan; se recalculan con EconomyLogic.recalc) ----
var dirty: bool = true
var base_income: BigNumber = BigNumber.zero()   # ingreso real/s sin M ni eventos
var global_mult: float = 1.0
var biz_up_mult: Dictionary = {}
var click_mult: float = 1.0
var click_pct: float = 0.0
var auto_remark_interval: float = 0.0
var auto_buy_interval: float = 0.0
var infl_up_mult: float = 1.0
var fee_mult: float = 1.0
var remark_bonus_mult: float = 1.0
var refuge_mult: float = 1.0                    # bono de cartera diversificada
var sticker_infl_mult: float = 1.0              # bonus permanente de páginas del álbum
var sticker_remark_mult: float = 1.0
var sticker_choice_bonus: float = 0.0

## Cola de notificaciones para la UI: [{sig: String, args: Array}]
var notifications: Array = []


func _init(seed_value: int = 0) -> void:
	GameData.ensure()
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	for r in GameData.refuges:
		refuge_units[r["id"]] = BigNumber.zero()
		refuge_price[r["id"]] = 1.0


func push(sig: String, args: Array = []) -> void:
	notifications.append({"sig": sig, "args": args})


func owned_count(id: String) -> int:
	return int(owned.get(id, 0))


func total_businesses() -> int:
	var n: int = 0
	for k in owned:
		n += int(owned[k])
	return n


func to_dict() -> Dictionary:
	var units: Dictionary = {}
	for k in refuge_units:
		units[k] = refuge_units[k].to_save()
	return {
		"version": SAVE_VERSION,
		"money": money.to_save(), "price_level": price_level.to_save(), "my_prices": my_prices.to_save(),
		"owned": owned.duplicate(), "upgrades": upgrades.duplicate(),
		"refuge_units": units, "refuge_price": refuge_price.duplicate(),
		"lifetime_real": lifetime_real.to_save(), "cycle_real": cycle_real.to_save(), "run_real": run_real.to_save(),
		"era": era, "credibility": credibility, "legacy_cred": legacy_cred,
		"reforms": reforms, "plans_done": plans_done, "plan_id": plan_id, "plans_used": plans_used.duplicate(),
		"album": album.duplicate(), "zeros_cut": zeros_cut, "measures": measures,
		"won": won, "won_notified": won_notified, "demo_finished": demo_finished,
		"clicks": clicks, "remarks": remarks, "events_seen": events_seen,
		"time_played": time_played, "run_time": run_time,
		"month_progress": month_progress, "month_count": month_count,
		"remark_window": remark_window, "auto_timer": auto_timer, "auto_buy_timer": auto_buy_timer,
		"event_timer": event_timer, "active_events": active_events.duplicate(true),
		"obj_index": obj_index, "unlocked": unlocked.duplicate(), "real_ref": real_ref.to_save(),
		"stickers": stickers.duplicate(), "packs_opened": packs_opened, "trades": trades,
		"gift_given": gift_given, "secret_seen": secret_seen,
		"pool_real": pool_real.to_save(), "gamble_won": gamble_won.to_save(), "gamble_lost": gamble_lost.to_save(),
		"gamble_best": gamble_best.to_save(), "scratches": scratches, "loss_streak": loss_streak,
		"loss_streak_max": loss_streak_max, "quiniela_wins": quiniela_wins, "dollar_wins": dollar_wins,
		"pozo_wins": pozo_wins, "gold_scratches": gold_scratches, "quiniela": quiniela.duplicate(), "dollar_bet": dollar_bet.duplicate(),
		"achievements": achievements.duplicate(), "saved_unix": Time.get_unix_time_from_system(),
	}


func from_dict(d: Dictionary) -> void:
	money = BigNumber.from_string(str(d.get("money", "0")))
	price_level = BigNumber.from_string(str(d.get("price_level", "1")))
	my_prices = BigNumber.from_string(str(d.get("my_prices", "1")))
	owned = {}
	for k in d.get("owned", {}):
		owned[k] = int(d["owned"][k])
	upgrades = {}
	for k in d.get("upgrades", {}):
		if GameData.upgrade_idx.has(k):
			upgrades[k] = true
	var units: Dictionary = d.get("refuge_units", {})
	var prices: Dictionary = d.get("refuge_price", {})
	for r in GameData.refuges:
		var rid: String = r["id"]
		refuge_units[rid] = BigNumber.from_string(str(units.get(rid, "0")))
		refuge_price[rid] = float(prices.get(rid, 1.0))
	lifetime_real = BigNumber.from_string(str(d.get("lifetime_real", "0")))
	cycle_real = BigNumber.from_string(str(d.get("cycle_real", "0")))
	run_real = BigNumber.from_string(str(d.get("run_real", "0")))
	era = int(d.get("era", 1))
	credibility = int(d.get("credibility", 0))
	legacy_cred = float(d.get("legacy_cred", 0.0))
	reforms = int(d.get("reforms", 0))
	plans_done = int(d.get("plans_done", 0))
	plan_id = str(d.get("plan_id", ""))
	plans_used = []
	for p in d.get("plans_used", []):
		plans_used.append(str(p))
	album = []
	for n in d.get("album", []):
		album.append(int(n))
	zeros_cut = int(d.get("zeros_cut", 0))
	measures = int(d.get("measures", 0))
	won = bool(d.get("won", false))
	won_notified = bool(d.get("won_notified", false))
	demo_finished = bool(d.get("demo_finished", false))
	clicks = int(d.get("clicks", 0))
	remarks = int(d.get("remarks", 0))
	events_seen = int(d.get("events_seen", 0))
	time_played = float(d.get("time_played", 0.0))
	run_time = float(d.get("run_time", 0.0))
	month_progress = float(d.get("month_progress", 0.0))
	month_count = int(d.get("month_count", 0))
	remark_window = float(d.get("remark_window", 0.0))
	auto_timer = float(d.get("auto_timer", 0.0))
	auto_buy_timer = float(d.get("auto_buy_timer", 0.0))
	event_timer = float(d.get("event_timer", 120.0))
	active_events = []
	for ev in d.get("active_events", []):
		if GameData.event_idx.has(ev.get("id", "")):
			var entry: Dictionary = {"id": ev["id"], "remaining": float(ev.get("remaining", 0.0))}
			if ev.has("fx"):
				entry["fx"] = ev["fx"]
			active_events.append(entry)
	achievements = {}
	for k in d.get("achievements", {}):
		achievements[k] = true
	saved_unix = float(d.get("saved_unix", 0.0))
	obj_index = int(d.get("obj_index", 0))
	unlocked = {}
	for k in d.get("unlocked", {}):
		unlocked[k] = true
	real_ref = BigNumber.from_string(str(d.get("real_ref", "0")))
	stickers = {}
	for k in d.get("stickers", {}):
		stickers[k] = int(d["stickers"][k])
	packs_opened = int(d.get("packs_opened", 0))
	trades = int(d.get("trades", 0))
	gift_given = bool(d.get("gift_given", false))
	secret_seen = bool(d.get("secret_seen", false))
	pool_real = BigNumber.from_string(str(d.get("pool_real", "0")))
	gamble_won = BigNumber.from_string(str(d.get("gamble_won", "0")))
	gamble_lost = BigNumber.from_string(str(d.get("gamble_lost", "0")))
	gamble_best = BigNumber.from_string(str(d.get("gamble_best", "0")))
	scratches = int(d.get("scratches", 0))
	loss_streak = int(d.get("loss_streak", 0))
	loss_streak_max = int(d.get("loss_streak_max", 0))
	quiniela_wins = int(d.get("quiniela_wins", 0))
	dollar_wins = int(d.get("dollar_wins", 0))
	pozo_wins = int(d.get("pozo_wins", 0))
	gold_scratches = int(d.get("gold_scratches", 0))
	quiniela = d.get("quiniela", {}).duplicate()
	dollar_bet = d.get("dollar_bet", {}).duplicate()
	dirty = true
