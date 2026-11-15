extends Control
## Menu inicial. Estrutura de arte (substitua as texturas no editor):
##   • Background → imagem de fundo da tela (1920×1080)
##   • Logo       → logo do jogo; enquanto estiver vazio, aparece o título em texto
##   • StartButton / links → estilos em Settings (MenuStart, MenuLink)
## Só existe o botão START. Com save, ele vira "continuar" trocando a ARTE:
##   • Sem save: usa os estilos do próprio botão (Theme Overrides → Styles).
##   • Com save: usa as texturas continue_* abaixo (arraste no Inspetor do MainMenu).
## Se não houver arte, o botão cai no estilo padrão com texto "START"/"CONTINUAR".

@export_group("Arte do botão quando há save (Continuar)")
@export var continue_normal: Texture2D
@export var continue_hover: Texture2D      # opcional; sem ela usa a normal
@export var continue_pressed: Texture2D    # opcional; sem ela usa a normal

@onready var logo: TextureRect = %Logo

@onready var start_btn: Button = %StartButton
@onready var settings_btn: Button = %SettingsButton
@onready var credits_btn: Button = %CreditsButton
@onready var restart_btn: Button = %RestartButton
@onready var settings_overlay: SettingsOverlay = %SettingsOverlay
@onready var credits_overlay: CreditsOverlay = %CreditsOverlay


func _ready() -> void:
	get_tree().paused = false
	AudioManager.play_music(&"bg")

	var saved := SaveManager.has_save()
	_setup_start_button(saved)
	start_btn.pressed.connect(_on_start_pressed)
	settings_btn.pressed.connect(settings_overlay.open)
	credits_btn.pressed.connect(credits_overlay.open)
	restart_btn.visible = GameState.DEBUG_RESTART      # só para debug
	restart_btn.pressed.connect(GameState.restart_game)
	start_btn.grab_focus()


func _on_start_pressed() -> void:
	if SaveManager.load_game():
		SceneRouter.go_to(GameState.resume_scene())
	else:                                   # sem save, ou save ilegível
		GameState.reset()
		SceneRouter.go_to(&"intro")


## START com arte própria: sem texto. Com save, troca para as texturas de "continuar".
func _setup_start_button(saved: bool) -> void:
	if saved and continue_normal:
		start_btn.add_theme_stylebox_override(&"normal", _tex_style(continue_normal))
		start_btn.add_theme_stylebox_override(&"hover", _tex_style(continue_hover if continue_hover else continue_normal))
		start_btn.add_theme_stylebox_override(&"pressed", _tex_style(continue_pressed if continue_pressed else continue_normal))
	var has_art := saved and continue_normal != null or start_btn.has_theme_stylebox_override(&"normal")
	start_btn.text = "" if has_art else ("CONTINUAR" if saved else "START")
	_fit_to_art()


## O botão assume o tamanho da arte do estado normal (sem texto ele ficaria com altura 0).
func _fit_to_art() -> void:
	var sb := start_btn.get_theme_stylebox(&"normal")
	if sb is StyleBoxTexture and sb.texture:
		start_btn.custom_minimum_size = sb.texture.get_size() * 0.8


func _tex_style(tex: Texture2D) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	return sb
