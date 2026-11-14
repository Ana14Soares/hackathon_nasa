class_name ConfirmOverlay
extends Overlay
## Pergunta sim/não. Uso: `if await confirm.ask("Viajar até aqui?"): ...`
## Esc ou clique fora contam como "não".

signal answered(ok: bool)

@onready var _message: Label = %Message
@onready var _ok: Button = %OkButton
@onready var _cancel: Button = %CancelButton

var _waiting := false


func _ready() -> void:
	super._ready()
	_ok.pressed.connect(_finish.bind(true))
	_cancel.pressed.connect(_finish.bind(false))


func ask(message: String, ok_text := "Confirmar", cancel_text := "Cancelar") -> bool:
	_message.text = message
	_ok.text = ok_text
	_cancel.text = cancel_text
	_waiting = true
	show_overlay()
	var ok: bool = await answered
	return ok


func close() -> void:
	if _waiting:
		_finish(false)
	else:
		super.close()


func _finish(ok: bool) -> void:
	if not _waiting:
		return
	_waiting = false
	super.close()
	answered.emit(ok)


func _focus_first() -> void:
	_cancel.grab_focus()
