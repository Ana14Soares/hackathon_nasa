class_name DiaryBook
extends Overlay
## Diário de bordo. Os textos e o layout de cada página vêm prontos na arte
## (ExplorerData.diary_page); este script só decide QUAL página mostrar:
##   • Uma aba por equipamento, na ordem do registro.
##   • Aba ativa  = equipamento já coletado (status SCANNED ou COMPLETED).
##   • Aba apagada = ainda não encontrado.
## O que está coletado vem do GameState, que já é gravado no save a cada
## checkpoint, então o diário reaparece igual ao continuar o jogo.

@onready var _aspect: AspectRatioContainer = %Aspect
@onready var _page: TextureRect = %Page
@onready var _missing: PanelContainer = %Missing
@onready var _missing_text: Label = %MissingText
@onready var _tabs: Control = %Tabs
@onready var _close_btn: Button = %CloseButton

var _selected: StringName = &""


func _ready() -> void:
	super._ready()
	_close_btn.pressed.connect(close)
	# Abas = botões invisíveis da cena (Tab1…TabN), na ordem do registro. Arraste-os no editor.
	var tabs := _tabs.get_children()
	for i in tabs.size():
		(tabs[i] as Button).pressed.connect(_on_tab_pressed.bind(i))
	Settings.changed.connect(_on_settings_changed)


## Abre o diário na página do equipamento informado (usado no encontro).
func open(data: ExplorerData, _story: StoryData = null) -> void:
	_selected = data.id
	_refresh()
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
	_refresh()
	AudioManager.play_sfx(&"diary_open")
	show_overlay()


func _refresh() -> void:
	_build_tabs()
	_show_page(ContentDB.get_explorer(_selected) if _selected != &"" else null)


# --- Abas ---------------------------------------------------------------------

func _build_tabs() -> void:
	var all := ContentDB.all_ids()
	var tabs := _tabs.get_children()
	for i in tabs.size():
		var b := tabs[i] as Button
		b.visible = i < all.size()
		if i >= all.size():
			continue
		var found := GameState.is_collected(all[i])
		b.disabled = not found
		# Já desbloqueado: o número aparece por cima da aba (a aba aberta já traz o número na arte).
		b.text = ("%03d" % (i + 1)) if found and all[i] != _selected else ""
		b.focus_mode = Control.FOCUS_ALL if found else Control.FOCUS_NONE
		b.tooltip_text = ("%03d · %s" % [i + 1, ContentDB.get_explorer(all[i]).display_name]) if found \
			else ("%03d · not found yet" % (i + 1))


func _on_tab_pressed(index: int) -> void:
	var all := ContentDB.all_ids()
	if index >= all.size() or not GameState.is_collected(all[index]) or all[index] == _selected:
		return
	_selected = all[index]
	_build_tabs()
	_show_page(ContentDB.get_explorer(_selected))


# --- Página -------------------------------------------------------------------

func _show_page(data: ExplorerData) -> void:
	var tex: Texture2D = data.diary_page if data else null
	_page.texture = tex
	_page.visible = tex != null
	_missing.visible = tex == null
	if tex:
		# A moldura segue a proporção da arte da página.
		_aspect.ratio = tex.get_size().x / tex.get_size().y
	elif data:
		_missing_text.text = "The log page for %s has not been created yet.\nAssign the art to \"Diary Page\" in the file %s." \
			% [data.display_name, data.resource_path.get_file()]
	else:
		_missing_text.text = "No equipment recorded yet.\nUse the scanner to meet the first one!"


func _on_settings_changed() -> void:
	if visible:
		_build_tabs()
