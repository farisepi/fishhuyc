extends CanvasLayer

@onready var hp_bar: AnimatedSprite2D = $UI_Container/HP_Bar
@onready var hearts: AnimatedSprite2D = $UI_Container/Hearts
@onready var stamina: AnimatedSprite2D = $UI_Container/Stamina
@onready var suit_icon: Sprite2D = $UI_Container/SuitIcon

var max_hearts: int = 5
var current_hearts: int = 5
var stamina_value: float = 100.0
var max_stamina: float = 100.0
var has_suit: bool = false

var shake_amount: float = 0.0
var shake_decay: float = 5.0
var pulse_timer: float = 0.0
var glow: ColorRect

var hp_bar_base_pos: Vector2
var hearts_base_pos: Vector2
var stamina_base_pos: Vector2

func _ready():
	hp_bar.play("HP_Bar")
	_update_hearts()
	_update_stamina()
	_update_suit()
	
	hp_bar_base_pos = hp_bar.position
	hearts_base_pos = hearts.position
	stamina_base_pos = stamina.position
	
	glow = ColorRect.new()
	glow.mouse_filter = 0
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform vec4 glow_color : source_color = vec4(1.0, 0.0, 0.0, 0.15);
	uniform float pulse : hint_range(0.0, 1.0) = 0.5;
	void fragment() {
		vec2 uv = UV;
		vec2 dist = abs(uv - 0.5) * 2.0;
		float d = max(dist.x, dist.y);
		float alpha = smoothstep(0.7, 1.0, d) * glow_color.a * pulse;
		COLOR = vec4(glow_color.rgb, alpha);
	}
	"""
	glow.material = ShaderMaterial.new()
	glow.material.shader = shader
	glow.material.set_shader_parameter("glow_color", Color(1, 0, 0, 0.15))
	glow.material.set_shader_parameter("pulse", 0.0)
	add_child(glow)

func _process(delta):
	if get_tree().paused:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	if player.has_method("get_hp"):
		current_hearts = player.get_hp()
		_update_hearts()
	
	if player.has_method("get_stamina"):
		stamina_value = player.get_stamina()
		_update_stamina()
	
	var hp_percent = float(current_hearts) / float(max_hearts)
	
	if hp_percent <= 0.2:
		shake_amount = 2.0 * (1.0 - hp_percent / 0.2)
		pulse_timer += delta
		var pulse = 0.3 + 0.3 * sin(pulse_timer * 2.0)
		glow.material.set_shader_parameter("pulse", pulse)
	else:
		shake_amount = 0.0
		pulse_timer = 0.0
		glow.material.set_shader_parameter("pulse", 0.0)
	
	if shake_amount > 0:
		var shake = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		hp_bar.position = hp_bar_base_pos + shake
		hearts.position = hearts_base_pos + shake
		stamina.position = stamina_base_pos + shake
		shake_amount = max(shake_amount - shake_decay * delta, 0.0)
	else:
		hp_bar.position = hp_bar_base_pos
		hearts.position = hearts_base_pos
		stamina.position = stamina_base_pos

func _update_hearts():
	if not hearts:
		return
	var total_frames = hearts.sprite_frames.get_frame_count("Hp")
	var frame = int((float(current_hearts) / float(max_hearts)) * (total_frames - 1))
	hearts.frame = clamp(frame, 0, total_frames - 1)
	hearts.stop()

func _update_stamina():
	if not stamina:
		return
	var total_frames = stamina.sprite_frames.get_frame_count("Stamina")
	var percent = clamp(stamina_value / max_stamina, 0, 1)
	var frame = int(percent * (total_frames - 1))
	stamina.frame = clamp(frame, 0, total_frames - 1)
	stamina.stop()

func _update_suit():
	if not suit_icon:
		return
	if has_suit:
		suit_icon.modulate = Color(1, 1, 1, 1)
	else:
		suit_icon.modulate = Color(0.3, 0.3, 0.3, 1)

func set_hearts(value: int):
	current_hearts = clamp(value, 0, max_hearts)
	_update_hearts()

func set_stamina(value: float):
	stamina_value = clamp(value, 0, max_stamina)
	_update_stamina()

func set_suit(active: bool):
	has_suit = active
	_update_suit()
