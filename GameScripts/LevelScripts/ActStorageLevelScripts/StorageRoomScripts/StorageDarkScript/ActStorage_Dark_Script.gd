extends Node
class_name StorageDark

const OUTLINE_SHADER := """
shader_type canvas_item;
uniform vec4 line_color : source_color = vec4(1.0);
uniform float strength = 1.0;
void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	float a = texture(TEXTURE, UV).a;
	float r = texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	float l = texture(TEXTURE, UV - vec2(px.x, 0.0)).a;
	float u = texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	float d = texture(TEXTURE, UV + vec2(0.0, px.y)).a;
	float mn = min(min(r, l), min(u, d));
	float edge = step(0.1, a) * (1.0 - step(0.1, mn));
	COLOR = vec4(line_color.rgb, line_color.a * edge * strength);
}
"""

const STEP_EVERY := 0.32
const FADE_TIME := 0.9

var room: Node2D = null
var active: bool = false
var _ghost_layer: CanvasLayer = null
var _ghosts: Dictionary = {}
var _shader: Shader = null

func _ready() -> void:
	_shader = Shader.new()
	_shader.code = OUTLINE_SHADER

const DARK_COLOR := Color(0.035, 0.035, 0.05, 1.0)

func set_dark(on: bool, fade: float = 0.25) -> void:
	active = on
	StorageEnemy.dark_mode = on
	if on and _ghost_layer == null:
		_ghost_layer = CanvasLayer.new()
		_ghost_layer.layer = 5
		_ghost_layer.follow_viewport_enabled = true
		add_child(_ghost_layer)
	var mod: CanvasModulate = room.get("_modulate") if room else null
	if mod:
		var target = DARK_COLOR if on else room.ambient
		if fade <= 0.0:
			mod.color = target
		else:
			create_tween().tween_property(mod, "color", target, fade)
	for n in get_tree().get_nodes_in_group("storage_lights"):
		n.visible = not on
	if not on:
		for k in _ghosts.keys():
			var g = _ghosts[k]
			if is_instance_valid(g["node"]):
				g["node"].queue_free()
		_ghosts.clear()

func _exit_tree() -> void:
	StorageEnemy.dark_mode = false

func _source_sprite(body: Node) -> Node2D:
	var s = body.get_node_or_null("AnimatedSprite2D")
	if s == null:
		s = body.get_node_or_null("Sprite")
	if s == null:
		for c in body.get_children():
			if c is AnimatedSprite2D:
				return c
	return s

func _ghost_for(body: Node, always: bool) -> Dictionary:
	var id = body.get_instance_id()
	if _ghosts.has(id):
		return _ghosts[id]
	var src = _source_sprite(body)
	if src == null:
		return {}
	var g = AnimatedSprite2D.new()
	var m = ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("line_color", Color(1, 1, 1, 1) if always else Color(1.0, 0.45, 0.4, 1))
	g.material = m
	g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ghost_layer.add_child(g)
	var d = {"node": g, "src": src, "body": body, "always": always, "alpha": 1.0 if always else 0.0, "step": 0.0}
	_ghosts[id] = d
	return d

func pulse(body: Node, amount: float = 1.0) -> void:
	if not active:
		return
	var d = _ghost_for(body, false)
	if not d.is_empty():
		d["alpha"] = max(float(d["alpha"]), amount)

func _process(delta: float) -> void:
	if not active or _ghost_layer == null:
		return
	var p = get_tree().get_first_node_in_group("player")
	if p:
		_ghost_for(p, true)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or bool(e.get("is_dead")):
			continue
		var d = _ghost_for(e, false)
		if d.is_empty():
			continue
		var moving = e is CharacterBody2D and abs(e.velocity.x) > 12.0 and e.is_on_floor()
		if moving:
			d["step"] = float(d["step"]) - delta
			if float(d["step"]) <= 0.0:
				d["step"] = STEP_EVERY
				d["alpha"] = 1.0
		if e is CharacterBody2D and e.velocity.y < -100.0:
			d["alpha"] = 1.0
	for k in _ghosts.keys():
		var d = _ghosts[k]
		var g: AnimatedSprite2D = d["node"]
		var src = d["src"]
		var body = d["body"]
		if not is_instance_valid(g):
			_ghosts.erase(k)
			continue
		if not is_instance_valid(src) or not is_instance_valid(body) or bool(body.get("is_dead")):
			g.queue_free()
			_ghosts.erase(k)
			continue
		if src is AnimatedSprite2D:
			if g.sprite_frames != src.sprite_frames:
				g.sprite_frames = src.sprite_frames
			if g.animation != src.animation:
				g.animation = src.animation
			g.frame = src.frame
			g.flip_h = src.flip_h
			g.flip_v = src.flip_v
			g.offset = src.offset
			g.centered = src.centered
		g.global_transform = src.global_transform
		g.visible = src.is_visible_in_tree()
		if not bool(d["always"]):
			d["alpha"] = max(0.0, float(d["alpha"]) - delta / FADE_TIME)
		(g.material as ShaderMaterial).set_shader_parameter("strength", float(d["alpha"]))
