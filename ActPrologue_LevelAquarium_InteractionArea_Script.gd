extends Area2D

signal interaction_available(available: bool)

func _ready() -> void:
	body_entered.connect(func(body): _on_body_changed(body, true))
	body_exited.connect(func(body): _on_body_changed(body, false))

func _on_body_changed(body: Node2D, entered: bool) -> void:
	if body.is_in_group("Player"):
		interaction_available.emit(entered)
