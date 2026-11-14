class_name DiaryBook
extends Overlay
## Diário de bordo no formato "relatório de missão":
##   • Esquerda: MISSION REPORT / EQUIPMENT 00N, imagem do equipamento (com o
##     rostinho), nome e tabela TYPE / LAUNCH / TARGET / OBJECTIVE.
##   • Direita: NOTES — o texto pessoal da Lyra em letra manuscrita.
##   • Abas à direita = coleção: uma aba por equipamento do registro. As coletadas
##     mostram a miniatura e abrem as páginas; as que faltam ficam apagadas.
## Cada coluna rola sozinha, então o texto grande nunca corta.

@onready var _report_header: Label = %ReportHeader
@onready var _image_box: PanelContainer = %ImageBox
@onready var _image: TextureRect = %Image
@onready var _face: CuteFace = %ImageFace
@onready var _name: Label = %NameLabel
@onready var _table: VBoxContainer = %Table
@onready var _footer: VBoxContainer = %Footer
@onready var _notes: RichTextLabel = %Notes
@onready var _left_scroll: ScrollContainer = %LeftScroll
@onready var _right_scroll: ScrollContainer = %RightScroll
@onready var _number: Label = %Number
@onready var _tab_list: VBoxContainer = %TabList
@onready var _close_btn: Button = %CloseButton

var _selected: StringName = &""
var _current: ExplorerData
var _group := ButtonGroup.new()


func _ready() -> void:
	super._ready()
	_close_btn.pressed.connect(close)
	_image.resized.connect(_place_face)
	Settings.changed.connect(_on_settings_changed)


## Abre o diário no equipamento informado (usado no encontro).
func open(data: ExplorerData, story: StoryData) -> void:
	_selected = data.id
	_build_tabs()
	_show_pages(data, story)
	AudioManager.play_sfx(&"diary_open")
	show_overlay()


## Abre o diário pela coleção (usado no radar).
func open_collection() -> void:
	var ids := GameState.collected_ids()
	if GameState.current_explorer in ids:
		_selected = GameState.current_explorer
	elif not ids.is_empty():
		_selected = ids[0]
	else:
		_selected = &""
	_build_tabs()
	if _selected != &"":
		_show_pages(ContentDB.get_explorer(_selected), ContentDB.get_story(_selected))
	else:
		_show_empty()
	AudioManager.play_sfx(&"diary_open")
	show_overlay()


# --- Abas (coleção) -----------------------------------------------------------

func _build_tabs() -> void:
	_clear(_tab_list)
	var collected := GameState.collected_ids()
	var all := ContentDB.all_ids()
	for i in all.size():
		var id := all[i]
		var b := Button.new()
		b.theme_type_variation = &"DiaryTab"
		b.toggle_mode = true
		b.button_group = _group
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.custom_minimum_size = Vector2(0, 50 * clampf(Settings.font_scale(), 1.0, 1.3))
		if id in collected:
			var data := ContentDB.get_explorer(id)
			b.icon = data.sprite
			b.tooltip_text = "%s · %s" % [_num(i), data.display_name]
			b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			b.button_pressed = id == _selected
			b.pressed.connect(_on_tab_pressed.bind(id))
		else:
			b.disabled = true
			b.tooltip_text = "%s · ainda não encontrado" % _num(i)
			b.focus_mode = Control.FOCUS_NONE
		_tab_list.add_child(b)


func _on_tab_pressed(id: StringName) -> void:
	if id == _selected:
		return
	_selected = id
	_show_pages(ContentDB.get_explorer(id), ContentDB.get_story(id))


# --- Páginas ------------------------------------------------------------------

func _show_pages(data: ExplorerData, story: StoryData) -> void:
	_current = data
	_left_scroll.scroll_vertical = 0
	_right_scroll.scroll_vertical = 0
	var n := _num(ContentDB.all_ids().find(data.id))
	_number.text = n
	_report_header.text = "MISSION REPORT / EQUIPMENT %s" % n
	_image_box.visible = true
	_image.texture = data.sprite
	_face.visible = GameState.is_collected(data.id)
	_place_face()
	_name.text = data.display_name.to_upper()

	_clear(_table)
	for i in story.report.size():
		var r: Dictionary = story.report[i]
		_add_row(str(r.get("label", "")), str(r.get("value", "")), i == story.report.size() - 1)

	_clear(_footer)
	var sources: Array[String] = []
	for sid in story.cited_source_ids():
		var s: Dictionary = story.sources.get(sid, {})
		sources.append(str(s.get("title", sid)))
	if not sources.is_empty():
		_add_small(_footer, "SOURCE: " + " · ".join(sources))
	if data.reward and data.reward.id in GameState.artifacts:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override(&"separation", 10)
		var tex := TextureRect.new()
		tex.texture = data.reward.texture
		tex.custom_minimum_size = Vector2(72, 46)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hb.add_child(tex)
		var l := _add_small(hb, "ARTIFACT: " + data.reward.display_name.to_upper())
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_footer.add_child(hb)

	_notes.text = _paragraphs(story.personal)


func _show_empty() -> void:
	_current = null
	_number.text = "---"
	_report_header.text = "MISSION REPORT / EQUIPMENT ---"
	_image_box.visible = false
	_name.text = "SEM REGISTROS"
	_clear(_table)
	_clear(_footer)
	_notes.text = "Ainda não registrei nenhum explorador. Use o scanner para conhecer o primeiro!"


func _add_row(key: String, value: String, last: bool) -> void:
	var row := PanelContainer.new()
	row.theme_type_variation = &"DiaryRowLast" if last else &"DiaryRow"
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override(&"separation", 16)
	var k := Label.new()
	k.text = key
	k.theme_type_variation = &"DiaryMonoSmall"
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	k.size_flags_stretch_ratio = 0.62
	k.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	k.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var v := Label.new()
	v.text = value
	v.theme_type_variation = &"DiaryValue"
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hb.add_child(k)
	hb.add_child(v)
	row.add_child(hb)
	_table.add_child(row)


func _add_small(parent: Control, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"DiaryMonoSmall"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	return l


## Linha em branco entre parágrafos, como no mockup.
func _paragraphs(text: String) -> String:
	return text.replace("\n\n", "\n").replace("\n", "\n\n")


## O rosto acompanha o sprite desenhado (quadrado centralizado na caixa).
func _place_face() -> void:
	if _current == null:
		return
	var s := minf(_image.size.x, _image.size.y)
	_face.place(_current.face_position, _current.face_size, Vector2(s, s))
	_face.position += (_image.size - Vector2(s, s)) / 2.0


func _on_settings_changed() -> void:
	if visible and _selected != &"":
		_build_tabs()
		_image_box.custom_minimum_size.y = 230 * clampf(Settings.font_scale(), 1.0, 1.2)


static func _num(i: int) -> String:
	return "%03d" % (i + 1)


func _clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()
