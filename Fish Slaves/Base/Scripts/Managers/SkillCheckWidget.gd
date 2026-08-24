extends Control

@onready var circle: TextureRect = $Circle
@onready var arrow: TextureRect = %Arrow
@onready var succes_zone: TextureRect = $SuccessZone

var rotation_speed float = 200
var is_active: bool = false
var current_angle: float = 0
var succes_start: float = 45
var success_end float = 135

func _process(delta):
	if not is_active: 
		return
	current_angle += rotation_speed * delta
	if current_angle > 360:
		current_angle -= 360	
	arrow.rotation = deg_to_rad(current_angle)
func show_skill_check():
	is_active = true
	visible = true
	current_angle = 0
	arrow.rotation = 0
func hide_skill_check():
	is_active = false
	visible = false
func check_sucess() -> bool:
	if not is_active:		
		return false	
	var in_zone = current_angle >= success_start and current_angle <= success_end 
	return in_zone
					
