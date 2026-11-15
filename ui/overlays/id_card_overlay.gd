class_name IdCardOverlay
extends Overlay
## Cartão de identificação da Lyra, em tela cheia: a arte do cartão aparece
## grande no centro e qualquer clique FORA dela (ou Esc) fecha. Um clique na
## própria arte não fecha. Não há botão de fechar.
##
## A arte vem de `card_texture` (nó raiz) ou, se esse campo estiver vazio, da
## textura do nó `Card`. A imagem é ajustada pela
## largura e ancorada embaixo; se tiver cordão comprido, ele sai pelo topo.

@export var card_texture: Texture2D
@export_range(0.1, 1.0) var width_fraction := 0.45     # largura da arte, em fração da tela
@export_range(0.0, 0.5) var bottom_margin := 0.1       # folga embaixo, em fração da altura

@onready var _card: TextureRect = %Card


func _ready() -> void:
	super._ready()
	if card_texture:                       # sem Card Texture, vale a textura do nó Card
		_card.texture = card_texture
	resized.connect(_layout)


func open() -> void:
	_layout()
	show_overlay()


## Centraliza a arte na horizontal e apoia a base dela perto do pé da tela.
func _layout() -> void:
	if _card.texture == null:
		return
	var ts := _card.texture.get_size()
	var k := size.x * width_fraction / ts.x
	_card.size = ts * k
	_card.position = Vector2((size.x - _card.size.x) / 2.0, size.y * (1.0 - bottom_margin) - _card.size.y)
