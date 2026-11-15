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
@export var show_starfield := true          # estrelas atrás do fundo; desligue se o fundo for uma imagem cheia

@export_group("Animação do equipamento")
@export var idle_motion := true             # liga/desliga toda a animação
@export_enum("float", "drift", "spin", "breathe") var idle_style: String = "float"
## float = sobe e desce balançando · drift = deriva devagar de lado a lado
## spin = gira lentamente · breathe = cresce e encolhe de leve
@export_range(0.0, 80.0) var idle_amplitude := 14.0   # alcance do movimento (px na tela 1920×1080)
@export_range(0.1, 4.0) var idle_speed := 1.0         # 1 = padrão; maior = mais rápido
## Folha de sprites (opcional): se o `sprite` for uma grade de quadros, informe
## colunas × linhas e a velocidade. 1×1 = imagem estática.
@export_range(1, 32) var frames_h := 1
@export_range(1, 32) var frames_v := 1
@export_range(1.0, 30.0) var frames_fps := 8.0

@export_group("Scanner")
## Os 2 quadros que se alternam no vidro enquanto ele fala. Vazio = usa os padrão
## do nó ScannerAnim (cena da nave).
@export var scanner_frames: Array[Texture2D] = []

@export_group("Diário")
## Página completa do diário deste equipamento (arte pronta, com os textos).
## Todas as páginas devem ter a mesma proporção (ex.: 1300×787).
@export var diary_page: Texture2D

@export_group("Radar")
## Arte do ponto no radar ANTES de descobrir. Vazio = balão branco com "?".
@export var radar_icon_unknown: Texture2D
## Arte do ponto no radar DEPOIS de visitado. Vazio = o sprite do equipamento num círculo.
## (A posição do ponto não fica aqui: arraste o nó dele na cena do radar.)
@export var radar_position := Vector2.ZERO
@export var radar_icon: Texture2D           # arte do ponto depois de visitado (descoberto)
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
