class_name RewardPopup
extends Overlay
## Popup "NEW ITEM": mostra a arte pronta (texto e imagem do artefato já desenhados)
## com um botão por cima. Só o botão fecha.
##
## • Arte: campo Default Art (nó raiz) ou, por artefato, RewardData.popup_art.
## • Botão (OkButton): arraste a arte "default" em Theme Overrides → Styles → Normal
##   e a "pressed" em Pressed (StyleBoxTexture). Com arte no Normal o texto some sozinho.
##   Posição e tamanho: âncoras do OkButton (frações da arte), para acompanhar a escala.

@export var default_art: Texture2D
@export_range(0.3, 1.0) var height_fraction := 0.72   # altura da arte, em fração da tela

@onready var _panel: TextureRect = %Panel
@onready var _ok: Button = %OkButton


func _ready() -> void:
	super._ready()
	_ok.pressed.connect(close)
	resized.connect(_layout)
	if _ok.has_theme_stylebox_override(&"normal"):
		_ok.text = ""        # a arte do botão já traz o rótulo


func open(reward: RewardData) -> void:
	_panel.texture = reward.popup_art if reward.popup_art else default_art
	_layout()
	AudioManager.play_sfx(&"plaque_received")
	show_overlay()


## Centraliza a arte, mantendo a proporção.
func _layout() -> void:
	if _panel.texture == null:
		return
	var ts := _panel.texture.get_size()
	var k := size.y * height_fraction / ts.y
	_panel.size = ts * k
	_panel.position = (size - _panel.size) / 2.0


func _focus_first() -> void:
	_ok.grab_focus()
