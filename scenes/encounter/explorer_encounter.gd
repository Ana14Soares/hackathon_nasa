extends Control
## Controlador do encontro (cena reutilizável para todos os equipamentos).
## Lê o explorador atual do GameState e roda as fases como corrotinas lineares:
## CHEGADA → SCAN → DIÁRIO → FECHAMENTO → RADAR.

enum Phase { ARRIVAL, AWAIT_SCAN, SCANNING, AWAIT_DIARY, WRAP_UP, AWAIT_RADAR }

## Quais itens ficam clicáveis ("enabled") e quais ficam com o visual de pressed
## ("pulse" = a dica de "clique aqui", mostrada como o estado pressed) em cada fase.
## • O diário fica ativo e com o pressed o tempo todo depois do scan.
## • O radar só abre depois do scan E do diário (fase AWAIT_RADAR), e ainda
##   depende da flag radar_unlocked (Placa Pioneer).
const RULES := {
	Phase.ARRIVAL:     {"enabled": [], "pulse": []},
	Phase.AWAIT_SCAN:  {"enabled": [&"scan", &"id_card"], "pulse": [&"scan"]},
	Phase.SCANNING:    {"enabled": [], "pulse": []},
	Phase.AWAIT_DIARY: {"enabled": [&"diary", &"id_card"], "pulse": [&"diary"]},
	Phase.WRAP_UP:     {"enabled": [&"diary"], "pulse": [&"diary"]},
	Phase.AWAIT_RADAR: {"enabled": [&"diary", &"id_card", &"radar"], "pulse": [&"diary", &"radar"]},
}
const ENDING_JSON := "res://data/ending/ending.json"
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
			await scan_overlay.run(story.scan, dialogue)   # varredura + falas
			ship.set_scanner_shown(false)                   # terminou de falar: o scanner sai do vidro
			GameState.set_status(data.id, GameState.Status.SCANNED)
			await dialogue.play(story.reaction)             # a Lyra reage; depois o diário pulsa
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
	# Radar "vazio" até a Placa Pioneer ser descoberta; depois usa default/pressed.
	ship.set_item_locked(&"radar", not GameState.get_flag(&"radar_unlocked"))


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


## Enquanto o equipamento fala (depois da varredura), o scanner aparece no vidro e anima.
## Quando o scan termina, ele sai (ver _enter_phase → SCANNING).
func _on_talking_changed(speaker: ExplorerData, talking: bool) -> void:
	if speaker != data:
		return
	ship.set_scanner_shown(true)
	ship.set_scanner_talking(talking)


func _on_diary_closed() -> void:
	if phase == Phase.AWAIT_DIARY:   # nas outras fases, fechar não muda nada
		_enter_phase(Phase.WRAP_UP)


func _wrap_up() -> void:
	# Último equipamento: no lugar da fala de "seguir viagem" vem a transição para a Terra.
	var is_last := true
	for id in ContentDB.all_ids():
		if id != data.id and GameState.get_status(id) != GameState.Status.COMPLETED:
			is_last = false
	if is_last:
		await dialogue.play(DialogueLine.list_from(ContentDB.load_json(ENDING_JSON).get("transition", [])))
	else:
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
		SceneRouter.go_to(&"ending", &"warp")          # viagem até a Terra, sem texto na tela
	else:
		_enter_phase(Phase.AWAIT_RADAR)
