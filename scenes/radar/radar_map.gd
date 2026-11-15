extends Control
## Radar: escolha do próximo equipamento.
##
## Fundo desenhado + um nó por equipamento dentro de `Map` (nome do nó = id dele).
## Você controla tudo pelo editor:
##   • POSIÇÃO e TAMANHO de cada ponto: arraste/redimensione o nó em Map (coordenadas
##     da arte 1920×1080).
##   • ARTE de cada ponto: no .tres do equipamento — Radar Icon Unknown (não descoberto)
##     e Radar Icon (descoberto).
## O nó `Map` é escalado e centralizado como o fundo (cobrindo a tela), então os
## pontos ficam sempre sobre o mesmo lugar da arte, em qualquer janela.
##
## Quais pontos aparecem: os N pendentes mais próximos de onde a Lyra está — medido
## pela posição dos nós na cena (o que você vê na tela), com N = unlock_count do
## registro — e os já visitados. Os demais ficam escondidos.

## Imagem de fundo do radar (arraste aqui, no nó raiz RadarMap). Proporção 16:9.
@export var background: Texture2D

const DESIGN_SIZE := Vector2(1920, 1080)
const SHIP_OFFSET := Vector2(0, -85)   # nave em relação ao centro do ponto atual (arte 1920×1080)

@onready var _background: TextureRect = %Background
@onready var _map: Control = %Map
@onready var _ship: TextureRect = %Ship
@onready var _back_btn: Button = %BackButton
@onready var _confirm: ConfirmOverlay = %ConfirmOverlay

var _markers: Dictionary = {}   # id -> RadarMarker


func _ready() -> void:
	AudioManager.play_music(&"bg")
	AudioManager.play_sfx(&"radar_map")
	if background:
		_background.texture = background
	resized.connect(_fit_map)
	_back_btn.pressed.connect(func() -> void: SceneRouter.go_to(&"encounter", &"fade"))
	_back_btn.visible = ContentDB.has_explorer(GameState.current_explorer)
	_setup_markers()
	_fit_map()
	_place_ship()


func _setup_markers() -> void:
	var available := _available_ids()             # os pontos mais próximos dela
	for child in _map.get_children():
		if not child is RadarMarker:
			continue
		var m := child as RadarMarker
		if not ContentDB.has_explorer(m.explorer_id):
			m.visible = false
			continue
		var status := GameState.get_status(m.explorer_id)
		if status != GameState.Status.COMPLETED and not m.explorer_id in available:
			m.visible = false                     # longe demais: ainda não aparece
			continue
		m.setup(ContentDB.get_explorer(m.explorer_id), status)
		m.chosen.connect(_on_marker_chosen)
		_markers[m.explorer_id] = m
	if not available.is_empty() and _markers.has(available[0]):
		(_markers[available[0]] as Control).grab_focus.call_deferred()


## Os N pendentes mais próximos do ponto onde a Lyra está agora (pela posição na cena).
func _available_ids() -> Array[StringName]:
	var here: Control = _map.get_node_or_null(NodePath(String(GameState.current_explorer)))
	var origin := (here.position + here.size / 2.0) if here else Vector2.ZERO
	var pending: Array[RadarMarker] = []
	for child in _map.get_children():
		if not child is RadarMarker:
			continue
		var m := child as RadarMarker
		if not ContentDB.has_explorer(m.explorer_id):
			continue
		if GameState.get_status(m.explorer_id) != GameState.Status.COMPLETED \
				and ContentDB.gates_ok(ContentDB.get_explorer(m.explorer_id)):
			pending.append(m)
	pending.sort_custom(func(a: RadarMarker, b: RadarMarker) -> bool:
		return a.position.distance_to(origin) < b.position.distance_to(origin))
	var out: Array[StringName] = []
	for i in mini(ContentDB.unlock_count, pending.size()):
		out.append(pending[i].explorer_id)
	return out


## A nave da Lyra fica ao lado do ponto onde ela está agora.
func _place_ship() -> void:
	var here: RadarMarker = _map.get_node_or_null(NodePath(String(GameState.current_explorer)))
	_ship.visible = here != null
	if here == null:
		return
	_ship.position = here.position + here.size / 2.0 + SHIP_OFFSET - _ship.size / 2.0
	_ship.pivot_offset = _ship.size / 2.0
	if not Settings.reduce_motion:
		var t := create_tween().set_loops()
		t.tween_property(_ship, "rotation", -0.06, 1.4).set_trans(Tween.TRANS_SINE)   # balanço suave
		t.tween_property(_ship, "rotation", 0.06, 1.4).set_trans(Tween.TRANS_SINE)


## Mesmo enquadramento do fundo (cobrir a tela, centralizado).
func _fit_map() -> void:
	var k := maxf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	_map.scale = Vector2(k, k)
	_map.position = (size - DESIGN_SIZE * k) / 2.0


func _on_marker_chosen(id: StringName) -> void:
	if not await _confirm.ask("Travel here?", "Travel", "Stay"):
		return
	GameState.set_current_explorer(id)            # grava o checkpoint
	SceneRouter.go_to(&"encounter", &"warp")      # viaja e continua na nave
