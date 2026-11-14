extends RefCounted


func _m() -> GameModel:
	var m: GameModel = GameModel.new(21)
	m.tree["fig_1"] = true      # álbum desbloqueado
	m.dirty = true
	return m


func run(t) -> void:
	t.eq(StickerLogic.total(), 60, "60 figuritas en total")
	t.eq(GameData.sticker_pages.size(), 6, "6 páginas")
	for p in range(6):
		t.eq(StickerLogic.page_ids(p).size(), 10, "la página %d tiene 10 figuritas" % p)
	var rar: Dictionary = {"common": 0, "rare": 0, "golden": 0}
	for s in GameData.stickers:
		rar[s["rarity"]] += 1
		t.check(I18n.has_key(s["name_key"], "es") and I18n.has_key(s["name_key"], "en"), "nombre de " + str(s["id"]))
		t.check(I18n.has_key(s["joke_key"], "es") and I18n.has_key(s["joke_key"], "en"), "chiste de " + str(s["id"]))
	t.eq(rar["golden"], 10, "10 doradas")
	t.check(rar["common"] > 0 and rar["rare"] > 0, "hay comunes y raras")
	# sobre: 5 figuritas, cuesta plata y sube con la inflación
	var m: GameModel = _m()
	t.check(StickerLogic.buy_pack(m).is_empty(), "sin plata no hay sobre")
	var cost1: BigNumber = StickerLogic.pack_cost(m)
	m.ln_p = log(1000.0)
	var cost2: BigNumber = StickerLogic.pack_cost(m)
	t.check(cost2.gt(cost1.mul_f(500.0)), "el precio del sobre sube con la inflación")
	m.ln_p = 0.0
	t.check(StickerLogic.buy_pack(GameModel.new(2)).is_empty(), "sin el nodo del álbum no hay sobres")
	m.money = BigNumber.from_float(1e6)
	m.owned["kiosco"] = 1
	var got: Array = StickerLogic.buy_pack(m)
	t.eq(got.size(), 5, "un sobre trae 5 figuritas")
	t.eq(m.packs_opened, 1, "sobre contado")
	t.check(m.money.lt(BigNumber.from_float(1e6)), "el sobre se pagó")
	var total_cards: int = 0
	for id in m.stickers:
		total_cards += int(m.stickers[id])
	t.eq(total_cards, 5, "se guardaron 5 figuritas")
	for it in got:
		t.check(StickerLogic.def(it["id"])["page"] != StickerLogic.PAGE_BILLETES, "los sobres no traen billetes")
	# rarezas forzadas
	var mf: GameModel = _m()
	var gold: Array = StickerLogic.gift_pack(mf, ["golden", "common", "common", "common", "common"])
	t.check(gold[0]["golden"], "se puede forzar una dorada")
	# repetidas
	var mr: GameModel = _m()
	var a: Dictionary = StickerLogic.give(mr, "biz_kiosco")
	var b: Dictionary = StickerLogic.give(mr, "biz_kiosco")
	t.check(a["new"] and not a["repe"], "la primera es nueva")
	t.check(b["repe"] and not b["new"], "la segunda es repe")
	t.eq(StickerLogic.repes(mr), 1, "1 repetida")
	# chupi: 5 repes por 1 faltante
	for i in range(4):
		StickerLogic.give(mr, "biz_kiosco")
	t.eq(StickerLogic.repes(mr), 5, "5 repetidas")
	t.check(StickerLogic.trade(mr, "biz_banco"), "chupi: cambia 5 repes por una faltante")
	t.eq(StickerLogic.owned(mr, "biz_banco"), 1, "recibió la figurita elegida")
	t.eq(StickerLogic.repes(mr), 0, "gastó las 5 repes")
	t.check(not StickerLogic.trade(mr, "biz_banco"), "no se puede pedir una que ya tenés")
	t.check(not StickerLogic.trade(mr, "pj_gato"), "sin repes no hay cambio")
	for i in range(14):
		StickerLogic.give(mr, "biz_empanadas")
	t.eq(StickerLogic.repes(mr), 13, "13 repetidas")
	t.check(not StickerLogic.trade(mr, "gold_1"), "una dorada cuesta 15 repes: con 13 no alcanza")
	StickerLogic.give(mr, "biz_empanadas")
	StickerLogic.give(mr, "biz_empanadas")
	t.check(StickerLogic.trade(mr, "gold_1"), "con 15 repes sí")
	# páginas completas dan bonus permanentes (a través de los modificadores del árbol)
	var mp: GameModel = _m()
	EconomyLogic.ensure_fresh(mp)
	t.near(float(mp.mods["album_income"]), 0.0, "sin páginas no hay bonus")
	for id in StickerLogic.page_ids(0):
		StickerLogic.give(mp, id)
	t.check(StickerLogic.page_complete(mp, 0), "página Negocios completa")
	EconomyLogic.ensure_fresh(mp)
	t.near(float(mp.mods["album_income"]), 0.10, "Negocios: +10 % producción")
	mp.owned["empanadas"] = 1
	mp.dirty = true
	t.near(EconomyLogic.income_per_sec(mp).to_float(), 0.5 * 1.10, "el bonus se aplica a la producción")
	for id in StickerLogic.page_ids(1):
		StickerLogic.give(mp, id)
	t.near(EconomyLogic.infl_speed(mp), 0.95, "Personajes: inflación 5 % más lenta")
	for id in StickerLogic.page_ids(3):
		StickerLogic.give(mp, id)
	EconomyLogic.ensure_fresh(mp)
	t.near(float(mp.mods["album_remark"]), 3.0, "Titulares: remarcar congela 3 s más")
	mp.tree["fig_4"] = true
	mp.dirty = true
	EconomyLogic.ensure_fresh(mp)
	t.near(float(mp.mods["album_income"]), 0.20, "Álbum lleno de vida duplica los bonus de página")
	t.eq(StickerLogic.trade_cost(mp, "biz_banco"), 5, "chupi: 5 repes")
	mp.tree["fig_3a"] = true
	mp.dirty = true
	t.eq(StickerLogic.trade_cost(mp, "biz_banco"), 3, "Chupi barato: 3 repes")
	# los billetes de las reformas se guardan como figuritas y las figuritas se conservan al reformar
	var mb: GameModel = _m()
	mb.run_earned = BigNumber.from_float(1e12)
	mb.collapse_shown = true
	StickerLogic.give(mb, "biz_kiosco")
	EconomyLogic.do_reform(mb)
	t.eq(StickerLogic.owned(mb, "note_0"), 1, "la reforma da el billete 0")
	t.eq(StickerLogic.owned(mb, "biz_kiosco"), 1, "las figuritas se conservan entre reformas")
	# álbum completo: aviso del final secreto
	var mall: GameModel = _m()
	for s in GameData.stickers:
		StickerLogic.give(mall, s["id"])
	var secret: bool = false
	for n in mall.notifications:
		if n["sig"] == "secret_end":
			secret = true
	t.check(secret, "el álbum completo avisa el final secreto")
	t.eq(StickerLogic.unique(mall), 60, "60 distintas")
	# se guarda y se carga
	var m2: GameModel = GameModel.new(1)
	m2.from_dict(JSON.parse_string(JSON.stringify(mall.to_dict())))
	t.eq(m2.stickers.size(), 60, "el álbum se guarda")
	# los billetes voladores pueden dar figuritas
	var me: GameModel = _m()
	for i in range(40):
		me.bill_timer = 0.0
		EconomyLogic.tick(me, 0.1)
		EconomyLogic.click_bill(me, int(me.bills_active[0]["id"]), "sticker")
	t.check(me.stickers.size() >= 10, "los billetes voladores dejan figuritas (%d)" % me.stickers.size())
