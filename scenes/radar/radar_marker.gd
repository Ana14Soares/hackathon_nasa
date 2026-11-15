class_name RadarMarker
extends Button
## Um ponto do radar. Cada equipamento tem o seu nó na cena do radar (nome = id dele):
## arraste o nó para escolher onde ele fica e mude o tamanho para a arte caber.
##   • Não descoberto: ExplorerData.radar_icon_unknown (sem arte: balão branco com "?").
##   • Descoberto (visitado): ExplorerData.radar_icon (sem arte: o sprite num círculo).

signal chosen(id: StringName)

@export var explorer_id: StringName

var revealed := false
var _tween: Tween


func setup(data: ExplorerData, status: int) -> void:
	revealed = status == GameState.Status.COMPLETED
	pivot_offset = size / 2.0
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	expand_icon = true
	var art: Texture2D = data.radar_icon if revealed else data.radar_icon_unknown
	if art:
		theme_type_variation = &"IconOnly"        # só a arte, sem fundo
		icon = art
		text = ""
	else:
		theme_type_variation = &"RadarMarker"     # balão branco
		if revealed:
			icon = data.sprite
			text = ""
		else:
			text = "?"
	if revealed:
		disabled = true
		tooltip_text = data.display_name
		focus_mode = Control.FOCUS_NONE
	else:
		tooltip_text = "Unknown area"
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		pressed.connect(func() -> void: chosen.emit(explorer_id))
		if not Settings.reduce_motion:
			_tween = create_tween().set_loops()
			_tween.tween_property(self, "scale", Vector2.ONE * 1.15, 0.6).set_trans(Tween.TRANS_SINE)
			_tween.tween_property(self, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
