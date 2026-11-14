class_name CuteFace
extends Control
## Rostinho fofo que personifica um equipamento depois do scan.
## Desenhado em código: olhos com brilho, bochechas, boca e piscadas.
## `talking = true` faz a boca abrir e fechar enquanto o texto do balão é digitado.

const INK := Color("2b2840")
const BLUSH := Color(1.0, 0.55, 0.7, 0.55)
const TONGUE := Color("f27d9b")
const ASPECT := 0.62   # altura = largura × ASPECT

var talking := false:
	set(v):
		talking = v
		_talk_t = 0.0

var _t := 0.0
var _talk_t := 0.0
var _mouth := 0.0        # 0 fechada … 1 bem aberta
var _blink := 0.0        # 0 aberto … 1 fechado
var _next_blink := 2.5
var _pop: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(func() -> void: set_process(is_visible_in_tree()))
	set_process(is_visible_in_tree())


## Centraliza o rosto num ponto normalizado (0..1) do pai, com largura relativa.
func place(norm_center: Vector2, width_frac: float, parent_size: Vector2) -> void:
	var w := parent_size.x * width_frac
	size = Vector2(w, w * ASPECT)
	position = norm_center * parent_size - size / 2.0
	pivot_offset = size / 2.0


## Aparece com um "pop" (ou direto, com "reduzir movimento").
func pop_in() -> void:
	visible = true
	if _pop:
		_pop.kill()
	if Settings.reduce_motion:
		scale = Vector2.ONE
		return
	scale = Vector2.ZERO
	_pop = create_tween()
	_pop.tween_property(self, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_t += delta
	if talking:
		_talk_t += delta
		# Duas ondas misturadas = boca "falando" sem parecer mecânica.
		var a := 0.5 + 0.5 * sin(_talk_t * 17.0)
		var b := 0.6 + 0.4 * sin(_talk_t * 5.3 + 1.0)
		_mouth = clampf(a * b, 0.0, 1.0)
	else:
		_mouth = move_toward(_mouth, 0.0, delta * 6.0)
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 1.0
		_next_blink = randf_range(2.2, 4.5)
	_blink = move_toward(_blink, 0.0, delta * 7.0)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var er := w * 0.12
	var line := maxf(2.0, w * 0.03)

	# Bochechas
	draw_circle(Vector2(w * 0.12, h * 0.66), w * 0.085, BLUSH)
	draw_circle(Vector2(w * 0.88, h * 0.66), w * 0.085, BLUSH)

	# Olhos (piscam achatando no eixo Y)
	var open := 1.0 - _blink * 0.92
	for x in [0.28, 0.72]:
		var c := Vector2(w * x, h * 0.38)
		draw_set_transform(c, 0.0, Vector2(1.0, open))
		draw_circle(Vector2.ZERO, er, INK)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if open > 0.5:
			draw_circle(c + Vector2(-er * 0.35, -er * 0.4), er * 0.36, Color.WHITE)
			draw_circle(c + Vector2(er * 0.32, er * 0.3), er * 0.15, Color.WHITE)

	# Boca
	var mc := Vector2(w * 0.5, h * 0.7)
	var mw := w * 0.17
	if _mouth < 0.08:
		draw_arc(mc - Vector2(0, mw * 0.35), mw * 0.6, deg_to_rad(25), deg_to_rad(155), 18, INK, line, true)
	else:
		draw_set_transform(mc, 0.0, Vector2(1.0, 0.35 + 0.85 * _mouth))
		draw_circle(Vector2.ZERO, mw * 0.55, INK)
		draw_circle(Vector2(0, mw * 0.25), mw * 0.3, TONGUE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
