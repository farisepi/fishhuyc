extends AnimatableBody2D
class_name StorageLift

const TX_LIFT := preload("res://GameAssets/LevelAssets/ActStorage/StorageTilesetTextures/NearFactoryLevelAssets/ActStorage_LevelNearFactory_TileSet_Lift_Option1_Texture.png")
const TX_RAIL := preload("res://GameAssets/LevelAssets/ActStorage/StorageTilesetTextures/NearFactoryLevelAssets/ActStorage_LevelNearFactory_TileSet_LiftRail_Option1_Texture.png")
const TX_BEACON := preload("res://GameAssets/LevelAssets/ActStorage/StorageTilesetTextures/NearFactoryLevelAssets/ActStorage_LevelNearFactory_TileSet_Beacon_Option1_Texture.png")
const GLOW_TEX := preload("res://GameAssets/Sprites/UserInterfaceSprites/LightTextures/Light_Option10_Texture.png")

@export var stops: PackedFloat32Array = PackedFloat32Array([1000.0, 520.0])
@export var speed: float = 120.0
@export var wait: float = 1.6
@export var width: float = 120.0
@export var shaft_top: float = 200.0

var _i: int = 0
var _dir: int = 1
var _wait_t: float = 0.0
var _beacon: Sprite2D = null
var _glow: PointLight2D = null

func _ready() -> void:
	sync_to_physics = true
	if stops.size() > 0:
		position.y = stops[0]
	var cs = CollisionShape2D.new()
	var rs = RectangleShape2D.new()
	rs.size = Vector2(width, 18.0)
	cs.shape = rs
	cs.position = Vector2(0, 9.0)
	add_child(cs)
	var spr = Sprite2D.new()
	spr.texture = TX_LIFT
	spr.scale = Vector2(3, 3)
	spr.centered = false
	spr.position = Vector2(-width * 0.5, 21.0 - TX_LIFT.get_height() * 3.0)
	spr.z_index = -1
	add_child(spr)
	_beacon = Sprite2D.new()
	_beacon.texture = TX_BEACON
	_beacon.scale = Vector2(3, 3)
	_beacon.position = Vector2(0, 21.0 - TX_LIFT.get_height() * 3.0 - 10.0)
	add_child(_beacon)
	_glow = PointLight2D.new()
	_glow.texture = GLOW_TEX
	_glow.texture_scale = 0.7
	_glow.color = Color(1.0, 0.7, 0.3)
	_glow.energy = 0.0
	_glow.position = _beacon.position
	add_child(_glow)
	_build_rails.call_deferred()
	_wait_t = wait

func _build_rails() -> void:
	var p = get_parent()
	if p == null:
		return
	var bottom = 1100.0
	for side in [-1.0, 1.0]:
		var r = Sprite2D.new()
		r.texture = TX_RAIL
		r.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		r.region_enabled = true
		r.region_rect = Rect2(0, 0, 8, (bottom - shaft_top) / 3.0)
		r.scale = Vector2(3, 3)
		r.centered = false
		r.position = Vector2(position.x + side * (width * 0.5 + 4.0) - 12.0, shaft_top)
		r.z_index = -6
		p.add_child(r)

func _physics_process(delta: float) -> void:
	if stops.size() < 2:
		return
	if _wait_t > 0.0:
		_wait_t -= delta
		if _glow:
			_glow.energy = 0.0
		return
	var target = stops[_i + _dir]
	var y = move_toward(position.y, target, speed * delta)
	position.y = y
	if _glow:
		_glow.energy = 0.6 + 0.4 * sin(Time.get_ticks_msec() / 90.0)
	if is_equal_approx(y, target):
		_i += _dir
		if _i == stops.size() - 1 or _i == 0:
			_dir = -_dir
		_wait_t = wait
