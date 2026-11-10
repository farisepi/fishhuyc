extends Node
## The maintenance room: where the fish sleep between shifts. A calm hub with no clock and no
## guard: bunks, nightstands, lockers, the other fish resting. The fish don't talk, but walking
## up to one and pressing E makes it answer with a little sign. The player's own bunk is marked;
## lying down on it -> sleep -> (the dream, if the next shift brings something new) -> morning:
## everybody walks out of the door on the left, the player follows -> "finished".
## Built from code far right of the hall (x ~ 6000) with its own floor and walls.

signal finished

const RX := 6000.0                 # the middle of the room
const PX := 3.0                    # the art is drawn in 3x pixels, like the hall tiles
const BACK_W := 292.0              # the back texture, native pixels
const BACK_FLOOR := 76.0           # its floor row
const LEFT := RX - BACK_W * PX * 0.5
const HALF := BACK_W * PX * 0.5 - 4.0
const FLOOR_Y := 380.0
const CEIL_Y := FLOOR_Y - BACK_FLOOR * PX
const DOOR_X := LEFT + 6.0 * PX + 49.5   # the exit, left (the hall's iron door)
const BUNK_XS := [RX - 190.0, RX, RX + 190.0]
const BUNK_W := 38.0
const BUNK_H := 49.0
const MY_BUNK := 2                 # the right bunk, lower bed
const LOCKER_X := RX + 300.0
const TEX_DIR := "res://GameAssets/LevelAssets/ActPrologue/FactoryLevelAssets/FactoryMaintRoomTextures/"
const DOOR_TEX := "res://GameAssets/LevelAssets/ActPrologue/FactoryLevelAssets/FactoryTilesetTextures/ActPrologue_LevelFactory_TileSet_IronDoor_Texture.png"
const LAMP_TEX := "res://GameAssets/LevelAssets/SharedLevelAssets/Shared_HangingLamp_Texture.png"
const CONE_TEX := "res://GameAssets/Sprites/UserInterfaceSprites/LightTextures/Light_Option9_Texture.png"
const NPC_DIR := "res://GameAssets/Sprites/EntitySprites/NPCSprites/MechaFishNPCSprites/"
const SLEEP_TEX := {
	"WithScar": "ScarMechaFishFrames/NPC_MechaFish_WithScar_Sleep_SpriteList_Animation.png",
	"WithBigEyes": "BigEyesMechaFishFrames/NPC_MechaFish_WithBigEyes_Sleep_SpriteList_Animation.png",
	"WithFunnyHat": "FunnyHatMechaFishFrames/NPC_MechaFish_WithFunnyHat_Sleep_SpriteList_Animation.png",
	"WithOutHand": "WithOutHandMechaFishFrames/NPC_MechaFish_WithOutHand_Sleep_SpriteList_Animation.png",
}
const NEAR := 46.0
const EMOTES := ["...", "?", "!", "zZ", "~", "<3", ":)", "..?"]

var L = null
var _built: bool = false
var _view: Node2D = null
var _body: StaticBody2D = null
var _on: bool = false
var _busy: bool = false
var _morning: bool = false
var _t: float = 0.0
var _emotes: Array = []            # [{fish, text, t}]
var _saved_npc: Array = []         # [[node, pos, flip, anim, visible, rot, z]]
var _saved_player_pos: Vector2 = Vector2.ZERO
var _saved_hud: bool = false
var _saved_gui: bool = false
var _saved_nav_vis: bool = false
var _saved_strip_vis: bool = false
var _sleepers: Array = []          # fish lying in bunks
var _zz_layer: CanvasLayer = null
var _zz: Label = null
var _saved_light: Color = Color.WHITE
var _my_bunk: Sprite2D = null
var _lie_sprites: Array = []       # [Sprite2D, npc]
var _lamp_cones: Array = []

func setup(level) -> void:
	L = level
	set_process(false)
	set_process_input(false)

func is_on() -> bool:
	return _on

func _bed_pos() -> Vector2:
	return Vector2(BUNK_XS[MY_BUNK], FLOOR_Y)

# ---------------------------------------------------------------- building
func _spr(tex_path: String, pos: Vector2, z: int, parent: Node = null) -> Sprite2D:
	var sp = Sprite2D.new()
	sp.texture = load(tex_path)
	sp.centered = false
	sp.scale = Vector2(PX, PX)
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.position = pos
	sp.z_as_relative = false
	sp.z_index = z
	(parent if parent else _view).add_child(sp)
	return sp

func _build() -> void:
	if _built:
		return
	_built = true
	_view = Node2D.new()
	_view.name = "MaintRoomView"
	_view.z_as_relative = false
	_view.z_index = -9
	_view.draw.connect(_draw_room)
	add_child(_view)
	# the room itself: the back wall, the door, the bunks, the nightstands, the lockers
	_spr(TEX_DIR + "Factory_MaintRoom_Back_Texture.png", Vector2(LEFT, CEIL_Y), -8)
	_spr(DOOR_TEX, Vector2(LEFT + 6.0 * PX, FLOOR_Y - 36.0 * PX), -7)
	for b in range(BUNK_XS.size()):
		var tex = "Factory_MaintRoom_BunkMine_Texture.png" if b == MY_BUNK else "Factory_MaintRoom_Bunk_Texture.png"
		var bs = _spr(TEX_DIR + tex, Vector2(BUNK_XS[b] - BUNK_W * PX * 0.5, FLOOR_Y - BUNK_H * PX), -6)
		if b == MY_BUNK:
			_my_bunk = bs
	_spr(TEX_DIR + "Factory_MaintRoom_StandMug_Texture.png", Vector2(RX - 95.0 - 24.0, FLOOR_Y - 22.0 * PX), -6)
	_spr(TEX_DIR + "Factory_MaintRoom_StandLamp_Texture.png", Vector2(RX + 95.0 - 24.0, FLOOR_Y - 22.0 * PX), -6)
	for k in range(2):
		_spr(TEX_DIR + "Factory_MaintRoom_Locker_Texture.png", Vector2(LOCKER_X - 24.0 + k * 48.0, FLOOR_Y - 41.0 * PX), -6)
	# two lamps over the nightstands, with a soft warm cone
	for lx in [RX - 95.0, RX + 95.0]:
		var lamp = _spr(LAMP_TEX, Vector2(lx - 21.0, CEIL_Y + 21.0), -5)
		lamp.modulate = Color(1.2, 1.1, 0.95)
		if ResourceLoader.exists(CONE_TEX):
			var cone = Sprite2D.new()
			cone.texture = load(CONE_TEX)
			cone.position = Vector2(lx, CEIL_Y + 130.0)
			var ts = cone.texture.get_size()
			cone.scale = Vector2(220.0 / ts.x, 240.0 / ts.y)
			cone.modulate = Color(1.0, 0.82, 0.55, 0.22)
			var cm = CanvasItemMaterial.new()
			cm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			cone.material = cm
			cone.z_as_relative = false
			cone.z_index = 30
			_view.add_child(cone)
			_lamp_cones.append(cone)
	# a front layer for the marks over the bed and the fish signs (over the fish)
	var front = Node2D.new()
	front.name = "MaintRoomFront"
	front.z_as_relative = false
	front.z_index = 60
	front.draw.connect(_draw_front.bind(front))
	add_child(front)
	_view.set_meta("front", front)
	_body = StaticBody2D.new()
	_body.name = "MaintRoomBody"
	add_child(_body)
	_add_box(Vector2(RX, FLOOR_Y + 40.0), Vector2(HALF * 2.0 + 400.0, 80.0))          # floor
	_add_box(Vector2(RX - HALF - 20.0, 200.0), Vector2(40.0, 600.0))                     # walls
	_add_box(Vector2(RX + HALF + 20.0, 200.0), Vector2(40.0, 600.0))

func _add_box(at: Vector2, size: Vector2) -> void:
	var cs = CollisionShape2D.new()
	var rs = RectangleShape2D.new()
	rs.size = size
	cs.shape = rs
	cs.position = at
	_body.add_child(cs)

func _front() -> Node2D:
	return _view.get_meta("front") if _view else null

# ---------------------------------------------------------------- enter / leave
func enter() -> void:
	_build()
	_on = true
	_busy = false
	_morning = false
	_emotes.clear()
	L._room_on = true
	L._update_escape_hint()
	# no leftover speech from the hall
	if L._bubble and is_instance_valid(L._bubble):
		L._bubble.queue_free()
	for ch in L._chan_bubbles.keys():
		var old = L._chan_bubbles[ch]
		if old.size() > 0 and is_instance_valid(old[0]):
			old[0].queue_free()
	L._chan_bubbles.clear()
	_view.visible = true
	_front().visible = true
	_body.process_mode = Node.PROCESS_MODE_INHERIT
	for cs in _body.get_children():
		cs.set_deferred("disabled", false)
	_saved_hud = L._hud_on
	# the room is lit warmer and brighter than the hall
	var lt = L.get_node_or_null("Lighting") as CanvasModulate
	if lt:
		_saved_light = lt.color
		lt.color = Color(0.78, 0.74, 0.72)
	_saved_gui = L.player_gui.visible if L.player_gui else false
	L._set_hud_visible(false)
	if L._nav:
		_saved_nav_vis = L._nav.visible
		L._nav.visible = false
	if L._act_strip:
		_saved_strip_vis = L._act_strip.visible
		L._act_strip.visible = true   # the journal can be read here
	if L.player:
		_saved_player_pos = L.player.global_position
		L.player.global_position = Vector2(DOOR_X + 30.0, 350.0)
		L.player.velocity = Vector2.ZERO
		if "facing_direction" in L.player:
			L.player.facing_direction = 1
		if L.player.has_method("set_movement_blocked"):
			L.player.set_movement_blocked(false)
		if L.camera and L.camera.has_method("snap_to"):
			L.camera.snap_to(L.player.global_position)
	_place_fish()
	set_process(true)
	set_process_input(true)
	_first_visit_card()

func leave() -> void:
	if not _on:
		return
	_on = false
	set_process(false)
	set_process_input(false)
	L._room_on = false
	L._update_escape_hint()
	var lt = L.get_node_or_null("Lighting") as CanvasModulate
	if lt:
		lt.color = _saved_light
	if _view:
		_view.visible = false
		_front().visible = false
	if _body:
		for cs in _body.get_children():
			cs.set_deferred("disabled", true)
	for s in _saved_npc:
		var n = s[0]
		if not is_instance_valid(n):
			continue
		n.position = s[1]
		n.flip_h = s[2]
		n.visible = s[4]
		n.rotation = s[5]
		n.z_index = s[6]
		n.modulate = Color.WHITE
		if n.sprite_frames and n.sprite_frames.has_animation(s[3]):
			n.play(s[3])
	_saved_npc.clear()
	_sleepers.clear()
	for l in _lie_sprites:
		if is_instance_valid(l[0]):
			l[0].queue_free()
	_lie_sprites.clear()
	if L._nav:
		L._nav.visible = _saved_nav_vis
	if L._act_strip:
		L._act_strip.visible = _saved_strip_vis
	if L.player_gui:
		L.player_gui.visible = _saved_gui
	L._set_hud_visible(_saved_hud)
	if L._spot:
		L._spot.hide_step()

func _variant(fish: AnimatedSprite2D) -> String:
	if fish.sprite_frames == null:
		return "WithScar"
	for anim in fish.sprite_frames.get_animation_names():
		if fish.sprite_frames.get_frame_count(anim) == 0:
			continue
		var tex = fish.sprite_frames.get_frame_texture(anim, 0)
		var path = tex.resource_path
		if tex is AtlasTexture and tex.atlas:
			path = tex.atlas.resource_path
		for k in SLEEP_TEX.keys():
			if k in path or k.replace("FunnyHat", "FannyHat") in path:
				return k
	return "WithScar"

func _lie_down(fish: AnimatedSprite2D, bunk: int, upper: bool) -> void:
	var path = NPC_DIR + SLEEP_TEX[_variant(fish)]
	if not ResourceLoader.exists(path):
		return
	var sp = Sprite2D.new()
	sp.texture = load(path)
	sp.hframes = 2
	sp.centered = false
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var w = sp.texture.get_width() / 2.0
	var h = float(sp.texture.get_height())
	sp.position = Vector2(BUNK_XS[bunk] - BUNK_W * PX * 0.5 + 9.0, _bed_y(0 if upper else 1) - h + 4.0)
	sp.z_as_relative = false
	sp.z_index = -5
	_view.add_child(sp)
	fish.visible = false
	_sleepers.append(fish)
	_lie_sprites.append([sp, fish, randf() * 3.0])

func _place_fish() -> void:
	_saved_npc.clear()
	_sleepers.clear()
	for l in _lie_sprites:
		if is_instance_valid(l[0]):
			l[0].queue_free()
	_lie_sprites.clear()
	# [x, y, faces left, lying (bunk, upper)]
	var spots = [
		[LEFT + 190.0, 344.0, false, null],        # standing near the door, by the notice board
		[0.0, 0.0, false, [0, true]],               # asleep up on the left bunk
		[RX - 95.0 + 34.0, 344.0, true, null],      # by the mug on the nightstand
		[0.0, 0.0, false, [1, false]],              # asleep down on the middle bunk
		[LOCKER_X - 70.0, 344.0, false, null],      # by the lockers
	]
	var i := 0
	for fish in L.npc_fishes:
		if fish == null:
			continue
		_saved_npc.append([fish, fish.position, fish.flip_h, String(fish.animation), fish.visible, fish.rotation, fish.z_index])
		var s = spots[i % spots.size()]
		fish.visible = true
		fish.rotation = 0.0
		fish.modulate = Color.WHITE
		fish.z_index = 25
		if s[3] != null:
			_lie_down(fish, s[3][0], s[3][1])
			fish.position = Vector2(BUNK_XS[s[3][0]] - 10.0, _bed_y(0 if s[3][1] else 1) - 14.0)   # (for the "zZ")
		else:
			fish.position = Vector2(s[0], s[1])
			fish.flip_h = s[2]
			if fish.sprite_frames and fish.sprite_frames.has_animation("idle"):
				fish.play("idle")
		i += 1

## y of the mattress top: 0 = upper bed, 1 = lower bed.
func _bed_y(level: int) -> float:
	return FLOOR_Y - (BUNK_H - (10.0 if level == 0 else 36.0)) * PX

func _first_visit_card() -> void:
	if L._tut_done("room"):
		return
	await get_tree().create_timer(0.9, false).timeout
	if not _on:
		return
	var j = tr(" Журнал — %s.") % L._key_name("journal")
	await L._tut_read(tr("КОМНАТА ТЕХОБСЛУЖИВАНИЯ"),
		tr("Здесь рыбы спят между сменами. Охраны нет, время не идёт — ходи, сколько хочешь.") + j + "\n" + tr("Когда будешь готов, подойди к своей койке (она подсвечена) и нажми %s.") % L._key_name("interact"),
		func(): return L._world_to_screen(Rect2(_bed_pos() + Vector2(-60, -112), Vector2(120, 116))), false)
	L._tut_mark("room")

# ---------------------------------------------------------------- loop / input
func _process(delta: float) -> void:
	_t += delta
	for e in _emotes:
		e["t"] += delta
	_emotes = _emotes.filter(func(e): return e["t"] < 2.0)
	for l in _lie_sprites:
		if is_instance_valid(l[0]):
			l[0].frame = 1 if fmod(_t + l[2], 3.2) < 1.4 else 0
	if _my_bunk:
		var on = not _morning and not _busy
		if on and not (_my_bunk.material is ShaderMaterial):
			L._ensure_outline(_my_bunk, L.COLOR_HIGHLIGHT_YELLOW)
		if _my_bunk.material is ShaderMaterial:
			_my_bunk.material.set_shader_parameter("active", 1.0 if on else 0.0)   # (steady, like in inspect)
	var flick = 0.92 + 0.08 * sin(_t * 1.7) * sin(_t * 0.43 + 1.0)
	for c in _lamp_cones:
		c.modulate.a = 0.22 * flick
	if _view:
		_view.queue_redraw()
		_front().queue_redraw()

func _near_door() -> bool:
	return L.player != null and abs(L.player.global_position.x - DOOR_X) < 46.0

func _near_bed() -> bool:
	return L.player != null and abs(L.player.global_position.x - _bed_pos().x) < 60.0

func _near_fish() -> Node:
	if L.player == null:
		return null
	var best = null
	var bd := NEAR
	for s in _saved_npc:
		var f = s[0]
		if not is_instance_valid(f) or not (f.visible or f in _sleepers):
			continue
		var d = abs(f.global_position.x - L.player.global_position.x)
		if d < bd:
			bd = d
			best = f
	return best

func _input(event: InputEvent) -> void:
	if not _on or _busy or L.journal_open or L._tut_reading:
		return
	if not event.is_action_pressed("interact"):
		return
	if not _morning and _near_bed():
		get_viewport().set_input_as_handled()
		_sleep()
		return
	if _morning and _near_door():
		get_viewport().set_input_as_handled()
		_go_out()
		return
	var f = _near_fish()
	if f:
		get_viewport().set_input_as_handled()
		_emote(f)

func _emote(f: Node) -> void:
	for e in _emotes:
		if e["fish"] == f and e["t"] < 1.2:
			return
	var txt: String
	if f in _sleepers:
		txt = "zZ"
	else:
		txt = EMOTES[randi() % EMOTES.size()]
		# it turns to the player and hops a little
		f.flip_h = L.player.global_position.x < f.global_position.x
		var y0 = f.position.y
		var tw = f.create_tween()
		tw.tween_property(f, "position:y", y0 - 6.0, 0.1).set_ease(Tween.EASE_OUT)
		tw.tween_property(f, "position:y", y0, 0.14).set_ease(Tween.EASE_IN)
	_emotes.append({"fish": f, "text": txt, "t": 0.0})

# ---------------------------------------------------------------- sleep and morning
func _sleep() -> void:
	_busy = true
	if L._spot:
		L._spot.hide_step()
	if L.player and L.player.has_method("set_movement_blocked"):
		L.player.set_movement_blocked(true)
	await L._fade_black(true, 1.3)
	if not _on:
		return
	await _zzz(1.6)
	var sh = L.current_shift + 1
	var st = L._plan_next_station()
	if L._dream and L._dream.night_has_lessons(sh, st):
		L._room_on = false
		await L._dream.run_night(sh, st)
		L._room_on = true
		if L._act_strip:
			L._act_strip.visible = true
		L._set_hud_visible(false)
		if L.player_gui:
			L.player_gui.visible = false
	# morning: standing by the bed, the others get up
	if L.player:
		L.player.global_position = Vector2(_bed_pos().x - 34.0, 350.0)
		L.player.velocity = Vector2.ZERO
		if "facing_direction" in L.player:
			L.player.facing_direction = -1
		if L.camera and L.camera.has_method("snap_to"):
			L.camera.snap_to(L.player.global_position)
	_wake_fish()
	_morning = true
	await L._fade_black(false, 1.2)
	if not _on:
		return
	if L.player and L.player.has_method("set_movement_blocked"):
		L.player.set_movement_blocked(false)
	_busy = false
	_walk_fish_out()
	if not L._tut_done("morning"):
		L._spot_show(tr("ПОДЪЁМ"), tr("Смена скоро начнётся. Иди за остальными к двери слева и нажми %s.") % L._key_name("interact"), ["A", L._key_name("interact")],
			func(): return L._world_to_screen(Rect2(DOOR_X - 40, CEIL_Y + 60, 80, FLOOR_Y - CEIL_Y - 56)), false)
		L._tut_mark("morning")

func _zzz(t: float) -> void:
	if _zz == null:
		_zz_layer = CanvasLayer.new()
		_zz_layer.layer = 90
		add_child(_zz_layer)
		_zz = Label.new()
		_zz.text = "z  Z  z"
		_zz.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_zz.set_anchors_preset(Control.PRESET_CENTER)
		_zz.position = Vector2(476, 300)
		_zz.size = Vector2(200, 40)
		var f = L._bubble_font()
		if f:
			_zz.add_theme_font_override("font", f)
		_zz.add_theme_font_size_override("font_size", 22)
		_zz.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
		_zz_layer.add_child(_zz)
	_zz.visible = true
	_zz.modulate.a = 0.0
	var tw = create_tween().set_ignore_time_scale(true)
	tw.tween_property(_zz, "modulate:a", 1.0, t * 0.3)
	tw.tween_interval(t * 0.4)
	tw.tween_property(_zz, "modulate:a", 0.0, t * 0.3)
	await tw.finished
	_zz.visible = false

func _wake_fish() -> void:
	for l in _lie_sprites:
		if is_instance_valid(l[0]):
			l[0].queue_free()
	_lie_sprites.clear()
	var i := 0
	for s in _saved_npc:
		var f = s[0]
		if not is_instance_valid(f):
			continue
		f.rotation = 0.0
		f.z_index = 25
		f.visible = true
		f.position = Vector2(BUNK_XS[i % BUNK_XS.size()] - 74.0 - (i / BUNK_XS.size()) * 22.0, 344.0)
		f.flip_h = true
		if f.sprite_frames and f.sprite_frames.has_animation("idle"):
			f.play("idle")
		i += 1
	_sleepers.clear()

func _walk_fish_out() -> void:
	var i := 0
	for s in _saved_npc:
		var f = s[0]
		if not is_instance_valid(f):
			continue
		var d = abs(f.position.x - DOOR_X)
		var tw = f.create_tween()
		tw.tween_interval(0.5 + i * 0.6)
		tw.tween_callback(func():
			if f.sprite_frames and f.sprite_frames.has_animation("jogging"):
				f.play("jogging"))
		tw.tween_property(f, "position:x", DOOR_X, d / max(1.0, L.NPC_WALK_SPEED))
		tw.tween_property(f, "modulate:a", 0.0, 0.25)
		tw.tween_callback(func(): f.visible = false)
		i += 1

func _go_out() -> void:
	_busy = true
	if L._spot:
		L._spot.hide_step()
	await L._fade_black(true, 0.9)
	finished.emit()

# ---------------------------------------------------------------- drawing
func _draw_room() -> void:
	var v = _view
	# outside the room: dark
	v.draw_rect(Rect2(RX - 1400, -600, 2800, 1600), Color(0.03, 0.035, 0.05))
	# above the ceiling slab: dark trusses; below the floor plates: the lower plating
	var x0 = LEFT
	var w = BACK_W * PX
	v.draw_rect(Rect2(x0, CEIL_Y - 300.0, w, 300.0), Color(0.055, 0.065, 0.09))
	var bx = x0
	while bx < x0 + w:
		v.draw_rect(Rect2(bx, CEIL_Y - 300.0, 9, 300.0), Color(0.09, 0.1, 0.13))
		v.draw_rect(Rect2(bx, CEIL_Y - 300.0, 3, 300.0), Color(0.12, 0.13, 0.17))
		bx += 72.0
	v.draw_rect(Rect2(x0, CEIL_Y - 36.0, w, 9), Color(0.1, 0.11, 0.14))
	v.draw_rect(Rect2(x0, CEIL_Y - 36.0, w, 3), Color(0.16, 0.17, 0.21))
	# the room's own side walls (beyond them: thick steel, not a black hole)
	for side in [-1.0, 1.0]:
		var wx = x0 - 340.0 if side < 0 else x0 + w
		v.draw_rect(Rect2(wx, CEIL_Y - 300.0, 340.0, 800.0), Color(0.1, 0.115, 0.15))
		var py = CEIL_Y - 300.0
		while py < FLOOR_Y + 500.0:
			v.draw_rect(Rect2(wx, py, 340.0, 3), Color(0.06, 0.07, 0.1))
			for rx in range(int(wx) + 12, int(wx + 340.0), 72):
				v.draw_rect(Rect2(rx, py + 9, 3, 3), Color(0.18, 0.2, 0.25))
			py += 66.0
		# a thick pillar right at the edge of the room, with a hazard band
		var pxl = x0 - 24.0 if side < 0 else x0 + w
		v.draw_rect(Rect2(pxl, CEIL_Y - 300.0, 24.0, 800.0), Color(0.2, 0.22, 0.26))
		v.draw_rect(Rect2(pxl + (21.0 if side < 0 else 0.0), CEIL_Y - 300.0, 3.0, 800.0), Color(0.3, 0.32, 0.37))
		for hy in range(0, 4):
			var yy = FLOOR_Y - 60.0 + hy * 6.0
			v.draw_rect(Rect2(pxl, yy, 24.0, 3.0), Color(0.95, 0.6, 0.3) if hy % 2 == 0 else Color(0.08, 0.08, 0.08))
		# pipes running into the wall
		v.draw_rect(Rect2(wx, CEIL_Y + 12.0, 340.0, 9.0), Color(0.36, 0.2, 0.15))
		v.draw_rect(Rect2(wx, CEIL_Y + 12.0, 340.0, 3.0), Color(0.5, 0.3, 0.22))
	var fy = FLOOR_Y + (100.0 - BACK_FLOOR) * PX
	v.draw_rect(Rect2(x0, fy, w, 400.0), Color(0.12, 0.125, 0.13))
	var fx = x0
	while fx < x0 + w:
		v.draw_rect(Rect2(fx, fy, 3, 400.0), Color(0.04, 0.06, 0.12))
		fx += 90.0
	for k in range(4):
		v.draw_rect(Rect2(x0, fy + 30.0 + k * 66.0, w, 3), Color(0.04, 0.06, 0.12))
	# the lamp over the door: red at night, blinking green in the morning
	var lamp_on = _morning and fmod(_t, 1.0) < 0.6
	var lc = Color(0.35, 1.0, 0.5) if lamp_on else Color(0.55, 0.12, 0.1)
	var lp = Vector2(DOOR_X - 6.0, FLOOR_Y - 36.0 * PX - 12.0)
	v.draw_rect(Rect2(lp - Vector2(3, 3), Vector2(18, 12)), Color(0.04, 0.06, 0.12))
	v.draw_rect(Rect2(lp, Vector2(12, 6)), lc)
	v.draw_rect(Rect2(lp, Vector2(12, 2)), lc.lightened(0.4))

## The interact key drawn like in the aquarium: a white key cap that is pressed now and then,
## a soft glow and a ring around it, and a word under it.
func _draw_key_prompt(c: Node2D, at: Vector2, word: String, accent: Color) -> void:
	var f = L._bubble_font()
	var key = L._key_name("interact")
	if key.length() > 3:
		key = key.substr(0, 3)
	var t = _t
	var pressed = fmod(t, 1.1) > 0.85
	var dip = 2.0 if pressed else 0.0
	var w = max(17.0, 6.0 * key.length() + 9.0)
	var x0 = round(at.x - w / 2.0)
	var y0 = round(at.y - 8.0)
	var pulse = 0.5 + 0.5 * sin(t * 4.0)
	for i in range(3):
		c.draw_circle(at, 15.0 - i * 3.0, Color(accent, (0.05 + 0.03 * i) * (0.6 + 0.4 * pulse)))
	var rt = fmod(t, 1.4) / 1.4
	c.draw_arc(at, 9.0 + rt * 12.0, 0.0, TAU, 40, Color(accent.lightened(0.3), 0.55 * (1.0 - rt)), 1.0)
	var o = Color(0.08, 0.09, 0.12)
	c.draw_rect(Rect2(x0, y0 + 1, w, 15), o)
	c.draw_rect(Rect2(x0 + 1, y0, w - 2, 17), o)
	c.draw_rect(Rect2(x0 + 1, y0 + 1, w - 2, 15), Color(0.35, 0.39, 0.48))
	c.draw_rect(Rect2(x0 + 1, y0 + 1 + dip, w - 2, 6), Color(0.95, 0.96, 0.98))
	c.draw_rect(Rect2(x0 + 1, y0 + 7 + dip, w - 2, 5), Color(0.83, 0.86, 0.91))
	c.draw_rect(Rect2(x0 + 2, y0 + 2 + dip, w - 4, 1), Color(1, 1, 1))
	c.draw_rect(Rect2(x0 + 1, y0 + 12 + dip, w - 2, 1), Color(0.65, 0.69, 0.77))
	if f:
		var tw = f.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var base_y = y0 + 3 + dip + f.get_ascent(8)
		c.draw_string(f, Vector2(round(at.x - tw / 2.0), base_y), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.16, 0.18, 0.25))
		var ww = f.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		c.draw_rect(Rect2(round(at.x - ww / 2.0) - 3, y0 + 21, ww + 6, 11), Color(0.04, 0.05, 0.07, 0.8))
		c.draw_string(f, Vector2(round(at.x - ww / 2.0), y0 + 29), word, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, accent)

func _draw_front(front: Node2D) -> void:
	var f = L._bubble_font()
	# my bunk: a glowing outline, the label and a bobbing arrow (until morning)
	if not _morning:
		var bp = _bed_pos()
		var bob = sin(_t * 4.0) * 2.0
		var ay = _bed_y(1) - 22.0 + bob
		front.draw_colored_polygon(PackedVector2Array([Vector2(bp.x - 7, ay), Vector2(bp.x + 7, ay), Vector2(bp.x, ay + 9)]), Color(1.0, 0.82, 0.25))
		if f:
			var lbl = tr("ТВОЯ КОЙКА")
			var sw = f.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
			front.draw_rect(Rect2(bp.x - sw * 0.5 - 4, ay - 16, sw + 8, 13), Color(0.05, 0.05, 0.06, 0.85))
			front.draw_string(f, Vector2(bp.x - sw * 0.5, ay - 6), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.85, 0.35))
			if _on and not _busy and _near_bed():
				_draw_key_prompt(front, Vector2(bp.x, FLOOR_Y - 150.0), tr("СПАТЬ"), Color(1.0, 0.84, 0.35))
	else:
		# morning: the way out
		var bob2 = sin(_t * 4.0) * 3.0
		var ax = DOOR_X
		var ay2 = FLOOR_Y - 158.0 + bob2
		front.draw_colored_polygon(PackedVector2Array([Vector2(ax - 7, ay2), Vector2(ax + 7, ay2), Vector2(ax, ay2 + 9)]), Color(0.4, 1.0, 0.5))
		if f:
			var lbl2 = tr("НА СМЕНУ")
			var sw2 = f.get_string_size(lbl2, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
			front.draw_rect(Rect2(ax - sw2 * 0.5 - 4, ay2 - 16, sw2 + 8, 13), Color(0.05, 0.05, 0.06, 0.85))
			front.draw_string(f, Vector2(ax - sw2 * 0.5, ay2 - 6), lbl2, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.5, 1.0, 0.6))
		if _on and not _busy and _near_door():
			_draw_key_prompt(front, Vector2(ax, FLOOR_Y - 86.0), tr("ВЫЙТИ"), Color(0.5, 1.0, 0.6))
	# the sleepers breathe out little "z"s
	if f:
		for l in _lie_sprites:
			var sp = l[0]
			if not is_instance_valid(sp):
				continue
			for k in range(2):
				var ph = fmod(_t * 0.45 + l[2] + k * 0.5, 1.0)
				var zp = sp.position + Vector2(14.0 + ph * 10.0 + sin(ph * 6.0) * 2.0, 4.0 - ph * 26.0)
				var za = sin(ph * PI) * 0.75
				front.draw_string(f, zp, "z" if k == 0 else "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, 8 + k * 2, Color(0.85, 0.9, 1.0, za))
	# the fish's little signs
	for e in _emotes:
		var fish = e["fish"]
		if not is_instance_valid(fish) or f == null:
			continue
		var a = clamp(min(e["t"] / 0.15, (2.0 - e["t"]) / 0.4), 0.0, 1.0)
		var pos = fish.global_position + Vector2(0, -34.0 - e["t"] * 6.0)
		if fish in _sleepers:
			pos = fish.global_position + Vector2(10, -18.0 - e["t"] * 8.0)
		var tw = f.get_string_size(e["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		var br = Rect2(pos.x - tw * 0.5 - 5, pos.y - 12, tw + 10, 15)
		front.draw_rect(br, Color(0.95, 0.95, 0.92, 0.95 * a))
		front.draw_colored_polygon(PackedVector2Array([Vector2(pos.x - 3, br.end.y), Vector2(pos.x + 3, br.end.y), Vector2(pos.x, br.end.y + 4)]), Color(0.95, 0.95, 0.92, 0.95 * a))
		front.draw_string(f, Vector2(pos.x - tw * 0.5, pos.y), e["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.1, 0.1, 0.12, a))
