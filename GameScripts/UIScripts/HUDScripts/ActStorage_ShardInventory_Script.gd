extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var blue_count: Label = $Panel/BlueRow/Count
@onready var green_count: Label = $Panel/GreenRow/Count
@onready var cyan_count: Label = $Panel/CyanRow/Count
@onready var total_count: Label = $Panel/TotalLabel

var is_open: bool = false

func _ready() -> void:
	panel.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		_toggle()
		get_viewport().set_input_as_handled()

func _toggle() -> void:
	is_open = not is_open
	panel.visible = is_open
	if is_open:
		_refresh()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _refresh() -> void:
	blue_count.text = str(Global.shards_blue)
	green_count.text = str(Global.shards_green)
	cyan_count.text = str(Global.shards_cyan)
	total_count.text = "Всего: " + str(Global.get_total_shards())
