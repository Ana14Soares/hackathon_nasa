class_name ImageRef
extends Resource
## Imagem citada pelo JSON de história ("image": "craft").

@export var key: StringName      # o JSON cita assim: "image": "craft"
@export var texture: Texture2D
@export var caption: String
@export var credit: String       # copiar do arquivo original, ex.: "NASA/JPL-Caltech"
@export var source_url: String
