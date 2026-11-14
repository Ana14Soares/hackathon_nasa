extends Control
## Menu inicial. "Começar" e "Continuar" são o mesmo botão com rótulo trocado;
## "Nova história" só aparece quando há save e pede confirmação.

@onready var start_btn: Button = %StartButton
@onready var new_btn: Button = %NewStoryButton
@onready var settings_btn: Button = %SettingsButton
@onready var quit_btn: Button = %QuitButton
@onready var confirm: ConfirmOverlay = %ConfirmOverlay
@onready var settings_overlay: SettingsOverlay = %SettingsOverlay


func _ready() -> void:
	get_tree().paused = false
	AudioManager.play_music(&"menu")
	var saved := SaveManager.has_save()
	start_btn.text = "Continuar" if saved else "Começar"
	new_btn.visible = saved
	quit_btn.visible = not OS.has_feature("web")
	start_btn.pressed.connect(_on_start_pressed)
	new_btn.pressed.connect(_on_new_story_pressed)
	settings_btn.pressed.connect(settings_overlay.open)
	quit_btn.pressed.connect(get_tree().quit)
	start_btn.grab_focus()


func _on_start_pressed() -> void:
	if SaveManager.load_game():
		SceneRouter.go_to(GameState.resume_scene())
	else:                                   # sem save, ou save ilegível
		GameState.reset()
		SceneRouter.go_to(&"intro")


func _on_new_story_pressed() -> void:
	var ok := await confirm.ask("Iniciar uma nova história? O progresso atual será substituído.",
		"Confirmar", "Cancelar")
	if not ok:
		return                              # volta ao menu e mantém o save
	SaveManager.delete()
	GameState.reset()
	SceneRouter.go_to(&"intro")
