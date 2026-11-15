class_name StoryData
extends RefCounted
## Versão tipada do story.<idioma>.json de um equipamento.

var arrival: Array[DialogueLine] = []
var scan: Array[DialogueLine] = []
var reaction: Array[DialogueLine] = []     # Lyra reage logo depois do scan
var wrap_up: Array[DialogueLine] = []
var reward_lines: Array[DialogueLine] = []

var report: Array[Dictionary] = []        # linhas do relatório de missão {label, value, source}
var summary := ""
var facts: Array[Dictionary] = []          # {label, value, source}
var image_keys: Array[StringName] = []
var personal := ""
var sources: Dictionary = {}               # id -> {title, url, checked_on, checked_by}


static func from_dict(d: Dictionary) -> StoryData:
	var s := StoryData.new()
	s.arrival = DialogueLine.list_from(d.get("arrival", []))
	s.scan = DialogueLine.list_from(d.get("scan", []))
	s.reaction = DialogueLine.list_from(d.get("reaction", []))
	s.wrap_up = DialogueLine.list_from(d.get("wrap_up", []))
	s.reward_lines = DialogueLine.list_from(d.get("reward_lines", []))

	var diary: Variant = d.get("diary", {})
	if diary is Dictionary:
		var tech: Variant = diary.get("technical", {})
		if tech is Dictionary:
			s.summary = str(tech.get("summary", ""))
			for r in tech.get("report", []):
				if r is Dictionary:
					s.report.append(r)
			for f in tech.get("facts", []):
				if f is Dictionary:
					s.facts.append(f)
			for k in tech.get("images", []):
				s.image_keys.append(StringName(str(k)))
		s.personal = str(diary.get("personal", ""))

	var src: Variant = d.get("sources", {})
	if src is Dictionary:
		s.sources = src
	return s


## Fontes do equipamento (citadas pelo relatório/fatos; se não houver, todas as do JSON).
func cited_source_ids() -> Array[String]:
	var out: Array[String] = []
	for f in report + facts:
		var sid := str(f.get("source", ""))
		if sid != "" and not out.has(sid):
			out.append(sid)
	if out.is_empty():
		for k in sources:
			out.append(str(k))
	return out
