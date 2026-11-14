@tool
extends EditorScript
## Verificador de conteúdo. No editor: abra este arquivo e use Arquivo → Executar (Ctrl+Shift+X).


func _run() -> void:
	var result := ContentChecks.run()
	for w in result["warnings"]:
		print_rich("[color=yellow]AVISO[/color] ", w)
	for e in result["errors"]:
		printerr("ERRO ", e)
	print("Verificador: %d erro(s), %d aviso(s)." % [result["errors"].size(), result["warnings"].size()])
