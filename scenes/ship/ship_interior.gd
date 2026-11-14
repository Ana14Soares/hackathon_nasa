class_name ShipInterior
extends Control
## Só visão: a sala de controle. Expõe uma API pequena; quem decide o que
## acontece é o controlador do encontro.
##
## Layout fixo dos itens:
##   • IdCard        → canto superior esquerdo
##   • DiaryObject   → painel de controle, à esquerda do radar solar
##   • RadarScreen   → centro do painel
##   • ScanButton    → direita do painel

signal item_activated(item_id: StringName)   # "scan", "diary", "radar", "id_card"

const REF_SIZE := Vector2(1920, 1080)

@onready var _backdrop: TextureRect = %Backdrop
@onready var _sprite: TextureRect = %ExplorerSprite
@onready var _face: CuteFace = %ExplorerFace
@onready var _shelf: HBoxContainer = %ArtifactShelf
@onready var _items: Dictionary = {
	&"scan": %ScanButton,
	&"diary": %DiaryObject,
	&"radar": %RadarScreen,
	&"id_card": %IdCard,
}

var _view_position := REF_SIZE / 2.0
var _view_scale := 1.0
var _idle_motion := false
var _face_position := Vector2(0.5, 0.5)
var _face_size := 0.3
var _float_tween: Tween


func _ready() -> void:
	for id in _items:
		var item: Interactable = _items[id]
		item.activated.connect(item_activated.emit)
		item.set_state(false, false)
	resized.connect(_layout_sprite)
	Settings.changed.connect(_layout_sprite)


func show_explorer(data: ExplorerData) -> void:
	_backdrop.texture = data.window_backdrop
	_sprite.texture = data.sprite
	_sprite.visible = data.sprite != null
	_view_position = data.view_position
	_view_scale = data.view_scale
	_idle_motion = data.idle_motion
	_face_position = data.face_position
	_face_size = data.face_size
	_face.visible = false
	_layout_sprite()


## Depois do scan o equipamento ganha um rostinho. Idempotente.
func set_personified(on: bool, animate := true) -> void:
	if on == _face.visible:
		return
	if on and animate:
		_face.pop_in()
	else:
		_face.visible = on
		_face.scale = Vector2.ONE


## Boca mexendo enquanto o texto do balão é digitado.
func set_face_talking(talking: bool) -> void:
	_face.talking = talking


func show_custom_window(backdrop: Texture2D) -> void:
	_backdrop.texture = backdrop
	_sprite.visible = false
	_face.visible = false
	if _float_tween:
		_float_tween.kill()


func set_item_state(item_id: StringName, enabled: bool, pulsing: bool) -> void:
	if _items.has(item_id):
		(_items[item_id] as Interactable).set_state(enabled, pulsing)


func set_items_visible(v: bool) -> void:
	for id in _items:
		(_items[id] as Control).visible = v


func place_artifact(reward: RewardData) -> void:
	if reward == null or _shelf.has_node(NodePath(String(reward.id))):
		return
	var t := TextureRect.new()
	t.name = String(reward.id)
	t.texture = reward.texture
	t.tooltip_text = reward.display_name
	t.custom_minimum_size = Vector2(110, 80)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_shelf.add_child(t)


## Posição e escala vêm dos dados (em coordenadas de 1920×1080) e acompanham o tamanho da tela.
func _layout_sprite() -> void:
	if _float_tween:
		_float_tween.kill()
		_float_tween = null
	if not _sprite.visible or _sprite.texture == null:
		return
	var k := minf(size.x / REF_SIZE.x, size.y / REF_SIZE.y)
	var s := _sprite.texture.get_size() * _view_scale * k
	var center := Vector2(_view_position.x / REF_SIZE.x * size.x, _view_position.y / REF_SIZE.y * size.y)
	_sprite.size = s
	_sprite.position = center - s / 2.0
	_sprite.pivot_offset = s / 2.0
	_sprite.rotation = 0.0
	_face.place(_face_position, _face_size, s)
	if _idle_motion and not Settings.reduce_motion:
		var y := _sprite.position.y
		_float_tween = create_tween().set_loops()
		_float_tween.tween_property(_sprite, "position:y", y - 14.0, 2.2).set_trans(Tween.TRANS_SINE)
		_float_tween.parallel().tween_property(_sprite, "rotation", 0.035, 2.2).set_trans(Tween.TRANS_SINE)
		_float_tween.tween_property(_sprite, "position:y", y + 14.0, 2.2).set_trans(Tween.TRANS_SINE)
		_float_tween.parallel().tween_property(_sprite, "rotation", -0.035, 2.2).set_trans(Tween.TRANS_SINE)
