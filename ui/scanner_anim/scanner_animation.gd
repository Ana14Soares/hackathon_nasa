class_name ScannerAnimation
extends TextureRect
## Sobreposição do scanner no vidro da nave: dois quadros que se alternam para
## dar a impressão de animação enquanto o equipamento "fala" com o jogador.
##   • Aparece depois que a varredura passa e SAI quando o equipamento termina de falar (set_shown).
##   • Alterna frame_a ↔ frame_b só enquanto fala (set_talking); parado, mostra frame_a.
##   • Com "reduzir movimento", fica parado no frame_a.
## Os quadros padrão estão no Inspetor deste nó; cada equipamento pode trocá-los
## em ExplorerData → scanner_frames (2 texturas).

@export var frame_a: Texture2D
@export var frame_b: Texture2D
@export_range(1.0, 20.0) var fps := 5.0

var _a: Texture2D
var _b: Texture2D
var _talking := false
var _t := 0.0
var _show_b := false
var _leaving := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	set_frames([])
	set_process(false)


## Troca os quadros por outros do equipamento; lista vazia = volta aos padrão.
func set_frames(frames: Array) -> void:
	_a = frames[0] if frames.size() >= 1 and frames[0] else frame_a
	_b = frames[1] if frames.size() >= 2 and frames[1] else (_a if frames.size() == 1 else frame_b)
	_show_b = false
	texture = _a


func set_shown(on: bool, animate := true) -> void:
	if on == visible and not _leaving:
		return
	_leaving = false
	if on:
		visible = true
		if animate and not Settings.reduce_motion:
			modulate.a = 0.0
			create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
		else:
			modulate.a = 1.0
		return
	set_talking(false)
	if animate and not Settings.reduce_motion:
		_leaving = true
		var t := create_tween()
		t.tween_property(self, "modulate:a", 0.0, 0.25)
		t.tween_callback(func() -> void:
			if _leaving:
				visible = false
				_leaving = false)
	else:
		visible = false


func set_talking(on: bool) -> void:
	_talking = on
	_t = 0.0
	_show_b = false
	texture = _a
	set_process(on and not Settings.reduce_motion)


func _process(delta: float) -> void:
	_t += delta
	if _t >= 1.0 / fps:
		_t = 0.0
		_show_b = not _show_b
		texture = _b if _show_b else _a
