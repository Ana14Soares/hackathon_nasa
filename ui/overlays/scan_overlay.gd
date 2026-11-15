class_name ScanOverlay
extends Control
## Camada do scan: a varredura visual sobre a nave, e depois o equipamento
## fala (balão do DialogueBox). Só isso: sem painéis de informação.
## Para limitar a varredura a uma área, mude Position/Size do nó ScanFx.

@onready var _fx: ColorRect = %ScanFx


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func run(lines: Array[DialogueLine], dialogue: DialogueBox) -> void:
	visible = true
	AudioManager.play_sfx(&"scan_start")
	var mat := _fx.material as ShaderMaterial
	mat.set_shader_parameter("intensity", 0.4 if Settings.reduce_motion else 1.0)

	# 1. Varredura
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.3)
	if Settings.reduce_motion:
		mat.set_shader_parameter("beam", -1.0)
		t.tween_interval(0.6)
	else:
		t.tween_method(func(v: float) -> void: mat.set_shader_parameter("beam", v), 0.0, 1.0, 1.6)
	await t.finished
	mat.set_shader_parameter("beam", -1.0)

	# 2. O equipamento fala
	await dialogue.play(lines)

	var out := create_tween()
	out.tween_property(self, "modulate:a", 0.0, 0.3)
	await out.finished
	visible = false
