class_name SoundFx
extends Node
## Sonidos y música generados por código (sin archivos de audio).

static var instance: SoundFx

const RATE: int = 22050

var _sounds: Dictionary = {}
var _players: Array = []
var _music: AudioStreamPlayer


func _ready() -> void:
	instance = self
	_sounds["click"] = _make([{"f": 700.0, "d": 0.06, "v": 0.35, "slide": 0.5}])
	_sounds["coin"] = _make([{"f": 1318.0, "d": 0.07, "v": 0.3}, {"f": 1760.0, "d": 0.16, "v": 0.3}])
	_sounds["register"] = _make([{"f": 200.0, "d": 0.04, "v": 0.5, "noise": 0.9}, {"f": 2093.0, "d": 0.35, "v": 0.3}])
	_sounds["buy"] = _make([{"f": 523.0, "d": 0.07, "v": 0.3}, {"f": 659.0, "d": 0.07, "v": 0.3}, {"f": 784.0, "d": 0.14, "v": 0.3}])
	_sounds["raise"] = _make([{"f": 440.0, "d": 0.18, "v": 0.35, "slide": -0.4}, {"f": 330.0, "d": 0.28, "v": 0.35, "slide": -0.4}])
	_sounds["snip"] = _make([{"f": 3000.0, "d": 0.05, "v": 0.4, "noise": 0.95}, {"f": 2500.0, "d": 0.08, "v": 0.4, "noise": 0.95}])
	_sounds["event"] = _make([{"f": 392.0, "d": 0.1, "v": 0.3}, {"f": 392.0, "d": 0.1, "v": 0.3}, {"f": 523.0, "d": 0.2, "v": 0.3}])
	_sounds["win"] = _make([{"f": 523.0, "d": 0.12, "v": 0.3}, {"f": 659.0, "d": 0.12, "v": 0.3}, {"f": 784.0, "d": 0.12, "v": 0.3}, {"f": 1047.0, "d": 0.4, "v": 0.3}])
	_sounds["error"] = _make([{"f": 180.0, "d": 0.12, "v": 0.3}])
	_sounds["rip"] = _make([{"f": 900.0, "d": 0.28, "v": 0.5, "noise": 0.95, "slide": -0.6}])
	_sounds["flip"] = _make([{"f": 520.0, "d": 0.05, "v": 0.3, "slide": 0.8}, {"f": 780.0, "d": 0.06, "v": 0.3}])
	_sounds["gold"] = _make([{"f": 1047.0, "d": 0.08, "v": 0.3}, {"f": 1319.0, "d": 0.08, "v": 0.3}, {"f": 1568.0, "d": 0.08, "v": 0.3}, {"f": 2093.0, "d": 0.12, "v": 0.3}, {"f": 2637.0, "d": 0.3, "v": 0.3}])
	_sounds["scratch"] = _make([{"f": 2200.0, "d": 0.07, "v": 0.25, "noise": 1.0}])
	_sounds["drum"] = _make([{"f": 90.0, "d": 0.18, "v": 0.6, "slide": -0.4}])
	_sounds["lose"] = _make([{"f": 330.0, "d": 0.14, "v": 0.3, "slide": -0.3}, {"f": 247.0, "d": 0.3, "v": 0.3, "slide": -0.3}])
	_sounds["stamp"] = _make([{"f": 140.0, "d": 0.08, "v": 0.6, "noise": 0.5}])
	_sounds["jackpot"] = _make([{"f": 523.0, "d": 0.1, "v": 0.3}, {"f": 659.0, "d": 0.1, "v": 0.3}, {"f": 784.0, "d": 0.1, "v": 0.3}, {"f": 1047.0, "d": 0.1, "v": 0.3}, {"f": 784.0, "d": 0.1, "v": 0.3}, {"f": 1047.0, "d": 0.1, "v": 0.3}, {"f": 1319.0, "d": 0.5, "v": 0.3}])
	for i in range(8):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.stream = _make_music()
	add_child(_music)
	apply_music_volume()


func apply_music_volume() -> void:
	if _music == null:
		return
	_music.volume_db = linear_to_db(maxf(Settings.music, 0.0001)) - 8.0
	if Settings.music <= 0.001:
		_music.stop()
	elif not _music.playing:
		_music.play()


## La música se acelera con la inflación (rate mensual: 0.03 .. 1.0+).
func set_tempo_from_inflation(rate: float) -> void:
	if _music != null:
		_music.pitch_scale = clampf(1.0 + rate * 0.5, 1.0, 1.9)


func play(sound: String, pitch: float = 1.0) -> void:
	if not _sounds.has(sound):
		return
	for p in _players:
		if not p.playing:
			p.stream = _sounds[sound]
			p.pitch_scale = pitch
			p.play()
			return


static func _make(parts: Array) -> AudioStreamWAV:
	var samples: PackedFloat32Array = PackedFloat32Array()
	for p in parts:
		var count: int = int(RATE * float(p["d"]))
		var phase: float = 0.0
		var noise: float = float(p.get("noise", 0.0))
		var slide: float = float(p.get("slide", 0.0))
		for i in range(count):
			var t: float = float(i) / float(count)
			phase += TAU * float(p["f"]) * (1.0 + slide * t) / float(RATE)
			var env: float = (1.0 - t) * minf(1.0, t * 40.0)
			var s: float = sin(phase) * (1.0 - noise) + (randf() * 2.0 - 1.0) * noise
			samples.append(s * env * float(p["v"]))
	return _to_wav(samples, false)


static func _make_music() -> AudioStreamWAV:
	# Arpegio simple en La menor pentatónica, 8 pasos de 0.25 s con bajo.
	var notes: Array = [220.0, 261.6, 329.6, 392.0, 440.0, 392.0, 329.6, 261.6]
	var samples: PackedFloat32Array = PackedFloat32Array()
	for n in notes:
		var count: int = int(RATE * 0.25)
		var phase: float = 0.0
		var phase_b: float = 0.0
		for i in range(count):
			var t: float = float(i) / float(count)
			phase += TAU * float(n) / float(RATE)
			phase_b += TAU * float(n) * 0.5 / float(RATE)
			var env: float = (1.0 - t * 0.7) * minf(1.0, t * 30.0)
			var tri: float = asin(sin(phase)) * 0.6366
			samples.append((tri * 0.5 + sin(phase_b) * 0.3) * env * 0.5)
	return _to_wav(samples, true)


static func _to_wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples.size() * 2)
	for i in range(samples.size()):
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var w: AudioStreamWAV = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w
