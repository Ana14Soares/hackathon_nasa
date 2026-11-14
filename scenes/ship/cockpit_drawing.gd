class_name CockpitDrawing
extends Control
## Arte fixa da sala de controle desenhada em código (moldura da janela e painel).
## Proporcional ao tamanho, então acompanha qualquer resolução.

const FRAME := Color("121119")
const FRAME_EDGE := Color("3c3754")
const CONSOLE := Color("1a1824")
const CONSOLE_TOP := Color("2a2640")
const SCREEN := Color("0d1f1b")
const SCREEN_LINE := Color(0.45, 1.0, 0.75, 0.35)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	# Faixa superior
	draw_rect(Rect2(0, 0, w, h * 0.055), FRAME)
	draw_line(Vector2(0, h * 0.055), Vector2(w, h * 0.055), FRAME_EDGE, 3.0)
	# Colunas laterais inclinadas
	var left := PackedVector2Array([Vector2(0, 0), Vector2(w * 0.05, 0), Vector2(w * 0.13, h * 0.73), Vector2(0, h * 0.73)])
	var right := PackedVector2Array([Vector2(w, 0), Vector2(w * 0.95, 0), Vector2(w * 0.87, h * 0.73), Vector2(w, h * 0.73)])
	draw_colored_polygon(left, FRAME)
	draw_colored_polygon(right, FRAME)
	draw_line(Vector2(w * 0.05, 0), Vector2(w * 0.13, h * 0.73), FRAME_EDGE, 3.0, true)
	draw_line(Vector2(w * 0.95, 0), Vector2(w * 0.87, h * 0.73), FRAME_EDGE, 3.0, true)
	# Painel de controle
	var console := PackedVector2Array([
		Vector2(0, h * 0.78), Vector2(w * 0.13, h * 0.72), Vector2(w * 0.87, h * 0.72),
		Vector2(w, h * 0.78), Vector2(w, h), Vector2(0, h)])
	draw_colored_polygon(console, CONSOLE)
	draw_polyline(PackedVector2Array([Vector2(0, h * 0.78), Vector2(w * 0.13, h * 0.72),
		Vector2(w * 0.87, h * 0.72), Vector2(w, h * 0.78)]), CONSOLE_TOP, 5.0, true)
	# Telinhas e botões decorativos
	for x in [0.17, 0.66]:
		var r := Rect2(w * x, h * 0.85, w * 0.07, h * 0.07)
		draw_rect(r, SCREEN)
		draw_rect(r, SCREEN_LINE, false, 2.0)
		for i in 3:
			var y := r.position.y + r.size.y * (0.3 + 0.2 * i)
			draw_line(Vector2(r.position.x + 8, y), Vector2(r.end.x - 8 - i * 14, y), SCREEN_LINE, 2.0)
	for i in 4:
		draw_circle(Vector2(w * (0.6 + i * 0.015), h * 0.95), 6.0, Color("4b4566"))
