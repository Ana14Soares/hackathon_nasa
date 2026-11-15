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
	return "\n".join([
		"[i]A story inspired by real space missions. Lyra and the memory scanner are fictional. The spacecraft’s lines were written to tell their stories; they are not messages the machines actually sent. Scientific information: NASA, JPL, and the other sources listed in the log.[/i]",
		"",
		"[b]Remembered explorers[/b]",
		"",
		"[b]Pioneer 10[/b] – Interplanetary probe · 1972",
		"   Source: NASA Science – Pioneer 10",
		"",
		"[b]Sojourner[/b] – Mars rover · 1997",
		"   Source: NASA Science – Mars Pathfinder / Sojourner",
		"",
		"[b]InSight[/b] – Mars lander · 2018",
		"   Source: NASA Science – InSight",
		"",
		"[b]Spirit[/b] – Mars rover · 2004",
		"   Source: NASA Science – Spirit (MER-A)",
		"",
		"[b]Eagle[/b] – Apollo 11 lunar module · 1969",
		"   Source: NASA – Apollo 11",
		"",
		"[b]NEAR Shoemaker[/b] – Asteroid probe · 1996",
		"   Source: NASA Science – NEAR Shoemaker",
		"",
		"[b]Surveyor 3[/b] – Lunar lander · 1967",
		"   Sources: NASA Science – Surveyor 3, NASA – Apollo 12",
		"",
		"[b]Created by:[/b] Amanda Coelho, Ana Soares, Giovanna Castro, Letícia Marreiro and Virna Carvalho",
		"",
		"[i]Thank you for remembering them. Thank you for exploring with us.[/i]",
	])
