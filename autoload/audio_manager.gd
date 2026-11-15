extends Node
## Barramentos Music, SFX e UI; crossfade de música por cena.
## Os arquivos são opcionais: assets/audio/music/<key>.mp3 e assets/audio/sfx/<key>.mp3.
## Chave sem arquivo é ignorada em silêncio, então o jogo roda sem áudio.
##
## Além de play_music / play_sfx:
##   • start_loop_sfx / stop_loop_sfx → som contínuo (ex.: a nave em movimento no warp).
##   • start_typing / stop_typing     → som da digitação do balão (um player só).
##   • Clique de botão: todo BaseButton que entra na árvore toca "click" no bus UI,
##     exceto os do grupo `no_click_sound` (que tocam o próprio som).
## Os loops (bg, ending, ship_flying) são ligados na importação (.import → loop=true).

const MUSIC_PATH := "res://assets/audio/music/%s.mp3"
const SFX_PATH := "res://assets/audio/sfx/%s.mp3"
const BUSES: Array[String] = ["Music", "SFX", "UI"]
const NO_CLICK_GROUP := &"no_click_sound"
const SILENT_DB := -40.0

var _music: AudioStreamPlayer
var _music_key: StringName = &""
var _music_tween: Tween
var _loops: Dictionary = {}          # key -> AudioStreamPlayer (sons contínuos ativos)
var _typing_player: AudioStreamPlayer
var _typing_active := false


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
	get_tree().node_added.connect(_on_node_added)


# --- Música -------------------------------------------------------------------

func play_music(key: StringName) -> void:
	if key == _music_key:
		return
	_music_key = key
	if _music_tween:
		_music_tween.kill()
	var path := MUSIC_PATH % key
	if not ResourceLoader.exists(path):
		_music.stop()
		return
	_music_tween = create_tween()
	if _music.playing:
		_music_tween.tween_property(_music, "volume_db", SILENT_DB, 0.6)
	_music_tween.tween_callback(func() -> void:
		_music.stream = load(path)
		_music.volume_db = SILENT_DB
		_music.play())
	_music_tween.tween_property(_music, "volume_db", 0.0, 0.8)


# --- Efeitos ------------------------------------------------------------------

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


## Começa um som contínuo (o arquivo precisa ter loop ligado na importação).
## Chamar de novo com a mesma key enquanto ele toca não faz nada.
func start_loop_sfx(key: StringName, bus: StringName = &"SFX") -> void:
	if _loops.has(key):
		return
	var path := SFX_PATH % key
	if not ResourceLoader.exists(path):
		return
	var p := AudioStreamPlayer.new()
	p.stream = load(path)
	p.bus = bus
	add_child(p)
	p.play()
	_loops[key] = p


## Para o som contínuo com fade-out.
func stop_loop_sfx(key: StringName, fade := 0.4) -> void:
	if not _loops.has(key):
		return
	var p: AudioStreamPlayer = _loops[key]
	_loops.erase(key)                      # um novo start_loop_sfx já cria outro player
	var t := create_tween()
	t.tween_property(p, "volume_db", SILENT_DB, maxf(fade, 0.01))
	t.tween_callback(p.queue_free)


# --- Digitação do balão -------------------------------------------------------

## Som de digitação (um player só, sem sobrepor). Se o arquivo for mais curto
## que a fala, recomeça ao terminar enquanto a digitação continuar.
## key: &"dialog_typing" (Lyra/narrador) ou &"robot_talk" (equipamento falando).
func start_typing(key: StringName = &"dialog_typing") -> void:
	var path := SFX_PATH % key
	if not ResourceLoader.exists(path):
		stop_typing()
		return
	if _typing_player == null:
		_typing_player = AudioStreamPlayer.new()
		_typing_player.bus = &"SFX"
		add_child(_typing_player)
		_typing_player.finished.connect(_on_typing_finished)
	var stream: AudioStream = load(path)
	if _typing_active and _typing_player.stream == stream:
		return
	_typing_player.stream = stream
	_typing_active = true
	_typing_player.play()


func stop_typing() -> void:
	_typing_active = false
	if _typing_player:
		_typing_player.stop()


func _on_typing_finished() -> void:
	if _typing_active:
		_typing_player.play()


# --- Clique de botão ----------------------------------------------------------

func _on_node_added(node: Node) -> void:
	if not node is BaseButton:
		return
	var cb := _on_button_pressed.bind(node)
	if not (node as BaseButton).pressed.is_connected(cb):
		(node as BaseButton).pressed.connect(cb)


## O grupo é checado no momento do clique (a cena pode adicioná-lo depois do node_added).
func _on_button_pressed(button: BaseButton) -> void:
	if is_instance_valid(button) and not button.is_in_group(NO_CLICK_GROUP):
		play_sfx(&"click", &"UI")


# --- Volumes ------------------------------------------------------------------

func _apply_volumes() -> void:
	_set_bus(&"Music", Settings.music_volume)
	_set_bus(&"SFX", Settings.sfx_volume)
	_set_bus(&"UI", Settings.sfx_volume)


func _set_bus(bus: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
