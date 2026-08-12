extends Area2D

@export var required_presses: int = 10
@export var key_button: TextureRect = null
@export var progress_ring: TextureProgressBar = null
@export var prompt_label: Label = null

var press_count: int = 0
var is_active: bool = false
var is_interacting: bool = false
var player: Node2D = null
var press_cooldown: float = 0.0

func _ready():
	print("🔍 TightPassage: _ready() ВЫЗВАН!")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Ищем UI в корне
	var canvas_layer = get_parent().get_node_or_null("CanvasLayer")
	if canvas_layer:
		var ui = canvas_layer.get_node_or_null("TightPassageUI")
		if ui:
			key_button = ui.get_node_or_null("KeyButton")
			progress_ring = ui.get_node_or_null("ProgressRing")
			prompt_label = ui.get_node_or_null("PromptLabel")
			
			print("🔍 key_button = ", key_button)
			print("🔍 progress_ring = ", progress_ring)
			print("🔍 prompt_label = ", prompt_label)
	
	if progress_ring:
		progress_ring.max_value = required_presses
		progress_ring.value = 0
		progress_ring.visible = false
	
	if key_button:
		key_button.visible = false
	
	if prompt_label:
		prompt_label.visible = false
		prompt_label.text = "Нажми E чтобы пролезть!"

func _on_body_entered(body: Node2D):
	if body.name == "Mecha_Fish":
		print("🔔 ИГРОК ЗАШЁЛ В ЗОНУ!")
		player = body
		is_active = true
		
		# Показываем подсказку "Нажми E"
		if prompt_label:
			prompt_label.visible = true
			prompt_label.text = "Нажми E чтобы пролезть!"

func _on_body_exited(body: Node2D):
	if body == player:
		print("🚪 ИГРОК ВЫШЕЛ ИЗ ЗОНЫ!")
		is_active = false
		is_interacting = false
		player = null
		
		if progress_ring:
			progress_ring.visible = false
		
		if key_button:
			key_button.visible = false
		
		if prompt_label:
			prompt_label.visible = false

func _input(event: InputEvent):
	if not is_active or not player:
		return
	
	# Нажатие E — начать мини-игру
	if event.is_action_pressed("interact") and not is_interacting:
		print("🔴 НАЖАТА E! НАЧИНАЮ МИНИ-ИГРУ!")
		is_interacting = true
		press_count = 0
		
		if progress_ring:
			progress_ring.visible = true
			progress_ring.value = 0
		
		if key_button:
			key_button.visible = true
		
		if prompt_label:
			prompt_label.text = "Нажимай D!"

func _process(delta):
	if not is_interacting or not player:
		return
	
	if press_cooldown > 0:
		press_cooldown -= delta
	
	if Input.is_action_just_pressed("ui_right") and press_cooldown <= 0:
		press_count += 1
		press_cooldown = 0.15
		
		if progress_ring:
			progress_ring.value = press_count
		
		if key_button:
			key_button.modulate = Color(0.5, 0.8, 1.0, 1)
			key_button.scale = Vector2(0.95, 0.95)
			await get_tree().create_timer(0.1).timeout
			key_button.modulate = Color(1, 1, 1, 1)
			key_button.scale = Vector2(1.0, 1.0)
		
		if press_count >= required_presses:
			_complete_passage()

func _complete_passage():
	print("✅ ПРОХОД ОТКРЫТ!")
	is_interacting = false
	is_active = false
	
	if progress_ring:
		progress_ring.visible = false
	
	if key_button:
		key_button.modulate = Color(0, 1, 0, 1)
		await get_tree().create_timer(0.5).timeout
		key_button.visible = false
	
	if prompt_label:
		prompt_label.text = "✅ ПРОХОД ОТКРЫТ!"
		await get_tree().create_timer(1.0).timeout
		prompt_label.visible = false
	
	# Отключаем триггер
	monitoring = false
	monitorable = false
	visible = false
	queue_free()
