extends CanvasLayer
## Único lugar que chama change_scene_to_file. Efeitos: fade, radar, warp.
## Com "reduzir movimento" ligado, todos viram fade simples.

signal transition_finished

const SCENES := {
	&"menu": "res://scenes/menu/main_menu.tscn",
	&"intro": "res://scenes/intro/intro_story.tscn",
	&"encounter": "res://scenes/encounter/explorer_encounter.tscn",
	&"radar": "res://scenes/radar/radar_map.tscn",
	&"ending": "res://scenes/ending/ending.tscn",
}
## Duração de cada metade (saída e entrada), em segundos.
const HALF := {&"fade": 0.3, &"radar": 0.5, &"warp": 1.0}

@onready var _fx: TransitionFx = $Fx
@onready var _blocker: ColorRect = $Blocker

var _busy := false
var _tween: Tween
var _skippable := false
var _started_at := 0


func _ready() -> void:
	_blocker.gui_input.connect(_on_blocker_input)


func is_busy() -> bool:
	return _busy


func go_to(scene_key: StringName, effect: StringName = &"fade", params: Dictionary = {}) -> void:
	if _busy or not SCENES.has(scene_key):
		return
	_busy = true
	if Settings.reduce_motion or not HALF.has(effect):
		effect = &"fade"
	get_tree().paused = false
	GameState.nav_params = params
	_fx.mode = effect
	_fx.visible = effect != &"fade"
	_blocker.visible = true
	_skippable = effect == &"warp"
	_started_at = Time.get_ticks_msec()
	if effect == &"warp":
		AudioManager.play_sfx(&"warp")
	var half: float = HALF[effect]

	await _animate(0.0, 1.0, half)
	get_tree().change_scene_to_file(SCENES[scene_key])
	await get_tree().process_frame
	await get_tree().process_frame
	await _animate(1.0, 0.0, half)

	_fx.visible = false
	_blocker.visible = false
	_busy = false
	transition_finished.emit()


func _animate(from: float, to: float, duration: float) -> void:
	_tween = create_tween()
	_tween.tween_method(_set_progress, from, to, duration)
	await _tween.finished


func _set_progress(p: float) -> void:
	var c := _blocker.color
	c.a = p
	_blocker.color = c
	_fx.progress = p


## O warp aceita clique para acelerar depois de meio segundo.
func _on_blocker_input(event: InputEvent) -> void:
	if not _skippable or not _tween:
		return
	if event is InputEventMouseButton and event.pressed and Time.get_ticks_msec() - _started_at > 500:
		_tween.set_speed_scale(4.0)
		_skippable = false
