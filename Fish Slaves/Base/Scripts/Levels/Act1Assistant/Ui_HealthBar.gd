extends CanvasLayer

@onready var health_bar: Control = $UI/HealthBar
@onready var stamina_bar: Control = $UI/StaminaBar
@onready var hp_hearts: AnimatedSprite2D = $UI/HealthBar/Hp

var glow: ColorRect
var shake_amount: float = 0.0
var shake_decay: float = 2.0
var pulse_timer: float = 0.0

# ЗАПОМИНАЕМ ИСХОДНЫЕ ПОЗИЦИИ
var health_bar_base_pos: Vector2
var stamina_bar_base_pos: Vector2
var hp_hearts_base_pos: Vector2

func _ready():

	health_bar_base_pos = health_bar.position
	stamina_bar_base_pos = stamina_bar.position
	hp_hearts_base_pos = hp_hearts.position
	

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
		float alpha = smoothstep(0.2, 1.0, d) * glow_color.a * pulse;
		COLOR = vec4(glow_color.rgb, alpha);
	}
	"""
	glow.material = ShaderMaterial.new()
	glow.material.shader = shader
	glow.material.set_shader_parameter("glow_color", Color(1, 0, 0, 0.15))
	glow.material.set_shader_parameter("pulse", 0.0)
	add_child(glow)
	
	if hp_hearts:
		hp_hearts.frame = 4
		hp_hearts.stop()

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
	
	# СВЕЧЕНИЕ
	if percent <= 0.5:
		shake_amount = 1.5 * (1.0 - percent / 0.5)
		pulse_timer += delta
		var pulse = 0.3 + 0.3 * sin(pulse_timer * 2.0)
		glow.material.set_shader_parameter("pulse", pulse)
	else:
		shake_amount = 0.0
		pulse_timer = 0.0
		glow.material.set_shader_parameter("pulse", 0.0)
	
	# ==========================================
	# ТРЯСКА НА МЕСТЕ (БЕЗ НАКОПЛЕНИЯ)
	# ==========================================
	if shake_amount > 0:
		var shake = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		
		# ВОЗВРАЩАЕМ НА БАЗУ + ДОБАВЛЯЕМ ТРЯСКУ
		health_bar.position = health_bar_base_pos + shake
		stamina_bar.position = stamina_bar_base_pos + shake
		hp_hearts.position = hp_hearts_base_pos + shake
		
		shake_amount = max(shake_amount - shake_decay * delta, 0.0)
	else:
		# ВОЗВРАЩАЕМ НА БАЗУ, КОГДА ТРЯСКА ЗАКОНЧИЛАСЬ
		health_bar.position = health_bar_base_pos
		stamina_bar.position = stamina_bar_base_pos
		hp_hearts.position = hp_hearts_base_pos
