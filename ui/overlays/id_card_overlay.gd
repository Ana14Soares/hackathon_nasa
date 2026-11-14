class_name IdCardOverlay
extends Overlay
## Cartão de identificação da protagonista (o mesmo em todas as cenas).

@onready var _portrait: TextureRect = %Portrait
@onready var _name: Label = %CardName
@onready var _origin: Label = %Origin
@onready var _ship: Label = %Ship
@onready var _note: Label = %Note
@onready var _close_btn: Button = %CloseButton


func _ready() -> void:
	super._ready()
	_close_btn.pressed.connect(close)


func open() -> void:
	var card := ContentDB.protagonist_card
	_portrait.texture = card.portrait
	_name.text = card.display_name
	_origin.text = "Origem: " + card.origin
	_ship.text = "Nave: " + card.ship_name
	_note.text = card.note
	show_overlay()
