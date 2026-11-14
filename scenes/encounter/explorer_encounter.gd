extends Control
## Controlador do encontro (cena reutilizável para todos os equipamentos).
## Lê o explorador atual do GameState e roda as fases como corrotinas lineares:
## CHEGADA → SCAN → DIÁRIO → FECHAMENTO → RADAR.

enum Phase { ARRIVAL, AWAIT_SCAN, SCANNING, AWAIT_DIARY, WRAP_UP, AWAIT_RADAR }

## Quais itens ficam clicáveis e pulsando em cada fase.
const RULES := {
	Phase.ARRIVAL:     {"enabled": [], "pulse": []},
	Phase.AWAIT_SCAN:  {"enabled": [&"scan", &"id_card"], "pulse": [&"scan"]},
	Phase.SCANNING:    {"enabled": [], "pulse": []},
	Phase.AWAIT_DIARY: {"enabled": [&"diary", &"id_card"], "pulse": [&"diary"]},
	Phase.WRAP_UP:     {"enabled": [], "pulse": []},
	Phase.AWAIT_RADAR: {"enabled": [&"diary", &"id_card", &"radar"], "pulse": [&"radar"]},
}
const ITEMS: Array[StringName] = [&"scan", &"diary", &"radar", &"id_card"]

@onready var ship: ShipInterior = %ShipInterior
@onready var dialogue: DialogueBox = %DialogueBox
@onready var scan_overlay: ScanOverlay = %ScanOverlay
@onready var diary: DiaryBook = %DiaryBook
@onready var id_card: IdCardOverlay = %IdCardOverlay
@onready var reward_popup: RewardPopup = %RewardPopup

var data: ExplorerData
var story: StoryData
var phase: Phase


func _ready() -> void:
	if not ContentDB.has_explorer(GameState.current_explorer):
		GameState.current_explorer = ContentDB.first_explorer   # atalho de depuração
	data = ContentDB.get_explorer(GameState.current_explorer)
	story = ContentDB.get_story(data.id)
	dialogue.explorer_context = data
	ship.show_explorer(data)
	for r in GameState.artifacts:
		ship.place_artifact(ContentDB.get_reward(r))
	ship.item_activated.connect(_on_item_activated)
	diary.closed.connect(_on_diary_closed)
	dialogue.talking_changed.connect(_on_talking_changed)
	# Já escaneado (retomada ou revisita): o equipamento continua personificado.
	var st := GameState.get_status(data.id)
	ship.set_personified(st == GameState.Status.SCANNED or st == GameState.Status.COMPLETED, false)
	AudioManager.play_music(&"encounter")
	phase = Phase.ARRIVAL
	_apply_rules()
	if SceneRouter.is_busy():
		await SceneRouter.transition_finished
	_enter_phase(_phase_from_status())


func _phase_from_status() -> Phase:
	match GameState.get_status(data.id):
		GameState.Status.SCANNED:
			return Phase.AWAIT_DIARY
		GameState.Status.COMPLETED:
			return Phase.AWAIT_RADAR
		_:
			return Phase.ARRIVAL   # repete a chegada, é curta


func _enter_phase(p: Phase) -> void:
	phase = p
	_apply_rules()
	match p:
		Phase.ARRIVAL:
			GameState.set_status(data.id, GameState.Status.ARRIVED)
			await dialogue.play(story.arrival)
			_enter_phase(Phase.AWAIT_SCAN)
		Phase.SCANNING:
			await scan_overlay.run(story.scan, data, dialogue)   # overlay + falas + imagens
			GameState.set_status(data.id, GameState.Status.SCANNED)
			_enter_phase(Phase.AWAIT_DIARY)
		Phase.WRAP_UP:
			await _wrap_up()
		_:
			pass   # fases de espera: só aguardam o jogador


func _apply_rules() -> void:
	var rule: Dictionary = RULES[phase]
	for item in ITEMS:
		var enabled: bool = item in rule["enabled"]
		if item == &"radar":
			enabled = enabled and GameState.get_flag(&"radar_unlocked")
		ship.set_item_state(item, enabled, enabled and item in rule["pulse"])


func _on_item_activated(item: StringName) -> void:
	match item:
		&"scan":
			if phase == Phase.AWAIT_SCAN:
				_enter_phase(Phase.SCANNING)
		&"diary":
			diary.open(data, story)
		&"id_card":
			id_card.open()
		&"radar":
			SceneRouter.go_to(&"radar", &"radar")


## Quando o equipamento se apresenta no scan, ganha um rostinho e "fala" o balão.
func _on_talking_changed(speaker: ExplorerData, talking: bool) -> void:
	if speaker != data:
		return
	ship.set_personified(true)
	ship.set_face_talking(talking)


func _on_diary_closed() -> void:
	if phase == Phase.AWAIT_DIARY:   # nas outras fases, fechar não muda nada
		_enter_phase(Phase.WRAP_UP)


func _wrap_up() -> void:
	await dialogue.play(story.wrap_up)
	if data.reward:
		var first_time := not (data.reward.id in GameState.artifacts)
		GameState.grant_reward(data.reward)           # idempotente: artefato + flags
		if first_time:
			reward_popup.open(data.reward)
			await reward_popup.closed
		ship.place_artifact(data.reward)              # a placa aparece na estante
		await dialogue.play(story.reward_lines)
	GameState.set_status(data.id, GameState.Status.COMPLETED)
	if GameState.is_all_completed():
		SceneRouter.go_to(&"ending")
	else:
		_enter_phase(Phase.AWAIT_RADAR)
