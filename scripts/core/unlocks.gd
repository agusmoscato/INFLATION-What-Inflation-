class_name Unlocks
extends RefCounted
## Desbloqueo progresivo: cada mecánica aparece sola en su momento (y se anuncia una vez).
##
## Ritmo (data/balance.json > pacing): como mucho UNA mecánica nueva cada 2 minutos o más, y solo cuando el jugador ya
## usó la anterior. Cadena: empanada -> carrito -> kiosco -> inflación (min 2) -> remarcar (min 4) -> mejoras (min 6) ->
## figuritas (min 9) -> refugios -> eventos -> timba -> reforma (por era, una cada 2,5 min) -> quiniela y dólar (Era 3).
## Las partidas viejas (Era 2 o con reformas) tienen todo desbloqueado.

## Orden de la cadena. "tab" = pestaña que se desbloquea (para la flecha).
const FEATURES: Array = ["inflation", "remark", "upgrades", "album", "refuges", "events", "timba", "reform", "quiniela", "dollar"]
const TAB_OF: Dictionary = {"upgrades": 1, "refuges": 2, "reform": 3, "album": 4, "timba": 5, "quiniela": 5, "dollar": 5}


static func _p(key: String) -> float:
	return float(GameData.balance["pacing"][key])


## Tiempo (s de juego) en que se anunció la mecánica; 0 si no consta.
static func time_of(m: GameModel, f: String) -> float:
	var v: Variant = m.unlocked.get(f, 0.0)
	return float(v) if (v is float or v is int) else 0.0


## ¿Ya "usó" la mecánica anterior? (o pasó el tiempo suficiente como para no trabar a nadie)
static func used(m: GameModel, f: String) -> bool:
	var since: float = m.time_played - time_of(m, f)
	match f:
		"inflation": return since >= _p("use_inflation_s")
		"remark": return m.remarks >= 1 or since >= _p("use_fallback_s")
		"upgrades": return m.upgrades.size() >= 1 or since >= _p("use_fallback_s")
		"album": return m.packs_opened >= 1 or since >= _p("use_fallback_s")
	return since >= _p("gap_late")


static func _old_save(m: GameModel) -> bool:
	return m.era >= 2 or m.reforms > 0


static func is_met(m: GameModel, f: String) -> bool:
	var t: float = m.time_played
	match f:
		"inflation": return _old_save(m) or (m.total_businesses() >= 1 and t >= _p("inflation_at"))
		"remark": return _old_save(m) or (m.unlocked.has("inflation") and used(m, "inflation") and t >= _p("remark_at"))
		"upgrades": return _old_save(m) or (m.unlocked.has("remark") and used(m, "remark") and t >= _p("upgrades_at"))
		"album": return _old_save(m) or (m.unlocked.has("upgrades") and used(m, "upgrades") and m.owned_count("kiosco") >= 1 and t >= _p("album_at"))
		"refuges": return m.unlocked.has("album") and _old_save(m)
		"events": return m.unlocked.has("refuges") and m.era >= 2
		"timba": return m.unlocked.has("events") and m.era >= 2
		"reform": return m.unlocked.has("timba") and m.era >= 2
		"quiniela": return m.era >= 3 and not m.demo_mode and m.unlocked.has("timba")
		"dollar": return m.era >= 3 and not m.demo_mode and m.unlocked.has("timba")
	return false


## ¿Está disponible la mecánica? (una vez anunciada queda disponible aunque el estado cambie)
static func has(m: GameModel, f: String) -> bool:
	return m.unlocked.has(f)


## Separación mínima (s) desde el último anuncio: la cadena temprana va más seguido que la tardía.
static func gap_for(f: String) -> float:
	return _p("gap_early") if ["inflation", "remark", "upgrades", "album"].has(f) else _p("gap_late")


## Segundos que faltan (como mucho) hasta que `f` pueda desbloquearse por tiempo; 0 si ya se puede o depende de otra cosa.
static func time_left(m: GameModel, f: String) -> float:
	if m.unlocked.has(f):
		return 0.0
	var need: float = 0.0
	match f:
		"inflation": need = _p("inflation_at")
		"remark": need = _p("remark_at")
		"upgrades": need = _p("upgrades_at")
		"album": need = _p("album_at")
	return maxf(0.0, need - m.time_played)


## Anuncia como mucho UNA mecánica nueva por llamada (y no antes de la separación mínima). Devuelve sus ids.
static func update(m: GameModel) -> Array:
	var last: float = 0.0
	for k in m.unlocked:
		last = maxf(last, time_of(m, str(k)))
	for f in FEATURES:
		if m.unlocked.has(f):
			continue
		if is_met(m, f) and (m.time_played - last >= gap_for(f) or last <= 0.0):
			m.unlocked[f] = m.time_played
			m.push("unlock", [f])
			return [f]
		break      # la cadena es ordenada: si la siguiente no está lista, las demás esperan
	return []


## Marca como ya vistas las mecánicas actuales sin anunciarlas (al cargar una partida vieja).
static func sync_silent(m: GameModel) -> void:
	for f in FEATURES:
		if not m.unlocked.has(f) and is_met(m, f):
			m.unlocked[f] = m.time_played


## Para pruebas, capturas y clips: deja todas las mecánicas disponibles (la demo no incluye la quiniela ni el dólar).
static func unlock_all(m: GameModel) -> void:
	for f in FEATURES:
		if m.demo_mode and (f == "quiniela" or f == "dollar"):
			continue
		if not m.unlocked.has(f):
			m.unlocked[f] = m.time_played
