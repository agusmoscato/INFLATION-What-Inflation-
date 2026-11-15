class_name GameModel
extends RefCounted
## Estado completo de una partida (datos puros, sin nodos). Serializable a diccionario/JSON.
## Diseño v2: una "vuelta" (run) se reinicia con cada reforma; el árbol, el álbum y los logros quedan.

const SAVE_VERSION: int = 2

# ---- la vuelta actual (se reinicia con la reforma) ----
var money: BigNumber = BigNumber.zero()
var run_earned: BigNumber = BigNumber.zero()       ## todo lo ganado en la vuelta (define la Credibilidad)
var run_time: float = 0.0
var ln_p: float = 0.0                              ## ln del nivel de precios de la vuelta (P = e^ln_p)
var owned: Dictionary = {}                         # id -> int
var upgrades: Dictionary = {}                      # id -> true
var run_clicks: int = 0                            ## clics de la vuelta (manuales + automáticos)
var run_manual_clicks: int = 0
var run_index: int = 1                             ## número de vuelta (1 = la primera)
var freeze_left: float = 0.0                       ## precios congelados: el reloj de inflación no avanza
var remark_cd: float = 0.0
var frenzy_left: float = 0.0
var clickfrenzy_left: float = 0.0
var combo: int = 0
var combo_idle: float = 99.0                       ## segundos desde el último clic
var click_rate: float = 0.0                        ## clics manuales por segundo (promedio móvil de ~1 s; no se guarda)
var bill_timer: float = 40.0
var bills_active: Array = []                       ## [{id:int, left:float, total:float}]
var bill_seq: int = 0
var event_timer: float = 120.0
var active_events: Array = []                      ## [{id, remaining, fx}]
var pending_choice: Dictionary = {}                ## {id, remaining, total}
var auto_click_acc: float = 0.0
var manager_timer: float = 0.0
var auto_scratch_timer: float = 0.0
var collapse_shown: bool = false                  ## ya se avisó de la traba en esta racha
var max_rate_run: float = 0.0
var stuck_t: float = 0.0                           ## segundos seguidos sin poder comprar nada
var stuck_check: float = 0.0
var stuck_bought: int = 0
var revealed: Dictionary = {}                      ## mejoras que ya aparecieron en la fila de esta vuelta
var reveal_cd: float = 2.0
var gain_hist: Array = []                          ## Credibilidad posible cada 5 s (para el consejo de reforma; no se guarda)
var gain_hist_t: float = 0.0

# ---- permanente ----
var credibility: int = 0                           ## sin gastar
var cred_total: int = 0                            ## ganada en total
var lifetime_earned: BigNumber = BigNumber.zero()  ## todo lo ganado en las vueltas terminadas
var tree: Dictionary = {}                          ## id -> true
var reforms: int = 0
var runs: Array = []                               ## historial: [{n, earned, time, cred}]
var best_run: BigNumber = BigNumber.zero()
var fastest_run: float = 9999.0
var lazy_run: int = 0
var early_remark: int = 0
var album: Array = []                              ## billetes conseguidos (uno por reforma)
var zeros_cut: int = 0
var won: bool = false
var won_notified: bool = false
var demo_finished: bool = false
var demo_mode: bool = false                        ## no se guarda: lo decide el build

var clicks: int = 0
var crits: int = 0
var max_combo: int = 0
var remarks: int = 0
var bills: int = 0
var bills_missed: int = 0
var frenzies: int = 0
var events_seen: int = 0
var max_buildings: int = 0
var max_carts: int = 0
var max_tier: int = 0
var max_upgrades: int = 0
var max_rate_pct: float = 0.0
var max_price_l10: float = 0.0                     ## ceros del nivel de precios más alto que se vio en una vuelta
var time_played: float = 0.0
var achievements: Dictionary = {}
var saved_unix: float = 0.0
var unlocked: Dictionary = {}                      ## avisos ya mostrados (mecánicas, tutorial): id -> segundo de juego
var tutorial_done: bool = false
var free_packs_pending: int = 0                    ## sobres de regalo que la UI todavía no abrió

var stickers: Dictionary = {}                      # id de figurita -> cantidad
var packs_opened: int = 0
var trades: int = 0
var secret_seen: bool = false

var scratches: int = 0
var scratch_big: int = 0
var loss_streak: int = 0
var loss_streak_max: int = 0
var gamble_won: BigNumber = BigNumber.zero()
var gamble_lost: BigNumber = BigNumber.zero()

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# ---- derivados (no se guardan; los recalcula EconomyLogic.recalc) ----
var dirty: bool = true
var mods: Dictionary = {}                          ## modificadores del árbol + álbum (TreeLogic.mods)
var base_income: BigNumber = BigNumber.zero()      ## producción/s sin frenesí, eventos ni inflación
var biz_income: Dictionary = {}                    ## id -> BigNumber (producción/s de todos los de ese tipo)
var click_mult: float = 1.0
var click_pct: float = 0.0

## Cola de notificaciones para la UI: [{sig: String, args: Array}]
var notifications: Array = []


func _init(seed_value: int = 0) -> void:
	GameData.ensure()
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	bill_timer = GameData.B("bill_first")


func push(sig: String, args: Array = []) -> void:
	notifications.append({"sig": sig, "args": args})


func owned_count(id: String) -> int:
	return int(owned.get(id, 0))


func total_businesses() -> int:
	var n: int = 0
	for k in owned:
		n += int(owned[k])
	return n


func has_node(id: String) -> bool:
	return tree.has(id)


static func _bn(d: Dictionary, k: String) -> BigNumber:
	return BigNumber.from_string(str(d.get(k, "0")))


func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"money": money.to_save(), "run_earned": run_earned.to_save(), "run_time": run_time, "ln_p": ln_p,
		"owned": owned.duplicate(), "upgrades": upgrades.duplicate(), "run_clicks": run_clicks,
		"run_manual_clicks": run_manual_clicks, "run_index": run_index, "freeze_left": freeze_left, "remark_cd": remark_cd,
		"frenzy_left": frenzy_left, "clickfrenzy_left": clickfrenzy_left, "bill_timer": bill_timer,
		"event_timer": event_timer, "active_events": active_events.duplicate(true), "manager_timer": manager_timer,
		"auto_scratch_timer": auto_scratch_timer, "collapse_shown": collapse_shown, "max_rate_run": max_rate_run,
		"stuck_t": stuck_t, "revealed": revealed.duplicate(), "reveal_cd": reveal_cd,
		"credibility": credibility, "cred_total": cred_total, "lifetime_earned": lifetime_earned.to_save(), "tree": tree.duplicate(), "reforms": reforms,
		"runs": runs.duplicate(true), "best_run": best_run.to_save(), "fastest_run": fastest_run, "lazy_run": lazy_run,
		"early_remark": early_remark, "album": album.duplicate(), "zeros_cut": zeros_cut, "won": won,
		"won_notified": won_notified, "demo_finished": demo_finished,
		"clicks": clicks, "crits": crits, "max_combo": max_combo, "remarks": remarks, "bills": bills,
		"bills_missed": bills_missed, "frenzies": frenzies, "events_seen": events_seen, "max_buildings": max_buildings,
		"max_carts": max_carts, "max_tier": max_tier, "max_upgrades": max_upgrades, "max_rate_pct": max_rate_pct, "max_price_l10": max_price_l10,
		"time_played": time_played, "achievements": achievements.duplicate(), "unlocked": unlocked.duplicate(),
		"tutorial_done": tutorial_done, "free_packs_pending": free_packs_pending,
		"stickers": stickers.duplicate(), "packs_opened": packs_opened, "trades": trades, "secret_seen": secret_seen,
		"scratches": scratches, "scratch_big": scratch_big, "loss_streak": loss_streak, "loss_streak_max": loss_streak_max,
		"gamble_won": gamble_won.to_save(), "gamble_lost": gamble_lost.to_save(),
		"saved_unix": Time.get_unix_time_from_system(),
	}


## Carga un diccionario guardado. Devuelve false si es de una versión vieja (no se convierte: se empieza de cero).
func from_dict(d: Dictionary) -> bool:
	if int(d.get("version", 1)) < SAVE_VERSION:
		return false
	money = _bn(d, "money")
	run_earned = _bn(d, "run_earned")
	run_time = float(d.get("run_time", 0.0))
	ln_p = float(d.get("ln_p", 0.0))
	owned = {}
	for k in d.get("owned", {}):
		if GameData.business_idx.has(k):
			owned[k] = int(d["owned"][k])
	upgrades = {}
	for k in d.get("upgrades", {}):
		if GameData.upgrade_idx.has(k):
			upgrades[k] = true
	run_clicks = int(d.get("run_clicks", 0))
	run_manual_clicks = int(d.get("run_manual_clicks", 0))
	run_index = int(d.get("run_index", 1))
	freeze_left = float(d.get("freeze_left", 0.0))
	remark_cd = float(d.get("remark_cd", 0.0))
	frenzy_left = float(d.get("frenzy_left", 0.0))
	clickfrenzy_left = float(d.get("clickfrenzy_left", 0.0))
	bill_timer = float(d.get("bill_timer", 40.0))
	event_timer = float(d.get("event_timer", 120.0))
	active_events = []
	for ev in d.get("active_events", []):
		if GameData.event_idx.has(str(ev.get("id", ""))):
			active_events.append({"id": ev["id"], "remaining": float(ev.get("remaining", 0.0)), "fx": ev.get("fx", {})})
	manager_timer = float(d.get("manager_timer", 0.0))
	auto_scratch_timer = float(d.get("auto_scratch_timer", 0.0))
	collapse_shown = bool(d.get("collapse_shown", false))
	max_rate_run = float(d.get("max_rate_run", 0.0))
	stuck_t = float(d.get("stuck_t", 0.0))
	reveal_cd = float(d.get("reveal_cd", 2.0))
	revealed = {}
	for k in d.get("revealed", upgrades):
		if GameData.upgrade_idx.has(k):
			revealed[k] = true
	for k in upgrades:
		revealed[k] = true
	credibility = int(d.get("credibility", 0))
	cred_total = int(d.get("cred_total", 0))
	lifetime_earned = _bn(d, "lifetime_earned")
	tree = {}
	for k in d.get("tree", {}):
		if GameData.tree_idx.has(k):
			tree[k] = true
	reforms = int(d.get("reforms", 0))
	runs = []
	for r in d.get("runs", []):
		runs.append(r)
	best_run = _bn(d, "best_run")
	fastest_run = float(d.get("fastest_run", 9999.0))
	lazy_run = int(d.get("lazy_run", 0))
	early_remark = int(d.get("early_remark", 0))
	album = []
	for n in d.get("album", []):
		album.append(int(n))
	zeros_cut = int(d.get("zeros_cut", 0))
	won = bool(d.get("won", false))
	won_notified = bool(d.get("won_notified", false))
	demo_finished = bool(d.get("demo_finished", false))
	clicks = int(d.get("clicks", 0))
	crits = int(d.get("crits", 0))
	max_combo = int(d.get("max_combo", 0))
	remarks = int(d.get("remarks", 0))
	bills = int(d.get("bills", 0))
	bills_missed = int(d.get("bills_missed", 0))
	frenzies = int(d.get("frenzies", 0))
	events_seen = int(d.get("events_seen", 0))
	max_buildings = int(d.get("max_buildings", 0))
	max_carts = int(d.get("max_carts", 0))
	max_tier = int(d.get("max_tier", 0))
	max_upgrades = int(d.get("max_upgrades", 0))
	max_rate_pct = float(d.get("max_rate_pct", 0.0))
	max_price_l10 = float(d.get("max_price_l10", 0.0))
	time_played = float(d.get("time_played", 0.0))
	achievements = {}
	for k in d.get("achievements", {}):
		achievements[k] = true
	unlocked = {}
	for k in d.get("unlocked", {}):
		unlocked[k] = d["unlocked"][k]
	tutorial_done = bool(d.get("tutorial_done", false))
	free_packs_pending = int(d.get("free_packs_pending", 0))
	stickers = {}
	for k in d.get("stickers", {}):
		if GameData.sticker_idx.has(k):
			stickers[k] = int(d["stickers"][k])
	packs_opened = int(d.get("packs_opened", 0))
	trades = int(d.get("trades", 0))
	secret_seen = bool(d.get("secret_seen", false))
	scratches = int(d.get("scratches", 0))
	scratch_big = int(d.get("scratch_big", 0))
	loss_streak = int(d.get("loss_streak", 0))
	loss_streak_max = int(d.get("loss_streak_max", 0))
	gamble_won = _bn(d, "gamble_won")
	gamble_lost = _bn(d, "gamble_lost")
	saved_unix = float(d.get("saved_unix", 0.0))
	bills_active = []
	pending_choice = {}
	dirty = true
	return true
