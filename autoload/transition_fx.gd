class_name TransitionFx
extends Control
## Desenho das transições do SceneRouter (warp: túnel de hiperespaço).

var mode: StringName = &"fade"
var progress := 0.0:
	set(v):
		progress = v
		queue_redraw()

var _stars: Array[Vector4] = []   # (ângulo, fase 0..1, velocidade, matiz)
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Brilho aditivo: os raios coloridos se somam e "acendem" o fundo.
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 600:
		_stars.append(Vector4(rng.randf() * TAU, rng.randf(), rng.randf_range(0.6, 1.6), rng.randf()))
	set_process(false)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_process(visible and mode == &"warp")


func _draw() -> void:
	var c := size / 2.0
	var diag := size.length() * 0.5
	match mode:
		&"warp":
			_draw_warp(c, diag)


## Hiperespaço: raios arco-íris saindo do centro (cada um acelera ao se afastar),
## com um anel e um brilho no meio, como o túnel de uma viagem de nave.
func _draw_warp(c: Vector2, diag: float) -> void:
	var p := clampf(progress, 0.0, 1.0)
	var boost := 0.4 + 2.2 * p * p                      # os raios aceleram junto com a transição
	for s in _stars:
		var f := fmod(s.y + _t * 0.5 * s.z * boost, 1.0)   # posição do raio no túnel (0 centro … 1 borda)
		var d := f * f                                      # perspectiva: perto do centro anda devagar
		var r0 := d * diag * 1.05 + 14.0
		var r1 := r0 + (6.0 + 340.0 * d * p) * s.z          # o raio estica ao se afastar e com o progresso
		var dir := Vector2.from_angle(s.x)
		var hue := fmod(s.w + _t * 0.05, 1.0)
		var col := Color.from_hsv(hue, 0.65, 1.0, clampf(0.15 + 0.85 * d, 0.0, 1.0) * clampf(p * 1.6, 0.0, 1.0))
		draw_line(c + dir * r0, c + dir * r1, col, 1.5 + 4.0 * d, true)
	# Anel e brilho central.
	var core := diag * (0.06 + 0.5 * p)
	for i in 5:
		draw_circle(c, core * (1.0 - i * 0.16), Color(0.85, 0.35, 0.9, 0.05 * p))
	draw_arc(c, core, 0.0, TAU, 96, Color(0.5, 1.0, 0.9, 0.55 * p), 4.0, true)
