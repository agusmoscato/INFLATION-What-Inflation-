class_name StickerLogic
extends RefCounted
## Álbum de figuritas del barrio (se desbloquea en el árbol): 60 figuritas en 6 páginas, sobres, repetidas, chupi (cambio)
## y bonus por página (TreeLogic.compute_mods). Los billetes (página 3) salen de las reformas; el resto, de sobres,
## billetes voladores, noticias y raspaditas.

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


## Precio del sobre (nominal): 60 s de producción, con un piso que sigue a los precios; más barato con el árbol.
static func pack_cost(m: GameModel) -> BigNumber:
	EconomyLogic.ensure_fresh(m)
	var c: BigNumber = BigNumber.max_of(EconomyLogic.income_per_sec(m).mul_f(GameData.B("pack_seconds")),
		EconomyLogic.cost_factor(m).mul_f(GameData.B("pack_floor")))
	return c.mul_f(float(m.mods["pack_discount"]))


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
	EconomyLogic.ensure_fresh(m)
	var out: Array = []
	var gp: float = P_GOLDEN * float(m.mods.get("golden_mult", 1.0))
	for i in range(int(m.mods.get("pack_size", PACK_SIZE))):
		var rar: String = str(forced[i]) if i < forced.size() else roll_rarity(m, gp)
		out.append(give(m, random_id(m, rar)))
	m.packs_opened += 1
	m.push("pack_opened")
	return out




## Compra y abre un sobre. Devuelve [] si no alcanza la plata.
static func buy_pack(m: GameModel, forced: Array = []) -> Array:
	if not TreeLogic.has(m, "album"):
		return []
	var cost: BigNumber = pack_cost(m)
	if cost.gt(m.money):
		return []
	m.money = m.money.sub(cost)
	return open_pack(m, forced)


## Sobre de regalo (premios y demo): no cuesta plata.
static func gift_pack(m: GameModel, forced: Array = []) -> Array:
	return open_pack(m, forced)


static func trade_cost(m: GameModel, id: String) -> int:
	EconomyLogic.ensure_fresh(m)
	var base: int = maxi(1, int(m.mods.get("trade_cost", TRADE_COST)))
	return base * 3 if def(id)["rarity"] == "golden" else base


## Chupi: cambia repetidas por una figurita faltante a elección.
static func trade(m: GameModel, target_id: String) -> bool:
	if not GameData.sticker_idx.has(target_id) or owned(m, target_id) > 0:
		return false
	var cost: int = trade_cost(m, target_id)
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
	EconomyLogic.ensure_fresh(m)
	var rar: String = rarity if rarity != "" else roll_rarity(m, 0.02 * float(m.mods.get("golden_mult", 1.0)), 0.2)
	var res: Dictionary = give(m, random_id(m, rar))
	m.push("sticker_won", [res["id"]])
	return res
