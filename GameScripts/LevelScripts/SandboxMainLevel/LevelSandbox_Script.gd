extends Node2D

const FLOOR_TOP := 592.0
const BLOCK_C := Color(0.33, 0.36, 0.42)
const BLOCK_TOP_C := Color(0.55, 0.6, 0.68)

var _fish: CharacterBody2D = null
var _hud: Label = null
var _course: Node2D = null
var _trail: Array = []
var _trail_node: Node2D = null
var show_debug: bool = true
var _enemies_root: Node2D = null
const ENEMY_SCENES := [
	"res://GameScenes/EntityScenes/EnemyEntityScenes/MechaDogScenes/Enemy_MechaDog_Storage_Scene.tscn",
	"res://GameScenes/EntityScenes/EnemyEntityScenes/MechaMonkeyScenes/Enemy_MechaMonkey_Storage_Scene.tscn",
	"res://GameScenes/EntityScenes/EnemyEntityScenes/MechaPigeonScenes/Enemy_MechaPigeon_Storage_Scene.tscn",
]

func _ready() -> void:
	_fish = get_node_or_null("Player/Mecha_Fish") as CharacterBody2D
	_course = Node2D.new()
	_course.name = "Course"
	add_child(_course)
	_build_course()
	_build_hud()
	_enemies_root = Node2D.new()
	_enemies_root.name = "Enemies"
	add_child(_enemies_root)
	if _fish and "enemies_node" in _fish:
		_fish.enemies_node = _enemies_root

func _block(x: float, w: float, h: float, label: String = "", top: float = FLOOR_TOP) -> StaticBody2D:
	var b = StaticBody2D.new()
	b.collision_layer = 5
	b.collision_mask = 7
	b.position = Vector2(x, top - h)
	var cs = CollisionShape2D.new()
	var rs = RectangleShape2D.new()
	rs.size = Vector2(w, h)
	cs.shape = rs
	cs.position = Vector2(w * 0.5, h * 0.5)
	b.add_child(cs)
	var r = ColorRect.new()
	r.size = Vector2(w, h)
	r.color = BLOCK_C
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(r)
	var t = ColorRect.new()
	t.size = Vector2(w, 4)
	t.color = BLOCK_TOP_C
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(t)
	if label != "":
		var l = Label.new()
		l.text = label
		l.position = Vector2(0, -22)
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0, 0.8))
		b.add_child(l)
	_course.add_child(b)
	return b

func _build_course() -> void:
	_block(820, 90, 30, "30")
	_block(1000, 90, 60, "60")
	_block(1180, 90, 95, "95")
	_block(1360, 120, 150, "150")
	var ceil_b = _block(1700, 260, 40, "roll", FLOOR_TOP - 56.0)
	ceil_b.name = "RollCeiling"
	_block(2060, 70, 46, "")
	_block(2130, 70, 92, "")
	_block(2200, 260, 138, "")
	_block(2560, 120, 220, "wall 220")
	_block(-440, 40, 700, "")
	_block(3200, 40, 700, "")

func _build_hud() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(12, 130)
	_hud.add_theme_font_size_override("font_size", 13)
	_hud.add_theme_color_override("font_color", Color(0.9, 1.0, 0.85))
	_hud.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_hud.add_theme_constant_override("outline_size", 4)
	layer.add_child(_hud)
	var help = Label.new()
	help.position = Vector2(12, 600)
	help.text = "A/D  Space  Shift tap = dash  Ctrl = roll  F = block  LMB = attack  RMB = parry\n1/2/3 = dog/monkey/pigeon  0 = clear  H = heal  F1 = debug  R = restart"
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95, 0.8))
	layer.add_child(help)
	_trail_node = Node2D.new()
	_trail_node.z_index = 200
	_trail_node.draw.connect(_draw_trail)
	add_child(_trail_node)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_F1:
			show_debug = not show_debug
		elif e.keycode == KEY_R:
			get_tree().reload_current_scene()
		elif e.keycode >= KEY_1 and e.keycode <= KEY_3:
			_spawn_enemy(e.keycode - KEY_1)
		elif e.keycode == KEY_0:
			for c in _enemies_root.get_children():
				c.queue_free()
		elif e.keycode == KEY_H and _fish:
			_fish.hp = _fish.max_hp
			if _fish.has_method("set_hp"):
				_fish.set_hp(_fish.max_hp)

func _spawn_enemy(i: int) -> void:
	if _fish == null or i < 0 or i >= ENEMY_SCENES.size():
		return
	var sc = load(ENEMY_SCENES[i]) as PackedScene
	if sc == null:
		return
	var e = sc.instantiate()
	_enemies_root.add_child(e)
	var dir = float(_fish.facing_direction) if "facing_direction" in _fish else 1.0
	e.global_position = _fish.global_position + Vector2(dir * 220.0, -60.0)

func _physics_process(_d: float) -> void:
	if _fish == null:
		return
	_trail.append(_fish.global_position)
	if _trail.size() > 90:
		_trail.pop_front()
	_trail_node.visible = show_debug
	if show_debug:
		_trail_node.queue_redraw()
	_hud.visible = show_debug
	if not show_debug:
		return
	var spr: AnimatedSprite2D = _fish.get_node_or_null("AnimatedSprite2D")
	var st: Array = []
	for k in ["is_sliding", "is_dashing", "is_landing", "is_climbing_animation", "is_attacking", "is_blocking", "is_hurt"]:
		if _fish.get(k):
			st.append(k.replace("is_", ""))
	_hud.text = "pos %.0f, %.0f\nvel %.0f, %.0f\nfloor %s  wall %s\nanim %s #%d\n%s\nfps %d" % [
		_fish.global_position.x, _fish.global_position.y, _fish.velocity.x, _fish.velocity.y,
		_fish.is_on_floor(), _fish.is_on_wall(),
		spr.animation if spr else "-", spr.frame if spr else 0,
		" ".join(st), Engine.get_frames_per_second()]

func _draw_trail() -> void:
	for i in range(1, _trail.size()):
		_trail_node.draw_line(_trail[i - 1], _trail[i], Color(1, 0.8, 0.2, float(i) / _trail.size()), 2.0)
