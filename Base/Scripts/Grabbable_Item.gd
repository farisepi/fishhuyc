# grabbable_item.gd
extends Area2D

@export var item_texture: Texture2D

func _ready():
	add_to_group("grabbable")
