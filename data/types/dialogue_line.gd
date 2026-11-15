class_name DialogueLine
extends RefCounted
## Uma fala. `who` define o estilo do balão:
##   "hero"            → Lyra (balão só com texto, sem foto)
##   "hero_to_player"  → Lyra falando com o jogador no final
##   "narrator"        → narração, sem nome
##   "explorer"        → o equipamento do encontro atual fala em 1ª pessoa
##   "<id>"            → um equipamento específico, ex.: "pioneer_10"

var who := "hero"
var emo := ""
var text := ""


static func from_dict(d: Dictionary) -> DialogueLine:
	var line := DialogueLine.new()
	line.who = str(d.get("who", "hero"))
	line.emo = str(d.get("emo", ""))
	line.text = str(d.get("text", ""))
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
