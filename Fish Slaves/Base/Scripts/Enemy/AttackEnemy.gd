<<<<<<< HEAD
	for i in range(10):
		var chip = ColorRect.new()
		chip.color = Color(0.08, 0.08, 0.1)
		chip.size = Vector2(randf_range(6, 20), randf_range(6, 20))
		chip.position = Vector2(randf_range(60, view_size.x - 60), randf_range(-140, -40))
		debris.add_child(chip)
		
		var ct = create_tween()
		ct.tween_property(chip, "position:y", view_size.y + 40, randf_range(0.4, 0.8))
		ct.tween_callback(chip.queue_free)
	
	var tween = create_tween()
	tween.tween_property(debris, "position:y", view_size.y + 200, 0.6).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		var overlay = ColorRect.new()
		overlay.color = Color.BLACK
		overlay.size = view_size
		overlay.position = Vector2.ZERO
		overlay.z_index = 201
		add_child(overlay)
	)
=======
extends CharacterBody2D

@export var speed: float = 140.0
@export var gravity: float = 980.0
@export var attack_range: float = 70.0
@export var windup_time: float = 1.0
@export var lunge_distance: float = 55.0
@export var knockback_distance: float = 80.0
@export var knockback_duration: float = 0.25
@export var block_duration: float = 1.5
@export var cooldown_time: float = 1.8

enum State { IDLE, CHASING, WINDUP, LUNGE, KNOCKBACK, BLOCK, COOLDOWN }
var state: State = State.IDLE
var player: CharacterBody2D = null
var is_aggro: bool = false
var windup_timer: float = 0.0
var cooldown_timer: float = 0.0
var block_timer: float = 0.0
var facing_dir: int = 1
var is_vaulting: bool = false

@onready var color_rect: ColorRect = $ColorRect
@onready var detection_area: Area2D = $DetectionArea
@onready var hit_area: Area2D = $HitArea

const COLOR_NORMAL: Color = Color(0.2, 0.6, 0.2, 1)
const COLOR_WINDUP: Color = Color(0.8, 0.2, 1.0, 1)
const COLOR_ATTACK: Color = Color(1, 0.2, 0.2, 1)
const COLOR_BLOCK: Color = Color(0.2, 0.5, 1.0, 1)
const COLOR_COOLDOWN: Color = Color(0.4, 0.4, 0.4, 1)

func _ready():
	add_to_group("enemies")
	collision_mask = 1
	collision_layer = 2
	color_rect.color = COLOR_NORMAL
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	hit_area.body_entered.connect(_on_hit_area_body_entered)

func _on_detection_area_body_entered(body: Node2D):
	if body.is_in_group("player") and not is_aggro:
		is_aggro = true
		player = body

func _on_hit_area_body_entered(body: Node2D):
	if not body.is_in_group("player"):
		return
	if state != State.LUNGE:
		return

	if body.has_method("take_damage"):
		body.take_damage(1)

	state = State.KNOCKBACK
	_knockback()

func _physics_process(delta):
	if not is_aggro:
		velocity.x = 0
		move_and_slide()
		return

	if not player:
		is_aggro = false
		state = State.IDLE
		return

	var dir_to_player = sign(player.global_position.x - global_position.x)
	if dir_to_player != 0:
		facing_dir = dir_to_player
		if color_rect:
			color_rect.scale.x = facing_dir

	var target_scale_x = 1.0 if facing_dir > 0 else -1.0
	scale.x = target_scale_x

	var dist = global_position.distance_to(player.global_position)

	match state:
		State.IDLE:
			velocity.x = 0
			if dist < 350:
				state = State.CHASING

		State.CHASING:
			velocity.x = facing_dir * speed
			move_and_slide()
			if dist < attack_range:
				state = State.WINDUP
				windup_timer = 0.0
				color_rect.color = COLOR_WINDUP

		State.WINDUP:
			velocity.x = facing_dir * speed * 0.2
			move_and_slide()
			windup_timer += delta
			if windup_timer >= windup_time:
				state = State.LUNGE
				color_rect.color = COLOR_ATTACK
				_lunge()

		State.LUNGE:
			velocity.x = 0

		State.KNOCKBACK:
			velocity.x = 0

		State.BLOCK:
			velocity.x = 0
			move_and_slide()
			block_timer -= delta
			if block_timer <= 0:
				state = State.COOLDOWN
				cooldown_timer = cooldown_time
				color_rect.color = COLOR_COOLDOWN

		State.COOLDOWN:
			velocity.x = 0
			move_and_slide()
			cooldown_timer -= delta
			if cooldown_timer <= 0:
				state = State.CHASING
				color_rect.color = COLOR_NORMAL

func _lunge():
	var target_x = global_position.x + facing_dir * lunge_distance
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "global_position:x", target_x, 0.1)
	await tween.finished

	if state == State.LUNGE:
		state = State.KNOCKBACK
		_knockback()
>>>>>>> 919ac15cbef60f930e0e71229fcd33f3dfa0dbfd

func _spawn_falling_blackout() -> void:
	var black_rect = ColorRect.new()
	black_rect.color = Color.BLACK
	black_rect.size = Vector2(get_viewport().get_visible_rect().size.x, 200)
	black_rect.position = Vector2(0, -200)
	black_rect.z_index = 200
	add_child(black_rect)
	
	var tween = create_tween()
	tween.tween_property(black_rect, "position:y", get_viewport().get_visible_rect().size.y, 0.5)
	await tween.finished
	black_rect.queue_free()

func _wait_for_typing_done() -> void:
	while waiting_for_next or typing_index < (part1 + mate + part2).length():
		await get_tree().create_timer(0.05).timeout
		if not cutscene_active:
			return
	await get_tree().create_timer(0.8).timeout

func _show_blackout_title():
	var blackout = CanvasLayer.new()
	blackout.layer = 100
	
	var rect = ColorRect.new()
	rect.color = Color.BLACK
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blackout.add_child(rect)
	
	var label = Label.new()
	label.text = "Пару дней назад..."
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	label.add_theme_font_size_override("font_size", 48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.modulate.a = 0.0
	blackout.add_child(label)
	
	add_child(blackout)
	
	var fade_tween = create_tween()
	fade_tween.tween_property(rect, "modulate:a", 1.0, 0.5)
	fade_tween.finished.connect(_on_fade_finished.bind(label, blackout))
	
func _on_fade_finished(label: Label, blackout: CanvasLayer):
	Achievements.unlock_flashback()
	_show_achievement_flashback("Флешбек")
	UISounds.play_achievement()
	
	var title_tween = create_tween()
	title_tween.tween_property(label, "modulate:a", 1.0, 1.0)
	title_tween.finished.connect(_on_title_finished.bind(label, blackout))

func _on_title_finished(label: Label, blackout: CanvasLayer):
	var hide_title = create_tween()
	hide_title.tween_property(label, "modulate:a", 0.0, 0.5)
	hide_title.finished.connect(_on_hide_finished.bind(blackout))

func _on_hide_finished(_blackout: CanvasLayer):
	_save_progress()
	_auto_save_to_current_slot()
	
	cutscene_active = false
	Global.came_from = Global.MenuSource.MAIN_MENU
	Global.prologue1_completed = true
	
	if has_node("/root/Fade"):
		Fade.fade_out()
	else:
		var temp_fade = ColorRect.new()
		temp_fade.color = Color.BLACK
		temp_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
		temp_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		temp_fade.z_index = 1000
		add_child(temp_fade)
		var tween_fade = create_tween()
		tween_fade.tween_property(temp_fade, "modulate:a", 1.0, 0.5)
		tween_fade.finished.connect(_change_to_act2)

func _change_to_act2():
	GlobalMusic.stop_music()
	get_tree().change_scene_to_file("res://Fish Slaves/Base/Scenes/Levels/Act2FactoryLevel.tscn")

func _save_progress():
	if not has_node("/root/Global"):
		return
	
	var save_path = "user://saves/save_" + str(Global.save_slot) + ".cfg"
	
	var config = ConfigFile.new()
	
	config.set_value("save", "scene", "res://Fish Slaves/Base/Scenes/Levels/Act2FactoryLevel.tscn")
	config.set_value("save", "time", Time.get_datetime_string_from_system())
	
	if player:
		config.set_value("save", "player_x", player.global_position.x)
		config.set_value("save", "player_y", player.global_position.y)
	
	config.set_value("save", "chatter_queue", get_chatter_state()["queue"])
	config.set_value("save", "chatter_text", get_chatter_state()["current_text"])
	config.set_value("save", "chatter_index", get_chatter_state()["char_index"])
	
	config.save(save_path)

func _auto_save_to_current_slot():
	Global.player_position = player.global_position
	Global.chatter_queue_state = get_chatter_state()["queue"]
	Global.chatter_current_text = get_chatter_state()["current_text"]
	Global.chatter_char_index = get_chatter_state()["char_index"]
	
	var config = ConfigFile.new()
	var save_path = "user://saves/save_" + str(Global.save_slot) + ".cfg"
	
	if config.load(save_path) != OK:
		return
	
	config.set_value("save", "scene", "res://Fish Slaves/Base/Scenes/Levels/Act2FactoryLevel.tscn")
	config.set_value("save", "time", Time.get_datetime_string_from_system())
	config.set_value("save", "player_x", player.global_position.x)
	config.set_value("save", "player_y", player.global_position.y)
	config.set_value("save", "chatter_queue", Global.chatter_queue_state)
	config.set_value("save", "chatter_text", Global.chatter_current_text)
	config.set_value("save", "chatter_index", Global.chatter_char_index)
	
	config.save(save_path)
	Global.last_save_level = 2

func _show_achievement_flashback(title: String):
	var canvas = CanvasLayer.new()
	canvas.layer = 200
	add_child(canvas)
	
	var ctrl = Control.new()
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ctrl)
	
	var view_size = get_viewport().get_visible_rect().size
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.2, 0.35, 0.85)
	bg.size = Vector2(320, 60)
	bg.position = Vector2(view_size.x, 10)
	ctrl.add_child(bg)
	
	var icon = Label.new()
	icon.text = "★"
	icon.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	icon.add_theme_font_size_override("font_size", 28)
	icon.position = Vector2(view_size.x + 15, 20)
	icon.size = Vector2(40, 40)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ctrl.add_child(icon)
	
	var header = Label.new()
	header.text = "ДОСТИЖЕНИЕ"
	header.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.9))
	header.add_theme_font_size_override("font_size", 18)
	header.position = Vector2(view_size.x + 65, 18)
	ctrl.add_child(header)
	
	var l = Label.new()
	l.text = title
	l.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	l.add_theme_font_size_override("font_size", 36)
	l.position = Vector2(view_size.x + 65, 35)
	ctrl.add_child(l)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(bg, "position:x", view_size.x - 330, 0.4)
	tween.parallel().tween_property(icon, "position:x", view_size.x - 305, 0.4)
	tween.parallel().tween_property(header, "position:x", view_size.x - 255, 0.4)
	tween.parallel().tween_property(l, "position:x", view_size.x - 255, 0.4)
	
	await get_tree().create_timer(3.5).timeout
	
	var tween2 = create_tween()
	tween2.set_ease(Tween.EASE_IN)
	tween2.tween_property(bg, "position:x", view_size.x, 0.3)
	tween2.parallel().tween_property(icon, "position:x", view_size.x + 15, 0.3)
	tween2.parallel().tween_property(header, "position:x", view_size.x + 65, 0.3)
	tween2.parallel().tween_property(l, "position:x", view_size.x + 65, 0.3)
	await tween2.finished
	
	canvas.queue_free()

func _wait_dialog() -> void:
	var tree = get_tree()
	if not tree:
		return
	await tree.create_timer(1.25).timeout

func _toggle_pause() -> void:
	if not pause_menu or not player:
		return
	
	var anim = player.get_node_or_null("AnimatedSprite2D")
	
	if pause_menu.visible:
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		GlobalMusic.restore_volume()
		UISounds.restore_ambience()
		if not cutscene_active:
			player.set_physics_process(true)
			player.set_process(true)
			if anim: anim.play()
			if scientist:
				scientist.set_process(true)
				scientist.play()
			if mechanic:
				mechanic.set_process(true)
				mechanic.play()
		pause_menu.hide_menu()
	else:
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GlobalMusic.lower_volume()
		UISounds.lower_ambience()
		player.set_physics_process(false)
		player.set_process(false)
		if anim: anim.pause()
		if scientist:
			scientist.set_process(false)
			scientist.pause()
		if mechanic:
			mechanic.set_process(false)
			mechanic.pause()
		pause_menu.show_menu()

func _on_dialogue_zone_body_entered(body: Node2D) -> void:
	if body == player and not dialogue_done:
		in_zone = true
		if interact_label:
			interact_label.visible = true
			interact_label.modulate.a = 0.0
			interact_label.scale = Vector2(0.5, 0.5)
			var tween = create_tween()
			tween.set_parallel(true)
			tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.tween_property(interact_label, "modulate:a", 1.0, 0.3)
			tween.tween_property(interact_label, "scale", Vector2.ONE, 0.3)

func _on_dialogue_zone_body_exited(body: Node2D) -> void:
	if body == player:
		in_zone = false
		if interact_label:
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(interact_label, "modulate:a", 0.0, 0.2)
			tween.tween_property(interact_label, "scale", Vector2(0.5, 0.5), 0.2)
			await tween.finished
			interact_label.visible = false

func _show_achievement(title: String):
	var canvas = CanvasLayer.new()
	canvas.layer = 200
	add_child(canvas)
	
	var ctrl = Control.new()
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ctrl)
	
	var view_size = get_viewport().get_visible_rect().size
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.2, 0.35, 0.85)
	bg.size = Vector2(320, 60)
	bg.position = Vector2(view_size.x, 10)
	ctrl.add_child(bg)
	
	var icon = Label.new()
	icon.text = "★"
	icon.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	icon.add_theme_font_size_override("font_size", 28)
	icon.position = Vector2(view_size.x + 15, 20)
	icon.size = Vector2(40, 40)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ctrl.add_child(icon)
	
	var header = Label.new()
	header.text = "ДОСТИЖЕНИЕ"
	header.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.9))
	header.add_theme_font_size_override("font_size", 18)
	header.position = Vector2(view_size.x + 65, 18)
	ctrl.add_child(header)
	
	var l = Label.new()
	l.text = title
	l.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	l.add_theme_font_size_override("font_size", 36)
	l.position = Vector2(view_size.x + 65, 35)
	ctrl.add_child(l)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(bg, "position:x", view_size.x - 330, 0.4)
	tween.parallel().tween_property(icon, "position:x", view_size.x - 305, 0.4)
	tween.parallel().tween_property(header, "position:x", view_size.x - 255, 0.4)
	tween.parallel().tween_property(l, "position:x", view_size.x - 255, 0.4)
	
	await get_tree().create_timer(3.5).timeout
	
	var tween2 = create_tween()
	tween2.set_ease(Tween.EASE_IN)
	tween2.tween_property(bg, "position:x", view_size.x, 0.3)
	tween2.parallel().tween_property(icon, "position:x", view_size.x + 15, 0.3)
	tween2.parallel().tween_property(header, "position:x", view_size.x + 65, 0.3)
	tween2.parallel().tween_property(l, "position:x", view_size.x + 65, 0.3)
	await tween2.finished
	
	canvas.queue_free()
	
func _spawn_prologue_bubble() -> void:
	if not bubble_scene:
		return
	
	var bubble = bubble_scene.instantiate()
	add_child(bubble)
	
	bubble.can_pop = false
	
	bubble.global_position = Vector2(
		randf_range(0, 1920),
		randf_range(0, 510)
	)
	
	var bubble_scale = randf_range(0.2, 0.8)
	bubble.scale = Vector2.ONE * bubble_scale
	
	bubble.modulate.a = 0.0
	
	bubble.set_direction(
		Vector2(
			randf_range(-0.2, 0.2),
			-1.0
		)
	)
	
	var tween = create_tween()
	tween.tween_property(
		bubble,
		"modulate:a",
		randf_range(0.1, 0.5),
		0.5
	)
	
	bubble.start_life(randf_range(1.0, 20.0))

func _get_player_camera() -> Camera2D:
	if player and player.has_node("PlayerCamera"):
		return player.get_node("PlayerCamera") as Camera2D
	return get_viewport().get_camera_2d()

func _resume_after_pause() -> void:
	if not player:
		return
<<<<<<< HEAD
	
	var anim = player.get_node_or_null("AnimatedSprite2D")
	if anim:
		anim.play()
	
	player.set_physics_process(true)
	player.set_process(true)
	player.can_move = true
	
	if scientist:
		scientist.set_process(true)
		scientist.play()
	
	if mechanic:
		mechanic.set_process(true)
		mechanic.play()
	
	if chatter_active:
		timer.start(typing_speed)
=======
	var dir = -1 if player.global_position.x > global_position.x else 1
	var target_x = global_position.x + dir * knockback_distance
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "global_position:x", target_x, knockback_duration)
	await tween.finished

	if state == State.KNOCKBACK:
		state = State.BLOCK
		block_timer = block_duration
		color_rect.color = COLOR_BLOCK
>>>>>>> 919ac15cbef60f930e0e71229fcd33f3dfa0dbfd
