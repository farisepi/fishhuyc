# grabbable_item.gd
extends Node2D

func _ready():
	add_to_group("grabbable")
	set_meta("item_type", "box")
