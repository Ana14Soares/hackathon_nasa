extends Node
## Única porta de entrada do conteúdo: as cenas pedem um id e recebem
## ExplorerData e StoryData prontos.

const REGISTRY := preload("res://data/registry.tres")
const PROTAGONIST_CARD := preload("res://data/protagonist_card.tres")

var first_explorer: StringName:
	get:
		return REGISTRY.first_explorer

var protagonist_card: ProtagonistCard:
	get:
		return PROTAGONIST_CARD

var _by_id: Dictionary = {}
var _stories: Dictionary = {}


func _ready() -> void:
	for e in REGISTRY.explorers:
		_by_id[e.id] = e


func all_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for e in REGISTRY.explorers:
		out.append(e.id)
	return out


func has_explorer(id: StringName) -> bool:
	return _by_id.has(id)


func get_explorer(id: StringName) -> ExplorerData:
	return _by_id.get(id)


## Os N pontos pendentes mais próximos de onde a protagonista está agora.
func available_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	var here := get_explorer(GameState.current_explorer)
	var origin := here.radar_position if here else Vector2.ZERO
	var pending: Array[ExplorerData] = []
	for e in REGISTRY.explorers:
		if GameState.get_status(e.id) != GameState.Status.COMPLETED and _gates_ok(e):
			pending.append(e)
	pending.sort_custom(func(a: ExplorerData, b: ExplorerData) -> bool:
		return a.radar_position.distance_to(origin) < b.radar_position.distance_to(origin))
	for i in mini(REGISTRY.unlock_count, pending.size()):
		out.append(pending[i].id)
	return out


func _gates_ok(e: ExplorerData) -> bool:      # unlock_after é uma trava opcional
	for dep in e.unlock_after:
		if GameState.get_status(dep) != GameState.Status.COMPLETED:
			return false
	return true


func get_reward(id: StringName) -> RewardData:
	for e in REGISTRY.explorers:
		if e.reward and e.reward.id == id:
			return e.reward
	return null


func get_story(id: StringName) -> StoryData:
	if _stories.has(id):
		return _stories[id]
	var base := get_explorer(id).resource_path.get_base_dir()
	var path := "%s/story.%s.json" % [base, TranslationServer.get_locale()]
	if not FileAccess.file_exists(path):
		path = "%s/story.pt_BR.json" % base          # idioma padrão
	var parsed := load_json(path)
	assert(not parsed.is_empty(), "JSON inválido: " + path)
	_stories[id] = StoryData.from_dict(parsed)
	return _stories[id]


func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Arquivo não encontrado: " + path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_error("JSON inválido: " + path)
	return {}


## Falas de cenas fixas (história inicial e final): {"lines": [...]}.
func load_lines(path: String) -> Array[DialogueLine]:
	return DialogueLine.list_from(load_json(path).get("lines", []))
