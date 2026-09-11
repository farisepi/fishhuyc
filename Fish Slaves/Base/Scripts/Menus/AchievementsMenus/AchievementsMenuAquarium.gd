extends Control

@onready var back_btn: Button = $BackButton
@onready var reset_btn: Button = $ResetButton
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var progress_label: Label = $ProgressLabel

@onready var coffee_achievement: Control = $AchievementsScroll/AchievementsList/CoffeeAchievement
@onready var coffee_icon: TextureRect = $AchievementsScroll/AchievementsList/CoffeeAchievement/Icon
@onready var coffee_check: TextureRect = $AchievementsScroll/AchievementsList/CoffeeAchievement/Check
@onready var coffee_name: Label = $AchievementsScroll/AchievementsList/CoffeeAchievement/NameLabel
@onready var coffee_desc: Label = $AchievementsScroll/AchievementsList/CoffeeAchievement/DescLabel

@onready var flashback_achievement: Control = $AchievementsScroll/AchievementsList/FlashbackAchievement
@onready var flashback_icon: TextureRect = $AchievementsScroll/AchievementsList/FlashbackAchievement/Icon
@onready var flashback_check: TextureRect = $AchievementsScroll/AchievementsList/FlashbackAchievement/Check
@onready var flashback_name: Label = $AchievementsScroll/AchievementsList/FlashbackAchievement/NameLabel
@onready var flashback_desc: Label = $AchievementsScroll/AchievementsList/FlashbackAchievement/DescLabel

@onready var pop_star_achievement: Control = $AchievementsScroll/AchievementsList/PopStarAchievement
@onready var pop_star_icon: TextureRect = $AchievementsScroll/AchievementsList/PopStarAchievement/Icon
@onready var pop_star_check: TextureRect = $AchievementsScroll/AchievementsList/PopStarAchievement/Check
@onready var pop_star_name: Label = $AchievementsScroll/AchievementsList/PopStarAchievement/NameLabel
@onready var pop_star_desc: Label = $AchievementsScroll/AchievementsList/PopStarAchievement/DescLabel
@onready var pop_star_progress: Label = $AchievementsScroll/AchievementsList/PopStarAchievement/ProgressLabel

@onready var rebel_achievement: Control = $AchievementsScroll/AchievementsList/RebelAchievement
@onready var rebel_icon: TextureRect = $AchievementsScroll/AchievementsList/RebelAchievement/Icon
@onready var rebel_check: TextureRect = $AchievementsScroll/AchievementsList/RebelAchievement/Check
@onready var rebel_name: Label = $AchievementsScroll/AchievementsList/RebelAchievement/NameLabel
@onready var rebel_desc: Label = $AchievementsScroll/AchievementsList/RebelAchievement/DescLabel
@onready var rebel_progress: Label = $AchievementsScroll/AchievementsList/RebelAchievement/ProgressLabel

@onready var acrobat_achievement: Control = $AchievementsScroll/AchievementsList/AcrobatAchievement
@onready var acrobat_icon: TextureRect = $AchievementsScroll/AchievementsList/AcrobatAchievement/Icon
@onready var acrobat_check: TextureRect = $AchievementsScroll/AchievementsList/AcrobatAchievement/Check
@onready var acrobat_name: Label = $AchievementsScroll/AchievementsList/AcrobatAchievement/NameLabel
@onready var acrobat_desc: Label = $AchievementsScroll/AchievementsList/AcrobatAchievement/DescLabel

var total_achievements: int = 5
var unlocked_count: int = 0

var bubble_scene: PackedScene = preload("res://Fish Slaves/Base/Scenes/Overlay/Effects/Bubble.tscn")

func _ready() -> void:
	Fade.fade_in()
	GlobalMusic.play_menu_music()
	
	ButtonEffects.setup(back_btn)
	ButtonEffects.setup(reset_btn)
	
	if not reset_btn.pressed.is_connected(_on_reset_pressed):
		reset_btn.pressed.connect(_on_reset_pressed)
	if not back_btn.pressed.is_connected(_on_back_button_pressed):
		back_btn.pressed.connect(_on_back_button_pressed)
	
	_setup_progress_bar()
	update_achievements()
	
	call_deferred("_start_background_bubbles")

func _setup_progress_bar() -> void:
	if progress_bar:
		progress_bar.max_value = total_achievements
		progress_bar.value = 0
	if progress_label:
		progress_label.text = "0/" + str(total_achievements)

func update_achievements() -> void:
	unlocked_count = 0
	
	# COFFEE
	if Achievements.coffee_unlocked:
		unlocked_count += 1
		_set_achievement_bright(coffee_achievement, coffee_icon, coffee_check, coffee_name)
		coffee_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	else:
		_set_achievement_gray(coffee_achievement, coffee_icon, coffee_check, coffee_name)
		coffee_desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	
	# FLASHBACK
	if Achievements.flashback_unlocked:
		unlocked_count += 1
		_set_achievement_bright(flashback_achievement, flashback_icon, flashback_check, flashback_name)
		flashback_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	else:
		_set_achievement_gray(flashback_achievement, flashback_icon, flashback_check, flashback_name)
		flashback_desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	
	# POP STAR
	if Achievements.pop_star_unlocked:
		unlocked_count += 1
		_set_achievement_bright(pop_star_achievement, pop_star_icon, pop_star_check, pop_star_name)
		pop_star_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		if pop_star_progress:
			pop_star_progress.text = "100/100"
			pop_star_progress.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	else:
		_set_achievement_gray(pop_star_achievement, pop_star_icon, pop_star_check, pop_star_name)
		pop_star_desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		if pop_star_progress:
			var popped = min(Global.bubbles_popped, 100)
			pop_star_progress.text = str(popped) + "/100"
			pop_star_progress.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	
	# REBEL
	if Achievements.rebel_unlocked:
		unlocked_count += 1
		_set_achievement_bright(rebel_achievement, rebel_icon, rebel_check, rebel_name)
		rebel_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		if rebel_progress:
			rebel_progress.text = "50/50"
			rebel_progress.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	else:
		_set_achievement_gray(rebel_achievement, rebel_icon, rebel_check, rebel_name)
		rebel_desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		if rebel_progress:
			var thrown = min(Global.boxes_thrown, 50)
			rebel_progress.text = str(thrown) + "/50"
			rebel_progress.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	
	# ACROBAT
	if Achievements.acrobat_unlocked:
		unlocked_count += 1
		_set_achievement_bright(acrobat_achievement, acrobat_icon, acrobat_check, acrobat_name)
		acrobat_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	else:
		_set_achievement_gray(acrobat_achievement, acrobat_icon, acrobat_check, acrobat_name)
		acrobat_desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	
	if progress_bar:
		progress_bar.value = unlocked_count
	if progress_label:
		progress_label.text = str(unlocked_count) + "/" + str(total_achievements)

func _set_achievement_bright(ach: Control, icon: TextureRect, check: TextureRect, name_label: Label) -> void:
	if ach: ach.modulate = Color.WHITE
	if icon: icon.modulate = Color.WHITE
	if check: check.visible = true
	if name_label: name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))

func _set_achievement_gray(ach: Control, icon: TextureRect, check: TextureRect, name_label: Label) -> void:
	if ach: ach.modulate = Color(0.4, 0.4, 0.4, 1.0)
	if icon: icon.modulate = Color(0.4, 0.4, 0.4, 1.0)
	if check: check.visible = false
	if name_label: name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

func _on_reset_pressed() -> void:
	if not Achievements.coffee_unlocked and not Achievements.flashback_unlocked \
		and not Achievements.pop_star_unlocked and not Achievements.rebel_unlocked \
		and not Achievements.acrobat_unlocked:
		return
	
	var menu = AcceptDialog.new()
	menu.title = "Сброс достижений"
	menu.dialog_text = "Весь прогресс достижений будет сброшен. Восстановить нельзя. Придётся начинать сначала."
	menu.add_button("Да", true, "yes")
	menu.add_cancel_button("Нет")
	var ok = menu.get_ok_button()
	if ok: ok.visible = false
	
	for child in menu.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(100, 40)
	
	menu.custom_action.connect(func(action):
		if action == "yes":
			Achievements.reset_all()
			Global.bubbles_popped = 0
			Global.boxes_thrown = 0
			update_achievements()
		menu.hide()
		menu.queue_free()
	)
	
	add_child(menu)
	menu.popup_centered()

func _on_back_button_pressed() -> void:
	Fade.fade_out()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://Fish Slaves/Base/Scenes/Menus/MainMenus/MainMenuAquarium.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()

# ==================== ФОНОВЫЕ ПУЗЫРИ (БЕЗ КЛИКА) ====================

func _start_background_bubbles() -> void:
	for i in range(randi_range(3, 6)):
		_make_menu_bubble()
	_spawn_next_bubble()

func _spawn_next_bubble() -> void:
	if not bubble_scene:
		return
	if not is_inside_tree():
		return
	var timer = get_tree().create_timer(randf_range(0.15, 0.35))
	timer.timeout.connect(_on_bubble_spawn_timer)

func _on_bubble_spawn_timer() -> void:
	if not is_inside_tree():
		return
	for i in range(randi_range(1, 2)):
		_make_menu_bubble()
	_spawn_next_bubble()

func _make_menu_bubble() -> void:
	if not bubble_scene:
		return
	var viewport = get_viewport()
	if not viewport:
		return
	var viewport_size = viewport.get_visible_rect().size
	var bubble = bubble_scene.instantiate()
	add_child(bubble)
	bubble.z_index = -10
	bubble.global_position = Vector2(randf_range(0, viewport_size.x), randf_range(0, viewport_size.y))
	bubble.scale = Vector2.ONE * randf_range(0.5, 1.4)
	bubble.speed = randf_range(10.0, 25.0)
	bubble.clickable = false
	bubble.modulate.a = 0.0
	var alpha_tween = create_tween()
	alpha_tween.tween_property(bubble, "modulate:a", randf_range(0.01, 0.75), 1.0)
	bubble.set_direction(Vector2(randf_range(-0.3, 0.3), randf_range(-1.0, -0.2)))
	bubble.start_life(randf_range(6.0, 15.0))
