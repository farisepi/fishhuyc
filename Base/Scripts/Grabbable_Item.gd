# grabbable_item.gd
extends Area2D

@export var item_name: String = "item"

func _ready():
	add_to_group("grabbable")
