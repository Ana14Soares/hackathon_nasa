class_name RewardPopup
extends Overlay
## "ITEM RECEIVED": mostra o artefato antes de ele ir para a estante.

@onready var _tex: TextureRect = %RewardTexture
@onready var _name: Label = %RewardName
@onready var _desc: Label = %RewardDesc
@onready var _ok: Button = %OkButton


func _ready() -> void:
	super._ready()
	_ok.pressed.connect(close)


func open(reward: RewardData) -> void:
	_tex.texture = reward.texture
	_name.text = reward.display_name
	_desc.text = reward.description
	AudioManager.play_sfx(&"plaque_received")
	show_overlay()
