class_name RadarMarker
extends Button
## Um ponto do radar. Pendente próximo: "?" pulsando, sem revelar o nome.
## Concluído: ícone do equipamento, apagado e sem ação.

signal chosen(id: StringName)
signal focused_info(id: StringName, revealed: bool)

const SIZE := 72.0

var explorer_id: StringName
var revealed := false
var _tween: Tween


func setup(data: ExplorerData, status: int) -> void:
	explorer_id = data.id
	revealed = status == GameState.Status.COMPLETED
	custom_minimum_size = Vector2(SIZE, SIZE)
	size = custom_minimum_size
	pivot_offset = size / 2.0
	theme_type_variation = &"RadarMarker"
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	expand_icon = true
	if revealed:
		icon = data.radar_icon if data.radar_icon else data.sprite
		text = ""
		disabled = true
		modulate = Color(1, 1, 1, 0.6)
		tooltip_text = data.display_name
		focus_mode = Control.FOCUS_NONE
	else:
		text = "?"
		tooltip_text = "Área desconhecida"
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		pressed.connect(func() -> void: chosen.emit(explorer_id))
		if not Settings.reduce_motion:
			_tween = create_tween().set_loops()
			_tween.tween_property(self, "scale", Vector2.ONE * 1.15, 0.6).set_trans(Tween.TRANS_SINE)
			_tween.tween_property(self, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
	mouse_entered.connect(func() -> void: focused_info.emit(explorer_id, revealed))
	focus_entered.connect(func() -> void: focused_info.emit(explorer_id, revealed))


## Centraliza o marcador no ponto dado.
func place_at(p: Vector2) -> void:
	position = p - size / 2.0
