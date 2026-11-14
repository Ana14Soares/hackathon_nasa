class_name Overlay
extends Control
## Base dos modais: escurece o fundo, fecha com Esc ou clique fora, prende o
## foco no primeiro botão e emite `closed`. O painel interno deve ter
## mouse_filter STOP para que cliques nele não contem como "fora".

signal closed

@export var close_on_click_outside := true

var _prev_focus: Control


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func show_overlay() -> void:
	_prev_focus = get_viewport().gui_get_focus_owner()
	visible = true
	if not Settings.reduce_motion:
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.15)
	_focus_first.call_deferred()


func close() -> void:
	if not visible:
		return
	visible = false
	modulate.a = 1.0
	if is_instance_valid(_prev_focus) and _prev_focus.is_visible_in_tree() and _prev_focus.focus_mode != Control.FOCUS_NONE:
		_prev_focus.grab_focus()
	closed.emit()


func _gui_input(event: InputEvent) -> void:
	if close_on_click_outside and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		close()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _focus_first() -> void:
	var b := _find_button(self)
	if b:
		b.grab_focus()


func _find_button(n: Node) -> BaseButton:
	for child in n.get_children():
		if child is BaseButton and (child as BaseButton).is_visible_in_tree() and not (child as BaseButton).disabled \
				and (child as Control).focus_mode != Control.FOCUS_NONE:
			return child
		var found := _find_button(child)
		if found:
			return found
	return null
