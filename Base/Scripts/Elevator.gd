# elevator.gd
extends ColorRect

var is_open: bool = false

func open():
	is_open = true
	color = Color.GREEN

func close():
	is_open = false
	color = Color(0.27, 0.27, 0.27)
