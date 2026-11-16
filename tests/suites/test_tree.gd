extends RefCounted
## Árbol de habilidades: estructura (90-120 nodos, 6 ramas con capstone, final central con 6 sellos, todo alcanzable),
## visibilidad con niebla, compra con Credibilidad y efectos.


func run(t) -> void:
	GameData.ensure()
	var total: int = TreeLogic.total()
	t.check(total >= 90 and total <= 120, "entre 90 y 120 nodos (%d)" % total)
	t.eq(GameData.tree_branches.size(), 6, "6 ramas")
	var fin: Dictionary = GameData.node("final")
	t.check(fin["pos"] == Vector2.ZERO, "el final está en el centro")
	t.eq(fin["parents"].size(), 6, "el final pide los 6 sellos")
	var caps: Dictionary = {}
	var seals: Dictionary = {}
	var positions: Array = []
	for n in GameData.tree:
		var id: String = n["id"]
		if bool(n["cap"]):
			caps[n["branch"]] = id
		if bool(n["seal"]):
			seals[n["branch"]] = id
		for p in n["parents"]:
			t.check(GameData.tree_idx.has(p), "%s: el padre %s existe" % [id, p])
		t.check(int(n["cost"]) >= 1, "%s cuesta algo" % id)
		for q in positions:
			t.check((q as Vector2).distance_to(n["pos"]) > 60.0, "%s no se pisa con otro nodo" % id)
		positions.append(n["pos"])
	t.eq(caps.size(), 6, "cada rama tiene su capstone")
	t.eq(seals.size(), 6, "cada rama tiene su sello")
	for s in fin["parents"]:
		t.check(bool(GameData.node(s)["seal"]), "el final pide sellos")
	# todo alcanzable: comprando lo comprable en orden, se compra el árbol entero
	var m: GameModel = GameModel.new(1)
	m.credibility = 1 << 40
	var guard: int = 0
	while not TreeLogic.complete(m) and guard < 500:
		guard += 1
		for n in GameData.tree:
			TreeLogic.buy(m, n["id"])
	t.check(TreeLogic.complete(m), "todo el árbol es alcanzable")
	t.check(m.won, "comprar el final gana el juego")
	# visibilidad y niebla
	var mv: GameModel = GameModel.new(2)
	t.check(TreeLogic.visible(mv, "emp_1") and TreeLogic.visible(mv, "final"), "raíces y final visibles al empezar")
	t.check(not TreeLogic.visible(mv, "emp_2"), "el anillo 2 no se ve al empezar")
	t.check(TreeLogic.fog(mv, "emp_2"), "el anillo 2 aparece como niebla")
	t.check(not TreeLogic.fog(mv, "emp_3"), "lo lejano no se dibuja")
	t.check(not TreeLogic.can_buy(mv, "emp_1"), "sin Credibilidad no se compra")
	mv.credibility = 100
	t.check(TreeLogic.buy(mv, "emp_1"), "compra la raíz")
	t.eq(mv.credibility, 100 - TreeLogic.cost("emp_1"), "se paga con Credibilidad")
	t.check(TreeLogic.visible(mv, "emp_2") and TreeLogic.visible(mv, "emp_2a"), "comprar revela los vecinos")
	t.check(not TreeLogic.buy(mv, "emp_3"), "no se puede saltear el camino")
	t.check(not TreeLogic.buy(mv, "final"), "el final pide los sellos")
	# camino al final: 6 sellos, uno por rama; lo que falta baja al comprar y llega a 0 con el centro comprado
	t.eq(TreeLogic.seal_ids().size(), 6, "6 sellos")
	var mr: GameModel = GameModel.new(31)
	var r0: Dictionary = TreeLogic.road(mr)
	t.eq(int(r0["have"]), 0, "al empezar no hay sellos")
	t.check(not bool(r0["ready"]), "todavía no se puede estabilizar")
	var s0: Dictionary = r0["seals"][0]
	t.eq(int(s0["nodes"]), 4, "el sello de la rama empanada está a 4 nodos")
	t.eq(str(s0["next"]), "emp_1", "y el próximo nodo es la raíz de su rama")
	var need0: int = int(r0["need"])
	var sum_paths: int = TreeLogic.cost("final")
	for row in r0["seals"]:
		sum_paths += int(row["cost"])
	t.check(need0 > sum_paths, "lo que falta = los 6 caminos + el centro + los nodos que pide de más (%d > %d)" % [need0, sum_paths])
	t.eq(int(r0["nodes_need"]), TreeLogic.final_nodes(), "el centro pide %d nodos" % TreeLogic.final_nodes())
	mr.credibility = 100000
	var prev_have: int = 0
	var mono: bool = true
	for sid in TreeLogic.seal_ids():
		for q in TreeLogic.path_to(mr, sid):
			TreeLogic.buy(mr, q)
		var have: int = int(TreeLogic.road(mr)["have"])
		if have != prev_have + 1:
			mono = false
		prev_have = have
	t.check(mono, "cada camino comprado suma exactamente un sello")
	var r6: Dictionary = TreeLogic.road(mr)
	t.eq(int(r6["have"]), 6, "con los 6 caminos comprados están los 6 sellos")
	t.check(not bool(r6["ready"]) and not TreeLogic.can_buy(mr, "final"), "pero con 24 nodos todavía no se puede estabilizar")
	# completar los nodos que pide el centro, de los más baratos
	var guard_n: int = 0
	while TreeLogic.nodes_owned(mr) < TreeLogic.final_nodes() and guard_n < 200:
		guard_n += 1
		BotPolicy.spend_cheapest_one(mr)
	t.check(bool(TreeLogic.road(mr)["ready"]), "con los sellos y %d nodos se puede estabilizar la economía" % TreeLogic.final_nodes())
	mr.credibility = 10
	t.eq(int(TreeLogic.road(mr)["need"]), TreeLogic.cost("final") - 10, "solo falta juntar lo del centro")
	mr.credibility = 100000
	TreeLogic.buy(mr, "final")
	t.check(bool(TreeLogic.road(mr)["final_owned"]) and int(TreeLogic.road(mr)["need"]) == 0, "con el centro comprado no falta nada")
	# efectos
	var me: GameModel = GameModel.new(3)
	me.credibility = 1000
	TreeLogic.buy(me, "emp_1")
	t.near(EconomyLogic.click_value(me).to_float(), 2.0, "Empanada de horno: clic x2")
	TreeLogic.buy(me, "neg_1")
	me.owned["kiosco"] = 1
	me.dirty = true
	t.near(EconomyLogic.income_per_sec(me).to_float(), 2.0 * 2.0 * pow(1.1, me.tree.size()), "Socio del barrio: producción x2 (y cada nodo comprado suma x1,1)")
	t.eq(int((me.mods["start_biz"] as Dictionary).get("empanadas", 0)), 5, "Socio del barrio: empezás con 5 carritos")
	TreeLogic.buy(me, "inf_1")
	t.near(EconomyLogic.infl_speed(me), 0.8, "Precios cuidados: inflación -20 %")
	TreeLogic.buy(me, "fig_1")
	t.check(TreeLogic.has(me, "album") and me.free_packs_pending >= 1, "el nodo del álbum lo desbloquea con un sobre de regalo")
	TreeLogic.buy(me, "sue_1")
	TreeLogic.buy(me, "sue_2")
	t.check(GambleLogic.unlocked(me), "el nodo de la raspadita la desbloquea")
	TreeLogic.buy(me, "ren_1")
	me.run_earned = BigNumber.from_float(1e6)
	t.near(EconomyLogic.reform_gain_f(me), EconomyLogic.cred_curve(6.0) * 1.25, "Memoria colectiva: +25 % de Credibilidad")
	TreeLogic.buy(me, "neg_2")
	TreeLogic.buy(me, "neg_2b")
	me.collapse_shown = true
	EconomyLogic.do_reform(me)
	t.eq(me.owned_count("empanadas"), 15, "Apertura con carrito: la vuelta empieza con 15 carritos")
	# demo: solo anillos 1-3
	var md: GameModel = GameModel.new(4)
	md.demo_mode = true
	t.check(TreeLogic.demo_locked(md, "emp_4") and not TreeLogic.demo_locked(md, "emp_3"), "la demo llega hasta el anillo 3")
	t.check(TreeLogic.demo_locked(md, "final"), "la demo no tiene final")
	md.reforms = 3
	md.run_earned = BigNumber.from_float(1e9)
	t.check(not EconomyLogic.can_reform(md), "la demo tiene 3 reformas")
	# costos: con la Credibilidad de una reforma típica se compran 2 a 5 nodos (anillos 1 a 3)
	t.check(TreeLogic.cost("emp_1") <= 4, "las raíces son baratas")
	t.check(TreeLogic.final_nodes() >= 50, "el centro pide muchos nodos comprados (%d)" % TreeLogic.final_nodes())
	t.check(TreeLogic.cost("final") < TreeLogic.cost("emp_4a"), "y cuesta menos que los nodos de al lado de los sellos (el que gasta en lo más barato también llega)")
