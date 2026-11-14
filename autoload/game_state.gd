extends Node
## Progresso do jogador. Cada mudança relevante grava o save (checkpoint).

enum Status { NOT_VISITED, ARRIVED, SCANNED, COMPLETED }

signal status_changed(id: StringName, status: Status)
signal flag_changed(flag: StringName, value: bool)

var intro_done := false
var finished := false
var current_explorer: StringName = &""
var statuses: Dictionary = {}          # id -> Status
var flags: Dictionary = {}             # radar_unlocked, ...
var artifacts: Array[StringName] = []  # ids de RewardData recebidos
var nav_params: Dictionary = {}        # transitório, não é salvo


func get_status(id: StringName) -> Status:
	return statuses.get(id, Status.NOT_VISITED)


func set_status(id: StringName, s: Status) -> void:
	statuses[id] = s
	status_changed.emit(id, s)
	SaveManager.save()


func set_current_explorer(id: StringName) -> void:
	current_explorer = id
	SaveManager.save()


func complete_intro() -> void:              # chamado no fim da história inicial
	intro_done = true
	current_explorer = ContentDB.first_explorer
	SaveManager.save()


func get_flag(flag: StringName) -> bool:
	return flags.get(flag, false)


func set_flag(flag: StringName, value: bool = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)
	SaveManager.save()


func grant_reward(r: RewardData) -> void:   # idempotente
	if r.id in artifacts:
		return
	artifacts.append(r.id)
	for f in r.unlocks:
		flags[f] = true
		flag_changed.emit(f, true)
	SaveManager.save()


func is_all_completed() -> bool:
	for id in ContentDB.all_ids():
		if get_status(id) != Status.COMPLETED:
			return false
	return true


## Equipamentos já coletados (escaneados ou registrados), na ordem do registro.
func collected_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id in ContentDB.all_ids():
		if is_collected(id):
			out.append(id)
	return out


func is_collected(id: StringName) -> bool:
	var s := get_status(id)
	return s == Status.SCANNED or s == Status.COMPLETED


## Para onde "Continuar" leva.
func resume_scene() -> StringName:
	if not intro_done:
		return &"intro"
	if is_all_completed() and not finished:
		return &"ending"
	if current_explorer != &"" and get_status(current_explorer) != Status.COMPLETED:
		return &"encounter"
	return &"radar"


func reset() -> void:
	intro_done = false
	finished = false
	current_explorer = &""
	statuses.clear()
	flags.clear()
	artifacts.clear()


func to_dict() -> Dictionary:
	var st := {}
	for id in statuses:
		st[String(id)] = Status.keys()[statuses[id]]   # grava o nome, não o número
	var arts: Array[String] = []
	for a in artifacts:
		arts.append(String(a))
	return {
		"intro_done": intro_done, "finished": finished,
		"current_explorer": String(current_explorer),
		"statuses": st, "flags": flags, "artifacts": arts,
	}


func from_dict(d: Dictionary) -> void:
	reset()
	intro_done = bool(d.get("intro_done", false))
	finished = bool(d.get("finished", false))
	current_explorer = StringName(str(d.get("current_explorer", "")))
	var st: Variant = d.get("statuses", {})
	if st is Dictionary:
		for k in st:
			statuses[StringName(k)] = Status.get(st[k], Status.NOT_VISITED)
	var fl: Variant = d.get("flags", {})
	if fl is Dictionary:
		for k in fl:
			flags[StringName(k)] = bool(fl[k])
	for a in d.get("artifacts", []):
		artifacts.append(StringName(str(a)))
