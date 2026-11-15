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
@onready var _scanner: ScannerAnimation = %ScannerAnim
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
var _idle_style := "float"
var _idle_amplitude := 14.0
var _idle_speed := 1.0
var _sheet_tex: Texture2D        # folha de sprites completa (se houver)
var _frames := Vector2i.ONE      # colunas × linhas
var _fps := 8.0
var _frame_tween: Tween
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
	$Window/Starfield.visible = data.show_starfield
	_sheet_tex = data.sprite
	_frames = Vector2i(data.frames_h, data.frames_v)
	_fps = data.frames_fps
	_sprite.texture = _frame_texture(0)
	_sprite.visible = data.sprite != null
	_view_position = data.view_position
	_view_scale = data.view_scale
	_idle_motion = data.idle_motion
	_idle_style = data.idle_style
	_idle_amplitude = data.idle_amplitude
	_idle_speed = maxf(data.idle_speed, 0.1)
	_scanner.set_frames(data.scanner_frames)
	_scanner.set_talking(false)
	_scanner.visible = false
	_layout_sprite()


## Depois da varredura, a sobreposição do scanner aparece no vidro. Idempotente.
func set_scanner_shown(on: bool, animate := true) -> void:
	_scanner.set_shown(on, animate)


## Os dois quadros se alternam enquanto o equipamento fala.
func set_scanner_talking(talking: bool) -> void:
	_scanner.set_talking(talking)


func show_custom_window(backdrop: Texture2D) -> void:
	_backdrop.texture = backdrop
	_sprite.visible = false
	_scanner.visible = false
	_kill_motion()


func set_item_state(item_id: StringName, enabled: bool, pulsing: bool) -> void:
	if _items.has(item_id):
		(_items[item_id] as Interactable).set_state(enabled, pulsing)


## Bloqueado = visual "vazio" do item (ex.: radar antes da Placa Pioneer).
func set_item_locked(item_id: StringName, locked: bool) -> void:
	if _items.has(item_id):
		(_items[item_id] as Interactable).set_locked(locked)


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
	t.custom_minimum_size = Vector2(331, 234)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_shelf.add_child(t)


## Textura de um quadro da folha de sprites (ou a imagem inteira se for 1×1).
func _frame_texture(index: int) -> Texture2D:
	if _sheet_tex == null or _frames == Vector2i.ONE:
		return _sheet_tex
	var fs := _sheet_tex.get_size() / Vector2(_frames)
	var at := AtlasTexture.new()
	at.atlas = _sheet_tex
	at.region = Rect2(Vector2(index % _frames.x, (index / _frames.x) % _frames.y) * fs, fs)
	return at


func _kill_motion() -> void:
	if _float_tween:
		_float_tween.kill()
		_float_tween = null
	if _frame_tween:
		_frame_tween.kill()
		_frame_tween = null


## Posição e escala vêm dos dados (em coordenadas de 1920×1080) e acompanham o tamanho da tela.
func _layout_sprite() -> void:
	_kill_motion()
	if not _sprite.visible or _sprite.texture == null:
		return
	var k := minf(size.x / REF_SIZE.x, size.y / REF_SIZE.y)
	var frame_size := _sheet_tex.get_size() / Vector2(_frames)
	var s := frame_size * _view_scale * k
	var center := Vector2(_view_position.x / REF_SIZE.x * size.x, _view_position.y / REF_SIZE.y * size.y)
	_sprite.size = s
	_sprite.position = center - s / 2.0
	_sprite.pivot_offset = s / 2.0
	_sprite.rotation = 0.0
	_sprite.scale = Vector2.ONE
	if Settings.reduce_motion:
		return
	_start_frames()
	if _idle_motion:
		_start_idle(k)


## Passa os quadros da folha de sprites em loop.
func _start_frames() -> void:
	var total := _frames.x * _frames.y
	if total <= 1:
		return
	_frame_tween = create_tween().set_loops()
	for i in total:
		_frame_tween.tween_callback(func() -> void: _sprite.texture = _frame_texture(i))
		_frame_tween.tween_interval(1.0 / _fps)


## Movimento suave de vai-e-volta para o objeto nunca ficar parado.
func _start_idle(k: float) -> void:
	var a := _idle_amplitude * k
	var t := 2.2 / _idle_speed
	var p := _sprite.position
	_float_tween = create_tween().set_loops()
	var sine := Tween.TRANS_SINE
	match _idle_style:
		"drift":
			t *= 1.8
			_float_tween.tween_property(_sprite, "position", p + Vector2(a * 1.6, -a * 0.5), t).set_trans(sine)
			_float_tween.parallel().tween_property(_sprite, "rotation", 0.05, t).set_trans(sine)
			_float_tween.tween_property(_sprite, "position", p + Vector2(-a * 1.6, a * 0.5), t).set_trans(sine)
			_float_tween.parallel().tween_property(_sprite, "rotation", -0.05, t).set_trans(sine)
		"spin":
			# Rotação contínua e uniforme (uma volta a cada ~20 s no padrão).
			_float_tween.set_trans(Tween.TRANS_LINEAR)
			_float_tween.tween_property(_sprite, "rotation", TAU, 20.0 / _idle_speed).from(0.0)
		"breathe":
			var amount := 1.0 + clampf(_idle_amplitude / 400.0, 0.01, 0.2)
			_float_tween.tween_property(_sprite, "scale", Vector2.ONE * amount, t).set_trans(sine)
			_float_tween.tween_property(_sprite, "scale", Vector2.ONE, t).set_trans(sine)
		_:  # float
			_float_tween.tween_property(_sprite, "position:y", p.y - a, t).set_trans(sine)
			_float_tween.parallel().tween_property(_sprite, "rotation", 0.035, t).set_trans(sine)
			_float_tween.tween_property(_sprite, "position:y", p.y + a, t).set_trans(sine)
			_float_tween.parallel().tween_property(_sprite, "rotation", -0.035, t).set_trans(sine)
