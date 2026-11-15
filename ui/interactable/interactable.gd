class_name Interactable
extends Button
## Componente único dos itens clicáveis (scan, diário, radar, cartão).
## set_state(enabled, pulsing) liga a DICA de "clique aqui": o botão fica com o
## visual de "pressed" (a arte pressionada) enquanto a dica estiver ativa. Se o
## botão não tiver visual de pressed (só ícone), usa um contorno fixo.
## O tamanho, a escala e a rotação definidos no editor são respeitados como estão.

signal activated(item_id: StringName)

@export var item_id: StringName
## Visual do botão enquanto estiver BLOQUEADO (set_locked(true)), no lugar do
## visual de desabilitado. Ex.: o radar vazio até a Placa Pioneer ser descoberta.
@export var locked_style: StyleBox

var _hinting := false
var _locked := false
var _scene_disabled: StyleBox          # estilo 'disabled' definido na cena (se houver)
var _locked_applied := false
var _base_variation: StringName
var _hint_overrode_normal := false
var _had_normal_override := false
var _saved_normal: StyleBox


func _ready() -> void:
	_base_variation = theme_type_variation
	if has_theme_stylebox_override(&"disabled"):
		_scene_disabled = get_theme_stylebox(&"disabled")
	pressed.connect(func() -> void: activated.emit(item_id))
	Settings.changed.connect(_refresh)


func set_state(enabled: bool, hint: bool) -> void:
	disabled = not enabled
	focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	if not enabled and has_focus():
		release_focus()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW
	_hinting = hint and enabled
	_refresh()


func set_locked(locked: bool) -> void:
	_locked = locked
	_refresh()


func _refresh() -> void:
	# Bloqueado: troca o visual de desabilitado pelo visual "vazio".
	if _locked_applied:
		if _scene_disabled:
			add_theme_stylebox_override(&"disabled", _scene_disabled)
		else:
			remove_theme_stylebox_override(&"disabled")
		_locked_applied = false
	if _locked and locked_style:
		add_theme_stylebox_override(&"disabled", locked_style)
		_locked_applied = true
	# Desfaz a dica anterior.
	if _hint_overrode_normal:
		if _had_normal_override:
			add_theme_stylebox_override(&"normal", _saved_normal)
		else:
			remove_theme_stylebox_override(&"normal")
		_hint_overrode_normal = false
	theme_type_variation = _base_variation
	if not _hinting:
		return
	var pressed_style := get_theme_stylebox(&"pressed")
	if pressed_style == null or pressed_style is StyleBoxEmpty \
			or (pressed_style is StyleBoxTexture and pressed_style.texture == null):
		# Sem visual de pressed (botão só de ícone): contorno fixo "<Variação>Pulse".
		var v := StringName(String(_base_variation) + "Pulse")
		theme_type_variation = v if v in Settings.theme.get_type_list() else &"InteractablePulse"
		return
	# Dica = o botão aparece no estado pressed (arte pressionada).
	_had_normal_override = has_theme_stylebox_override(&"normal")
	_saved_normal = get_theme_stylebox(&"normal")
	add_theme_stylebox_override(&"normal", pressed_style)
	_hint_overrode_normal = true
