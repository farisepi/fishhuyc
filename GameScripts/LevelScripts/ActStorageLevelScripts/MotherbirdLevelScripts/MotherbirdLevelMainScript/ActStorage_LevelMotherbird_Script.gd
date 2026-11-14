extends StorageRoom

var _done: bool = false

func room_ready(_first: bool) -> void:
	var l = Label.new()
	l.text = tr("МАТЬ-ПТИЦА") + "\n" + tr("финальный босс — в разработке")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(360, 60)
	l.position = Vector2(room_rect.get_center().x - 180.0, GROUND_Y - 200.0)
	l.z_index = -5
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color(0.9, 0.5, 0.45, 0.7))
	add_child(l)
	var a = Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 1
	a.position = Vector2(room_rect.get_center().x + 120.0, GROUND_Y - 60.0)
	var cs = CollisionShape2D.new()
	var rs = RectangleShape2D.new()
	rs.size = Vector2(40, 200)
	cs.shape = rs
	a.add_child(cs)
	add_child(a)
	a.body_entered.connect(_finish)

func _finish(b: Node) -> void:
	if b != player or _done:
		return
	_done = true
	lock_player(true)
	travelling = true
	show_title(tr("ПРОДОЛЖЕНИЕ СЛЕДУЕТ"), tr("склад ещё не закончен"), 3.0)
	await get_tree().create_timer(4.2).timeout
	if not is_inside_tree():
		return
	get_tree().paused = false
	Global.goto_scene(Global.SCENE_MAIN_MENU_FACTORY)
