class_name Unlocks
extends RefCounted
## Diseño v2: las mecánicas se desbloquean comprando nodos del árbol (TreeLogic). Esta clase queda como atajo.


static func has(m: GameModel, feature: String) -> bool:
	return TreeLogic.has(m, feature)


## Para pruebas, capturas y clips: compra todo el árbol sin costo (en la demo, solo lo que la demo permite).
static func unlock_all(m: GameModel) -> void:
	for n in GameData.tree:
		if not TreeLogic.demo_locked(m, n["id"]):
			m.tree[n["id"]] = true
	m.dirty = true
