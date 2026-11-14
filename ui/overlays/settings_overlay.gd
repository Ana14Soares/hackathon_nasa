class_name SettingsOverlay
extends Overlay
## Acessibilidade e som, aberto pelo menu inicial.

@onready var _close_btn: Button = %CloseButton


func _ready() -> void:
	super._ready()
	_close_btn.pressed.connect(close)


func open() -> void:
	show_overlay()
