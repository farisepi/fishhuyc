extends CanvasLayer

@onready var bar_fill: ColorRect = $UI/HealthBar/BarFill

var shake_amount: float = 0.0
var shake_decay: float = 5.0
var pulse_timer: float = 0.0
var glow: ColorRect

func _ready():
	bar_fill = get_node_or_null("UI/HealthBar/BarFill")
	
	if bar_fill:
		bar_fill.scale = Vector2(1.5, 1.5)
	
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
	
	if not player.has_method("get_hp"):
		return
	
	var hp = player.get_hp()
	var max_hp = player.get_max_hp()
	var percent = float(hp) / float(max_hp)
	
	if bar_fill:
		bar_fill.size.x = 196 * clamp(percent, 0, 1)
		bar_fill.size.y = 26
		bar_fill.position.x = 22 + 10
		bar_fill.position.y = 22 + 5
	
	if percent <= 0.5:
		bar_fill.color = Color(1, 0.2, 0.2)
		shake_amount = 2.0 * (1.0 - percent / 0.5)
		
		pulse_timer += delta
		var pulse = 0.3 + 0.3 * sin(pulse_timer * 2.0)
		glow.material.set_shader_parameter("pulse", pulse)
	else:
		bar_fill.color = Color(0.2, 0.8, 0.2)
		shake_amount = 0.0
		pulse_timer = 0.0
		glow.material.set_shader_parameter("pulse", 0.0)
	
	if shake_amount > 0:
		var shake = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		bar_fill.position = Vector2(22 + 10, 22 + 5) + shake
		shake_amount = max(shake_amount - shake_decay * delta, 0.0)
