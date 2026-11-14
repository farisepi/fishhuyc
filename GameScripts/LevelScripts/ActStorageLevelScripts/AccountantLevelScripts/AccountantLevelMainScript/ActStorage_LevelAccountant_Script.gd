extends StorageRoom

const BOSS_HP := 30
const BOSS_SCALE := 1.7

var _card: Node2D = null

func room_ready(_first: bool) -> void:
	if not StorageMap.flag("accountant_beaten"):
		_start_boss()
	elif not StorageMap.flag("keycard"):
		var mk = get_node_or_null("SpawnPoints/Boss")
		_drop_card(mk.global_position if mk else room_rect.get_center())

func _start_boss() -> void:
	var mk = get_node_or_null("SpawnPoints/Boss")
	if mk == null:
		return
	show_title(tr("ГОРИЛЛА-БУХГАЛТЕР"), tr("босс — заглушка"), 1.8)
	var boss = spawn_enemy_at(mk)
	if boss == null:
		return
	if "max_hp" in boss:
		boss.max_hp = BOSS_HP
	if "hp" in boss:
		boss.hp = BOSS_HP
	boss.scale = Vector2.ONE * BOSS_SCALE
	boss.modulate = Color(0.72, 0.68, 0.8)
	if "aggro_range" in boss:
		boss.aggro_range = 2000.0
	if "deaggro_range" in boss:
		boss.deaggro_range = 4000.0
	if boss.has_signal("died"):
		boss.died.connect(func(_c): _on_boss_died(boss))

func _on_boss_died(boss: Node2D) -> void:
	Global.storage_state["accountant_beaten"] = true
	Global.storage_state["accountant_open"] = true
	Global.save_factory_state()
	for d in get_tree().get_nodes_in_group("storage_doors"):
		d.refresh()
	var p = boss.global_position if is_instance_valid(boss) else room_rect.get_center()
	_drop_card(p)

func _drop_card(p: Vector2) -> void:
	if _card:
		return
	_card = Node2D.new()
	var c = ColorRect.new()
	c.color = Color(0.85, 0.95, 0.9)
	c.size = Vector2(16, 11)
	c.position = Vector2(-8, -6)
	_card.add_child(c)
	var strip = ColorRect.new()
	strip.color = Color(0.2, 0.75, 0.4)
	strip.size = Vector2(16, 3)
	strip.position = Vector2(0, 2)
	c.add_child(strip)
	var glow = PointLight2D.new()
	glow.texture = preload("res://GameAssets/Sprites/UserInterfaceSprites/LightTextures/Light_Option10_Texture.png")
	glow.texture_scale = 0.4
	glow.color = Color(0.4, 1.0, 0.6)
	glow.energy = 0.8
	_card.add_child(glow)
	_card.z_index = 10
	add_child(_card)
	_card.global_position = Vector2(p.x, GROUND_Y - 24.0)
	var tw = _card.create_tween().set_loops()
	tw.tween_property(_card, "position:y", _card.position.y - 6.0, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_card, "position:y", _card.position.y, 0.6).set_trans(Tween.TRANS_SINE)
	var a = Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 1
	var cs = CollisionShape2D.new()
	var rs = CircleShape2D.new()
	rs.radius = 30.0
	cs.shape = rs
	a.add_child(cs)
	_card.add_child(a)
	a.body_entered.connect(_on_card_touch)

func _on_card_touch(b: Node) -> void:
	if b != player or StorageMap.flag("keycard"):
		return
	StorageMap.set_flag("keycard")
	if _card:
		_card.queue_free()
		_card = null
	show_title(tr("КЛЮЧ-КАРТА ПОЛУЧЕНА"), tr("Дверь бухгалтерии теперь открыта"), 1.6)
	for d in get_tree().get_nodes_in_group("storage_doors"):
		d.refresh()
