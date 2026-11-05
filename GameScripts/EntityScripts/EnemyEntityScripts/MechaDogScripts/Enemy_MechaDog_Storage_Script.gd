extends StorageEnemy
## Storage mecha-dog (blue).
## Fast and agile: dodges the player's swings, punishes whiffs, circles while other enemies
## attack, and has a "death grip": it drops to four legs, sprints and bites. If the bite lands
## the dog locks its jaws on the fish - mash the attack button to tear the mech jaws off and
## knock it out with an elbow, or get chewed.
## The Hallway dog uses Enemy_MechaDog_Script.gd - this file is only for the storage dog.

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var detection_area: Area2D = get_node_or_null("DetectionArea")

enum State { PATROL, ALERT, STALK, CHASE, ATTACK, DODGE, QUAD_START, QUAD_RUN, QUAD_BITE, BITE_RECOVER, GRAPPLE, JAW_BREAK, STUN, DEAD }
var state: State = State.PATROL

## Fur ramp drawn in the dog sheets (light -> dark) and the recoloured variants.
var FUR_SOURCE := [Color8(204, 169, 110), Color8(178, 144, 98), Color8(153, 121, 81), Color8(126, 97, 68), Color8(97, 74, 60), Color8(69, 49, 37)]
var FUR_VARIANTS := [
	[Color8(96, 96, 104), Color8(78, 78, 86), Color8(62, 62, 70), Color8(48, 48, 56), Color8(36, 36, 42), Color8(24, 24, 30)],        # black
	[Color8(236, 232, 224), Color8(214, 208, 198), Color8(188, 182, 172), Color8(158, 152, 146), Color8(124, 120, 116), Color8(90, 86, 84)],  # white / husky
	[Color8(222, 148, 82), Color8(200, 120, 62), Color8(172, 96, 48), Color8(140, 74, 38), Color8(106, 56, 32), Color8(74, 38, 24)],  # ginger
	[Color8(170, 150, 128), Color8(146, 126, 106), Color8(120, 102, 86), Color8(96, 80, 68), Color8(74, 60, 52), Color8(52, 42, 36)],  # grey-brown
]

## Where the dog / the fish are drawn inside the 128 px wide combined grab frames.
const GRAB_DOG_CX := 43.0
const GRAB_FISH_CX := 85.5
const QUAD_CX := 52.0

@export var run_speed: float = 250.0
@export var quad_speed: float = 440.0
@export var punch_range: float = 72.0
@export var bite_min_range: float = 110.0
@export var bite_max_range: float = 320.0
@export var stalk_distance: float = 175.0
@export var grip_presses: int = 9
@export var grip_time: float = 2.6

var t: float = 0.0
var cooldown: float = 0.0
var quad_cooldown: float = 1.2
var dodge_cooldown: float = 0.0
var combo_left: int = 0
var hit_done: bool = false
var _stalk_dir: int = 1
var _stalk_timer: float = 0.0
var _grip_value: float = 0.0
var _grip_tick: float = 0.0
var _grip_ui: Node2D = null
var _grip_bar: ProgressBar = null
var _ko_finish: bool = false
var _alerted_allies: bool = false


func _ready() -> void:
	super._ready()
	shard_color = "blue"
	max_hp = 6
	hp = max_hp
	can_be_parried = true
	aggro_range = 400.0
	deaggro_range = 760.0
	if sprite:
		_base_sprite_offset = sprite.offset
		apply_fur_variant(sprite, FUR_SOURCE, FUR_VARIANTS)
	if detection_area:
		detection_area.body_entered.connect(func(b):
			if b.is_in_group("player") and player == null:
				player = b
		)
	_play("idle")


func _play(anim_name: String, restart: bool = false) -> void:
	var extra = Vector2.ZERO
	match anim_name:
		"quad_start", "quad_run", "quad_bite":
			extra = Vector2(64.0 - QUAD_CX, 0)
		"grabbed_jaws", "jaw_break":
			extra = Vector2(64.0 - GRAB_DOG_CX, 0)
	_play_on(sprite, anim_name, extra, restart)
	if sprite:
		sprite.speed_scale = 1.0


# ------------------------------------------------------------------ main loop
func _physics_process(delta: float) -> void:
	if is_dead:
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		move_and_slide()
		return
	super._physics_process(delta)

	if player == null:
		_find_player()
	if not _player_ok():
		if state in [State.GRAPPLE, State.JAW_BREAK]:
			_release_player(false)
		player = null
		is_aggro = false
	_observe_player(delta)

	# the grip ignores outside stuns (the parry pulse of the held fish, etc.)
	if state in [State.GRAPPLE, State.JAW_BREAK]:
		is_stunned = false
	elif is_stunned:
		_stun_logic(delta)
		move_and_slide()
		return

	cooldown = max(0.0, cooldown - delta)
	quad_cooldown = max(0.0, quad_cooldown - delta)
	dodge_cooldown = max(0.0, dodge_cooldown - delta)
	t += delta

	var dist := 99999.0
	var dx := 0.0
	var dy := 0.0
	if _player_ok():
		dx = player.global_position.x - global_position.x
		dy = player.global_position.y - global_position.y
		dist = abs(dx)
		_update_aggro(global_position.distance_to(player.global_position))
		if is_aggro and abs(dy) > 160.0 and not _has_line_of_sight(global_position + Vector2(0, -20), player.global_position):
			is_aggro = false

	match state:
		State.PATROL: _patrol(delta)
		State.ALERT: _alert_logic()
		State.STALK: _stalk_logic(delta, dist, dx, dy)
		State.CHASE: _chase_logic(dist, dx, dy)
		State.ATTACK: _attack_logic(dist)
		State.DODGE: _dodge_logic()
		State.QUAD_START: _quad_start_logic()
		State.QUAD_RUN: _quad_run_logic(dist, dx, dy)
		State.QUAD_BITE: _quad_bite_logic()
		State.BITE_RECOVER: _bite_recover_logic(delta)
		State.GRAPPLE: _grapple_logic(delta)
		State.JAW_BREAK: _jaw_break_logic()

	if sprite:
		sprite.scale.x = abs(sprite.scale.x) * (1 if facing_dir > 0 else -1)
	move_and_slide()


func _face(dx: float) -> void:
	if dx != 0.0:
		facing_dir = 1 if dx > 0 else -1


func _go(s: State) -> void:
	state = s
	t = 0.0
	hit_done = false


# ------------------------------------------------------------------ states
func _patrol(delta: float) -> void:
	if is_aggro:
		velocity.x = 0
		_go(State.ALERT)
		return
	if _ledge_ahead(patrol_dir) or _wall_ahead(patrol_dir):
		patrol_dir = -patrol_dir
	_patrol_step(delta)
	_play("run_fast" if abs(velocity.x) > 5 else "idle")
	if sprite:
		sprite.speed_scale = 0.55


func _alert_logic() -> void:
	velocity.x = 0
	if _player_ok():
		_face(player.global_position.x - global_position.x)
	_play("idle")
	if sprite:
		sprite.speed_scale = 1.0
	if t == 0.0 or t < get_physics_process_delta_time() * 1.5:
		_bark()
	if not _alerted_allies:
		_alerted_allies = true
		_alert_allies()
	if t > 0.28:
		_go(State.CHASE)


func _bark() -> void:
	if sprite == null:
		return
	var base = Vector2(abs(sprite.scale.x), abs(sprite.scale.y))
	var tw = create_tween()
	tw.tween_property(sprite, "scale:y", base.y * 1.15, 0.06)
	tw.tween_property(sprite, "scale:y", base.y, 0.1)


## Keeps a dangerous distance and waits for an opening (or for a free attack slot).
func _stalk_logic(delta: float, dist: float, dx: float, dy: float) -> void:
	if not is_aggro:
		_release_token()
		_go(State.PATROL)
		return
	_face(dx)
	if _react_to_player(dist):
		return
	_stalk_timer -= delta
	if _stalk_timer <= 0.0:
		_stalk_timer = randf_range(0.35, 0.8)
		_stalk_dir = -1 if randf() < 0.5 else 1
	var want = stalk_distance + _stalk_dir * 40.0
	var move = 0.0
	if dist > want + 25.0:
		move = 1.0
	elif dist < want - 25.0:
		move = -1.0
	var dir = int(sign(dx)) * int(move)
	if dir != 0 and (_ledge_ahead(dir) or _wall_ahead(dir)):
		dir = 0
	velocity.x = dir * run_speed * 0.55 + _separation() * 120.0
	_play("run_fast" if abs(velocity.x) > 10 else "idle")
	if sprite:
		sprite.speed_scale = 0.8
	# an opening appeared, or it is our turn
	if t > 0.5 and abs(dy) < 70.0 and _request_token():
		_go(State.CHASE)


func _chase_logic(dist: float, dx: float, dy: float) -> void:
	if not is_aggro:
		_release_token()
		_go(State.PATROL)
		return
	_face(dx)
	if sprite:
		sprite.speed_scale = 1.0
	if _react_to_player(dist):
		return
	# someone else is already biting the fish - wait our turn
	if not _request_token():
		_go(State.STALK)
		return
	# player is on another floor above us: pace under them
	if dy < -90.0:
		velocity.x = sign(dx) * run_speed * 0.4 if dist > 40.0 else 0.0
		_play("run_fast" if abs(velocity.x) > 5 else "idle")
		return
	var dir = int(sign(dx))
	if _ledge_ahead(dir) and dy < 40.0:
		velocity.x = 0
		_play("idle")
		_release_token()
		_go(State.STALK)
		return
	velocity.x = dir * run_speed
	_play("run_fast")
	if cooldown > 0.0 or abs(dy) > 70.0:
		return
	# blocking players get grabbed: the bite ignores a raised guard
	var want_bite = quad_cooldown <= 0.0 and dist > bite_min_range and dist < bite_max_range
	if player_block_habit > 0.35 and quad_cooldown <= 0.0 and dist < bite_max_range and dist > 70.0:
		want_bite = true
	if want_bite:
		velocity.x = 0
		_go(State.QUAD_START)
		_play("quad_start", true)
		return
	if dist < punch_range:
		_start_combo()


## Smart reactions shared by stalk / chase. Returns true when it took over.
func _react_to_player(dist: float) -> bool:
	# the fish swings at us: sidestep out of reach (the dog is agile)
	if dodge_cooldown <= 0.0 and _player_threatens(100.0) and randf() < 0.75:
		_start_dodge()
		return true
	# the fish is parrying: never bite into a parry, back off
	if _player_flag("is_parrying") and dist < 140.0:
		velocity.x = -facing_dir * run_speed * 0.8
		_play("run_fast")
		return true
	# the fish just missed: punish the recovery
	if _whiff_window > 0.0 and cooldown <= 0.0 and _request_token():
		if dist < punch_range + 20.0:
			_start_combo()
			return true
		if quad_cooldown <= 0.0 and dist < bite_max_range:
			_go(State.QUAD_START)
			_play("quad_start", true)
			return true
	return false


func _start_combo() -> void:
	combo_left = 2 if randf() < 0.6 else 1
	_go(State.ATTACK)
	_play("attack_right" if combo_left % 2 == 0 else "attack_left", true)


func _attack_logic(dist: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 30.0)
	if not hit_done and t >= 0.2:
		hit_done = true
		if dist < punch_range + 14.0 and _player_ok() and abs(player.global_position.y - global_position.y) < 60.0:
			_snap_fx()
			_hurt_player_smart(1)
	if t >= 0.5:
		combo_left -= 1
		if combo_left > 0 and dist < punch_range + 20.0 and not _player_flag("is_parrying"):
			_go(State.ATTACK)
			_play("attack_left", true)
			return
		cooldown = randf_range(0.7, 1.1)
		_release_token()
		_go(State.STALK)


func _start_dodge() -> void:
	dodge_cooldown = 1.3
	_go(State.DODGE)
	velocity.x = -facing_dir * 380.0
	if is_on_floor():
		velocity.y = -170.0
	_play("run_fast")


func _dodge_logic() -> void:
	velocity.x = move_toward(velocity.x, 0.0, 25.0)
	if t > 0.3:
		# counter-attack straight out of the dodge half of the time
		if randf() < 0.5 and quad_cooldown <= 0.0 and _request_token():
			_go(State.QUAD_START)
			_play("quad_start", true)
		else:
			_go(State.STALK)


func _quad_start_logic() -> void:
	velocity.x = 0
	_play("quad_start")
	if t >= _anim_length(sprite, "quad_start"):
		_go(State.QUAD_RUN)
		_play("quad_run", true)


func _quad_run_logic(dist: float, _dx: float, dy: float) -> void:
	# commit to where the fish will be, not where it is
	if _player_ok():
		var target = _predict_player(0.25)
		_face(target.x - global_position.x)
	_play("quad_run")
	if _ledge_ahead(facing_dir) or _wall_ahead(facing_dir) or abs(dy) > 90.0 or t > 1.3:
		quad_cooldown = 2.0
		_release_token()
		_go(State.BITE_RECOVER)
		return
	velocity.x = facing_dir * quad_speed
	if dist < 78.0:
		_go(State.QUAD_BITE)
		_play("quad_bite", true)
		velocity.x = facing_dir * 470.0


func _quad_bite_logic() -> void:
	velocity.x = move_toward(velocity.x, 0.0, 22.0)
	if not hit_done and t >= 0.13:
		hit_done = true
		_snap_fx()
		if _bite_connects():
			if _player_flag("is_parrying"):
				_get_parried()
			elif _player_flag("is_dashing"):
				pass
			else:
				_start_grapple()
				return
	if t >= _anim_length(sprite, "quad_bite"):
		quad_cooldown = randf_range(2.6, 3.6)
		_release_token()
		_go(State.BITE_RECOVER)


func _bite_connects() -> bool:
	if not _player_ok():
		return false
	var rel = player.global_position - global_position
	return rel.x * facing_dir > -12.0 and abs(rel.x) < 82.0 and abs(rel.y) < 55.0


## Missed bite: the dog skids and is open to a counter for a moment.
func _bite_recover_logic(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	_play("idle")
	if t > 0.55:
		cooldown = 0.4
		_go(State.STALK if is_aggro else State.PATROL)


func _get_parried() -> void:
	_release_token()
	velocity.x = -facing_dir * 220.0
	is_stunned = true
	stun_timer = 1.5
	state = State.STUN
	_play("hit", true)


func _stun_logic(delta: float) -> void:
	stun_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 1100.0 * delta)
	if stun_timer <= 0.0:
		is_stunned = false
		if sprite:
			sprite.modulate = Color.WHITE
		cooldown = 0.25
		_go(State.STALK if is_aggro else State.PATROL)


# ------------------------------------------------------------------ the death grip
func _start_grapple() -> void:
	_go(State.GRAPPLE)
	velocity = Vector2.ZERO
	_grip_value = 0.0
	_grip_tick = 0.0
	quad_cooldown = 4.0
	if player.has_method("set_movement_blocked"):
		player.set_movement_blocked(true)
	if player.has_method("_set_blocking"):
		player._set_blocking(false)
	player.velocity = Vector2.ZERO
	player.global_position.x = global_position.x + facing_dir * (GRAB_FISH_CX - GRAB_DOG_CX)
	var ps = player.get("sprite")
	if ps:
		ps.visible = false
	_play("grabbed_jaws", true)
	_shake(0.3)
	_make_grip_ui()


func _grapple_logic(delta: float) -> void:
	velocity.x = 0
	if not _player_ok():
		_release_player(false)
		_go(State.STALK)
		return
	player.velocity = Vector2.ZERO
	var need = grip_presses + (3 if float(player.get("stamina")) < 30.0 else 0)
	_grip_value = max(0.0, _grip_value - delta * 1.2)
	if _grip_bar:
		_grip_bar.max_value = need
		_grip_bar.value = _grip_value
	_grip_tick += delta
	if _grip_tick >= 1.1:
		# the jaws keep chewing while the fish struggles
		_grip_tick = 0.0
		if player.has_method("take_damage"):
			player.take_damage(1, self)
		_shake(0.12)
		if not _player_ok() or int(player.get("hp")) <= 0:
			_release_player(false)
			_go(State.STALK)
			return
	if _grip_value >= need:
		_go(State.JAW_BREAK)
		_free_grip_ui()
		_play("jaw_break", true)
		return
	if t >= grip_time:
		# fish failed: a last hard chomp, then the dog lets go and backs off
		if player.has_method("take_damage"):
			player.take_damage(2, self)
		_shake(0.35)
		_release_player(true)
		cooldown = 1.0
		_go(State.BITE_RECOVER)


func _input(event: InputEvent) -> void:
	if state != State.GRAPPLE:
		return
	var pressed := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
	elif event is InputEventKey and event.pressed and not event.echo:
		var act = (InputMap.has_action("interact") and event.is_action("interact")) or event.is_action("ui_accept")
		if act or event.keycode == KEY_E or event.keycode == KEY_SPACE:
			pressed = true
	if pressed:
		_grip_value += 1.0
		if sprite:
			var base = Vector2(abs(sprite.scale.x), abs(sprite.scale.y))
			var tw = create_tween()
			tw.tween_property(sprite, "scale:y", base.y * 0.95, 0.04)
			tw.tween_property(sprite, "scale:y", base.y, 0.06)


func _jaw_break_logic() -> void:
	velocity.x = 0
	if _player_ok():
		player.velocity = Vector2.ZERO
	# the elbow lands on frame 7
	if not hit_done and sprite and sprite.animation == "jaw_break" and sprite.frame >= 7:
		hit_done = true
		_shake(0.45)
		if has_node("/root/UISounds"):
			UISounds.play_hit()
	if t >= _anim_length(sprite, "jaw_break") + 0.15:
		_release_player(false)
		if _player_ok():
			player.set("stamina", float(player.get("max_stamina")))
		_ko_finish = true
		hp = 0
		die()


func _release_player(knockback: bool) -> void:
	_free_grip_ui()
	_release_token()
	if player == null or not is_instance_valid(player):
		return
	var ps = player.get("sprite")
	if ps:
		ps.visible = true
	if player.has_method("set_movement_blocked") and not bool(player.get("is_dead")):
		player.set_movement_blocked(false)
	if knockback:
		player.velocity.x = facing_dir * 260.0
	if sprite and state != State.JAW_BREAK:
		_play("idle", true)


func _make_grip_ui() -> void:
	_free_grip_ui()
	_grip_ui = Node2D.new()
	_grip_ui.z_index = 120
	_grip_ui.position = Vector2(facing_dir * (GRAB_FISH_CX - GRAB_DOG_CX) * 0.5, -74)
	add_child(_grip_ui)
	var lbl = Label.new()
	lbl.text = "ЖМИ ЛКМ!"
	lbl.position = Vector2(-50, -26)
	lbl.size = Vector2(100, 20)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 4)
	_grip_ui.add_child(lbl)
	_grip_bar = ProgressBar.new()
	_grip_bar.show_percentage = false
	_grip_bar.position = Vector2(-40, -4)
	_grip_bar.size = Vector2(80, 8)
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.1, 0.85)
	bg.border_color = Color(0.02, 0.02, 0.03)
	bg.set_border_width_all(1)
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.3, 0.65, 1.0)
	_grip_bar.add_theme_stylebox_override("background", bg)
	_grip_bar.add_theme_stylebox_override("fill", fill)
	_grip_ui.add_child(_grip_bar)
	var tw = lbl.create_tween().set_loops()
	tw.tween_property(lbl, "scale", Vector2(1.12, 1.12), 0.18)
	tw.tween_property(lbl, "scale", Vector2.ONE, 0.18)


func _free_grip_ui() -> void:
	if _grip_ui and is_instance_valid(_grip_ui):
		_grip_ui.queue_free()
	_grip_ui = null
	_grip_bar = null


# ------------------------------------------------------------------ damage / death
func take_damage(amount: int) -> void:
	# while it holds the fish the attack button is used for the struggle, not for damage
	if state in [State.GRAPPLE, State.JAW_BREAK]:
		return
	super.take_damage(amount)


func _on_hurt() -> void:
	# agile: sometimes slips out of a combo instead of eating the next hit
	if dodge_cooldown <= 0.0 and randf() < 0.35:
		_start_dodge()
		return
	_release_token()
	state = State.STUN
	is_stunned = true
	stun_timer = 0.32
	if _player_ok():
		var away = sign(global_position.x - player.global_position.x)
		velocity.x = (away if away != 0 else float(-facing_dir)) * 170.0
	_play("hit", true)


func _snap_fx() -> void:
	if sprite == null:
		return
	var base = Vector2(abs(sprite.scale.x), abs(sprite.scale.y))
	var dir = 1.0 if facing_dir > 0 else -1.0
	var tw = create_tween()
	tw.tween_property(sprite, "scale", Vector2(base.x * 1.08 * dir, base.y * 0.92), 0.05)
	tw.tween_property(sprite, "scale", Vector2(base.x * dir, base.y), 0.1)


func _on_death() -> void:
	_free_grip_ui()
	if state == State.GRAPPLE:
		_release_player(false)
	state = State.DEAD
	collision_layer = 0
	if detection_area:
		detection_area.set_deferred("monitoring", false)
	var anim_len := 0.6
	if not _ko_finish and sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		sprite.modulate = Color.WHITE
		_play("death", true)
		anim_len = _anim_length(sprite, "death")
	elif sprite:
		sprite.stop()   # knocked out: keep the last KO frame
	death_free_delay = anim_len + 1.4
	if sprite:
		var tw = create_tween()
		tw.tween_interval(anim_len + 0.6)
		tw.tween_property(sprite, "modulate:a", 0.0, 0.7)


func _exit_tree() -> void:
	# never leave the fish invisible / frozen if the dog disappears mid-grip
	if state in [State.GRAPPLE, State.JAW_BREAK]:
		_release_player(false)
