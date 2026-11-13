extends CanvasLayer

@onready var hp_bar: AnimatedSprite2D = $UI_Container/HP_Bar
@onready var hearts: AnimatedSprite2D = $UI_Container/Hearts
@onready var stamina: AnimatedSprite2D = $UI_Container/Stamina
@onready var suit_icon: Sprite2D = $UI_Container/SuitIcon

var max_hearts: int = 5
var current_hearts: int = 1
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
var _player: Node = null
var _last_hearts: int = -1
var _last_stamina: float = -1.0
var _glow_on: bool = true
var glow_disabled: bool = false
var _shaken: bool = true
var _glow_k: float = 0.0


const HP_BAR_SPEED_TABLE: Dictionary = {
	5: 1.0,
	4: 1.125,
	3: 1.25,
	2: 1.375,
	1: 1.5,
	0: 0.0,
}

func _ready():
	hp_bar.play("HP_Bar")
	hp_bar.frame = 0
	_update_hearts()
	_update_stamina()

	hp_bar_base_pos = hp_bar.position
	hearts_base_pos = hearts.position
	stamina_base_pos = stamina.position

	glow = ColorRect.new()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		float alpha = smoothstep(0.5, 1.0, d) * glow_color.a * pulse;
		COLOR = vec4(glow_color.rgb, alpha);
	}
"""
	glow.material = ShaderMaterial.new()
	glow.material.shader = shader
	glow.material.set_shader_parameter("glow_color", Color(1, 0, 0, LOW_HP_GLOW_A))
	glow.material.set_shader_parameter("pulse", 0.0)
	add_child(glow)
	_add_shimmer(suit_icon, 0.35)
	glow.visible = false

const LOW_HP_GLOW_A := 0.17

static func low_hp_pulse(t: float) -> float:
	return 0.5 + 0.35 * sin(t * 2.4)

func _add_shimmer(spr: Sprite2D, phase: float) -> void:
	if spr == null or spr.texture == null:
		return
	var sh = load("res://GameShaders/SharedShaders/Shared_UIShimmer_Shader.gdshader")
	if sh == null:
		return
	var m = ShaderMaterial.new()
	m.shader = sh
	var sz = spr.texture.get_size()
	m.set_shader_parameter("rect_min", -sz * 0.5 if spr.centered else Vector2.ZERO)
	m.set_shader_parameter("rect_size", sz)
	m.set_shader_parameter("pixel", 1.0)
	m.set_shader_parameter("phase", phase)
	spr.material = m

func _process(delta):
	if get_tree().paused:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		_last_hearts = -1
		_last_stamina = -1.0
	var player = _player
	var ui = get_node_or_null("UI_Container") as CanvasItem
	var ui_alpha = 0.0
	if ui and ui.visible and visible:
		ui_alpha = ui.modulate.a
	if not player:
		glow.visible = false
		return
	if player.has_method("get_hp"):
		current_hearts = player.get_hp()
		if current_hearts != _last_hearts:
			_last_hearts = current_hearts
			_update_hearts()
			if hp_bar:
				var speed = HP_BAR_SPEED_TABLE.get(clamp(current_hearts, 0, 5), 1.0)
				hp_bar.speed_scale = speed
				if speed <= 0.0:
					hp_bar.stop()
	if player.has_method("get_stamina"):
		stamina_value = player.get_stamina()
		if absf(stamina_value - _last_stamina) > 0.25:
			_last_stamina = stamina_value
			_update_stamina()

	var hp_percent = float(current_hearts) / float(max_hearts)
	if hp_percent <= 0.2:
		shake_amount = 2.0 * (1.0 - hp_percent / 0.2)
		pulse_timer += delta
		glow.material.set_shader_parameter("pulse", low_hp_pulse(pulse_timer))
		_glow_on = true
		if ui_alpha >= 0.99:
			_glow_k = move_toward(_glow_k, 1.0, delta / 1.6)
		else:
			_glow_k = min(_glow_k, ui_alpha)
		var ga = smoothstep(0.0, 1.0, _glow_k)
		glow.visible = not glow_disabled and ga > 0.01 and current_hearts > 0
		glow.modulate.a = ga
	elif _glow_on:
		_glow_on = false
		_glow_k = 0.0
		shake_amount = 0.0
		pulse_timer = 0.0
		glow.material.set_shader_parameter("pulse", 0.0)
		glow.visible = false

	if shake_amount > 0:
		var shake = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		hp_bar.position = hp_bar_base_pos + shake
		hearts.position = hearts_base_pos + shake
		stamina.position = stamina_base_pos + shake
		shake_amount = max(shake_amount - shake_decay * delta, 0.0)
		_shaken = true
	elif _shaken:
		_shaken = false
		hp_bar.position = hp_bar_base_pos
		hearts.position = hearts_base_pos
		stamina.position = stamina_base_pos

func _update_hearts():
	if not hearts:
		return
	var total_frames = hearts.sprite_frames.get_frame_count("Hp")
	var frame = total_frames - 1 - int(clamp(float(current_hearts) / float(max_hearts), 0.0, 1.0) * (total_frames - 1))
	hearts.stop()
	hearts.frame = clamp(frame, 0, total_frames - 1)

func _update_stamina():
	if not stamina:
		return
	var total_frames = stamina.sprite_frames.get_frame_count("Stamina")
	var percent = clamp(stamina_value / max_stamina, 0, 1)
	var frame = int(percent * (total_frames - 1))
	stamina.frame = clamp(frame, 0, total_frames - 1)
	stamina.stop()

func set_hearts(value: int):
	current_hearts = clamp(value, 0, max_hearts)
	_update_hearts()

func set_stamina(value: float):
	stamina_value = clamp(value, 0, max_stamina)
	_update_stamina()
