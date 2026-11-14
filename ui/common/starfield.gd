class_name Starfield
extends Control
## Céu estrelado procedural (sem textura). Cintila de leve, exceto com "reduzir movimento".

@export var star_count := 240
@export var bg_color := Color("07070d")
@export var seed_value := 7

var _stars: Array[Vector3] = []   # x, y normalizados e raio
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in star_count:
		_stars.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.6, 2.2)))
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	if Settings.reduce_motion or not is_visible_in_tree():
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)
	for s in _stars:
		var tw := 0.75 + 0.25 * sin(_t * 1.3 + s.x * 97.0 + s.y * 31.0)
		draw_circle(Vector2(s.x * size.x, s.y * size.y), s.z, Color(1, 1, 1, 0.25 + 0.55 * tw))
