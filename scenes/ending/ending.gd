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
	GameState.finished = true
	SaveManager.save()
	_show_credits()


func _show_credits() -> void:
	var bb := "[b]Exploradores lembrados[/b]\n\n"
	for id in ContentDB.all_ids():
		var d := ContentDB.get_explorer(id)
		var story := ContentDB.get_story(id)
		bb += "[b]%s[/b] — %s\n" % [d.display_name, d.subtitle]
		for img in d.images:
			bb += "   Imagem \"%s\": %s\n" % [img.caption, img.credit]
		for sid in story.cited_source_ids():
			var s: Dictionary = story.sources.get(sid, {})
			bb += "   Fonte: %s\n" % str(s.get("title", sid))
		bb += "\n"
	bb += "[i]Obrigada por lembrar deles.[/i]"
	credits_text.text = bb
	credits.visible = true
	menu_btn.grab_focus()
