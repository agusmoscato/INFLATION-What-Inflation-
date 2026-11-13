class_name Unlocks
extends RefCounted
## Desbloqueo progresivo: cada mecánica aparece sola en su momento (y se anuncia una vez).

## Orden de anuncio. "tab" = pestaña que se desbloquea (para la flecha).
const FEATURES: Array = ["upgrades", "album", "events", "refuges", "reform", "timba", "quiniela", "dollar"]
const TAB_OF: Dictionary = {"upgrades": 1, "refuges": 2, "reform": 3, "album": 4, "timba": 5, "quiniela": 5, "dollar": 5}


static func is_met(m: GameModel, f: String) -> bool:
	match f:
		"upgrades": return m.total_businesses() >= 1 or m.era >= 2 or m.reforms > 0
		"album": return m.owned_count("kiosco") >= 1 or m.era >= 2 or m.reforms > 0
		"events": return m.era >= 2
		"refuges": return m.era >= 2 or m.reforms > 0
		"reform": return m.era >= 2
		"timba": return m.era >= 2
		"quiniela": return m.era >= 3 and not m.demo_mode
		"dollar": return m.era >= 3 and not m.demo_mode
	return false


## ¿Está disponible la mecánica? (una vez anunciada queda disponible aunque el estado cambie)
static func has(m: GameModel, f: String) -> bool:
	return m.unlocked.has(f) or is_met(m, f)


## Anuncia las mecánicas que se acaban de cumplir. Devuelve sus ids.
static func update(m: GameModel) -> Array:
	var fresh: Array = []
	for f in FEATURES:
		if not m.unlocked.has(f) and is_met(m, f):
			m.unlocked[f] = true
			fresh.append(f)
			m.push("unlock", [f])
	return fresh


## Marca como ya vistas las mecánicas actuales sin anunciarlas (al cargar una partida vieja).
static func sync_silent(m: GameModel) -> void:
	for f in FEATURES:
		if is_met(m, f):
			m.unlocked[f] = true
