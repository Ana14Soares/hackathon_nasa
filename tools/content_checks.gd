class_name ContentChecks
extends RefCounted
## Regras do verificador de conteúdo. Usado pelo EditorScript content_linter.gd
## e pode ser chamado de testes. Erros bloqueiam; avisos pedem revisão humana.


static func run() -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var registry: ExplorerRegistry = load("res://data/registry.tres")
	var ids: Array[StringName] = []
	for e in registry.explorers:
		if e == null:
			errors.append("registry.tres tem uma entrada vazia")
			continue
		if e.id in ids:
			errors.append("id repetido: %s" % e.id)
		ids.append(e.id)
	if not registry.first_explorer in ids:
		errors.append("first_explorer '%s' não está no registro" % registry.first_explorer)

	for e in registry.explorers:
		if e == null:
			continue
		var tag := String(e.id)
		if e.sprite == null:
			errors.append("%s: sprite da janela ausente" % tag)
		if e.window_backdrop == null:
			errors.append("%s: fundo da janela ausente" % tag)
		for dep in e.unlock_after:
			if not dep in ids:
				errors.append("%s: unlock_after aponta para id inexistente '%s'" % [tag, dep])
			elif dep == e.id:
				errors.append("%s: unlock_after aponta para si mesmo" % tag)
		var keys: Array[StringName] = []
		for img in e.images:
			keys.append(img.key)
			if img.credit.strip_edges() == "":
				errors.append("%s: imagem '%s' sem crédito" % [tag, img.key])
			if img.source_url.strip_edges() == "":
				errors.append("%s: imagem '%s' sem source_url" % [tag, img.key])
			if img.credit.begins_with("Placeholder"):
				warnings.append("%s: imagem '%s' ainda é provisória" % [tag, img.key])

		var path := e.resource_path.get_base_dir() + "/story.pt_BR.json"
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		if not parsed is Dictionary:
			errors.append("%s: JSON ausente ou inválido (%s)" % [tag, path])
			continue
		var story := StoryData.from_dict(parsed)
		for list in [story.arrival, story.scan, story.reaction, story.wrap_up, story.reward_lines]:
			for line in list:
				if line.text.strip_edges() == "":
					errors.append("%s: fala com texto vazio" % tag)
		for k in story.image_keys:
			if not k in keys:
				errors.append("%s: diário cita imagem inexistente '%s'" % [tag, k])
		if e.diary_page == null:
			warnings.append("%s: sem arte de página do diário (diary_page)" % tag)
		for f in story.report + story.facts:
			var sid := str(f.get("source", ""))
			if sid == "" or not story.sources.has(sid):
				errors.append("%s: fato '%s' sem fonte válida" % [tag, f.get("label", "?")])
		for sid in story.sources:
			var s: Dictionary = story.sources[sid]
			if str(s.get("checked_on", "")) == "":
				warnings.append("%s: fonte '%s' ainda não foi conferida (checked_on vazio)" % [tag, sid])
	return {"errors": errors, "warnings": warnings}
