extends Node

@onready var dialog: Node = $"/root/levelprolog/DialogCanvas/DialogController"

func _ready() -> void:
	if dialog:
		dialog.show_dialog("mechanic")
