extends Control
## Radar solar: seleção do próximo equipamento. O radar fica sempre centralizado
## na tela; o diário fica na lateral esquerda. Os marcadores são montados a
## partir dos dados (desbloqueio por proximidade).

const MARKER_SCENE := preload("res://scenes/radar/radar_marker.tscn")
const SCREEN_FRACTION := 0.86   # o radar ocupa 86% do menor lado da tela

@onready var _display: RadarDisplay = %RadarDisplay
@onready var _markers: Control = %Markers
@onready var _you: Control = %YouAreHere
@onready var _info_title: Label = %InfoTitle
@onready var _info_text: Label = %InfoText
@onready var _diary_btn: Button = %DiaryButton
@onready var _card_btn: Button = %IdCardButton
@onready var _back_btn: Button = %BackButton
@onready var _diary: DiaryBook = %DiaryBook
@onready var _id_card: IdCardOverlay = %IdCardOverlay
@onready var _confirm: ConfirmOverlay = %ConfirmOverlay

var _marker_by_id: Dictionary = {}


func _ready() -> void:
	AudioManager.play_music(&"radar")
	resized.connect(_layout)
	_display.resized.connect(_place_markers)
	_diary_btn.pressed.connect(_diary.open_collection)
	_card_btn.pressed.connect(_id_card.open)
	_back_btn.pressed.connect(func() -> void: SceneRouter.go_to(&"encounter", &"fade"))
	_back_btn.visible = ContentDB.has_explorer(GameState.current_explorer)
	_build_markers()
	_layout()
	_show_default_info()


## Mantém o radar quadrado e centralizado em qualquer proporção de tela.
func _layout() -> void:
	var side := minf(size.x, size.y) * SCREEN_FRACTION
	_display.offset_left = -side / 2.0
	_display.offset_right = side / 2.0
	_display.offset_top = -side / 2.0
	_display.offset_bottom = side / 2.0


func _build_markers() -> void:
	var available := ContentDB.available_ids()    # os pontos mais próximos dela
	for id in ContentDB.all_ids():
		var status := GameState.get_status(id)
		if status != GameState.Status.COMPLETED and not id in available:
			continue                              # longe demais: ainda não aparece
		var data := ContentDB.get_explorer(id)
		var marker: RadarMarker = MARKER_SCENE.instantiate()
		_markers.add_child(marker)
		marker.setup(data, status)
		marker.chosen.connect(_on_marker_chosen)
		marker.focused_info.connect(_on_marker_info)
		_marker_by_id[id] = marker
	_place_markers.call_deferred()
	if not available.is_empty():
		(_marker_by_id[available[0]] as Control).grab_focus.call_deferred()


func _place_markers() -> void:
	for id in _marker_by_id:
		var m: RadarMarker = _marker_by_id[id]
		m.place_at(_display.units_to_local(ContentDB.get_explorer(id).radar_position))
	var here := ContentDB.get_explorer(GameState.current_explorer)
	_you.visible = here != null
	if here:
		_you.position = _display.units_to_local(here.radar_position) - _you.size / 2.0 + Vector2(0, 58)


func _show_default_info() -> void:
	if ContentDB.available_ids().is_empty():
		_info_title.text = "All remembered"
		_info_text.text = "You found every explorer. Open the log to read their stories again."
	else:
		_info_title.text = "Solar radar"
		_info_text.text = "The \"?\" points are signals near you. Pick one to travel there."


func _on_marker_info(id: StringName, revealed: bool) -> void:
	if revealed:
		var d := ContentDB.get_explorer(id)
		_info_title.text = d.display_name
		_info_text.text = d.subtitle + "\nAlready recorded in the log."
	else:
		_info_title.text = "Unknown area"
		_info_text.text = "A faint signal... something made by humans is out there."


func _on_marker_chosen(id: StringName) -> void:
	if not await _confirm.ask("Travel here?", "Travel", "Stay"):
		return
	GameState.set_current_explorer(id)            # grava o checkpoint
	SceneRouter.go_to(&"encounter", &"warp")      # viaja e continua na nave
