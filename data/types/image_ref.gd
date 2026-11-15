class_name ImageRef
extends Resource
## Imagem real do equipamento, com legenda e crédito (usada nos créditos do jogo).

@export var key: StringName      # nome de referência, ex.: "craft"
@export var texture: Texture2D
@export var caption: String
@export var credit: String       # copiar do arquivo original, ex.: "NASA/JPL-Caltech"
@export var source_url: String
