extends Area2D

signal player_died

@export var death_delay: float = 0.5

var is_triggered: bool = false
var death_screen_scene: PackedScene = preload("res://DeathScreen.tscn")

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if is_triggered:
		return
	if body.is_in_group("player"):
		print("игрок вошёл в DeathZone!")
		is_triggered = true
		
		if body.has_method("die"):
			print("вызываю die() у игрока")
			body.die()
			print("жду 0.5 секунды...")
			await get_tree().create_timer(0.5).timeout
			print("показываю экран смерти")
			_show_death_screen()
		else:
			print("у игрока нет метода die()")
			_show_death_screen()

func _show_death_screen():
	print("_show_death_screen() вызван")
	var death_screen = get_tree().current_scene.get_node_or_null("DeathScreen")
	print("поиск DeathScreen в сцене: ", death_screen)
	
	if death_screen and death_screen.has_method("show_death"):
		print("DeathScreen найден, вызываю show_death()")
		death_screen.show_death()
		print("show_death() вызван")
	else:
		print("DeathScreen НЕ НАЙДЕН, создаю новый")
		var new_death_screen = death_screen_scene.instantiate()
		print("создан экземпляр DeathScreen")
		get_tree().current_scene.add_child(new_death_screen)
		print("добавлен в сцену")
		new_death_screen.show_death()
		print("show_death() вызван у нового экрана")

func reset():
	is_triggered = false
