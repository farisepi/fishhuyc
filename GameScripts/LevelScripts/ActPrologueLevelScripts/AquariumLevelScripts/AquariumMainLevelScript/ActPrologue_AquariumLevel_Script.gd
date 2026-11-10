extends Node2D

var bubble_scene: PackedScene = preload("res://GameScenes/EntityScenes/BubbleEntityScenes/Bubble_Scene.tscn")

const WATER_RECT: Rect2 = Rect2(363, 103, 551, 288)

@onready var animationtrack = $AnimationPlayer
@onready var scientistsprite = $npc/Scientist/ScientistSprite
@onready var mechanicsprite = $npc/Mechanic/MechanicSprite
@onready var chatter: ChatterController = $ChatterController
@onready var cutscene_chatter: ChatterController = $CutsceneController
@onready var quake_chatter: ChatterController = $QuakeController
@onready var pausemenu: CanvasLayer = get_node_or_null("Pausemenu")
@onready var player: CharacterBody2D = $Player
@onready var lights_root: Node = get_node_or_null("Visual/Light")
@onready var fade_rect: CanvasItem = get_node_or_null("Visual/stuff/Fade")
var _ending: bool = false

# ---- lab lights: soft flicker, NPC shadows, panic ----
var _lamps: Array = []          # PointLight2D
var _lamp_base: Array = []
var _lamp_k: Array = []
var _lamp_x: Array = []          # current brightness factor per lamp (1 = normal)
var _beams: Array = []           # LabBeam ColorRects (fake light cones), same order as the lamps
var _beam_base: Array = []
var _blink_lamp: int = -1
var _blink_time: float = 0.0
var _next_blink: float = 3.0
var _light_t: float = 0.0
var _light_acc: float = 0.0
var _quake_on: bool = false
var _npc_shadows: Array = []     # [{sprite, holder, shadows:[AnimatedSprite2D, AnimatedSprite2D], blob}]
var _panicking: bool = false
var _box_shadow: Dictionary = {}
var _jolt_rot: float = 0.0
const BG_RECT := Rect2(319, 61, 640, 440)
const LETTERBOX_K := 0.08   # height of the cinema bars, part of the screen
const PANIC_FRAMES := {
	"Scientist": ["res://GameAssets/Sprites/EntitySprites/NPCSprites/ScientistNpcSprites/ScientistAnimationFrames/NPC_Scientist_Panic_Sprite1_Animation.png",
		"res://GameAssets/Sprites/EntitySprites/NPCSprites/ScientistNpcSprites/ScientistAnimationFrames/NPC_Scientist_Panic_Sprite2_Animation.png"],
	"Mechanic": ["res://GameAssets/Sprites/EntitySprites/NPCSprites/MechanicNpcSprites/MechanicAnimationFrames/NPC_Mechanic_Panic_Sprite1_Animation.png",
		"res://GameAssets/Sprites/EntitySprites/NPCSprites/MechanicNpcSprites/MechanicAnimationFrames/NPC_Mechanic_Panic_Sprite2_Animation.png",
		"res://GameAssets/Sprites/EntitySprites/NPCSprites/MechanicNpcSprites/MechanicAnimationFrames/NPC_Mechanic_Panic_Sprite3_Animation.png",
		"res://GameAssets/Sprites/EntitySprites/NPCSprites/MechanicNpcSprites/MechanicAnimationFrames/NPC_Mechanic_Panic_Sprite4_Animation.png"],
}
const NPC_FEET_Y := {"Scientist": 154.0, "Mechanic": 152.0}

## Where the fish has to be to hit the glass (bottom of the tank, in front of the two).
const GLASS_ZONE: Rect2 = Rect2(540, 300, 280, 104)

var _in_glass_zone: bool = false
var _cutscene: bool = false
var _hint: Node2D = null
var _bars: CanvasLayer = null
var _hint_layer: CanvasLayer = null
var _glass_glow: Node2D = null
var _hint_key_text: String = "F"
var _hint_font: Font = null
var _hint_alpha: float = 0.0
var _glow_power: float = 0.0
const GLASS_HIT_X: float = 680.0
const GLASS_TOP_Y: float = 391.0
const GLASS_BOTTOM_Y: float = 404.0
const GLASS_HALF_W: float = 110.0

const QUAKE_DELAY: float = 1.5
const QUAKE_DURATION: float = 4.5
var scientist_boring_timer: Timer
var mechanic_boring_timer: Timer

const BORING_INTERVAL_MIN: float = 15.0
const BORING_INTERVAL_MAX: float = 20.0

const TUTORIAL := preload("res://GameScripts/UIScripts/TutorialScripts/Tutorial_Hints.gd")
var _tut = null
var _tut_t := 0.0

func _ready():
	GlobalMusic.play_level_music()
	_fit_intro_zoom()
	animationtrack.play("INTRO")
	_tut = TUTORIAL.new()
	_tut.style = "aquarium"
	add_child(_tut)
	
	_setup_character_animations()
	_spawn_bubbles()
	# the fish is in water here: no air meter
	var air = player.get_node_or_null("GUI/UI_Container/Air_Bar") if player else null
	if air:
		air.visible = false
	# the fish stays put until the intro camera has zoomed out
	if player and "can_move" in player:
		player.can_move = false
	_intro_lock = true
	if cutscene_chatter:
		cutscene_chatter.skippable = true
	if quake_chatter:
		quake_chatter.skippable = true
	UISounds.stop_factory_ambience()  # the factory hum belongs to the factory, not the aquarium
	if pausemenu:
		pausemenu.visible = false
	# background talk loops until the fish hits the glass
	if chatter and chatter.is_active():
		chatter.stop()   # nothing on screen while the intro camera zooms out
	_start_chatter_after_intro()
	_make_glass_hint()
	_setup_lab_lights()
	_setup_npc_shadows()
	_setup_toolbox_shadow()

var _intro_lock: bool = false

## The INTRO zooms out to 2x, but on a wide window the camera needs a bit more zoom to not
## show anything outside the location - it used to snap to that zoom when the animation
## ended (the little jerk on entering the aquarium). The animation now ends exactly there.
func _fit_intro_zoom() -> void:
	var cam = _get_player_camera()
	if cam == null or animationtrack == null:
		return
	var vp = get_viewport().get_visible_rect().size
	var w = float(max(1, cam.limit_right - cam.limit_left))
	var h = float(max(1, cam.limit_bottom - cam.limit_top))
	var z = max(2.0, max(vp.x / w, vp.y / h))
	for anim_name in ["INTRO", "RESET"]:
		if not animationtrack.has_animation(anim_name):
			continue
		var anim: Animation = animationtrack.get_animation(anim_name)
		var tr_i = anim.find_track(NodePath("Player/PlayerCamera:zoom"), Animation.TYPE_VALUE)
		if tr_i < 0:
			continue
		var last = anim.track_get_key_count(tr_i) - 1
		if last >= 0:
			anim.track_set_key_value(tr_i, last, Vector2(z, z))
## end of the camera zoom-out in the INTRO animation
const INTRO_ZOOM_END := 2.7

func _update_intro_lock() -> void:
	if not _intro_lock:
		return
	var done = animationtrack == null or not animationtrack.is_playing() or animationtrack.current_animation != "INTRO" \
		or animationtrack.current_animation_position >= INTRO_ZOOM_END
	if done:
		_intro_lock = false
		if player and "can_move" in player and not _cutscene:
			player.can_move = true
	elif player and "can_move" in player:
		player.can_move = false

func _schedule_boring(t: Timer) -> void:
	t.start(randf_range(BORING_INTERVAL_MIN, BORING_INTERVAL_MAX))

func _setup_character_animations() -> void:
	if scientistsprite and scientistsprite.sprite_frames:
		scientistsprite.animation_finished.connect(_on_scientist_animation_finished)
		scientist_boring_timer = _make_boring_timer(_on_scientist_boring_timer)
		scientistsprite.play("idle")
		_schedule_boring(scientist_boring_timer)
	
	if mechanicsprite and mechanicsprite.sprite_frames:
		mechanicsprite.animation_finished.connect(_on_mechanic_animation_finished)
		mechanic_boring_timer = _make_boring_timer(_on_mechanic_boring_timer)
		mechanicsprite.play("idle")
		_schedule_boring(mechanic_boring_timer)

func _make_boring_timer(callback: Callable) -> Timer:
	var t := Timer.new()
	t.one_shot = true
	t.timeout.connect(callback)
	add_child(t)
	return t

func _on_scientist_boring_timer() -> void:
	scientistsprite.play("boring")

func _on_scientist_animation_finished() -> void:
	match scientistsprite.animation:
		"boring":
			scientistsprite.play("idle")
			_schedule_boring(scientist_boring_timer)
		"angry", "angry_end":
			scientistsprite.play("idle")
		"angry_start":
			scientistsprite.play("angry_jump")
			
func _on_mechanic_boring_timer() -> void:
	if not mechanicsprite or mechanicsprite.animation != "idle":
		_schedule_boring(mechanic_boring_timer)
		return
	mechanicsprite.play("boring")

func _on_mechanic_animation_finished() -> void:
	if mechanicsprite.animation == "boring":
		mechanicsprite.play("idle")
		_schedule_boring(mechanic_boring_timer)
		
func _spawn_bubbles() -> void:
	await get_tree().process_frame
	for i in range(6):
		_make_bubble()
		await get_tree().create_timer(0.5).timeout

func _make_bubble() -> void:
	if not bubble_scene:
		return
	
	var bubble = bubble_scene.instantiate()
	add_child(bubble)
	
	bubble.global_position = _get_random_position_with_y_limit(0.0)
	
	var bubble_scale = randf_range(0.35, 0.7)
	bubble.scale = Vector2(bubble_scale, bubble_scale)
	
	bubble.modulate.a = 0.0
	
	var direction_x = randf_range(-0.2, 0.2)
	bubble.set_direction(Vector2(direction_x, -1.0))
	
	var appear_tween = create_tween()
	appear_tween.tween_property(bubble, "modulate:a", randf_range(0.1, 0.5), 0.8)
	
	bubble.start_life(randf_range(5.0, 10.0))
	bubble.clickable = false
	
	if bubble.has_signal("body_entered"):
		bubble.body_entered.connect(_on_bubble_body_entered.bind(bubble))
	
	var spawn_timer = get_tree().create_timer(randf_range(1.5, 3.0), false)
	spawn_timer.timeout.connect(_make_bubble)

func _on_bubble_body_entered(body: Node2D, bubble: Area2D) -> void:
	if body == player and not bubble.popped:
		bubble._pop()

func _get_random_position_with_y_limit(_max_y: float) -> Vector2:
	var area: Rect2 = _get_camera_view_rect().intersection(WATER_RECT)
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		area = WATER_RECT
	
	var y_min = area.position.y + area.size.y * 0.3
	var y_max = area.end.y - 8.0
	return Vector2(
		randf_range(area.position.x + 8.0, area.end.x - 8.0),
		randf_range(y_min, y_max)
	)

func _get_camera_view_rect() -> Rect2:
	var camera = _get_player_camera()
	if not camera:
		return WATER_RECT
	var view_size: Vector2 = get_viewport().get_visible_rect().size / camera.zoom
	return Rect2(camera.get_screen_center_position() - view_size / 2.0, view_size)

func _get_player_camera() -> Camera2D:
	if player and player.has_node("PlayerCamera"):
		return player.get_node("PlayerCamera") as Camera2D
	return get_viewport().get_camera_2d()

func _wait_dialog() -> void:
	var tree = get_tree()
	if not tree:
		return
	await tree.create_timer(1.25).timeout


# ---------------------------------------------------------------------------
# Chatter
# ---------------------------------------------------------------------------

func _start_chatter_after_intro() -> void:
	if animationtrack and animationtrack.is_playing():
		await animationtrack.animation_finished
	await get_tree().create_timer(0.6).timeout
	if not is_inside_tree() or _cutscene:
		return
	_start_background_chatter()


func _start_background_chatter() -> void:
	if chatter == null:
		return
	if chatter.is_active():
		chatter.stop()
	# the talk runs once and ends on the quarrel - it does NOT loop back to calm small talk
	chatter.loop = false
	# listening to the whole thing (the last line is heard) earns the "Кофе бы..." achievement
	if not chatter.line_finished.is_connected(_on_chatter_line_finished):
		chatter.line_finished.connect(_on_chatter_line_finished)
	chatter.start()

## The player overheard the full argument to its end -> the tired "coffee" achievement.
func _on_chatter_line_finished(_line, index: int) -> void:
	if chatter and index >= chatter.lines.size() - 1:
		if has_node("/root/Achievements") and Achievements.has_method("unlock_coffee"):
			Achievements.unlock_coffee()


## Plays a list of lines through a given controller and waits until they are done.
func _run_controller(ctrl: ChatterController) -> void:
	if ctrl == null:
		return
	# Stop the background chatter while this controller runs
	if chatter and chatter.is_active():
		chatter.stop()
	if ctrl.is_active():
		ctrl.stop()
	ctrl.start()
	while ctrl.is_active():
		await get_tree().process_frame
		if not is_inside_tree():
			return


# ---------------------------------------------------------------------------
# Lab lights
# ---------------------------------------------------------------------------

func _setup_lab_lights() -> void:
	if lights_root:
		for l in lights_root.get_children():
			if l is PointLight2D and String(l.name).begins_with("LightLamp"):
				_lamps.append(l)
				_lamp_base.append(l.energy)
				_lamp_k.append(1.0)
	var bg = get_node_or_null("Visual/bg")
	for i in range(_lamps.size()):
		var beam = bg.get_node_or_null("LabBeam" + str(i)) if bg else null
		_beams.append(beam)
		var base := 0.22
		if beam and beam.material is ShaderMaterial:
			var v = (beam.material as ShaderMaterial).get_shader_parameter("intensity")
			if v != null:
				base = float(v)
		_beam_base.append(base)


func _process_lab_lights(dt: float) -> void:
	if _lamps.is_empty() or _quake_on:
		return
	_light_t += dt
	# 30 updates a second are plenty for a lamp hum (8 lamps + 8 shader params per update)
	_light_acc += dt
	if _light_acc < 1.0 / 30.0:
		return
	dt = _light_acc
	_light_acc = 0.0
	# every few seconds one lamp stutters
	_next_blink -= dt
	if _next_blink <= 0.0:
		_next_blink = randf_range(2.5, 7.0)
		_blink_lamp = randi() % _lamps.size()
		_blink_time = randf_range(0.18, 0.45)
	if _blink_time > 0.0:
		_blink_time -= dt
		if _blink_time <= 0.0:
			_blink_lamp = -1
	for i in range(_lamps.size()):
		var hum = 1.0 + 0.035 * sin(_light_t * 7.3 + i * 1.9) + 0.025 * sin(_light_t * 17.1 + i * 4.3)
		if i == _blink_lamp:
			hum *= 0.25 if randf() < 0.5 else randf_range(0.6, 1.05)
		_lamp_k[i] = hum
		_lamps[i].energy = _lamp_base[i] * hum
		var beam = _beams[i]
		if beam and beam.material is ShaderMaterial:
			(beam.material as ShaderMaterial).set_shader_parameter("intensity", _beam_base[i] * hum)


func _setup_npc_shadows() -> void:
	for spr in [scientistsprite, mechanicsprite]:
		if spr == null or not (spr is AnimatedSprite2D):
			continue
		var holder: Node2D = spr.get_parent()
		var copies: Array = []
		for k in range(2):
			var sh = AnimatedSprite2D.new()
			sh.sprite_frames = spr.sprite_frames
			sh.position = spr.position
			sh.rotation = spr.rotation
			sh.scale = spr.scale
			sh.centered = spr.centered
			sh.offset = spr.offset
			sh.modulate = Color(0, 0, 0, 0.0)
			sh.texture_filter = spr.texture_filter
			holder.add_child(sh)
			holder.move_child(sh, 0)
			copies.append(sh)
		var feet_y = NPC_FEET_Y.get(String(holder.name), spr.position.y + 34.0)
		var blob = Polygon2D.new()
		var pts = PackedVector2Array()
		for a in range(16):
			var ang = TAU * a / 16.0
			pts.append(Vector2(cos(ang) * 15.0, sin(ang) * 2.5))
		blob.polygon = pts
		blob.color = Color(0, 0, 0, 0.35)
		blob.position = Vector2(spr.position.x, feet_y - 1.0)
		holder.add_child(blob)
		holder.move_child(blob, 0)
		_npc_shadows.append({"sprite": spr, "holder": holder, "shadows": copies, "blob": blob, "feet": feet_y})


func _setup_toolbox_shadow() -> void:
	var box = get_node_or_null("Visual/stuff/MechanicInstrumentBox1") as Sprite2D
	if box == null or box.texture == null:
		return
	var holder: Node2D = box.get_parent()
	var copies: Array = []
	for k in range(2):
		var sh = Sprite2D.new()
		sh.texture = box.texture
		sh.centered = box.centered
		sh.offset = box.offset
		sh.flip_h = box.flip_h
		sh.region_enabled = box.region_enabled
		sh.region_rect = box.region_rect
		sh.hframes = box.hframes
		sh.vframes = box.vframes
		sh.frame = box.frame
		sh.position = box.position
		sh.scale = box.scale
		sh.rotation = box.rotation
		sh.z_index = box.z_index
		sh.modulate = Color(0, 0, 0, 0.0)
		holder.add_child(sh)
		holder.move_child(sh, box.get_index())
		copies.append(sh)
	var h = box.texture.get_height() * abs(box.scale.y) / (box.vframes if box.vframes > 0 else 1)
	var w = box.texture.get_width() * abs(box.scale.x) / (box.hframes if box.hframes > 0 else 1)
	var bottom = box.position.y + (h * 0.5 if box.centered else h)
	var cx = box.position.x + (0.0 if box.centered else w * 0.5)
	var blob = Polygon2D.new()
	var pts = PackedVector2Array()
	for a in range(16):
		var ang = TAU * a / 16.0
		pts.append(Vector2(cos(ang) * (w * 0.55), sin(ang) * 2.5))
	blob.polygon = pts
	blob.color = Color(0, 0, 0, 0.35)
	blob.position = Vector2(cx, bottom - 1.0)
	blob.z_index = box.z_index
	holder.add_child(blob)
	holder.move_child(blob, box.get_index())
	_box_shadow = {"sprite": box, "shadows": copies}


func _update_box_shadow() -> void:
	if _box_shadow.is_empty() or _lamps.is_empty():
		return
	var box: Sprite2D = _box_shadow["sprite"]
	if not is_instance_valid(box):
		return
	var x = box.global_position.x
	var li = -1
	var ri = -1
	for i in range(_lamps.size()):
		var lx = _lamps[i].global_position.x
		if lx <= x and (li == -1 or lx > _lamps[li].global_position.x):
			li = i
		if lx > x and (ri == -1 or lx < _lamps[ri].global_position.x):
			ri = i
	var sides = [li, ri]
	for k in range(2):
		var sh: Sprite2D = _box_shadow["shadows"][k]
		var i = sides[k]
		if i == -1:
			sh.visible = false
			continue
		var dist = abs(x - _lamps[i].global_position.x)
		var shift = clamp(dist * 0.12, 1.5, 8.0) * (1.0 if k == 0 else -1.0)
		sh.position = box.position + Vector2(shift, 1.0)
		sh.skew = clamp(-shift * 0.04, -0.3, 0.3)
		var lamp_k = _lamp_k[i] if i < _lamp_k.size() else 1.0
		sh.modulate = Color(0, 0, 0, clamp(0.32 - dist * 0.0012, 0.12, 0.3) * lamp_k)


func _keep_fish_on_screen() -> void:
	if player == null or _cutscene:
		return
	if animationtrack and animationtrack.is_playing() and animationtrack.current_animation == "INTRO":
		return
	var cam = _get_player_camera()
	if cam == null:
		return
	var half = get_viewport().get_visible_rect().size / cam.zoom / 2.0
	var c = cam.global_position
	var m = 14.0
	var p = player.global_position
	var lo = c - half + Vector2(m, m)
	var hi = c + half - Vector2(m, m)
	var np = Vector2(clamp(p.x, lo.x, hi.x), clamp(p.y, lo.y, hi.y))
	if np != p:
		player.global_position = np
		if "velocity" in player:
			var v: Vector2 = player.velocity
			if np.x != p.x:
				v.x = 0.0
			if np.y != p.y:
				v.y = 0.0
			player.velocity = v


func _update_npc_shadows() -> void:
	if _npc_shadows.is_empty() or _lamps.is_empty():
		return
	for d in _npc_shadows:
		var spr: AnimatedSprite2D = d["sprite"]
		if not is_instance_valid(spr):
			continue
		var x = spr.global_position.x
		# nearest lamp on each side (lamp x positions are cached, the lamps never move)
		if _lamp_x.size() != _lamps.size():
			_lamp_x.clear()
			for l in _lamps:
				_lamp_x.append(l.global_position.x)
		var li = -1
		var ri = -1
		for i in range(_lamp_x.size()):
			var lx = _lamp_x[i]
			if lx <= x and (li == -1 or lx > _lamp_x[li]):
				li = i
			if lx > x and (ri == -1 or lx < _lamp_x[ri]):
				ri = i
		var sides = [li, ri]
		for k in range(2):
			var sh: AnimatedSprite2D = d["shadows"][k]
			var i = sides[k]
			if i == -1:
				sh.visible = false
				continue
			sh.visible = spr.visible
			if sh.animation != spr.animation:
				sh.animation = spr.animation
			sh.frame = spr.frame
			sh.flip_h = spr.flip_h
			var dist = abs(x - _lamp_x[i])
			var away = 1.0 if k == 0 else -1.0   # a lamp on the left throws the shadow right
			var shift = clamp(dist * 0.16, 2.0, 11.0) * away
			sh.position = spr.position + Vector2(shift, 1.0)
			sh.skew = clamp(-shift * 0.03, -0.3, 0.3)
			var lamp_k = _lamp_k[i] if i < _lamp_k.size() else 1.0
			sh.modulate = Color(0, 0, 0, clamp(0.32 - dist * 0.0012, 0.12, 0.3) * lamp_k * spr.modulate.a)
		var blob: Polygon2D = d["blob"]
		blob.position.x = spr.position.x
		blob.color.a = 0.32 * spr.modulate.a


# ---------------------------------------------------------------------------
# Panic during the earthquake
# ---------------------------------------------------------------------------

func _start_panic() -> void:
	if _panicking:
		return
	_panicking = true
	for t in [scientist_boring_timer, mechanic_boring_timer]:
		if t:
			t.stop()
	var i := 0
	for spr in [scientistsprite, mechanicsprite]:
		if spr and spr is AnimatedSprite2D:
			_panic(spr, i)
		i += 1


func _panic(spr: AnimatedSprite2D, idx: int) -> void:
	var holder: Node2D = spr.get_parent()
	var base_pos = holder.position
	var anim = _ensure_panic_anim(spr, String(holder.name))
	spr.play(anim)
	spr.speed_scale = 1.0
	var tex = spr.sprite_frames.get_frame_texture(spr.animation, 0) if spr.sprite_frames else null
	var head_y = spr.position.y - (tex.get_height() * abs(spr.scale.y) * 0.5 if tex else 30.0) - 4.0
	var t := 0.0
	var target_x = base_pos.x
	var retarget := 0.0
	var sweat := 0.6
	var vx := 0.0
	var hop_t := 0.0
	var delay = 0.35 + 0.25 * idx
	while _panicking and is_inside_tree() and is_instance_valid(spr):
		var dt = get_process_delta_time()
		t += dt
		retarget -= dt
		var ramp = clamp((t - delay) / 2.0, 0.0, 1.0)
		ramp = ramp * ramp * (3.0 - 2.0 * ramp)
		if spr.animation != anim:
			spr.play(anim)
		if anim != "panic":
			spr.speed_scale = lerp(1.0, 3.2, ramp)
		if retarget <= 0.0:
			retarget = randf_range(0.35, 0.8) * lerp(1.6, 1.0, ramp)
			target_x = base_pos.x + randf_range(-1.0, 1.0) * lerp(6.0, 24.0, ramp) + (6.0 if idx == 0 else -6.0) * ramp
		var dx = target_x - holder.position.x
		var want = clamp(dx * 6.0, -1.0, 1.0) * lerp(20.0, 85.0, ramp)
		vx = lerp(vx, want, 1.0 - exp(-5.0 * dt))
		holder.position.x += vx * dt
		if abs(vx) > 6.0:
			spr.flip_h = (vx < 0.0) != (idx == 1)
		hop_t += dt * lerp(8.0, 16.0, ramp)
		holder.position.y = base_pos.y - round(abs(sin(hop_t + idx)) * 3.0 * ramp)
		sweat -= dt
		if sweat <= 0.0:
			sweat = randf_range(0.15, 0.35)
			_sweat_drop(holder, Vector2(spr.position.x + randf_range(-8, 8), head_y + 6))
		await get_tree().process_frame
	if is_instance_valid(spr):
		spr.speed_scale = 1.0


func _ensure_panic_anim(spr: AnimatedSprite2D, who: String) -> String:
	var sf = spr.sprite_frames
	if sf == null:
		return "idle"
	if sf.has_animation("panic"):
		return "panic"
	var paths: Array = PANIC_FRAMES.get(who, [])
	var texs: Array = []
	for p in paths:
		if ResourceLoader.exists(p):
			texs.append(load(p))
	if texs.size() < 2:
		return "idle"
	sf.add_animation("panic")
	sf.set_animation_loop("panic", true)
	sf.set_animation_speed("panic", 9.0)
	for tx in texs:
		sf.add_frame("panic", tx)
	return "panic"


func _sweat_drop(holder: Node2D, at: Vector2) -> void:
	var d = ColorRect.new()
	d.color = Color(0.6, 0.85, 1.0, 0.9)
	d.size = Vector2(2, 3)
	d.position = at
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(d)
	var tw = create_tween()
	var side = randf_range(-10, 10)
	tw.tween_property(d, "position", at + Vector2(side, 14), 0.45).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(d, "modulate:a", 0.0, 0.45)
	tw.tween_callback(d.queue_free)


# ---------------------------------------------------------------------------
# Hitting the glass
# ---------------------------------------------------------------------------

func _make_glass_hint() -> void:
	_hint_layer = CanvasLayer.new()
	_hint_layer.layer = 3
	_hint_layer.follow_viewport_enabled = true
	add_child(_hint_layer)
	if has_node("/root/InputRebind"):
		_hint_key_text = InputRebind.get_key_text("interact")
	if _hint_key_text.length() > 3:
		_hint_key_text = _hint_key_text.substr(0, 3)
	_hint_font = load("res://GameAssets/Fonts/MainFont/FontFiles/MainFont_Font.ttf")
	_glass_glow = Node2D.new()
	_glass_glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_glass_glow.draw.connect(_draw_glass_glow)
	_hint_layer.add_child(_glass_glow)
	_hint = Node2D.new()
	_hint.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hint.position = Vector2(GLASS_HIT_X, GLASS_TOP_Y - 16)
	_hint.modulate.a = 0.0
	_hint.draw.connect(_draw_key)
	_hint_layer.add_child(_hint)


func _draw_glass_glow() -> void:
	var t = Time.get_ticks_msec() / 1000.0
	var pulse = 0.5 + 0.5 * sin(t * 2.4)
	var a = (0.10 + 0.06 * pulse) * (0.6 + 1.4 * _glow_power)
	var c = Color(0.62, 0.9, 1.0)
	var steps = 8
	for i in range(steps):
		var k = float(i) / steps
		var w = GLASS_HALF_W * (1.0 - k)
		_glass_glow.draw_rect(Rect2(GLASS_HIT_X - w, GLASS_TOP_Y, w * 2.0, GLASS_BOTTOM_Y - GLASS_TOP_Y), Color(c, a * 0.35))
	for i in range(5):
		var h = 3.0 + i * 3.0
		var w2 = GLASS_HALF_W * (0.75 - i * 0.12)
		_glass_glow.draw_rect(Rect2(GLASS_HIT_X - w2, GLASS_TOP_Y - h, w2 * 2.0, h), Color(c, a * 0.18))
	_glass_glow.draw_rect(Rect2(GLASS_HIT_X - GLASS_HALF_W * 0.8, GLASS_TOP_Y, GLASS_HALF_W * 1.6, 1), Color(1, 1, 1, a * 1.4))
	var s = fmod(t, 3.2) / 1.2
	if s < 1.0:
		var sx = GLASS_HIT_X - GLASS_HALF_W + s * GLASS_HALF_W * 2.0
		for j in range(4):
			_glass_glow.draw_rect(Rect2(sx + j * 2 - 4, GLASS_TOP_Y + 1 + j * 2, 3, 2), Color(1, 1, 1, a * 2.2))


func _draw_key() -> void:
	var t = Time.get_ticks_msec() / 1000.0
	var pressed = fmod(t, 1.1) > 0.85
	var dip = 2.0 if pressed else 0.0
	var w = max(17.0, 6.0 * _hint_key_text.length() + 9.0)
	var x0 = round(-w / 2.0)
	var y0 = -8.0
	var pulse = 0.5 + 0.5 * sin(t * 4.0)
	var glow = Color(0.55, 0.88, 1.0)
	for i in range(3):
		_hint.draw_circle(Vector2(0, 0), 15.0 - i * 3.0, Color(glow, (0.05 + 0.03 * i) * (0.6 + 0.4 * pulse)))
	var rt = fmod(t, 1.4) / 1.4
	_hint.draw_arc(Vector2(0, 0), 9.0 + rt * 12.0, 0.0, TAU, 40, Color(0.7, 0.93, 1.0, 0.55 * (1.0 - rt)), 1.0)
	var o = Color(0.08, 0.09, 0.12)
	_hint.draw_rect(Rect2(x0, y0 + 1, w, 15), o)
	_hint.draw_rect(Rect2(x0 + 1, y0, w - 2, 17), o)
	_hint.draw_rect(Rect2(x0 + 1, y0 + 1, w - 2, 15), Color(0.35, 0.39, 0.48))
	_hint.draw_rect(Rect2(x0 + 1, y0 + 15, w - 2, 1), Color(0.24, 0.27, 0.34))
	_hint.draw_rect(Rect2(x0 + 1, y0 + 1 + dip, w - 2, 6), Color(0.95, 0.96, 0.98))
	_hint.draw_rect(Rect2(x0 + 1, y0 + 7 + dip, w - 2, 5), Color(0.83, 0.86, 0.91))
	_hint.draw_rect(Rect2(x0 + 2, y0 + 2 + dip, w - 4, 1), Color(1, 1, 1))
	_hint.draw_rect(Rect2(x0 + 2, y0 + 3 + dip, 1, 3), Color(1, 1, 1, 0.8))
	_hint.draw_rect(Rect2(x0 + 1, y0 + 12 + dip, w - 2, 1), Color(0.65, 0.69, 0.77))
	if _hint_font:
		var tw = _hint_font.get_string_size(_hint_key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var base_y = y0 + 3 + dip + _hint_font.get_ascent(8)
		var lx = round(-tw / 2.0)
		_hint.draw_string(_hint_font, Vector2(lx, base_y + 1), _hint_key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.6))
		_hint.draw_string(_hint_font, Vector2(lx, base_y), _hint_key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.16, 0.18, 0.25))
	for i in range(3):
		var a = t * 1.3 + i * 2.1
		var s = 0.5 + 0.5 * sin(t * 6.0 + i * 2.0)
		var p = Vector2(round(cos(a) * 14.0), round(sin(a) * 12.0))
		var sc = Color(1.0, 0.96, 0.7, s)
		_hint.draw_rect(Rect2(p, Vector2.ONE), sc)
		if s > 0.6:
			for dv in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				_hint.draw_rect(Rect2(p + dv, Vector2.ONE), Color(sc, s * 0.6))
	var ay = y0 + 20.0 + round(sin(t * 5.0))
	var widths = [7, 5, 3, 1]
	for i in range(widths.size()):
		var wd = widths[i]
		_hint.draw_rect(Rect2(-floor(wd / 2.0) - 1, ay + i, wd + 2, 1), Color(0.16, 0.11, 0.03))
	var inner = [5, 3, 1]
	for i in range(inner.size()):
		var wd2 = inner[i]
		_hint.draw_rect(Rect2(-floor(wd2 / 2.0), ay + i, wd2, 1), Color(1.0, 0.84, 0.35))

## Mini tutorial: swim -> go listen at the glass -> hit the crack.
func _tutorial_tick(dt: float) -> void:
	if _tut == null:
		return
	if animationtrack and animationtrack.is_playing() and animationtrack.current_animation == "INTRO":
		return
	_tut_t += dt
	if _intro_lock:
		return
	_tut.hint("a_swim", tr("ПЛАВАТЬ|W A S D — плыть в любую сторону"), ["W", "A", "S", "D"],
		func(): return player.get("velocity") is Vector2 and (player.get("velocity") as Vector2).length() > 30.0, 2.0, 8.0)


func _process(_delta: float) -> void:
	_update_intro_lock()
	_process_lab_lights(get_process_delta_time())
	_update_npc_shadows()
	_update_box_shadow()
	_keep_fish_on_screen()
	if player and _cutscene and "can_move" in player and player.can_move:
		player.can_move = false
	var dt = get_process_delta_time()
	if player == null or _cutscene:
		_in_glass_zone = false
		_glow_power = move_toward(_glow_power, 0.0, dt * 2.0)
		if _glass_glow:
			_glass_glow.modulate.a = move_toward(_glass_glow.modulate.a, 0.0, dt * 1.5)
			_glass_glow.queue_redraw()
		return
	_in_glass_zone = GLASS_ZONE.has_point(player.global_position)
	_tutorial_tick(dt)
	_hint_alpha = move_toward(_hint_alpha, 1.0 if _in_glass_zone else 0.0, dt * 5.0)
	_glow_power = move_toward(_glow_power, 1.0 if _in_glass_zone else 0.0, dt * 3.0)
	if _hint:
		_hint.modulate.a = _hint_alpha
		_hint.position = Vector2(GLASS_HIT_X, GLASS_TOP_Y - 24 + round(sin(Time.get_ticks_msec() / 260.0)))
		_hint.queue_redraw()
	if _glass_glow:
		_glass_glow.queue_redraw()


func _start_glass_cutscene() -> void:
	if _cutscene or _ending:
		return
	_cutscene = true
	_ending = true
	# whatever they were saying breaks off: "..." - then the cutscene
	if chatter and chatter.is_active():
		chatter.interrupt()
	for bt in [scientist_boring_timer, mechanic_boring_timer]:
		if bt:
			bt.stop()
	if _hint:
		var ht = create_tween()
		ht.tween_property(_hint, "modulate:a", 0.0, 0.2)
	if player and "can_move" in player:
		player.can_move = false
	_hide_player_ui()
	if player and player.has_method("hit_glass"):
		player.hit_glass()
	var cam = _get_player_camera()
	if cam and cam.has_method("begin_cutscene"):
		cam.begin_cutscene()
	elif cam and "look_amount" in cam:
		cam.look_amount = 0.0
	await get_tree().create_timer(0.25).timeout
	if not is_inside_tree():
		return
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.45)
	UISounds.play_hit()
	_flash(Color(1, 1, 1, 0.35), 0.25)
	_letterbox(true)
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	var waited := 0.0
	while player and "shake_amount" in player and float(player.shake_amount) > 0.0 and waited < 1.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
	if player and "shake_amount" in player:
		player.shake_amount = 0.0
	if player and "can_move" in player:
		player.can_move = false
	if cam:
		var npc_pos = (scientistsprite.global_position + mechanicsprite.global_position) * 0.5 if scientistsprite and mechanicsprite else cam.global_position
		if not cam.has_method("begin_cutscene"):
			var gp = cam.global_position
			cam.top_level = true
			cam.global_position = gp
		var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		var z = cam.zoom * 1.7
		if "limit_bottom" in cam:
			var bar_world = round(get_viewport().get_visible_rect().size.y * LETTERBOX_K) / z.y
			cam.limit_bottom = int(BG_RECT.end.y + bar_world)
		var half_y = get_viewport().get_visible_rect().size.y / z.y / 2.0
		var end_pos = npc_pos + Vector2(0, 26)
		if "limit_bottom" in cam:
			end_pos.y = min(end_pos.y, cam.limit_bottom - half_y - 5.0)
		tw.tween_property(cam, "global_position", end_pos, 1.6)
		tw.parallel().tween_property(cam, "zoom", z, 1.6)
	# Bubble scale: cutscene controller uses full size bubbles
	var cbox = cutscene_chatter.find_child("ChatterBox", true, false) if cutscene_chatter else null
	if cbox and "bubble_scale" in cbox:
		if "force_near" in cbox:
			cbox.force_near = true
		var bt = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		bt.tween_property(cbox, "bubble_scale", 1.0, 1.6)
	# Also scale the main chatter box to 1.0 (it's being stopped, but just in case)
	var cbox2 = chatter.find_child("ChatterBox", true, false) if chatter else null
	if cbox2 and "bubble_scale" in cbox2:
		if "force_near" in cbox2:
			cbox2.force_near = true
		var bt2 = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		bt2.tween_property(cbox2, "bubble_scale", 1.0, 1.6)
	_angry_jump()
	await get_tree().create_timer(0.7).timeout
	if not is_inside_tree():
		return
	await _run_controller(cutscene_chatter)
	if not is_inside_tree():
		return
	if player and "can_move" in player:
		player.can_move = false
	if player and "velocity" in player:
		player.velocity = Vector2.ZERO
	_play_earthquake()


const ANGRY_DIR := "res://GameAssets/Sprites/EntitySprites/NPCSprites/ScientistNpcSprites/ScientistAnimationFrames/"
## the scientist's angry jumping, in three sprite lists: he starts jumping, jumps (looped, while
## he says his two lines) and stops when the mechanic starts talking
func _setup_angry_anims() -> void:
	if scientistsprite == null or scientistsprite.sprite_frames == null:
		return
	var sf: SpriteFrames = scientistsprite.sprite_frames
	for a in [["angry_start", "NPC_Scientist_AngryStart_SpriteList_Animation.png", false, 10.0],
			["angry_jump", "NPC_Scientist_AngryJump_SpriteList_Animation.png", true, 10.0],
			["angry_end", "NPC_Scientist_AngryEnd_SpriteList_Animation.png", false, 10.0]]:
		if sf.has_animation(a[0]):
			continue
		var tex = load(ANGRY_DIR + a[1]) as Texture2D
		if tex == null:
			continue
		sf.add_animation(a[0])
		sf.set_animation_loop(a[0], a[2])
		sf.set_animation_speed(a[0], a[3])
		var fh = tex.get_height()
		for i in range(int(float(tex.get_width()) / float(fh))):
			var at = AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * fh, 0, fh, fh)
			sf.add_frame(a[0], at)

func _angry_jump() -> void:
	if scientistsprite == null or scientistsprite.sprite_frames == null:
		return
	_setup_angry_anims()
	var sf = scientistsprite.sprite_frames
	if not sf.has_animation("angry_start"):
		if sf.has_animation("angry"):
			scientistsprite.play("angry")
		return
	scientistsprite.play("angry_start")
	if cutscene_chatter and not cutscene_chatter.line_shown.is_connected(_on_cutscene_line):
		cutscene_chatter.line_shown.connect(_on_cutscene_line)
		cutscene_chatter.chatter_stopped.connect(_stop_angry_jump)

func _on_cutscene_line(line, _i) -> void:
	if line and line.speaker == ChatterLine.Speaker.MECHANIC:
		_stop_angry_jump()

func _stop_angry_jump() -> void:
	if scientistsprite and String(scientistsprite.animation).begins_with("angry_") and scientistsprite.animation != "angry_end":
		scientistsprite.play("angry_end")

func _hide_player_ui() -> void:
	if player == null:
		return
	var gui = player.get_node_or_null("GUI")
	if gui == null:
		return
	if animationtrack and animationtrack.is_playing():
		animationtrack.stop(true)
	for c in gui.get_children():
		if c is CanvasItem and c.visible:
			var tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(c, "modulate:a", 0.0, 0.6)


func _letterbox(on: bool) -> void:
	if _bars == null:
		_bars = CanvasLayer.new()
		_bars.layer = 60
		add_child(_bars)
		for i in range(2):
			var r = ColorRect.new()
			r.color = Color.BLACK
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_bars.add_child(r)
	var vp = get_viewport().get_visible_rect().size
	var h = round(vp.y * LETTERBOX_K)
	var top: ColorRect = _bars.get_child(0)
	var bottom: ColorRect = _bars.get_child(1)
	top.size = Vector2(vp.x, h)
	bottom.size = Vector2(vp.x, h)
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(top, "position:y", 0.0 if on else -h, 0.6).from(-h if on else 0.0)
	tw.parallel().tween_property(bottom, "position:y", vp.y - h if on else vp.y, 0.6).from(vp.y if on else vp.y - h)


func _flash(c: Color, time: float) -> void:
	var layer = CanvasLayer.new()
	layer.layer = 61
	add_child(layer)
	var r = ColorRect.new()
	r.color = c
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(r)
	var tw = create_tween()
	tw.tween_property(r, "modulate:a", 0.0, time)
	tw.tween_callback(layer.queue_free)

func _quake_shake(duration: float, lights: Array, base_energy: Array) -> void:
	var t := 0.0
	var flicker_timer := 0.0
	var cam = _get_player_camera()
	var jolt_timer := 0.35
	var dust_timer := 0.0
	var jolts := 0
	var alarm = _make_alarm_overlay()
	while t < duration:
		var dt = get_process_delta_time()
		t += dt
		var kk = clamp(t / duration, 0.0, 1.0)
		jolt_timer -= dt
		if jolt_timer <= 0.0:
			jolt_timer = randf_range(0.55, 1.2) * lerp(1.0, 0.6, kk)
			jolts += 1
			_quake_jolt(cam, kk, jolts)
		_jolt_rot = move_toward(_jolt_rot, 0.0, dt * 0.25)
		dust_timer -= dt
		if dust_timer <= 0.0:
			dust_timer = lerp(0.12, 0.04, kk)
			_spawn_dust(cam, 1 + int(kk * 2.0))
		if alarm:
			alarm.color.a = (0.05 + 0.1 * kk) * (0.5 + 0.5 * sin(t * 7.0))
		var k = clamp(t / duration, 0.0, 1.0)
		var onset = clamp(t / 0.3, 0.0, 1.0)
		onset = onset * onset * (3.0 - 2.0 * onset)
		if cam:
			if "trauma" in cam:
				cam.trauma = max(float(cam.trauma), lerp(0.45, 0.8, k) * onset)
			elif cam.has_method("add_trauma"):
				cam.add_trauma(0.2)
			cam.rotation = randf_range(-1.0, 1.0) * lerp(0.018, 0.05, k) * onset + _jolt_rot
		UISounds.set_glitch(k)
		flicker_timer -= dt
		if flicker_timer <= 0.0:
			flicker_timer = randf_range(0.04, 0.18)
			for i in range(lights.size()):
				var on = randf() > lerp(0.1, 0.65, k)
				lights[i].energy = base_energy[i] * (randf_range(0.7, 1.25) if on else 0.05)
		await get_tree().process_frame
		if not is_inside_tree():
			return
	if cam:
		cam.rotation = 0.0


func _make_alarm_overlay() -> ColorRect:
	var layer = CanvasLayer.new()
	layer.layer = 55
	add_child(layer)
	var r = ColorRect.new()
	r.color = Color(1.0, 0.08, 0.05, 0.0)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(r)
	return r


func _quake_jolt(cam: Camera2D, k: float, _n: int) -> void:
	if cam:
		if "trauma" in cam:
			cam.trauma = min(1.0, float(cam.trauma) + lerp(0.25, 0.45, k))
		_jolt_rot = randf_range(-1.0, 1.0) * lerp(0.03, 0.06, k)
		var z0 = cam.zoom
		var zt = create_tween()
		zt.tween_property(cam, "zoom", z0 * 1.035, 0.06).set_ease(Tween.EASE_OUT)
		zt.tween_property(cam, "zoom", z0, 0.22).set_ease(Tween.EASE_IN_OUT)
	_spawn_dust(cam, 10)
	for l in _lamps:
		l.energy *= 0.2


func _spawn_dust(cam: Camera2D, count: int) -> void:
	if cam == null:
		return
	var half = get_viewport().get_visible_rect().size / cam.zoom / 2.0
	var c = cam.global_position
	for i in range(count):
		var d = ColorRect.new()
		var big = randf() < 0.2
		d.size = Vector2(2, 2) if big else Vector2(1, 1)
		d.color = Color(0.55, 0.52, 0.48, 0.9) if big else Color(0.75, 0.72, 0.66, 0.7)
		d.position = Vector2(c.x + randf_range(-half.x, half.x), c.y - half.y - 4.0)
		d.z_index = 30
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(d)
		var fall = randf_range(0.7, 1.4) if big else randf_range(1.2, 2.2)
		var tw = d.create_tween()
		tw.tween_property(d, "position", d.position + Vector2(randf_range(-10, 10), half.y * 2.0 + 10.0), fall).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(d, "modulate:a", 0.0, fall).set_delay(fall * 0.6)
		tw.tween_callback(d.queue_free)


func _play_earthquake() -> void:
	UISounds.play_earthquake()
	_quake_on = true
	var qcam = _get_player_camera()
	if qcam:
		if "shake_mult" in qcam:
			qcam.shake_mult = 1.7
		if "shake_bounds" in qcam:
			qcam.shake_bounds = BG_RECT
	var lights: Array = _lamps.duplicate()
	var base_energy: Array = _lamp_base.duplicate()
	_start_panic()
	_quake_shake(QUAKE_DURATION + 6.0, lights, base_energy)
	var qbox = quake_chatter.find_child("ChatterBox", true, false) if quake_chatter else null
	if qbox and "bubble_scale" in qbox:
		qbox.bubble_scale = 1.0
		qbox._scale_cur = 0.0
		if "force_near" in qbox:
			qbox.force_near = true
	# Track the last quake line to know when to trigger the debris
	var hit := [false]
	var last = quake_chatter.lines.size() - 1
	var on_line = func(_l, i):
		if i >= last:
			hit[0] = true
	if quake_chatter and quake_chatter.has_signal("line_shown"):
		quake_chatter.line_shown.connect(on_line)
	_run_controller(quake_chatter)
	while not hit[0] and quake_chatter and quake_chatter.is_active():
		await get_tree().process_frame
		if not is_inside_tree():
			return
	# "МЫ НЕ УСПЕ..." — cut off mid-word by the falling slab
	await get_tree().create_timer(0.45).timeout
	if not is_inside_tree():
		return
	if quake_chatter and quake_chatter.line_shown.is_connected(on_line):
		quake_chatter.line_shown.disconnect(on_line)
	_knockout_fish()
	_spawn_falling_debris()
	_panicking = false
	await get_tree().create_timer(0.7).timeout
	if not is_inside_tree():
		return
	for ctrl in [chatter, cutscene_chatter, quake_chatter]:
		if ctrl and ctrl.is_active():
			ctrl.stop()
	await get_tree().create_timer(0.1).timeout
	if not is_inside_tree():
		return
	# blackout
	for l in lights:
		l.energy = 0.0
	if fade_rect:
		fade_rect.visible = true
		var tw = create_tween()
		tw.tween_property(fade_rect, "modulate:a", 1.0, 1.4)
		await tw.finished
	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree():
		return
	UISounds.stop_earthquake()
	var title_layer = await _show_flashback_title()
	if not is_inside_tree():
		return
	UISounds.set_glitch(0.0)
	UISounds.stop_factory_ambience()
	Global.prologue1_completed = true
	Global.reset_factory_progress()
	Global.autosave(Global.SCENE_FACTORY)
	# the title stays on screen through the scene change and only then dissolves into the
	# factory (it lives on the root, above the global fade)
	if title_layer:
		title_layer.set_meta("go", true)
	Global.goto_scene(Global.SCENE_FACTORY)

func _knockout_fish() -> void:
	if player == null:
		return
	if "can_move" in player:
		player.can_move = false
	player.velocity = Vector2.ZERO
	var spr = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr == null or spr.sprite_frames == null:
		return
	if spr.sprite_frames.has_animation("wake"):
		spr.play("wake")
		spr.speed_scale = -1.0
		spr.frame = spr.sprite_frames.get_frame_count("wake") - 1
	var tw = create_tween()
	tw.tween_property(spr, "modulate", Color(0.4, 0.4, 0.5, 1.0), 1.2)


func _spawn_falling_debris() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	var vp = get_viewport().get_visible_rect().size
	var debris = Node2D.new()
	layer.add_child(debris)
	var bw = 340.0
	var bh = 200.0
	var tw_ = 90.0
	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-60, -1500), Vector2(vp.x + 60, -1500), Vector2(vp.x + 60, -bh),
		Vector2(vp.x - tw_ + 60, -bh), Vector2(vp.x - tw_ + 60, -tw_), Vector2(vp.x - bw + 60, -tw_),
		Vector2(vp.x - bw + 60, 0), Vector2(-60, 0)])
	body.color = Color(0.06, 0.06, 0.08)
	debris.add_child(body)
	for r in [[Vector2(vp.x - bw + 60, 0), Vector2(vp.x - bw + 40, 70)], [Vector2(vp.x - bw + 120, 0), Vector2(vp.x - bw + 110, 100)],
			[Vector2(vp.x - bw + 220, 0), Vector2(vp.x - bw + 240, 80)], [Vector2(vp.x - tw_ + 60, -tw_), Vector2(vp.x - tw_ + 120, -tw_ - 60)]]:
		var rebar = Line2D.new()
		rebar.width = 4
		rebar.default_color = Color(0.35, 0.25, 0.2)
		rebar.points = PackedVector2Array(r)
		debris.add_child(rebar)
	for i in range(10):
		var chip = ColorRect.new()
		chip.color = Color(0.08, 0.08, 0.1)
		chip.size = Vector2(randf_range(6, 20), randf_range(6, 20))
		chip.position = Vector2(randf_range(60, vp.x - 60), randf_range(-140, -40))
		layer.add_child(chip)
		var ct = create_tween()
		ct.tween_property(chip, "position:y", vp.y + 40, randf_range(0.15, 0.3))
		ct.tween_callback(chip.queue_free)
	var tw = create_tween()
	tw.tween_property(debris, "position:y", vp.y + 200, 0.18).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		var black = ColorRect.new()
		black.color = Color.BLACK
		black.size = vp
		layer.add_child(black)
	)
	var cam = _get_player_camera()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.8)


## Small helper script for the title overlay: waits until the factory is really there, then
## fades the words and the black away.
const _TITLE_FADE_SRC := """extends CanvasLayer
var _scene_id := 0
var _t := 0.0
var _phase := 0
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_scene_id = get_tree().current_scene.get_instance_id() if get_tree().current_scene else 0
func _process(delta):
	if not has_meta("go"):
		return
	var sc = get_tree().current_scene
	if _phase == 0:
		if sc and sc.get_instance_id() != _scene_id:
			_phase = 1
			_t = 0.0
		return
	_t += min(delta, 0.05)
	if _phase == 1 and _t > 0.9:
		_phase = 2
		var tw = create_tween()
		tw.tween_property(get_node("Title"), "modulate:a", 0.0, 0.7)
		tw.tween_property(get_node("Black"), "modulate:a", 0.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(queue_free)
"""

func _show_flashback_title() -> CanvasLayer:
	var layer = CanvasLayer.new()
	layer.layer = 1030   # over the global fade: the black never blinks during the change
	var src = GDScript.new()
	src.source_code = _TITLE_FADE_SRC
	if src.reload() == OK:
		layer.set_script(src)
	get_tree().root.add_child(layer)
	var rect = ColorRect.new()
	rect.color = Color.BLACK
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.name = "Black"
	layer.add_child(rect)
	var label = Label.new()
	label.name = "Title"
	label.text = "Пару дней назад..."
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	var tf = load("res://GameAssets/Fonts/MainFont/FontFiles/MainFont_Font.ttf")
	if tf:
		label.add_theme_font_override("font", tf)
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.0))
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.modulate.a = 0.0
	layer.add_child(label)
	if has_node("/root/Achievements") and Achievements.has_method("unlock_flashback"):
		Achievements.unlock_flashback()
	var tw = create_tween()
	tw.tween_property(label, "modulate:a", 1.0, 1.0)
	tw.tween_interval(1.4)
	await tw.finished
	return layer


# ---------------------------------------------------------------------------
# Pause
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_toggle_pause()
		return
	if _cutscene and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		for ctrl in [cutscene_chatter, quake_chatter]:
			if ctrl and ctrl.is_active() and ctrl.skippable:
				get_viewport().set_input_as_handled()
				ctrl.skip_line()
				return
	if _in_glass_zone and not _cutscene and (event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E)):
		get_viewport().set_input_as_handled()
		_start_glass_cutscene()

func _toggle_pause() -> void:
	if pausemenu == null or _ending:
		return
	if get_tree().paused:
		get_tree().paused = false
		GlobalMusic.restore_volume()
		UISounds.restore_ambience()
		for ctrl in [chatter, cutscene_chatter, quake_chatter]:
			if ctrl:
				ctrl.resume_chatter()
		if pausemenu.has_method("hide_menu"):
			pausemenu.hide_menu()
		else:
			pausemenu.visible = false
	else:
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GlobalMusic.lower_volume()
		UISounds.lower_ambience()
		for ctrl in [chatter, cutscene_chatter, quake_chatter]:
			if ctrl:
				ctrl.pause_chatter()
		if pausemenu.has_method("show_menu"):
			pausemenu.show_menu()
		else:
			pausemenu.visible = true
