@tool
extends Area2D
class_name StorageDoor

signal locked_tried(door: StorageDoor)
signal used(door: StorageDoor)

const DOOR_TEX := preload("res://GameAssets/LevelAssets/ActStorage/StorageTilesetTextures/NearFactoryLevelAssets/ActSrorage_LevelNearFactory_TileSet_IronDoor_Texture.png")
const LAMP_TEX := preload("res://GameAssets/LevelAssets/SharedLevelAssets/Shared_WallLamp_Texture.png")
const GLOW_TEX := preload("res://GameAssets/Sprites/UserInterfaceSprites/LightTextures/Light_Option10_Texture.png")
const C_OPEN := Color(0.45, 1.0, 0.55)
const C_LOCK := Color(1.0, 0.35, 0.3)

@export var door_id: String = ""
@export var target_room: String = ""
@export var target_door: String = ""
@export_enum("edge", "door", "hatch") var kind: String = "edge"
@export var lock: String = ""
@export var spawn_dir: int = 1
@export var arrow: String = ""

var _near: bool = false
var _prompt: Label = null
var _msg: Label = null
var _lamp: Sprite2D = null
var _glow: PointLight2D = null
var _busy: bool = false
var _msg_tw: Tween = null

func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	add_to_group("storage_doors")
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	var cs = CollisionShape2D.new()
	var rs = RectangleShape2D.new()
	match kind:
		"edge":
			rs.size = Vector2(20, 240)
			cs.position = Vector2(0, -120)
		"hatch":
			rs.size = Vector2(70, 60)
			cs.position = Vector2(0, -20)
		_:
			rs.size = Vector2(56, 90)
			cs.position = Vector2(0, -45)
	cs.shape = rs
	add_child(cs)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	if kind == "door":
		var spr = Sprite2D.new()
		spr.texture = DOOR_TEX
		spr.scale = Vector2(3, 3)
		spr.position = Vector2(0, -54)
		spr.z_index = -2
		add_child(spr)
		_lamp = Sprite2D.new()
		_lamp.texture = LAMP_TEX
		_lamp.scale = Vector2(3, 3)
		_lamp.position = Vector2(0, -126)
		_lamp.z_index = -1
		add_child(_lamp)
		_glow = PointLight2D.new()
		_glow.texture = GLOW_TEX
		_glow.texture_scale = 0.6
		_glow.energy = 0.9
		_glow.position = _lamp.position
		add_child(_glow)
	if kind == "edge" and lock != "sealed":
		var arr = Label.new()
		arr.text = "«" if spawn_dir > 0 else "»"
		arr.size = Vector2(40, 30)
		arr.position = Vector2(spawn_dir * 34.0 - 20.0, -34.0)
		arr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arr.add_theme_font_size_override("font_size", 16)
		arr.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35, 0.55))
		arr.z_index = 4
		add_child(arr)
		var tw = arr.create_tween().set_loops()
		tw.tween_property(arr, "position:x", arr.position.x - spawn_dir * 6.0, 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(arr, "position:x", arr.position.x, 0.6).set_trans(Tween.TRANS_SINE)
	_prompt = _make_label(12)
	_prompt.position = Vector2(-60, -170 if kind == "door" else -90)
	_prompt.visible = false
	_msg = _make_label(10)
	_msg.position = Vector2(-120, -200 if kind == "door" else -120)
	_msg.size = Vector2(240, 30)
	_msg.modulate.a = 0.0
	refresh()

func _make_label(fs: int) -> Label:
	var l = Label.new()
	l.size = Vector2(120, 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.z_index = 50
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 4)
	add_child(l)
	return l

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var c = Color(0.3, 1.0, 0.4, 0.5) if lock == "" else Color(1.0, 0.3, 0.3, 0.5)
	match kind:
		"edge":
			draw_rect(Rect2(-10, -240, 20, 240), c)
		"hatch":
			draw_rect(Rect2(-35, -50, 70, 60), c)
		_:
			draw_rect(Rect2(-28, -90, 56, 90), c)
	draw_string(ThemeDB.fallback_font, Vector2(-30, -250), door_id + " → " + target_room, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

func is_locked() -> bool:
	match lock:
		"power":
			return not StorageMap.flag("power_cut")
		"keycard":
			return not StorageMap.flag("keycard")
		"accountant":
			return not StorageMap.flag("accountant_open")
		"sealed":
			return true
	return false

func lock_text() -> String:
	match lock:
		"power":
			return tr("ЗАПЕРТО. На замок подан ток.")
		"keycard":
			return tr("НУЖНА КЛЮЧ-КАРТА.")
		"accountant":
			return tr("ЗАПЕРТО С ДРУГОЙ СТОРОНЫ.")
		"sealed":
			return tr("ЗАВАРЕНО.")
	return ""

func refresh() -> void:
	var c = C_LOCK if is_locked() else C_OPEN
	if _lamp:
		_lamp.modulate = c
	if _glow:
		_glow.color = c

func spawn_point() -> Vector2:
	match kind:
		"edge":
			return global_position + Vector2(spawn_dir * 70.0, -30.0)
		"hatch":
			return global_position + Vector2(spawn_dir * 50.0, -30.0)
	return global_position + Vector2(0, -30.0)

func _player() -> Node:
	return get_tree().get_first_node_in_group("player")

func _on_enter(body: Node) -> void:
	if body != _player():
		return
	_near = true
	if kind == "edge":
		_try_use()
	elif _prompt:
		_prompt.text = "[" + _key_name() + "] " + (arrow if arrow != "" else "")
		_prompt.visible = true

func _on_exit(body: Node) -> void:
	if body != _player():
		return
	_near = false
	if _prompt:
		_prompt.visible = false

func _key_name() -> String:
	for e in InputMap.action_get_events("interact"):
		if e is InputEventKey:
			var code = e.physical_keycode if e.physical_keycode != 0 else e.keycode
			return OS.get_keycode_string(code)
	return "E"

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not _near or kind == "edge" or _busy:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_try_use()

func _try_use() -> void:
	if _busy:
		return
	var room = get_tree().current_scene
	if room == null or not room.has_method("travel"):
		return
	if bool(room.get("travelling")):
		return
	if is_locked():
		show_msg(lock_text())
		locked_tried.emit(self)
		if kind == "edge":
			var p = _player()
			if p:
				p.global_position.x += spawn_dir * 18.0
				p.velocity.x = 0.0
		return
	_busy = true
	used.emit(self)
	room.travel(target_room, target_door)

func show_msg(text: String) -> void:
	if _msg == null:
		return
	_msg.text = text
	if _msg_tw:
		_msg_tw.kill()
	_msg.modulate.a = 1.0
	_msg_tw = create_tween()
	_msg_tw.tween_interval(1.8)
	_msg_tw.tween_property(_msg, "modulate:a", 0.0, 0.5)
