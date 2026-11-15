class_name SettingsPanel
extends VBoxContainer
## Opções de acessibilidade e som, usadas no menu inicial e na pausa.

var _large: CheckButton
var _motion: CheckButton
var _speed: HSlider
var _music: HSlider
var _sfx: HSlider


func _ready() -> void:
	add_theme_constant_override(&"separation", 12)
	_large = _check("Large text (accessibility mode)", Settings.large_text, &"large_text")
	_motion = _check("Reduce motion", Settings.reduce_motion, &"reduce_motion")
	_speed = _slider("Text speed", 15.0, 120.0, 5.0, Settings.text_speed, &"text_speed")
	_music = _slider("Music volume", 0.0, 1.0, 0.05, Settings.music_volume, &"music_volume")
	_sfx = _slider("Effects volume", 0.0, 1.0, 0.05, Settings.sfx_volume, &"sfx_volume")


func _check(text: String, value: bool, key: StringName) -> CheckButton:
	var c := CheckButton.new()
	c.text = text
	c.button_pressed = value
	c.toggled.connect(func(on: bool) -> void: Settings.set_value(key, on))
	add_child(c)
	return c


func _slider(text: String, min_v: float, max_v: float, step: float, value: float, key: StringName) -> HSlider:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"SmallLabel"
	add_child(l)
	var s := HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(0, 32)
	s.value_changed.connect(func(v: float) -> void: Settings.set_value(key, v))
	add_child(s)
	return s
