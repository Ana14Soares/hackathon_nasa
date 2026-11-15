extends Control
## Cena final: a mesma sala de controle, com a Terra na janela. A Lyra fala
## diretamente com o jogador e os créditos são gerados a partir do registro.

const ENDING_JSON := "res://data/ending/ending.json"

@onready var ship: ShipInterior = %ShipInterior
@onready var dialogue: DialogueBox = %DialogueBox
@onready var credits: Control = %Credits
@onready var credits_text: RichTextLabel = %CreditsText
@onready var menu_btn: Button = %MenuButton


func _ready() -> void:
	AudioManager.play_music(&"ending")
	credits.visible = false
	var cfg := ContentDB.load_json(ENDING_JSON)
	var backdrop_path := str(cfg.get("backdrop", ""))
	if ResourceLoader.exists(backdrop_path):
		ship.show_custom_window(load(backdrop_path))
	ship.set_items_visible(false)
	for r in GameState.artifacts:
		ship.place_artifact(ContentDB.get_reward(r))
	menu_btn.pressed.connect(func() -> void: SceneRouter.go_to(&"menu"))
	if SceneRouter.is_busy():
		await SceneRouter.transition_finished
	await dialogue.play(DialogueLine.list_from(cfg.get("lines", [])))
	# História concluída: apaga o progresso. Ao voltar ao menu, START recomeça do início.
	GameState.finished = true
	SaveManager.delete()
	GameState.reset()
	await get_tree().create_timer(4.0).timeout           # segura a vista da Terra (a música continua)
	_show_credits()


func _show_credits() -> void:
	var bb := CreditsOverlay.build_bbcode()
	credits_text.text = bb
	credits.visible = true
	menu_btn.grab_focus()
