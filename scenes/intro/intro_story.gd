extends Control
## História inicial: a nave vista de fora, com a Lyra relembrando — em tom de
## relato do futuro — o dia em que encontrou o Pioneer 10.

const INTRO_JSON := "res://data/intro/intro.json"

@onready var _saucer: TextureRect = %Saucer
@onready var _speck: TextureRect = %FirstExplorer
@onready var _dialogue: DialogueBox = %DialogueBox

var _line_index := 0
var _lines: Array[DialogueLine] = []


func _ready() -> void:
	AudioManager.play_music(&"intro")
	var first := ContentDB.get_explorer(ContentDB.first_explorer)
	_speck.texture = first.sprite if first else null
	_speck.modulate.a = 0.0
	if not Settings.reduce_motion:
		var t := create_tween().set_loops()
		t.tween_property(_saucer, "position:y", _saucer.position.y - 16.0, 1.8).set_trans(Tween.TRANS_SINE)
		t.tween_property(_saucer, "position:y", _saucer.position.y + 16.0, 1.8).set_trans(Tween.TRANS_SINE)
	_lines = ContentDB.load_lines(INTRO_JSON)
	_dialogue.line_started.connect(_on_line_started)
	if SceneRouter.is_busy():
		await SceneRouter.transition_finished
	await _dialogue.play(_lines)
	GameState.complete_intro()
	SceneRouter.go_to(&"encounter", &"fade")


## Nas duas últimas falas o Pioneer aparece ao longe.
func _on_line_started(_line: DialogueLine) -> void:
	_line_index += 1
	if _line_index == _lines.size() - 1:
		create_tween().tween_property(_speck, "modulate:a", 1.0, 1.2)
