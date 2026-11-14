class_name TransitionFx
extends Control
## Desenho das transições do SceneRouter (warp: estrelas esticadas; radar: anéis e varredura).

var mode: StringName = &"fade"
var progress := 0.0:
	set(v):
		progress = v
		queue_redraw()

var _stars: Array[Vector3] = []   # (ângulo, raio inicial 0..1, velocidade)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 180:
		_stars.append(Vector3(rng.randf() * TAU, rng.randf_range(0.03, 1.0), rng.randf_range(0.4, 1.4)))


func _draw() -> void:
	var c := size / 2.0
	var diag := size.length() * 0.5
	match mode:
		&"warp":
			for s in _stars:
				var dir := Vector2.from_angle(s.x)
				var r0 := s.y * diag
				var stretch := progress * progress * diag * 0.6 * s.z
				var col := Color(0.85, 0.9, 1.0, 0.2 + 0.8 * progress)
				draw_line(c + dir * r0, c + dir * (r0 + stretch + 2.0), col, 2.0 + 2.0 * progress, true)
		&"radar":
			for i in 4:
				var r := diag * fmod(progress * 1.5 + i * 0.25, 1.0)
				var a := 0.6 * progress * (1.0 - r / diag)
				draw_arc(c, r, 0.0, TAU, 96, Color(0.4, 1.0, 0.7, a), 3.0, true)
			var y := 0.0
			while y < size.y:
				draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.3, 1.0, 0.6, 0.07 * progress), 1.0)
				y += 6.0
