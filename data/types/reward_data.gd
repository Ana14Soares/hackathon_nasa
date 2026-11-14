class_name RewardData
extends Resource
## Artefato recebido ao concluir um equipamento (ex.: Placa Pioneer).

@export var id: StringName               # &"pioneer_plaque"
@export var display_name: String
@export var description: String          # "Lembrança de um novo amigo."
@export var texture: Texture2D           # vira item decorativo na nave
@export var shelf_slot: StringName       # nome do slot em ShipInterior
@export var unlocks: Array[StringName] = []   # [&"radar_unlocked"]
