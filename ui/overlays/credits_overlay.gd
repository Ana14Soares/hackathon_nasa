class_name CreditsOverlay
extends Overlay
## Créditos gerados a partir do registro de equipamentos (imagens e fontes).
## Usado no menu inicial; o texto também é reaproveitado na cena final.

@onready var _text: RichTextLabel = %CreditsText
@onready var _close_btn: Button = %CloseButton


func _ready() -> void:
	super._ready()
	_close_btn.pressed.connect(close)


func open() -> void:
	_text.text = build_bbcode()
	show_overlay()


static func build_bbcode() -> String:
	var bb := "[b]Remembered explorers[/b]\n\n"
	for id in ContentDB.all_ids():
		var d := ContentDB.get_explorer(id)
		var story := ContentDB.get_story(id)
		bb += "[b]%s[/b] — %s\n" % [d.display_name, d.subtitle]
		for img in d.images:
			bb += "   Image \"%s\": %s\n" % [img.caption, img.credit]
		for sid in story.cited_source_ids():
			var s: Dictionary = story.sources.get(sid, {})
			bb += "   Source: %s\n" % str(s.get("title", sid))
		bb += "\n"
	bb += "[i]Thank you for remembering them.[/i]"
	return bb
