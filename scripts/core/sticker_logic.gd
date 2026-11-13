class_name StickerLogic
extends RefCounted
## Álbum de figuritas del barrio: 60 figuritas en 6 páginas, sobres, repetidas, chupi (cambio) y bonus permanentes.
## Los billetes (página 3) se consiguen con las reformas; el resto, con sobres, eventos y timba.

const PACK_SIZE: int = 5
const P_GOLDEN: float = 0.03
const P_RARE: float = 0.22
const TRADE_COST: int = 5
const TRADE_COST_GOLDEN: int = 15
const PAGE_BILLETES: int = 2
const PAGE_DORADAS: int = 5


static func total() -> int:
	return GameData.stickers.size()


static func def(id: String) -> Dictionary:
	return GameData.stickers[GameData.sticker_idx[id]]


static func owned(m: GameModel, id: String) -> int:
	return int(m.stickers.get(id, 0))


static func unique(m: GameModel) -> int:
	return m.stickers.size()


static func missing_count(m: GameModel) -> int:
	return total() - unique(m)


## Repetidas: figuritas de más (cantidad - 1) sumadas.
static func repes(m: GameModel) -> int:
	var n: int = 0
	for id in m.stickers:
		n += maxi(0, int(m.stickers[id]) - 1)
	return n


static func page_ids(page: int) -> Array:
	var out: Array = []
	for s in GameData.stickers:
		if int(s["page"]) == page:
			out.append(s["id"])
	return out


static func page_count(m: GameModel, page: int) -> int:
	var n: int = 0
	for id in page_ids(page):
		if m.stickers.has(id):
			n += 1
	return n


static func page_complete(m: GameModel, page: int) -> bool:
	return page_count(m, page) >= page_ids(page).size()


static func pages_done(m: GameModel) -> int:
	var n: int = 0
	for p in range(GameData.sticker_pages.size()):
		if page_complete(m, p):
			n += 1
	return n


## Ids de un nivel de rareza que pueden salir de un sobre (los billetes solo salen de reformas).
static func pool(rarity: String) -> Array:
	var out: Array = []
	for s in GameData.stickers:
		if s["rarity"] == rarity and int(s["page"]) != PAGE_BILLETES:
			out.append(s["id"])
	return out


static func roll_rarity(m: GameModel, golden_p: float = P_GOLDEN, rare_p: float = P_RARE) -> String:
	var r: float = m.rng.randf()
	if r < golden_p:
		return "golden"
	if r < golden_p + rare_p:
		return "rare"
	return "common"


static func random_id(m: GameModel, rarity: String) -> String:
	var p: Array = pool(rarity)
	return str(p[m.rng.randi() % p.size()])


## Precio del sobre (nominal): sube con la inflación (45 s de tus ingresos, con un piso que sigue a los precios).
static func pack_cost(m: GameModel) -> BigNumber:
	return BigNumber.max_of(EconomyLogic.income_per_sec(m).mul_f(45.0), m.price_level.mul_f(60.0))


## Entrega una figurita. Devuelve {id, repe, new, rarity}.
static func give(m: GameModel, id: String) -> Dictionary:
	var before: int = owned(m, id)
	m.stickers[id] = before + 1
	var d: Dictionary = def(id)
	var res: Dictionary = {"id": id, "repe": before > 0, "new": before == 0, "rarity": d["rarity"], "golden": d["rarity"] == "golden"}
	if before == 0:
		m.dirty = true
		var page: int = int(d["page"])
		var key: String = "page_%d" % page
		if page_complete(m, page) and not m.unlocked.has(key):
			m.unlocked[key] = true
			m.push("page_done", [page])
		if unique(m) >= total() and not m.secret_seen:
			m.push("secret_end")
	return res


## Abre un sobre ya pagado: 5 figuritas. `forced` fuerza rarezas (para clips y tests).
static func open_pack(m: GameModel, forced: Array = []) -> Array:
	var out: Array = []
	for i in range(PACK_SIZE):
		var rar: String = str(forced[i]) if i < forced.size() else roll_rarity(m)
		out.append(give(m, random_id(m, rar)))
	m.packs_opened += 1
	m.push("pack_opened")
	return out




## Compra y abre un sobre. Devuelve [] si no alcanza la plata.
static func buy_pack(m: GameModel, forced: Array = []) -> Array:
	if not Unlocks.has(m, "album"):
		return []
	var cost: BigNumber = pack_cost(m)
	if cost.gt(m.money):
		return []
	m.money = m.money.sub(cost)
	return open_pack(m, forced)


## Sobre de regalo (premios y demo): no cuesta plata.
static func gift_pack(m: GameModel, forced: Array = []) -> Array:
	return open_pack(m, forced)


static func trade_cost(id: String) -> int:
	return TRADE_COST_GOLDEN if def(id)["rarity"] == "golden" else TRADE_COST


## Chupi: cambia repetidas por una figurita faltante a elección.
static func trade(m: GameModel, target_id: String) -> bool:
	if not GameData.sticker_idx.has(target_id) or owned(m, target_id) > 0:
		return false
	var cost: int = trade_cost(target_id)
	if repes(m) < cost:
		return false
	# se gastan primero las repetidas más abundantes
	var left: int = cost
	while left > 0:
		var best_id: String = ""
		var best_n: int = 1
		for id in m.stickers:
			if int(m.stickers[id]) > best_n:
				best_n = int(m.stickers[id])
				best_id = id
		if best_id == "":
			return false
		m.stickers[best_id] = best_n - 1
		left -= 1
	m.trades += 1
	give(m, target_id)
	return true


## Figurita de premio (eventos y timba): rareza sorteada o forzada.
static func award(m: GameModel, rarity: String = "") -> Dictionary:
	var rar: String = rarity if rarity != "" else roll_rarity(m, 0.02, 0.2)
	var res: Dictionary = give(m, random_id(m, rar))
	m.push("sticker_won", [res["id"]])
	return res


## Bonus permanentes por páginas completas: {income, inflation, remark, choice_time}.
static func bonuses(m: GameModel) -> Dictionary:
	var b: Dictionary = {"income": 0.0, "inflation": 0.0, "remark": 0.0, "choice_time": 0.0}
	for p in range(GameData.sticker_pages.size()):
		if not page_complete(m, p):
			continue
		var bon: Dictionary = GameData.sticker_pages[p]["bonus"]
		for k in b:
			if bon.has(k):
				b[k] += float(bon[k])
	return b
