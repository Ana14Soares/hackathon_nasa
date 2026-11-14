class_name DiaryFrame
extends Control
## Moldura do diário (mockup "Mission report"): placa cinza com cantos
## chanfrados, entalhes no topo, na base e à esquerda, e o painel claro
## interno com o corte diagonal no canto inferior direito.
## Tudo em frações do tamanho, então escala com a tela.

const OUTER := Color("808080")
const INNER := Color("c4c4c4")

# Proporções medidas no mockup (1416 × 856)
const NOTCH_X0 := 0.31        # entalhe do topo/base: início
const NOTCH_X1 := 0.565       # fim
const NOTCH_SLOPE := 0.011    # largura da rampa do entalhe (fração da largura)
const NOTCH_DEPTH := 0.022    # profundidade (fração da altura)
const SIDE_Y0 := 0.27         # entalhe da esquerda
const SIDE_Y1 := 0.71
const SIDE_DEPTH := 0.0134
const CHAMFER := 0.024        # chanfro dos cantos (fração da largura)
const INNER_INSET := Vector2(0.0134, 0.021)
const INNER_RIGHT := 0.862    # o painel claro termina antes da coluna de abas
const CUT_Y0 := 0.69          # corte diagonal do canto inferior direito
const CUT_Y1 := 0.757
const CUT_X := 0.812


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_colored_polygon(_shape(Rect2(Vector2.ZERO, size), false), OUTER)
	var inner := Rect2(INNER_INSET.x * w, INNER_INSET.y * h,
		INNER_RIGHT * w - INNER_INSET.x * w, h - 2.0 * INNER_INSET.y * h)
	draw_colored_polygon(_shape(inner, true), INNER)


## Polígono com cantos chanfrados e entalhes. `cut` = corte diagonal inferior direito.
func _shape(r: Rect2, cut: bool) -> PackedVector2Array:
	var W := size.x
	var H := size.y
	var x0 := r.position.x
	var y0 := r.position.y
	var x1 := r.end.x
	var y1 := r.end.y
	var ch := CHAMFER * W
	var d := NOTCH_DEPTH * H
	var sl := NOTCH_SLOPE * W
	var nx0 := NOTCH_X0 * W
	var nx1 := NOTCH_X1 * W
	var sd := SIDE_DEPTH * W
	var sy0 := SIDE_Y0 * H
	var sy1 := SIDE_Y1 * H
	var p := PackedVector2Array()
	# topo
	p.append(Vector2(x0 + ch, y0))
	p.append(Vector2(nx0, y0))
	p.append(Vector2(nx0 + sl, y0 + d))
	p.append(Vector2(nx1 - sl, y0 + d))
	p.append(Vector2(nx1, y0))
	p.append(Vector2(x1 - ch, y0))
	p.append(Vector2(x1, y0 + ch))
	# direita + canto inferior direito
	if cut:
		p.append(Vector2(x1, CUT_Y0 * H))
		p.append(Vector2(CUT_X * W, CUT_Y1 * H))
		p.append(Vector2(CUT_X * W, y1))
	else:
		p.append(Vector2(x1, y1 - ch))
		p.append(Vector2(x1 - ch, y1))
	# base
	p.append(Vector2(nx1, y1))
	p.append(Vector2(nx1 - sl, y1 - d))
	p.append(Vector2(nx0 + sl, y1 - d))
	p.append(Vector2(nx0, y1))
	p.append(Vector2(x0 + ch, y1))
	p.append(Vector2(x0, y1 - ch))
	# esquerda com entalhe
	p.append(Vector2(x0, sy1))
	p.append(Vector2(x0 + sd, sy1 - sd))
	p.append(Vector2(x0 + sd, sy0 + sd))
	p.append(Vector2(x0, sy0))
	p.append(Vector2(x0, y0 + ch))
	return p
