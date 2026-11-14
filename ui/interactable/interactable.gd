class_name Interactable
extends Button
## Componente único dos itens clicáveis (scan, diário, radar, cartão).
## set_state(enabled, pulsing) liga um pulso em loop; com "reduzir movimento"
## o pulso vira um contorno fixo.

signal activated(item_id: StringName)

@export var item_id: StringName

var _pulsing := false
var _tween: Tween
var _base_variation: StringName


func _ready() -> void:
	_base_variation = theme_type_variation
	pressed.connect(func() -> void: activated.emit(item_id))
	resized.connect(_center_pivot)
	Settings.changed.connect(_refresh)
	_center_pivot()


func set_state(enabled: bool, pulsing: bool) -> void:
	disabled = not enabled
	focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	if not enabled and has_focus():
		release_focus()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW
	_pulsing = pulsing and enabled
	_refresh()


func _refresh() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	scale = Vector2.ONE
	self_modulate = Color.WHITE
	theme_type_variation = _base_variation
	if not _pulsing:
		return
	if Settings.reduce_motion:
		theme_type_variation = &"InteractablePulse"
		return
	_tween = create_tween().set_loops()
	_tween.tween_property(self, "scale", Vector2.ONE * 1.08, 0.55).set_trans(Tween.TRANS_SINE)
	_tween.parallel().tween_property(self, "self_modulate", Color(1.35, 1.35, 1.35), 0.55)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE)
	_tween.parallel().tween_property(self, "self_modulate", Color.WHITE, 0.55)


func _center_pivot() -> void:
	pivot_offset = size / 2.0
