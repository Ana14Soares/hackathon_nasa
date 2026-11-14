extends Node
## Barramentos Music, SFX e UI; crossfade de música por cena.
## Os arquivos são opcionais: assets/audio/music/<key>.ogg e assets/audio/sfx/<key>.ogg.
## Chave sem arquivo é ignorada em silêncio, então o jogo roda sem áudio.

const MUSIC_PATH := "res://assets/audio/music/%s.ogg"
const SFX_PATH := "res://assets/audio/sfx/%s.ogg"
const BUSES: Array[String] = ["Music", "SFX", "UI"]

var _music: AudioStreamPlayer
var _music_key: StringName = &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in BUSES:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, &"Master")
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	add_child(_music)
	Settings.changed.connect(_apply_volumes)
	_apply_volumes()


func play_music(key: StringName) -> void:
	if key == _music_key:
		return
	_music_key = key
	var path := MUSIC_PATH % key
	if not ResourceLoader.exists(path):
		_music.stop()
		return
	var t := create_tween()
	if _music.playing:
		t.tween_property(_music, "volume_db", -40.0, 0.6)
	t.tween_callback(func() -> void:
		_music.stream = load(path)
		_music.volume_db = -40.0
		_music.play())
	t.tween_property(_music, "volume_db", 0.0, 0.8)


func play_sfx(key: StringName, bus: StringName = &"SFX") -> void:
	var path := SFX_PATH % key
	if not ResourceLoader.exists(path):
		return
	var p := AudioStreamPlayer.new()
	p.stream = load(path)
	p.bus = bus
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func _apply_volumes() -> void:
	_set_bus(&"Music", Settings.music_volume)
	_set_bus(&"SFX", Settings.sfx_volume)
	_set_bus(&"UI", Settings.sfx_volume)


func _set_bus(bus: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
