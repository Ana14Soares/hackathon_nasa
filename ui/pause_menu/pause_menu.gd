class_name PauseMenu
extends CanvasLayer
## Botão de pausa sempre visível (canto superior direito) + painel de pausa.
## Pausa a árvore e oferece voltar direto ao menu inicial. Tecla P também pausa.
## O progresso já está salvo no último checkpoint, então sair é seguro.

@onready var _pause_btn: Button = %PauseButton
@onready var _panel: Control = %Panel
@onready var _resume_btn: Button = %ResumeButton
@onready var _menu_btn: Button = %MainMenuButton
@onready var _restart_btn: Button = %RestartButton


func _ready() -> void:
	_panel.visible = false
	_pause_btn.pressed.connect(open)
	_resume_btn.pressed.connect(resume)
	_menu_btn.pressed.connect(_go_to_menu)
	_restart_btn.visible = GameState.DEBUG_RESTART      # só para debug
	_restart_btn.pressed.connect(_restart)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_P:
		get_viewport().set_input_as_handled()
		if _panel.visible:
			resume()
		else:
			open()
	elif _panel.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		resume()


func open() -> void:
	if SceneRouter.is_busy() or _panel.visible:
		return
	get_tree().paused = true
	_panel.visible = true
	_pause_btn.visible = false
	_resume_btn.grab_focus()


func resume() -> void:
	get_tree().paused = false
	_panel.visible = false
	_pause_btn.visible = true


func _go_to_menu() -> void:
	resume()
	SceneRouter.go_to(&"menu")


func _restart() -> void:
	resume()
	GameState.restart_game()
