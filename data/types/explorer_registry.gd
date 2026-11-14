class_name ExplorerRegistry
extends Resource
## Lista explícita dos equipamentos (DirAccess não se comporta igual no jogo exportado).

@export var explorers: Array[ExplorerData] = []  # ordem padrão: créditos
@export var first_explorer: StringName           # alvo da história inicial
@export var unlock_count := 2                    # quantos pontos "?" o radar mostra por vez
