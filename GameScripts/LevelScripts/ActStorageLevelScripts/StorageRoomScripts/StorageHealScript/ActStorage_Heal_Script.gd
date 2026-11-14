extends Area2D
class_name StorageHeal

const TEX := preload("res://GameAssets/LevelAssets/ActStorage/StorageTilesetTextures/NearFactoryLevelAssets/ActStorage_LevelNearFactory_TileSet_FishFood_Option1_Texture.png")
const GLOW_TEX := preload("res://GameAssets/Sprites/UserInterfaceSprites/LightTextures/Light_Option10_Texture.png")
const SND := preload("res://GameAssets/Audio/SoundEffects/UserInterfaceSounds/PopUpOptionSounds/Menu_Aquarium_MainMenu_Pop_Option3_SoundEffect.mp3")

@export var heal_id: String = ""
@export var amount: int = 1

var _spr: Sprite2D = null
var _glow: PointLight2D = null
var _t: float = 0.0
var _delay: float = 0.0
var _taken: bool = false
var _drop_vy: float = 0.0
var _floor_y: float = INF

static func drop(parent: Node, pos: Vector2) -> StorageHeal:
	var n = StorageHeal.new()
	n._delay = 0.6
	n._drop_vy = -220.0
	n.position = pos
	parent.add_child(n)
	return n

func _room_id() -> String:
	var r = get_tree().current_scene
	return str(r.get("room_id")) if r and "room_id" in r else ""

func _ready() -> void:
	if heal_id != "" and StorageMap.is_taken(_room_id(), heal_id):
		queue_free()
		return
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	var cs = CollisionShape2D.new()
	var sh = CircleShape2D.new()
	sh.radius = 30.0
	cs.shape = sh
	add_child(cs)
	_glow = PointLight2D.new()
	_glow.texture = GLOW_TEX
	_glow.texture_scale = 0.35
	_glow.energy = 0.7
	_glow.color = Color(1.0, 0.75, 0.55)
	add_child(_glow)
	_spr = Sprite2D.new()
	_spr.texture = TEX
	_spr.scale = Vector2(3, 3)
	_spr.z_index = 3
	add_child(_spr)
	if _drop_vy != 0.0:
		var q = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 600))
		q.collision_mask = 1
		var hit = get_world_2d().direct_space_state.intersect_ray(q)
		_floor_y = (hit.position.y - 22.0) if hit else global_position.y

func _process(delta: float) -> void:
	if _taken:
		return
	_t += delta
	if _drop_vy != 0.0 or global_position.y < _floor_y - 0.5:
		if _floor_y != INF:
			_drop_vy += 900.0 * delta
			global_position.y += _drop_vy * delta
			if global_position.y >= _floor_y and _drop_vy > 0.0:
				global_position.y = _floor_y
				_drop_vy = 0.0
				_floor_y = INF
	if _spr:
		_spr.position.y = sin(_t * 3.0) * 3.0
		_spr.rotation = sin(_t * 1.7) * 0.12
	if _glow:
		_glow.energy = 0.55 + 0.2 * sin(_t * 4.0)
	if _delay > 0.0:
		_delay -= delta
		return
	for b in get_overlapping_bodies():
		if b.is_in_group("player"):
			_try(b)
			return

func _try(p: Node) -> void:
	if not ("hp" in p and "max_hp" in p):
		return
	if "is_dead" in p and p.is_dead:
		return
	if int(p.hp) >= int(p.max_hp):
		return
	_taken = true
	p.hp = mini(int(p.max_hp), int(p.hp) + amount)
	if heal_id != "":
		StorageMap.mark_taken(_room_id(), heal_id)
	var room = get_tree().current_scene
	if room and room.has_method("float_text"):
		room.float_text(p.global_position + Vector2(0, -70), "+" + str(amount), Color(1.0, 0.55, 0.5), 1.0)
	var a = AudioStreamPlayer2D.new()
	a.stream = SND
	a.volume_db = -6.0
	if AudioServer.get_bus_index("SFX") >= 0:
		a.bus = "SFX"
	a.global_position = global_position
	if room:
		room.add_child(a)
		a.play()
		a.finished.connect(a.queue_free)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "global_position", p.global_position + Vector2(0, -20), 0.2)
	if _spr:
		tw.tween_property(_spr, "scale", Vector2(4.5, 4.5), 0.2)
		tw.tween_property(_spr, "modulate:a", 0.0, 0.2)
	if _glow:
		tw.tween_property(_glow, "energy", 2.0, 0.1)
	tw.chain().tween_callback(queue_free)
