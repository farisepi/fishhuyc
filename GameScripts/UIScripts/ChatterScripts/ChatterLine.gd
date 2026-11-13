class_name ChatterLine
extends Resource

enum Speaker { SCIENTIST, MECHANIC }

@export var speaker: Speaker = Speaker.SCIENTIST

@export_multiline var text: String = ""

@export var swear_words: Array[String] = []

@export_range(0.0, 200.0, 2.0) var panel_height: float = 0.0

@export_range(0.0, 10.0, 0.1) var display_time: float = 0.0

@export var is_silent: bool = false
