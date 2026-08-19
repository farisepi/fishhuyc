extends Area2D

@export var required_presses: int = 10
@export var move_distance: float = 10.0
@export var key_button: TextureRect = null
@export var progress_ring: TextureProgressBar = null

var press_count: int = 0
var is_active: bool = false
var player: CharacterBody2D = null
var press_cooldown: float = 0.0

func _ready():
	print("🔍 TightPassage: _ready()")
	
	var canvas_layer = get_parent().get_node_or_null("CanvasLayer")
	if canvas_layer:
		print("✅ CanvasLayer найден!")
		var ui = canvas_layer.get_node_or_null("TightPassageUI")
		if ui:
			print("✅ TightPassageUI найден!")
			key_button = ui.get_node_or_null("KeyButton")
			progress_ring = ui.get_node_or_null("ProgressRing")
			print("🔍 key_button = ", key_button)
			print("🔍 progress_ring = ", progress_ring)
		else:
			print("❌ TightPassageUI НЕ НАЙДЕН!")
	else:
		print("❌ CanvasLayer НЕ НАЙДЕН!")
	
	if progress_ring:
		progress_ring.max_value = required_presses
		progress_ring.value = 0
		progress_ring.visible = false
		print("✅ ProgressRing настроен!")
	
	if key_button:
		key_button.visible = false
		print("✅ KeyButton настроен!")

func activate(player_node: CharacterBody2D):
	if is_active:
		return
	
	print("🔴 АКТИВАЦИЯ УЗКОГО ПРОХОДА!")
	player = player_node
	is_active = true
	press_count = 0
	
	if player.has_method("set_movement_blocked"):
		player.set_movement_blocked(true)
	
	if progress_ring:
		progress_ring.visible = true
		progress_ring.value = 0
	
	if key_button:
		key_button.visible = true
		key_button.modulate = Color(1, 1, 1, 1)
		key_button.scale = Vector2(1.0, 1.0)

func _process(delta):
	if not is_active or not player:
		return
	
	if press_cooldown > 0:
		press_cooldown -= delta
	
	if Input.is_action_just_pressed("ui_right") and press_cooldown <= 0:
		press_count += 1
		press_cooldown = 0.15
		
		# ПЛАВНЫЙ СДВИГ ИГРОКА
		var target_x = player.global_position.x + move_distance
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(player, "global_position:x", target_x, 0.15)
		
		# ОБНОВЛЯЕМ ШКАЛУ
		if progress_ring:
			progress_ring.value = press_count
		
		# АНИМАЦИЯ КНОПКИ
		if key_button:
			key_button.modulate = Color(0.5, 0.8, 1.0, 1)
			key_button.scale = Vector2(0.95, 0.95)
			await get_tree().create_timer(0.1).timeout
			key_button.modulate = Color(1, 1, 1, 1)
			key_button.scale = Vector2(1.0, 1.0)
		
		# ПРОВЕРКА ЗАВЕРШЕНИЯ
		if press_count >= required_presses:
			_complete_passage()

func _complete_passage():
	print("✅ ПРОХОД ПРОЙДЕН!")
	is_active = false
	
	if player and player.has_method("set_movement_blocked"):
		player.set_movement_blocked(false)
	
	if progress_ring:
		progress_ring.visible = false
	
	if key_button:
		key_button.visible = false
	
	queue_free()
