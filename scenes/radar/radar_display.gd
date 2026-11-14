class_name RadarDisplay
extends Control
## Tela circular do radar: Sol, órbitas, cinturão, planetas e varredura.
## Tudo é desenhado a partir de RADIUS_UNITS, as mesmas unidades de
## ExplorerData.radar_position. Distâncias e tamanhos fora de escala.

const RADIUS_UNITS := 450.0
## [nome, raio da órbita, ângulo em graus, tamanho, cor]
const PLANETS := [
	["Mercúrio", 45.0, 60.0, 5.0, Color("b9b1a3")],
	["Vênus", 75.0, 160.0, 7.0, Color("e8cf8f")],
	["Terra", 110.0, -30.0, 8.0, Color("5fa8ff")],
	["Marte", 175.0, 200.0, 7.0, Color("e0704a")],
	["Júpiter", 310.0, 30.0, 15.0, Color("e2b98a")],
	["Saturno", 355.0, 120.0, 13.0, Color("e8d6a0")],
	["Urano", 395.0, 250.0, 10.0, Color("9fe3e8")],
	["Netuno", 425.0, 290.0, 10.0, Color("6c8dff")],
]
const MOON := Vector2(125, -50)
const BELT_INNER := 230.0
const BELT_OUTER := 275.0
const GREEN := Color(0.4, 1.0, 0.7)

var sweep := 0.0
var _belt: PackedVector2Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 260:
		_belt.append(Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(BELT_INNER, BELT_OUTER))
	resized.connect(queue_redraw)


func scale_k() -> float:
	return minf(size.x, size.y) * 0.5 / RADIUS_UNITS


func units_to_local(p: Vector2) -> Vector2:
	return size / 2.0 + p * scale_k()


func _process(delta: float) -> void:
	if Settings.reduce_motion:
		return
	sweep = fmod(sweep + delta * 0.8, TAU)
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var k := scale_k()
	var r := RADIUS_UNITS * k
	var font := get_theme_default_font()
	var fsize := Settings.fs(15)

	draw_circle(c, r, Color("08130f"))
	for i in range(1, 4):
		draw_arc(c, r * i / 4.0, 0.0, TAU, 128, Color(GREEN, 0.07), 1.0, true)
	draw_line(c - Vector2(r, 0), c + Vector2(r, 0), Color(GREEN, 0.07), 1.0)
	draw_line(c - Vector2(0, r), c + Vector2(0, r), Color(GREEN, 0.07), 1.0)

	# Cinturão de asteroides
	for p in _belt:
		draw_circle(c + p * k, 1.3, Color(0.8, 0.75, 0.65, 0.45))

	# Órbitas e planetas
	for pl in PLANETS:
		var orbit: float = pl[1]
		draw_arc(c, orbit * k, 0.0, TAU, 128, Color(0.7, 0.9, 0.85, 0.16), 1.5, true)
		var pos := c + Vector2.from_angle(deg_to_rad(pl[2])) * orbit * k
		draw_circle(pos, maxf(3.0, pl[3] * k * 1.6), pl[4])
		draw_string(font, pos + Vector2(10, -8), pl[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(1, 1, 1, 0.55))
	draw_circle(c + MOON * k, 4.0, Color("d8d8d8"))
	draw_string(font, c + MOON * k + Vector2(8, 14), "Lua", HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(1, 1, 1, 0.5))

	# Sol
	draw_circle(c, 16.0, Color("ffcf4a"))
	draw_circle(c, 24.0, Color(1.0, 0.8, 0.3, 0.2))

	# Varredura
	if not Settings.reduce_motion:
		var steps := 24
		for i in steps:
			var a0 := sweep - i * 0.035
			var a1 := a0 - 0.035
			var alpha := 0.28 * (1.0 - float(i) / steps)
			draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a0) * r, c + Vector2.from_angle(a1) * r]), Color(GREEN, alpha))

	draw_arc(c, r, 0.0, TAU, 160, Color(GREEN, 0.7), 3.0, true)
