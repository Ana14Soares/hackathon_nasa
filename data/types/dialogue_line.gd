class_name DialogueLine
extends RefCounted
## Uma fala. `who` define o estilo do balão:
##   "hero"            → Lyra (balão só com texto, sem foto)
##   "hero_to_player"  → Lyra falando com o jogador no final (sem foto)
##   "narrator"        → narração, sem nome e sem foto
##   "explorer"        → o equipamento do encontro atual fala em 1ª pessoa (com foto)
##   "<id>"            → um equipamento específico, ex.: "pioneer_10" (com foto)

var who := "hero"
var emo := ""
var text := ""
var image: StringName = &""


static func from_dict(d: Dictionary) -> DialogueLine:
	var line := DialogueLine.new()
	line.who = str(d.get("who", "hero"))
	line.emo = str(d.get("emo", ""))
	line.text = str(d.get("text", ""))
	line.image = StringName(str(d.get("image", "")))
	return line


static func list_from(raw: Variant) -> Array[DialogueLine]:
	var out: Array[DialogueLine] = []
	if raw is Array:
		for d in raw:
			if d is Dictionary:
				out.append(from_dict(d))
	return out


func is_hero() -> bool:
	return who == "hero" or who == "hero_to_player"
