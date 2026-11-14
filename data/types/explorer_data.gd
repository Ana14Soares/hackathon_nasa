class_name ExplorerData
extends Resource
## Tudo o que muda por equipamento e depende da Godot (texturas, posições).
## Falas, diário e fontes ficam no story.<idioma>.json da mesma pasta.

@export var id: StringName                  # &"pioneer_10"
@export var display_name: String
@export var subtitle: String                # ex.: "Sonda · 1972" (diário e coleção)
@export_enum("moon", "mars", "asteroid", "deep_space", "other") var region: String = "deep_space"

@export_group("Janela da nave")
@export var window_backdrop: Texture2D      # fundo atrás do objeto (céu transparente)
@export var sprite: Texture2D               # objeto à frente
@export var portrait: Texture2D             # foto no balão quando o equipamento fala; vazio = sprite
@export var view_position := Vector2(960, 420)
@export var view_scale := 1.0
@export var idle_motion := true             # flutua suavemente

@export_group("Rostinho")
@export var face_position := Vector2(0.5, 0.5)   # centro do rosto, normalizado no sprite (0..1)
@export_range(0.05, 0.8) var face_size := 0.3    # largura do rosto em fração da largura do sprite

@export_group("Radar")
@export var radar_position := Vector2.ZERO  # em unidades do radar (borda = 450)
@export var radar_icon: Texture2D           # ícone revelado depois de visitado
@export var unlock_after: Array[StringName] = []  # trava opcional; vazio = só proximidade

@export_group("Conteúdo")
@export var images: Array[ImageRef] = []    # imagens citadas pelo JSON por chave
@export var reward: RewardData              # nulo = não entrega artefato


func get_portrait() -> Texture2D:
	return portrait if portrait else sprite


func get_image(key: StringName) -> ImageRef:
	for img in images:
		if img and img.key == key:
			return img
	return null
