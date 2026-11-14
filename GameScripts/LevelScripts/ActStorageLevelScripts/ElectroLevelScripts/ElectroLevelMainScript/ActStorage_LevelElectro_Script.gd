extends StorageRoom

var dark: StorageDark = null
var _panel: Area2D = null
var _leds: Array = []
var _busy: bool = false
var _sparks: CPUParticles2D = null

func _state() -> int:
	return int(Global.storage_state.get("electro", 0))

func _set_state(v: int) -> void:
	Global.storage_state["electro"] = v
	Global.save_factory_state()

func room_ready(_first: bool) -> void:
	dark = StorageDark.new()
	dark.room = self
	add_child(dark)
	var mk = get_node_or_null("PanelPos")
	var pos: Vector2 = mk.global_position if mk else Vector2(room_rect.end.x - 120.0, GROUND_Y)
	_build_panel(pos)
	_panel = make_interact(pos, Vector2(90, 110), "", _use_panel)
	_refresh_prompt()
	if _state() == 1:
		dark.set_dark(true, 0.0)
		_spawn_event(false)

func _build_panel(pos: Vector2) -> void:
	var box = ColorRect.new()
	box.color = Color(0.22, 0.24, 0.26)
	box.size = Vector2(54, 78)
	box.position = pos + Vector2(-27, -128)
	box.z_index = -3
	add_child(box)
	var door = ColorRect.new()
	door.color = Color(0.3, 0.32, 0.34)
	door.size = Vector2(46, 70)
	door.position = Vector2(4, 4)
	box.add_child(door)
	var sign = ColorRect.new()
	sign.color = Color(0.95, 0.78, 0.15)
	sign.size = Vector2(14, 12)
	sign.position = Vector2(16, 8)
	door.add_child(sign)
	for i in range(4):
		var led = ColorRect.new()
		led.size = Vector2(4, 4)
		led.position = Vector2(8 + i * 9, 56)
		led.color = Color(0.3, 1.0, 0.4)
		door.add_child(led)
		_leds.append(led)
	var cable = ColorRect.new()
	cable.color = Color(0.06, 0.06, 0.07)
	cable.size = Vector2(6, 300)
	cable.position = pos + Vector2(-3, -428)
	cable.z_index = -4
	add_child(cable)
	_sparks = CPUParticles2D.new()
	_sparks.position = pos + Vector2(0, -100)
	_sparks.emitting = false
	_sparks.one_shot = true
	_sparks.amount = 26
	_sparks.lifetime = 0.5
	_sparks.explosiveness = 0.9
	_sparks.direction = Vector2(0, -1)
	_sparks.spread = 80.0
	_sparks.initial_velocity_min = 80.0
	_sparks.initial_velocity_max = 200.0
	_sparks.gravity = Vector2(0, 500)
	_sparks.scale_amount_min = 2.0
	_sparks.scale_amount_max = 3.0
	_sparks.color = Color(1.0, 0.9, 0.5)
	_sparks.z_index = 30
	add_child(_sparks)
	_update_leds()

func _update_leds() -> void:
	var st = _state()
	for i in range(_leds.size()):
		var c = Color(0.3, 1.0, 0.4)
		if st == 1:
			c = Color(1.0, 0.3, 0.25) if i % 2 == 0 else Color(0.2, 0.08, 0.06)
		elif st == 2:
			c = Color(0.3, 1.0, 0.4) if i == 0 else Color(1.0, 0.3, 0.25)
		_leds[i].color = c

func _refresh_prompt() -> void:
	match _state():
		0:
			set_prompt(_panel, tr("Отключить ток на двери"))
		1:
			set_prompt(_panel, tr("Ударить по щитку"))
		_:
			set_prompt(_panel, "")

func _process(_delta: float) -> void:
	super._process(_delta)
	if _state() == 1 and _leds.size() > 0:
		var on = int(Time.get_ticks_msec() / 300.0) % 2 == 0
		for i in range(_leds.size()):
			_leds[i].visible = on if i % 2 == 0 else not on

func _hit_fx() -> void:
	if _sparks:
		_sparks.restart()
		_sparks.emitting = true
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.45)
	if player and player.get("sprite"):
		var s = player.sprite
		if s.sprite_frames and s.sprite_frames.has_animation("AttackRight"):
			s.play("AttackRight" if not s.flip_h else "AttackLeft")

func _use_panel() -> void:
	if _busy:
		return
	_busy = true
	match _state():
		0:
			await _lights_out()
		1:
			await _lights_back()
	_busy = false

func _lights_out() -> void:
	lock_player(true)
	_hit_fx()
	await get_tree().create_timer(0.35, false).timeout
	for i in range(3):
		for n in get_tree().get_nodes_in_group("storage_lights"):
			n.visible = false
		await get_tree().create_timer(0.08, false).timeout
		for n in get_tree().get_nodes_in_group("storage_lights"):
			n.visible = true
		await get_tree().create_timer(0.12 + i * 0.06, false).timeout
	_set_state(1)
	dark.set_dark(true, 0.15)
	_update_leds()
	_refresh_prompt()
	if player:
		float_text(player.global_position + Vector2(0, -70), tr("...не тот рубильник."), Color(0.9, 0.9, 1.0), 2.2)
	await get_tree().create_timer(1.0, false).timeout
	lock_player(false)
	await get_tree().create_timer(0.8, false).timeout
	_spawn_event(true)

func _spawn_event(staggered: bool) -> void:
	var sp = get_node_or_null("SpawnPoints")
	if sp == null:
		return
	for point in sp.get_children():
		if not point is Marker2D or not bool(point.get_meta("event", false)):
			continue
		if StorageMap.is_dead(room_id, point.name):
			continue
		spawn_enemy_at(point)
		if staggered:
			await get_tree().create_timer(0.9, false).timeout

func _lights_back() -> void:
	lock_player(true)
	_hit_fx()
	await get_tree().create_timer(0.4, false).timeout
	_set_state(2)
	StorageMap.set_flag("power_cut")
	dark.set_dark(false, 0.5)
	_update_leds()
	_refresh_prompt()
	var mk = get_node_or_null("PanelPos")
	var pos: Vector2 = mk.global_position if mk else player.global_position
	float_text(pos + Vector2(0, -150), tr("Ток с двери снят."), Color(0.6, 1.0, 0.6), 2.4)
	await get_tree().create_timer(0.6, false).timeout
	lock_player(false)
