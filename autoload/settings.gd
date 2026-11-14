extends Node
## Configurações do jogador (fora do save, em user://settings.cfg) e o tema global.
## O tema é reconstruído a cada mudança: no modo "texto grande" todas as fontes,
## margens dos balões e ícones crescem juntas, e os contêineres se ajustam sozinhos.

signal changed

const PATH := "user://settings.cfg"
const BASE_FONT := 26
const LARGE_SCALE := 1.6

const C_BG := Color("0b0b12")
const C_PANEL := Color("17161f")
const C_PANEL_LIGHT := Color("ece9f6")
const C_ACCENT := Color("9b8cf0")
const C_ACCENT_DARK := Color("5b4b9a")
const C_TEXT := Color("f2f1ee")
const C_TEXT_DIM := Color("b9b5cc")
const C_TEXT_DARK := Color("2a2540")
const C_SCAN := Color("c0394b")
const C_FINAL := Color("23423a")
const C_HOLO := Color("7fe3ff")
const C_PAPER := Color("f6f2e7")

var large_text := false        # modo acessibilidade: fonte grande
var text_speed := 45.0         # caracteres por segundo
var reduce_motion := false     # desliga pulsos, flutuação e efeitos fortes
var music_volume := 0.8
var sfx_volume := 0.8

var theme: Theme

# Fontes do diário. Coloque um .ttf/.otf nesses caminhos para fixar a fonte
# (recomendado para exportação Web); sem arquivo, usa fontes do sistema.
const MONO_FONT_PATH := "res://assets/fonts/mono.ttf"
const HAND_FONT_PATH := "res://assets/fonts/handwriting.ttf"
var _mono: Font
var _mono_title: Font
var _hand: Font

# Cores do diário (mockup)
const D_INK := Color("1e1e1e")
const D_INK_SOFT := Color("3a3a3a")
const D_RULE := Color("8c8c8c")
const D_TAB := Color("ababab")
const D_TAB_ON := Color("e4e4e4")
const D_IMAGE := Color("d9d9d9")


const THEMED_GROUP := &"_settings_themed"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	_load()
	_apply()


func font_scale() -> float:
	return LARGE_SCALE if large_text else 1.0


## Tamanho de fonte escalado.
func fs(base: int) -> int:
	return int(round(base * font_scale()))


func set_value(key: StringName, value: Variant) -> void:
	if get(key) == value:
		return
	set(key, value)
	_apply()
	_save()
	changed.emit()


func _apply() -> void:
	theme = _build_theme()
	get_tree().root.theme = theme
	for n in get_tree().get_nodes_in_group(THEMED_GROUP):
		(n as Control).theme = theme


## CanvasLayer interrompe a herança de tema da janela. Todo Control no topo de
## uma CanvasLayer recebe o tema global, para que a fonte grande valha em
## balões, overlays e menu de pausa.
func _on_node_added(n: Node) -> void:
	if not n is Control or n.get_parent() is Control or n.get_parent() == get_tree().root:
		return
	var c := n as Control
	if c.theme == null or c.is_in_group(THEMED_GROUP):
		c.theme = theme
		c.add_to_group(THEMED_GROUP)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	large_text = bool(cfg.get_value("a11y", "large_text", large_text))
	text_speed = float(cfg.get_value("a11y", "text_speed", text_speed))
	reduce_motion = bool(cfg.get_value("a11y", "reduce_motion", reduce_motion))
	music_volume = float(cfg.get_value("audio", "music", music_volume))
	sfx_volume = float(cfg.get_value("audio", "sfx", sfx_volume))


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("a11y", "large_text", large_text)
	cfg.set_value("a11y", "text_speed", text_speed)
	cfg.set_value("a11y", "reduce_motion", reduce_motion)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save(PATH)


# --- Tema --------------------------------------------------------------------

func _build_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = fs(BASE_FONT)
	for type in [&"Label", &"Button", &"CheckButton", &"CheckBox", &"LinkButton", &"LineEdit"]:
		t.set_font_size(&"font_size", type, fs(BASE_FONT))
	for item in [&"normal_font_size", &"bold_font_size", &"italics_font_size", &"bold_italics_font_size", &"mono_font_size"]:
		t.set_font_size(item, &"RichTextLabel", fs(BASE_FONT))
	t.set_color(&"font_color", &"Label", C_TEXT)
	t.set_color(&"default_color", &"RichTextLabel", C_TEXT)
	t.set_constant(&"line_spacing", &"Label", fs(4))
	t.set_constant(&"line_separation", &"RichTextLabel", fs(4))

	# Rótulos
	_label_var(t, &"TitleLabel", 64, C_TEXT)
	_label_var(t, &"HeadingLabel", 36, C_TEXT)
	_label_var(t, &"NameLabel", 24, C_ACCENT)
	_label_var(t, &"SmallLabel", 18, C_TEXT_DIM)
	_label_var(t, &"PaperLabel", 24, C_TEXT_DARK)
	_label_var(t, &"PaperHeading", 32, C_TEXT_DARK)
	_label_var(t, &"PaperSmall", 18, Color("6b6580"))
	t.set_type_variation(&"PaperText", &"RichTextLabel")
	t.set_color(&"default_color", &"PaperText", C_TEXT_DARK)
	for item in [&"normal_font_size", &"bold_font_size", &"italics_font_size", &"bold_italics_font_size"]:
		t.set_font_size(item, &"PaperText", fs(24))

	# Painéis
	t.set_stylebox(&"panel", &"PanelContainer", _box(Color(C_PANEL, 0.96), C_ACCENT_DARK, 2, 16, 22))
	_panel_var(t, &"Balloon", _box(Color("141320", 0.97), C_ACCENT, 3, 18, 24))
	_panel_var(t, &"BalloonExplorer", _box(Color("0f1a22", 0.97), C_HOLO, 3, 18, 24))
	_panel_var(t, &"BalloonFinal", _box(Color(C_FINAL, 0.97), Color("8fe0b8"), 3, 18, 26))
	_panel_var(t, &"BalloonNarrator", _box(Color(0.03, 0.03, 0.06, 0.9), Color(1, 1, 1, 0.15), 1, 18, 24))
	_panel_var(t, &"PortraitFrame", _box(Color("05080c"), C_HOLO, 2, 12, 6))
	_panel_var(t, &"Holo", _box(Color(0.04, 0.14, 0.2, 0.88), C_HOLO, 2, 12, 18))
	_panel_var(t, &"Book", _box(Color("2b2238"), Color("8a6d3b"), 4, 20, 24))
	_panel_var(t, &"Paper", _box(C_PAPER, Color("d8cfb8"), 2, 10, 24))
	_panel_var(t, &"MenuBox", _box(Color("111018", 0.95), C_ACCENT_DARK, 2, 20, 36))
	_panel_var(t, &"Card", _box(Color("1d1b29"), C_ACCENT, 3, 18, 28))
	_panel_var(t, &"InfoPanel", _box(Color(0.03, 0.08, 0.07, 0.9), Color(0.4, 1.0, 0.7, 0.5), 2, 14, 20))

	# Botões
	_button_styles(t, &"Button", C_PANEL_LIGHT, C_TEXT_DARK, C_ACCENT_DARK)
	t.set_constant(&"icon_max_width", &"Button", fs(52))
	t.set_constant(&"h_separation", &"Button", fs(10))
	_button_var(t, &"ScanButton", C_SCAN, Color.WHITE, Color("ffb3bd"))
	_button_var(t, &"InteractablePulse", Color("fff4b8"), C_TEXT_DARK, Color("ffd23f"), 6)
	_button_var(t, &"GhostButton", Color(0.1, 0.1, 0.16, 0.85), C_TEXT, C_ACCENT)
	_button_var(t, &"ItemCard", Color("efe9da"), C_TEXT_DARK, Color("c9b98f"))
	_button_var(t, &"RadarMarker", Color(0.1, 0.35, 0.25, 0.95), Color("d6ffe9"), Color("6effb5"), 3, 999)
	t.set_stylebox(&"pressed", &"ItemCard", _box(C_ACCENT_DARK, C_ACCENT, 4, 14, 12))
	t.set_color(&"font_pressed_color", &"ItemCard", Color.WHITE)
	t.set_color(&"font_hover_pressed_color", &"ItemCard", Color.WHITE)
	t.set_constant(&"icon_max_width", &"ItemCard", fs(110))
	t.set_constant(&"icon_max_width", &"RadarMarker", fs(48))
	_diary_styles(t)
	return t


# --- Diário de bordo (relatório de missão) -------------------------------------

func _diary_styles(t: Theme) -> void:
	_load_fonts()
	_font_label(t, &"DiaryMono", _mono, 20, D_INK)
	_font_label(t, &"DiaryMonoSmall", _mono, 16, D_INK_SOFT)
	_font_label(t, &"DiaryValue", _mono, 20, D_INK)
	_font_label(t, &"DiaryTitle", _mono_title, 40, D_INK)
	_font_label(t, &"DiaryNumber", _mono, 26, D_INK_SOFT)

	t.set_type_variation(&"DiaryNotes", &"RichTextLabel")
	t.set_color(&"default_color", &"DiaryNotes", D_INK)
	for item in [&"normal_font", &"italics_font", &"bold_font", &"bold_italics_font"]:
		t.set_font(item, &"DiaryNotes", _hand)
	for item in [&"normal_font_size", &"italics_font_size", &"bold_font_size", &"bold_italics_font_size"]:
		t.set_font_size(item, &"DiaryNotes", fs(26))
	t.set_constant(&"line_separation", &"DiaryNotes", fs(12))

	var img := StyleBoxFlat.new()
	img.bg_color = D_IMAGE
	img.set_content_margin_all(10)
	_panel_var(t, &"DiaryImageBox", img)

	var row := StyleBoxFlat.new()
	row.bg_color = Color.TRANSPARENT
	row.border_color = D_RULE
	row.border_width_top = 2
	row.content_margin_left = 10
	row.content_margin_right = 6
	row.content_margin_top = 10 * clampf(font_scale(), 1.0, 1.4)
	row.content_margin_bottom = 10 * clampf(font_scale(), 1.0, 1.4)
	_panel_var(t, &"DiaryRow", row)
	var last := row.duplicate() as StyleBoxFlat
	last.border_width_bottom = 2
	_panel_var(t, &"DiaryRowLast", last)

	_panel_var(t, &"DiaryTabHeader", _chamfer(D_TAB, Color.TRANSPARENT, 0))
	t.set_type_variation(&"DiaryTab", &"Button")
	t.set_stylebox(&"normal", &"DiaryTab", _chamfer(D_TAB, Color.TRANSPARENT, 0))
	t.set_stylebox(&"hover", &"DiaryTab", _chamfer(D_TAB.lightened(0.15), Color.TRANSPARENT, 0))
	t.set_stylebox(&"pressed", &"DiaryTab", _chamfer(D_TAB_ON, D_INK_SOFT, 3))
	t.set_stylebox(&"hover_pressed", &"DiaryTab", _chamfer(D_TAB_ON, D_INK_SOFT, 3))
	t.set_stylebox(&"disabled", &"DiaryTab", _chamfer(Color("9a9a9a"), Color.TRANSPARENT, 0))
	var focus := _chamfer(Color.TRANSPARENT, Color("ffd23f"), 4)
	focus.draw_center = false
	t.set_stylebox(&"focus", &"DiaryTab", focus)
	t.set_font(&"font", &"DiaryTab", _mono)
	t.set_font_size(&"font_size", &"DiaryTab", fs(18))
	t.set_constant(&"icon_max_width", &"DiaryTab", fs(40))
	for c in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]:
		t.set_color(c, &"DiaryTab", D_INK_SOFT)
	t.set_color(&"font_disabled_color", &"DiaryTab", Color(D_INK_SOFT, 0.4))


## Formato das abas do mockup: cantos superior-direito e inferior-esquerdo chanfrados.
func _chamfer(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_detail = 1
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


func _font_label(t: Theme, type_name: StringName, font: Font, size: int, color: Color) -> void:
	_label_var(t, type_name, size, color)
	t.set_font(&"font", type_name, font)


func _load_fonts() -> void:
	if _mono:
		return
	_mono = _font_or_system(MONO_FONT_PATH,
		["IBM Plex Mono", "SF Mono", "Menlo", "Consolas", "DejaVu Sans Mono", "Courier New", "monospace"])
	# Título: mono em itálico (inclinação sintética, funciona com qualquer fonte).
	var title := FontVariation.new()
	title.base_font = _mono
	title.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.22, 1), Vector2.ZERO)
	title.variation_embolden = 0.5
	_mono_title = title
	_hand = _font_or_system(HAND_FONT_PATH,
		["Noteworthy", "Chalkboard SE", "Bradley Hand", "Segoe Print", "Comic Neue", "Comic Sans MS", "cursive"])


func _font_or_system(path: String, names: Array) -> Font:
	if ResourceLoader.exists(path):
		return load(path)
	var f := SystemFont.new()
	f.font_names = PackedStringArray(names)
	return f


func _box(bg: Color, border := Color.TRANSPARENT, bw := 0, radius := 14, pad := 18) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(pad * clampf(font_scale(), 1.0, 1.4))
	sb.anti_aliasing = true
	return sb


func _label_var(t: Theme, type_name: StringName, size: int, color: Color) -> void:
	t.set_type_variation(type_name, &"Label")
	t.set_font_size(&"font_size", type_name, fs(size))
	t.set_color(&"font_color", type_name, color)


func _panel_var(t: Theme, type_name: StringName, sb: StyleBox) -> void:
	t.set_type_variation(type_name, &"PanelContainer")
	t.set_stylebox(&"panel", type_name, sb)


func _button_var(t: Theme, type_name: StringName, bg: Color, fg: Color, border: Color, bw := 2, radius := 14) -> void:
	t.set_type_variation(type_name, &"Button")
	_button_styles(t, type_name, bg, fg, border, bw, radius)


func _button_styles(t: Theme, type_name: StringName, bg: Color, fg: Color, border: Color, bw := 2, radius := 14) -> void:
	t.set_stylebox(&"normal", type_name, _box(bg, border, bw, radius, 14))
	t.set_stylebox(&"hover", type_name, _box(bg.lightened(0.12), border.lightened(0.2), bw + 1, radius, 14))
	t.set_stylebox(&"pressed", type_name, _box(bg.darkened(0.15), border, bw + 1, radius, 14))
	t.set_stylebox(&"disabled", type_name, _box(Color(bg, 0.35), Color(border, 0.3), bw, radius, 14))
	var focus := _box(Color.TRANSPARENT, Color("ffd23f"), 4, radius, 14)
	focus.draw_center = false
	t.set_stylebox(&"focus", type_name, focus)
	t.set_color(&"font_color", type_name, fg)
	t.set_color(&"font_hover_color", type_name, fg)
	t.set_color(&"font_pressed_color", type_name, fg)
	t.set_color(&"font_focus_color", type_name, fg)
	t.set_color(&"font_hover_pressed_color", type_name, fg)
	t.set_color(&"font_disabled_color", type_name, Color(fg, 0.45))
