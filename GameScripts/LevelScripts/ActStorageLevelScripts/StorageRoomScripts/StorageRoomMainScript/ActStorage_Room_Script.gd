extends Node2D
class_name StorageRoom

const DOG_SCENE = preload("res://GameScenes/EntityScenes/EnemyEntityScenes/MechaDogScenes/Enemy_MechaDog_Storage_Scene.tscn")
const MONKEY_SCENE = preload("res://GameScenes/EntityScenes/EnemyEntityScenes/MechaMonkeyScenes/Enemy_MechaMonkey_Storage_Scene.tscn")
const PIGEON_SCENE = preload("res://GameScenes/EntityScenes/EnemyEntityScenes/MechaPigeonScenes/Enemy_MechaPigeon_Storage_Scene.tscn")
const HUD_SCENE = preload("res://GameScenes/UIScenes/ScreenScenes/HUDScenes/ActStorage_ShardHUD_Scene.tscn")
const INVENTORY_SCENE = preload("res://GameScenes/UIScenes/ScreenScenes/HUDScenes/ActStorage_ShardInventory_Scene.tscn")
const TITLE_SCENE = preload("res://GameScenes/UIScenes/ScreenScenes/HUDScenes/ActStorage_TitleCard_Scene.tscn")

const SH_WALL := preload("res://GameShaders/SharedShaders/Shared_IndustrialWall_Shader.gdshader")
const SH_FLOOR := preload("res://GameShaders/SharedShaders/Shared_IndustrialFloor_Shader.gdshader")
const SH_BEAM := preload("res://GameShaders/SharedShaders/Shared_LightBeam_Shader.gdshader")
const SH_POST := preload("res://GameShaders/SharedShaders/Shared_PostProcess_Shader.gdshader")
const TX_LAMP := preload("res://GameAssets/LevelAssets/SharedLevelAssets/Shared_HangingLamp_Texture.png")
const TX_CONE := preload("res://GameAssets/Sprites/UserInterfaceSprites/LightTextures/Light_Option9_Texture.png")

const GROUND_Y := 1000.0

@export var room_id: String = ""
@export var room_rect: Rect2 = Rect2(0, 380, 1200, 620)
@export var ambient: Color = Color(0.5, 0.49, 0.57, 1.0)
@export var dress: bool = true
@export var flash_title: bool = true
@export var stub_name: String = ""

var player: CharacterBody2D = null
var camera: Camera2D = null
var hud_instance: CanvasLayer = null
var inventory_instance: CanvasLayer = null
var pausemenu: CanvasLayer = null
var travelling: bool = false
var _pending_dead: Array = []
var _modulate: CanvasModulate = null
var _interacts: Array = []

func _ready() -> void:
	randomize()
	player = get_tree().get_first_node_in_group("player")
	pausemenu = get_node_or_null("Pausemenu")
	if player:
		camera = player.get_node_or_null("MechaFishCameraFactory")
	UISounds.stop_everything_gameplay()
	GlobalMusic.play_level_music()
	if dress:
		_dress()
	_place_player()
	_setup_camera()
	_spawn_hud()
	_spawn_enemies()
	var ds = get_node_or_null("DeathScreen")
	if ds and ds.has_method("hide_death"):
		ds.hide_death()
	if pausemenu:
		pausemenu.visible = false
	Global.load_shards_from_slot()
	Global.storage_state["room"] = room_id
	var seen: Array = (Global.storage_state.get("seen", []) as Array).duplicate()
	var first = not seen.has(room_id)
	if first:
		seen.append(room_id)
		Global.storage_state["seen"] = seen
	if flash_title:
		_flash_title(StorageMap.title(room_id))
	if stub_name != "":
		_make_stub_sign()
	if player:
		Global.autosave(scene_file_path, player.global_position)
	room_ready(first)

func _make_stub_sign() -> void:
	var l = Label.new()
	l.text = stub_name + "\n" + tr("заглушка")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(300, 60)
	l.position = Vector2(room_rect.get_center().x - 150.0, GROUND_Y - 190.0)
	l.z_index = -5
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", Color(0.75, 0.7, 0.55, 0.55))
	add_child(l)

func make_interact(pos: Vector2, size: Vector2, prompt: String, cb: Callable) -> Area2D:
	var a = Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 1
	a.monitorable = false
	a.position = pos
	var cs = CollisionShape2D.new()
	var rs = RectangleShape2D.new()
	rs.size = size
	cs.shape = rs
	cs.position = Vector2(0, -size.y * 0.5)
	a.add_child(cs)
	var l = Label.new()
	l.size = Vector2(160, 20)
	l.position = Vector2(-80, -size.y - 26.0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 50
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	l.visible = false
	a.add_child(l)
	a.set_meta("prompt", prompt)
	a.set_meta("near", false)
	a.body_entered.connect(func(b):
		if b == player:
			a.set_meta("near", true)
			l.text = "[" + _interact_key() + "] " + String(a.get_meta("prompt"))
			l.visible = String(a.get_meta("prompt")) != "")
	a.body_exited.connect(func(b):
		if b == player:
			a.set_meta("near", false)
			l.visible = false)
	a.set_meta("cb", cb)
	add_child(a)
	_interacts.append(a)
	return a

func set_prompt(a: Area2D, text: String) -> void:
	a.set_meta("prompt", text)
	for c in a.get_children():
		if c is Label:
			c.text = "[" + _interact_key() + "] " + text
			c.visible = bool(a.get_meta("near")) and text != ""

func _interact_key() -> String:
	for e in InputMap.action_get_events("interact"):
		if e is InputEventKey:
			var code = e.physical_keycode if e.physical_keycode != 0 else e.keycode
			return OS.get_keycode_string(code)
	return "E"

func _unhandled_input(event: InputEvent) -> void:
	if travelling or get_tree().paused:
		return
	if event.is_action_pressed("interact"):
		for a in _interacts:
			if is_instance_valid(a) and bool(a.get_meta("near")) and String(a.get_meta("prompt")) != "":
				get_viewport().set_input_as_handled()
				(a.get_meta("cb") as Callable).call()
				return

func float_text(world_pos: Vector2, text: String, col: Color = Color(1, 1, 1), hold: float = 1.6) -> void:
	var l = Label.new()
	l.text = text
	l.size = Vector2(260, 20)
	l.position = world_pos + Vector2(-130, -20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 60
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	add_child(l)
	var tw = l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 14.0, hold)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.5).set_delay(hold - 0.5)
	tw.tween_callback(l.queue_free)

func lock_player(on: bool) -> void:
	if player and player.has_method("set_movement_blocked"):
		player.set_movement_blocked(on)
	if on and player:
		player.velocity = Vector2.ZERO

func room_ready(_first: bool) -> void:
	pass

func _mat_wall() -> ShaderMaterial:
	var m = ShaderMaterial.new()
	m.shader = SH_WALL
	m.set_shader_parameter("pixel_size", 3.0)
	m.set_shader_parameter("panel_size", Vector2(96, 72))
	m.set_shader_parameter("column_spacing", 600.0)
	m.set_shader_parameter("column_width", 33.0)
	m.set_shader_parameter("pipe_y1", 444)
	m.set_shader_parameter("pipe_y2", 744)
	m.set_shader_parameter("pipe_radius", 9.0)
	m.set_shader_parameter("stripe_y", 955)
	m.set_shader_parameter("stripe_height", 15.0)
	m.set_shader_parameter("gloom_y", 260)
	m.set_shader_parameter("gloom_length", 380.0)
	m.set_shader_parameter("col_base", Color(0.115, 0.105, 0.1))
	m.set_shader_parameter("col_light", Color(0.185, 0.17, 0.16))
	m.set_shader_parameter("col_rust", Color(0.3, 0.16, 0.08))
	m.set_shader_parameter("rust_amount", 0.5)
	return m

func _mat_wall_dark() -> ShaderMaterial:
	var m = ShaderMaterial.new()
	m.shader = SH_WALL
	m.set_shader_parameter("pixel_size", 3.0)
	m.set_shader_parameter("panel_size", Vector2(48, 144))
	m.set_shader_parameter("column_spacing", 9999.0)
	m.set_shader_parameter("column_width", 0.0)
	m.set_shader_parameter("col_base", Color(0.06, 0.055, 0.06))
	m.set_shader_parameter("col_light", Color(0.1, 0.095, 0.1))
	m.set_shader_parameter("rust_amount", 0.25)
	return m

func _mat_floor(kind: String) -> ShaderMaterial:
	var m = ShaderMaterial.new()
	m.shader = SH_FLOOR
	m.set_shader_parameter("pixel_size", 3.0)
	match kind:
		"ground":
			m.set_shader_parameter("plate_width", 96.0)
			m.set_shader_parameter("plate_depth", 24.0)
			m.set_shader_parameter("hazard_edge", false)
			m.set_shader_parameter("col_plate", Color(0.29, 0.26, 0.23))
			m.set_shader_parameter("col_top", Color(0.6, 0.55, 0.48))
		"catwalk":
			m.set_shader_parameter("plate_width", 48.0)
			m.set_shader_parameter("plate_depth", 9.0)
			m.set_shader_parameter("hazard_edge", true)
			m.set_shader_parameter("girder", false)
			m.set_shader_parameter("col_plate", Color(0.26, 0.26, 0.28))
			m.set_shader_parameter("col_top", Color(0.58, 0.58, 0.6))
		_:
			m.set_shader_parameter("plate_width", 96.0)
			m.set_shader_parameter("plate_depth", 15.0)
			m.set_shader_parameter("hazard_edge", true)
			m.set_shader_parameter("col_plate", Color(0.3, 0.27, 0.24))
			m.set_shader_parameter("col_top", Color(0.62, 0.57, 0.5))
	return m

func _dress() -> void:
	var vis = Node2D.new()
	vis.name = "AutoVisuals"
	add_child(vis)
	move_child(vis, 0)
	var bg = ColorRect.new()
	bg.z_index = -10
	bg.material = _mat_wall()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var r = room_rect.grow(700)
	bg.position = r.position
	bg.size = r.size
	vis.add_child(bg)
	var solids = get_node_or_null("Solids")
	if solids:
		for body in solids.get_children():
			if not body is StaticBody2D:
				continue
			for cs in body.get_children():
				if not cs is CollisionShape2D or not cs.shape is RectangleShape2D:
					continue
				var sz: Vector2 = cs.shape.size
				var c: Vector2 = cs.global_position
				var rect = Rect2(c - sz * 0.5, sz)
				var kind = "slab"
				if cs.one_way_collision:
					kind = "catwalk"
				elif sz.y >= 120.0:
					kind = "wall"
				elif rect.position.y >= GROUND_Y - 5.0:
					kind = "ground"
				var cr = ColorRect.new()
				cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
				match kind:
					"wall":
						cr.material = _mat_wall_dark()
						cr.position = rect.position
						cr.size = rect.size
						cr.z_index = 5
					"ground":
						cr.material = _mat_floor("ground")
						cr.position = rect.position
						cr.size = Vector2(rect.size.x, max(rect.size.y, 400.0))
					"catwalk":
						cr.material = _mat_floor("catwalk")
						cr.position = rect.position
						cr.size = Vector2(rect.size.x, 24.0)
					_:
						cr.material = _mat_floor("slab")
						cr.position = rect.position
						cr.size = rect.size
				vis.add_child(cr)
	var lamps = get_node_or_null("Lamps")
	if lamps:
		var i := 0
		for mk in lamps.get_children():
			if mk is Marker2D:
				_add_lamp(vis, mk.global_position, float(mk.get_meta("beam_h", 258.0)), i, bool(mk.get_meta("flicker", false)))
				i += 1
	_modulate = CanvasModulate.new()
	_modulate.color = ambient
	add_child(_modulate)
	var post = ColorRect.new()
	post.z_index = 1000
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pm = ShaderMaterial.new()
	pm.shader = SH_POST
	pm.set_shader_parameter("vignette_strength", 0.55)
	pm.set_shader_parameter("grade_amount", 0.6)
	pm.set_shader_parameter("grain_amount", 0.045)
	pm.set_shader_parameter("aberration", 0.0015)
	pm.set_shader_parameter("highlight_tint", Color(1, 0.84, 0.62))
	post.material = pm
	var pr = room_rect.grow(2000)
	post.position = pr.position
	post.size = pr.size
	vis.add_child(post)

func _add_lamp(parent: Node, p: Vector2, beam_h: float, i: int, flicker: bool) -> void:
	var cable = ColorRect.new()
	cable.color = Color(0.05, 0.05, 0.06)
	cable.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cable.position = Vector2(p.x - 1.5, p.y - 16.0)
	cable.size = Vector2(3, 16)
	parent.add_child(cable)
	var lamp = Sprite2D.new()
	lamp.texture = TX_LAMP
	lamp.scale = Vector2(3, 3)
	lamp.position = p
	parent.add_child(lamp)
	var beam = ColorRect.new()
	beam.z_index = 20
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bm = ShaderMaterial.new()
	bm.shader = SH_BEAM
	bm.set_shader_parameter("rect_size", Vector2(300, beam_h))
	bm.set_shader_parameter("pixel_size", 3.0)
	bm.set_shader_parameter("intensity", 0.22)
	bm.set_shader_parameter("seed", float(i * 7 % 23))
	bm.set_shader_parameter("top_width", 0.1)
	bm.set_shader_parameter("bottom_width", 0.95)
	bm.set_shader_parameter("flicker_amount", 0.06)
	bm.set_shader_parameter("dropout_chance", 0.04 if flicker else 0.004)
	beam.material = bm
	beam.position = Vector2(p.x - 150.0, p.y + 6.0)
	beam.size = Vector2(300, beam_h)
	parent.add_child(beam)
	var light = PointLight2D.new()
	light.position = p + Vector2(0, 6)
	light.rotation = PI / 2.0
	light.color = Color(1, 0.8, 0.56)
	light.energy = 1.05
	light.texture = TX_CONE
	light.add_to_group("storage_lights")
	parent.add_child(light)
	beam.add_to_group("storage_lights")

func _place_player() -> void:
	if player == null:
		return
	var entry: String = Global.storage_state.get("entry", "")
	var placed := false
	if entry != "":
		for d in get_tree().get_nodes_in_group("storage_doors"):
			if d.door_id == entry:
				player.global_position = d.spawn_point()
				_face(d.spawn_dir)
				placed = true
				break
	if not placed and Global.player_position != Vector2.ZERO and room_rect.grow(-8.0).has_point(Global.player_position):
		player.global_position = Global.player_position
		placed = true
	Global.player_position = Vector2.ZERO
	if not placed:
		var st = get_node_or_null("PlayerStart")
		if st:
			player.global_position = st.global_position
	player.velocity = Vector2.ZERO

func _face(dir: int) -> void:
	if player == null or dir == 0:
		return
	if "facing_direction" in player:
		player.facing_direction = dir
	var spr = player.get_node_or_null("AnimatedSprite2D")
	if spr:
		spr.flip_h = dir < 0

func _setup_camera() -> void:
	if camera == null:
		return
	camera.make_current()
	if "bounds" in camera:
		camera.bounds = room_rect
	if camera.has_method("snap_to"):
		camera.snap_to(player.global_position)

func _spawn_hud() -> void:
	hud_instance = HUD_SCENE.instantiate()
	add_child(hud_instance)
	inventory_instance = INVENTORY_SCENE.instantiate()
	add_child(inventory_instance)

func show_title(title: String, subtitle: String = "", hold: float = 2.5) -> void:
	var card = TITLE_SCENE.instantiate()
	add_child(card)
	await get_tree().process_frame
	if is_instance_valid(card) and card.has_method("show_title"):
		card.show_title(title, subtitle, hold)

func _flash_title(text: String) -> void:
	var layer = CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var l = Label.new()
	l.text = text
	l.position = Vector2(24, 586)
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(0.85, 0.85, 0.88))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	l.modulate.a = 0.0
	layer.add_child(l)
	var tw = l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.4)
	tw.tween_interval(1.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.8)
	tw.tween_callback(layer.queue_free)

func enemy_scene(kind: String) -> PackedScene:
	match kind:
		"dog":
			return DOG_SCENE
		"monkey":
			return MONKEY_SCENE
		"pigeon":
			return PIGEON_SCENE
	return null

func _spawn_enemies() -> void:
	var sp = get_node_or_null("SpawnPoints")
	if sp == null:
		return
	var parent = get_node_or_null("Enemies")
	if parent == null:
		parent = Node2D.new()
		parent.name = "Enemies"
		add_child(parent)
	for point in sp.get_children():
		if not point is Marker2D:
			continue
		if bool(point.get_meta("event", false)):
			continue
		if StorageMap.is_dead(room_id, point.name):
			continue
		spawn_enemy_at(point, parent)

func spawn_enemy_at(point: Marker2D, parent: Node = null) -> Node:
	var scene = enemy_scene(String(point.get_meta("enemy_type", "dog")))
	if scene == null:
		return null
	if parent == null:
		parent = get_node_or_null("Enemies")
	var enemy = scene.instantiate()
	for key in point.get_meta_list():
		if key != "enemy_type" and key != "event" and key in enemy:
			enemy.set(key, point.get_meta(key))
	enemy.global_position = point.global_position
	parent.add_child(enemy)
	var mname = String(point.name)
	if enemy.has_signal("died"):
		enemy.died.connect(func(_c): _pending_dead.append(mname))
	return enemy

func alive_enemies() -> Array:
	var out: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not bool(e.get("is_dead")):
			out.append(e)
	return out

func travel(target_room: String, target_door: String) -> void:
	if travelling:
		return
	var path = StorageMap.scene_path(target_room)
	if path == "" or not ResourceLoader.exists(path):
		return
	travelling = true
	if player:
		if player.has_method("set_movement_blocked"):
			player.set_movement_blocked(true)
	StorageMap.mark_dead(room_id, _pending_dead)
	_pending_dead.clear()
	Global.storage_state["entry"] = target_door
	Global.storage_state["room"] = target_room
	Global.goto_scene(path)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if travelling:
			return
		if player and "is_dead" in player and player.is_dead:
			return
		_toggle_pause()

func _toggle_pause() -> void:
	if not pausemenu:
		return
	if get_tree().paused:
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		GlobalMusic.restore_volume()
		UISounds.restore_ambience()
		if pausemenu.has_method("hide_menu"):
			pausemenu.hide_menu()
		else:
			pausemenu.visible = false
		if player:
			player.set_physics_process(true)
			player.set_process(true)
	else:
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GlobalMusic.lower_volume()
		UISounds.lower_ambience()
		if pausemenu.has_method("show_menu"):
			pausemenu.show_menu()
		else:
			pausemenu.visible = true
		if player:
			player.set_physics_process(false)
			player.set_process(false)

func _resume_after_pause() -> void:
	if not player:
		return
	player.set_physics_process(true)
	player.set_process(true)

func _exit_tree() -> void:
	if hud_instance and is_instance_valid(hud_instance):
		hud_instance.queue_free()
	if inventory_instance and is_instance_valid(inventory_instance):
		inventory_instance.queue_free()
