class_name DialogueBox
extends Control
## Balão de fala. Contrato: `await dialogue.play(lines)` só retorna depois que a
## última fala for dispensada.
##
## Balões sem foto: só o nome de quem fala e o texto.
##   • Lyra ("hero" / "hero_to_player") e narrador → texto (a Lyra com nome).
##   • Equipamento ("explorer" ou um id do registro) → nome dele e texto em 1ª pessoa.
##     O rostinho dele aparece na nave (talking_changed), não no balão.
##
## Responsividade: o balão é ancorado embaixo e cresce para cima conforme o
## conteúdo (grow_vertical = BEGIN). O texto tem quebra automática e o
## RichTextLabel usa fit_content, então fonte maior = balão maior. Se o texto
## passar de MAX_HEIGHT_RATIO da tela, ele rola em vez de vazar.

signal line_started(line: DialogueLine)
signal line_dismissed
signal finished
## Um equipamento começou/parou de "falar" (texto sendo digitado).
signal talking_changed(speaker: ExplorerData, talking: bool)

const MAX_HEIGHT_RATIO := 0.5
const INPUT_GUARD_MS := 150

## Equipamento do encontro atual: quem fala quando `who` == "explorer".
var explorer_context: ExplorerData

var _playing := false
var _typing := false
var _tween: Tween
var _shown_at := 0
var _last_event: InputEvent
var _speaker: ExplorerData
var _talking := false

@onready var _balloon: PanelContainer = %Balloon
@onready var _name: Label = %NameLabel
@onready var _scroll: ScrollContainer = %TextScroll
@onready var _text: RichTextLabel = %Text
@onready var _hint: Label = %Hint


func _ready() -> void:
	_balloon.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_balloon.gui_input.connect(_on_click)
	_scroll.gui_input.connect(_on_click)
	Settings.changed.connect(_on_settings_changed)
	_on_settings_changed()
	set_process(false)


func is_playing() -> bool:
	return _playing


## Topo do balão na tela (para outros painéis não ficarem por baixo dele).
func balloon_top() -> float:
	return _balloon.get_global_rect().position.y if _balloon.visible else INF


func play(lines: Array[DialogueLine]) -> void:
	if lines.is_empty():
		return
	_playing = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_balloon.visible = true
	set_process(true)
	for line in lines:
		_show_line(line)
		line_started.emit(line)
		await line_dismissed
	_set_talking(false)
	_balloon.visible = false
	set_process(false)
	_playing = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	finished.emit()


func _show_line(line: DialogueLine) -> void:
	var speaker := _resolve_explorer(line.who)
	var variation: StringName = &"Balloon"
	var speaker_name := ""

	if speaker:
		# O equipamento fala por si: só o nome dele e a fala (sem foto).
		speaker_name = speaker.display_name
		variation = &"BalloonExplorer"
	elif line.is_hero():
		# Lyra: nome e fala.
		speaker_name = ContentDB.protagonist_card.display_name
		if line.who == "hero_to_player":
			variation = &"BalloonFinal"
	else:
		variation = &"BalloonNarrator"

	_set_talking(false)
	_speaker = speaker
	_balloon.theme_type_variation = variation
	_name.text = speaker_name
	_name.visible = speaker_name != ""
	_text.text = ("[i]%s[/i]" % line.text) if variation == &"BalloonNarrator" else line.text
	_scroll.scroll_vertical = 0
	_text.visible_ratio = 0.0
	_shown_at = Time.get_ticks_msec()

	var chars := float(_text.get_parsed_text().length())
	var duration := maxf(0.05, chars / maxf(Settings.text_speed, 1.0))
	_typing = true
	_set_talking(true)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_text, "visible_ratio", 1.0, duration)
	_tween.finished.connect(func() -> void:
		_typing = false
		_set_talking(false))
	_fit_height()


## A boca do equipamento (rostinho na nave) só mexe enquanto o texto é digitado.
func _set_talking(on: bool) -> void:
	on = on and _speaker != null
	if _talking == on:
		return
	_talking = on
	if _speaker:
		talking_changed.emit(_speaker, on)


func _resolve_explorer(who: String) -> ExplorerData:
	if who == "explorer":
		return explorer_context
	if ContentDB.has_explorer(StringName(who)):
		return ContentDB.get_explorer(StringName(who))
	return null


func _advance() -> void:
	if not _playing or Time.get_ticks_msec() - _shown_at < INPUT_GUARD_MS:
		return
	if _typing:
		# 1º clique completa a digitação; o seguinte avança.
		if _tween:
			_tween.kill()
		_text.visible_ratio = 1.0
		_typing = false
		_set_talking(false)
		_shown_at = Time.get_ticks_msec()
	else:
		line_dismissed.emit()


func _gui_input(event: InputEvent) -> void:
	_on_click(event)


func _on_click(event: InputEvent) -> void:
	if event == _last_event:
		return   # o mesmo clique subindo pela árvore
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_last_event = event
		_advance()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if _playing and is_visible_in_tree() and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()


# --- Tamanho responsivo -------------------------------------------------------

func _process(_delta: float) -> void:
	_fit_height()


## O texto ocupa a altura que precisar, até o limite; depois disso, rola.
func _fit_height() -> void:
	var content_h := float(_text.get_content_height())
	var max_h := get_viewport_rect().size.y * MAX_HEIGHT_RATIO
	var target := minf(content_h, max_h)
	if not is_equal_approx(_scroll.custom_minimum_size.y, target):
		_scroll.custom_minimum_size.y = target
	var overflow := content_h > max_h + 1.0
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if overflow else ScrollContainer.SCROLL_MODE_DISABLED
	_hint.text = "Scroll to read it all · click or Enter to continue" if overflow else "Click, Enter or Space to continue ▸"


func _on_settings_changed() -> void:
	_fit_height()
