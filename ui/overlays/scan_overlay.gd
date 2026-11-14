class_name ScanOverlay
extends Control
## Camada do scan: 1) varredura visual sobre a janela; 2) o equipamento fala
## (balão com a foto dele) e, quando a fala tem "image", o painel holográfico
## mostra a imagem com legenda e crédito.

@onready var _fx: ColorRect = %ScanFx
@onready var _holo: PanelContainer = %HoloPanel
@onready var _image: TextureRect = %HoloImage
@onready var _caption: Label = %Caption
@onready var _credit: Label = %Credit

const IMAGE_HEIGHT := 240.0
const GAP := 16.0

var _data: ExplorerData
var _dialogue: DialogueBox


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


## Com texto grande o balão cresce para cima: a imagem do painel encolhe
## (ou some) para que o painel nunca fique por baixo do balão.
func _process(_delta: float) -> void:
	if not _holo.visible or _dialogue == null:
		return
	var overlap := _holo.get_global_rect().end.y - (_dialogue.balloon_top() - GAP)
	if overlap > 0.5 and _image.visible:
		var h := _image.custom_minimum_size.y - overlap
		_image.custom_minimum_size.y = maxf(h, 0.0)
		_image.visible = h > 60.0


func run(lines: Array[DialogueLine], data: ExplorerData, dialogue: DialogueBox) -> void:
	_data = data
	_dialogue = dialogue
	_holo.visible = false
	visible = true
	set_process(true)
	AudioManager.play_sfx(&"scan_start")
	var mat := _fx.material as ShaderMaterial
	mat.set_shader_parameter("intensity", 0.4 if Settings.reduce_motion else 1.0)

	# 1. Varredura
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.3)
	if Settings.reduce_motion:
		mat.set_shader_parameter("beam", -1.0)
		t.tween_interval(0.6)
	else:
		t.tween_method(func(v: float) -> void: mat.set_shader_parameter("beam", v), 0.0, 1.0, 1.6)
	await t.finished
	mat.set_shader_parameter("beam", -1.0)

	# 2. O equipamento fala
	dialogue.line_started.connect(_on_line_started)
	await dialogue.play(lines)
	dialogue.line_started.disconnect(_on_line_started)

	var out := create_tween()
	out.tween_property(self, "modulate:a", 0.0, 0.3)
	await out.finished
	visible = false
	set_process(false)


func _on_line_started(line: DialogueLine) -> void:
	if line.image == &"" or _data == null:
		return
	var img := _data.get_image(line.image)
	if img == null:
		return
	_image.texture = img.texture
	_image.custom_minimum_size.y = IMAGE_HEIGHT
	_image.visible = true
	_caption.text = img.caption
	_credit.text = "Crédito: " + img.credit
	_holo.visible = true
