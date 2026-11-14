extends Node
## Lê, grava e apaga user://save.json. Status vão como texto ("COMPLETED"),
## porque JSON.parse_string devolve todo número como float.

const PATH := "user://save.json"
const VERSION := 1


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


func save() -> void:
	var data := GameState.to_dict()
	data["version"] = VERSION
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_error("Falha ao salvar: %s" % error_string(FileAccess.get_open_error()))
		return
	f.store_string(JSON.stringify(data, "\t"))


func load_game() -> bool:
	if not has_save():
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return false                       # save corrompido
	GameState.from_dict(_migrate(parsed))
	return true


func delete() -> void:
	if has_save():
		DirAccess.remove_absolute(PATH)


func _migrate(d: Dictionary) -> Dictionary:
	# if d.get("version", 1) < 2: converter campos antigos aqui
	return d
