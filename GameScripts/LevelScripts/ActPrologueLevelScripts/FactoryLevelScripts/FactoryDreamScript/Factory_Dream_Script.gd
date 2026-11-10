extends Node
## The dream: an empty white place where the fish learns everything, step by step, with no
## time pressure (every card waits for "next"). It runs inside the factory level so the real
## press, minigames, incidents, guard, inspect mode and journal are used - the hall is just
## hidden and the background turns into a white void.
##   run_first()          - right after the shock in shift 1: moving, the suit, the zone, the
##                          shift panel, work, the guard and his checks, the sniper, the rules
##   run_night(sh, st)    - between shifts (from the bunk): before shift 2 the inspect mode and
##                          the journal; every night the next station and the new accident

const DREAM_SHADER := "res://GameShaders/SharedShaders/Shared_DreamVoid_Shader.gdshader"
const FADE_SHADER := "res://GameShaders/SharedShaders/Shared_DreamFade_Shader.gdshader"
var _saved_mats: Dictionary = {}   # conveyor pieces -> their own material

var L = null                       # the factory level
var _on: bool = false
var _saved_vis: Dictionary = {}    # node -> was visible
var _saved_bg: Material = null
var _saved_state = null
var _saved_station: int = -1
var _saved_player_pos: Vector2 = Vector2.ZERO
var _saved_guard_pos: Vector2 = Vector2.ZERO
var _saved_sniper_pos: Vector2 = Vector2.ZERO
var _saved_guard_flip: bool = false
var _saved_sniper_flip: bool = false
var _saved_hud_on: bool = false
var _saved_gui: bool = false
var _props: Node2D = null
var _belt_x: float = 0.0
var _white_layer: CanvasLayer = null
var _white: ColorRect = null

func setup(level) -> void:
	L = level

func is_on() -> bool:
	return _on

# ---------------------------------------------------------------- white fade
func white(on: bool, t: float = 0.9) -> void:
	if _white == null:
		_white_layer = CanvasLayer.new()
		_white_layer.layer = 86
		add_child(_white_layer)
		_white = ColorRect.new()
		_white.set_anchors_preset(Control.PRESET_FULL_RECT)
		_white.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_white.color = Color(1, 1, 1, 0)
		_white_layer.add_child(_white)
	if t <= 0.0:
		_white.color.a = 1.0 if on else 0.0
		return
	var tw = create_tween().set_ignore_time_scale(true)
	tw.tween_property(_white, "color:a", 1.0 if on else 0.0, t).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

# ---------------------------------------------------------------- the void
func enter(station: int) -> void:
	_on = true
	L._dream_on = true
	_saved_state = L.state
	_saved_station = L.player_station
	_saved_player_pos = L.player.global_position if L.player else Vector2.ZERO
	_saved_guard_pos = L.guard_sprite.position if L.guard_sprite else Vector2.ZERO
	_saved_guard_flip = L.guard_sprite.flip_h if L.guard_sprite else false
	_saved_sniper_flip = L.sniper_sprite.flip_h if L.sniper_sprite else false
	_saved_sniper_pos = L.sniper_sprite.position if L.sniper_sprite else Vector2.ZERO
	_saved_hud_on = L._hud_on
	_saved_gui = L.player_gui.visible if L.player_gui else false
	L.player_station = station
	L.state = L.State.WORKING
	var press: Node2D = L.presses[station] if station < L.presses.size() else null
	_belt_x = L._get_stop_zone_x(station)
	# the hall disappears: only the fish, its press and the zone stay
	var keep: Array = [L.player, press, L.work_zone_rect, L._zone_marks, L.get_node_or_null("Background")]
	# the conveyor stays: it runs out to both sides (belt and legs) and melts into the white
	var belt: Array = []
	belt.append_array(L.conveyor_sprites)
	belt.append_array(L.conveyor_legs)
	keep.append_array(belt)
	_saved_mats.clear()
	var fm = ShaderMaterial.new()
	fm.shader = load(FADE_SHADER)
	fm.set_shader_parameter("center_x", L._get_stop_zone_x(station) + L.NPC_PRESS_OFFSET_X * 0.5)
	for b in belt:
		if is_instance_valid(b):
			_saved_mats[b] = [b.material, b.visible]
			b.material = fm
			b.visible = true
	_saved_vis.clear()
	for c in L.get_children():
		if not (c is CanvasItem) or c in keep or c is CanvasLayer:
			continue
		_saved_vis[c] = c.visible
		c.visible = false
	# guard and sniper wait until they are introduced
	for a in [L.guard_sprite, L.sniper_sprite]:
		if a:
			_saved_vis[a] = a.visible
			a.visible = false
	var bg = L.get_node_or_null("Background") as ColorRect
	if bg and ResourceLoader.exists(DREAM_SHADER):
		_saved_bg = bg.material
		var m = ShaderMaterial.new()
		m.shader = load(DREAM_SHADER)
		m.set_shader_parameter("floor_y", L.ZONE_FLOOR_Y)
		bg.material = m
	# a piece of ghost belt under the press so the food has something to lie on
	_props = Node2D.new()
	_props.name = "DreamProps"
	_props.z_as_relative = false
	_props.z_index = L.Z_FOOD - 2
	_props.draw.connect(_draw_props)
	set_process(true)
	L.add_child(_props)
	_props.queue_redraw()
	# no interface yet (the lessons switch it on piece by piece)
	L._set_hud_visible(false)
	if L.player_gui:
		L.player_gui.visible = false
	if L._act_strip:
		L._act_strip.visible = false
	# the fish stands on the left; the press waits further right ("walk right")
	var spawn_x = _belt_x + L.NPC_PRESS_OFFSET_X
	L.player_turn_x = spawn_x
	L.player_zone_center = Vector2(spawn_x, L.PLAYER_ZONE_CENTER.y)
	L._update_work_zone_position()
	if L.player:
		L.player.global_position = Vector2(max(spawn_x - 430.0, -280.0), 350.0)
		if "facing_direction" in L.player:
			L.player.facing_direction = 1
		if L.player_sprite:
			L.player_sprite.scale.x = abs(L.player_sprite.scale.x)
		L._unlock_player_after_accident()
		if L.camera and L.camera.has_method("snap_to"):
			L.camera.snap_to(L.player.global_position)

func leave() -> void:
	if not _on:
		return
	_clear_targets()
	set_process(false)
	_balcony_a = 0.0
	if L.inspect_text_panel:
		L.inspect_text_panel.visible = false
	if L.state == L.State.INSPECT:
		L._exit_inspect()
	if L.journal_open:
		L._on_journal_close()
	for n in _saved_vis.keys():
		if is_instance_valid(n):
			n.visible = _saved_vis[n]
	_saved_vis.clear()
	for b in _saved_mats.keys():
		if is_instance_valid(b):
			b.material = _saved_mats[b][0]
			b.visible = _saved_mats[b][1]
	_saved_mats.clear()
	var bg = L.get_node_or_null("Background") as ColorRect
	if bg and _saved_bg:
		bg.material = _saved_bg
	if _props:
		_props.queue_free()
		_props = null
	if L.guard_sprite:
		L.guard_sprite.position = _saved_guard_pos
		L.guard_sprite.modulate = Color.WHITE
		L.guard_sprite.flip_h = _saved_guard_flip
		if L.guard_sprite.sprite_frames and L.guard_sprite.sprite_frames.has_animation("idle"):
			L.guard_sprite.play("idle")
	if L.sniper_sprite:
		L.sniper_sprite.position = _saved_sniper_pos
		L.sniper_sprite.flip_h = _saved_sniper_flip
		L.sniper_sprite.modulate = Color.WHITE
	L.player_station = _saved_station
	var sx = L._get_stop_zone_x(_saved_station) + L.NPC_PRESS_OFFSET_X
	L.player_turn_x = sx
	L.player_zone_center = Vector2(sx, L.PLAYER_ZONE_CENTER.y)
	L._update_work_zone_position()
	if L.player:
		L.player.global_position = _saved_player_pos
		if L.camera and L.camera.has_method("snap_to"):
			L.camera.snap_to(L.player.global_position)
	L._set_hud_visible(_saved_hud_on)
	if L.player_gui:
		L.player_gui.visible = _saved_gui
	L.state = _saved_state
	L._dream_on = false
	L._dream_allow_inspect = false
	if L._spot:
		L._spot.hide_step()
	_on = false

var _balcony_a: float = 0.0
const SNIPER_FEET := 314.0

func _zone_x() -> float:
	return L.player_zone_center.x

func _guard_spot() -> Vector2:
	return Vector2(_zone_x() - 190.0, L.GUARD_POSITION.y)

## The sniper stands on a piece of a ghost balcony up on the right, like the real one in the
## hall: high, looking down at the fish.
func _sniper_spot() -> Vector2:
	var half = 36.0
	var sn = L.sniper_sprite
	if sn and sn.sprite_frames and sn.sprite_frames.has_animation(sn.animation):
		var tex = sn.sprite_frames.get_frame_texture(sn.animation, 0)
		if tex:
			half = tex.get_height() * abs(sn.global_scale.y) * 0.5
	return Vector2(_zone_x() + 175.0, SNIPER_FEET - half + 2.0)

func _draw_props() -> void:
	if _balcony_a > 0.01:
		var bx = _zone_x() + 175.0
		var y0 = SNIPER_FEET
		var w = 120.0
		for i in range(int(w / 4.0)):
			var t = float(i) / (w / 4.0)
			var a = smoothstep(0.0, 0.2, t) * smoothstep(1.0, 0.8, t) * _balcony_a
			var x = bx - w * 0.5 + i * 4.0
			_props.draw_rect(Rect2(x, y0, 4, 6), Color(0.24, 0.25, 0.3, a))
			_props.draw_rect(Rect2(x, y0, 4, 2), Color(0.5, 0.52, 0.58, a))
			# its rail and posts
			_props.draw_rect(Rect2(x, y0 - 26.0, 4, 2), Color(0.42, 0.44, 0.5, a * 0.8))
			if i % 5 == 2:
				_props.draw_rect(Rect2(x + 1, y0 - 24.0, 2, 24), Color(0.36, 0.38, 0.44, a * 0.7))
			# it fades downward into the void like a reflection
			_props.draw_rect(Rect2(x, y0 + 6.0, 4, 10), Color(0.24, 0.25, 0.3, a * 0.18))

	pass

# ---------------------------------------------------------------- helpers
func _t() -> SceneTree:
	return L._tree()

func _wait(sec: float) -> void:
	await _t().create_timer(sec, false).timeout

func _until(cond: Callable, max_t: float = 1e9) -> void:
	var t := 0.0
	while L.is_inside_tree() and not cond.call() and t < max_t:
		await _t().process_frame
		t += L.get_process_delta_time()

func _read(title: String, body: String, target: Callable = Callable(), dim: bool = true, keys: Array = []) -> void:
	await L._tut_read(title, body, target, dim, keys)

## Shows a task card and waits until cond() is true.
func _task(title: String, body: String, keys: Array, target: Callable, cond: Callable, dim: bool = false) -> void:
	L._spot_show(title, body, keys, target if target.is_valid() else func(): return Rect2(), dim)
	await _until(cond)
	if not is_instance_valid(L) or not L.is_inside_tree():
		return
	if L._spot:
		L._spot.done()
	await _wait(0.45)
	if L._spot:
		L._spot.hide_step()

func _air_bar() -> AnimatedSprite2D:
	if L.player_gui == null:
		return null
	var cont = L.player_gui.get_node_or_null("UI_Container")
	return cont.get_node_or_null("Air_Bar") as AnimatedSprite2D if cont else null

func _gui_rect(name: String, pad: float = 8.0) -> Rect2:
	if L.player_gui == null:
		return Rect2()
	var cont = L.player_gui.get_node_or_null("UI_Container")
	var n = cont.get_node_or_null(name) if cont else null
	if n == null:
		return Rect2()
	if n is AnimatedSprite2D and n.sprite_frames:
		var tex = n.sprite_frames.get_frame_texture(n.animation, n.frame)
		if tex:
			var sz = tex.get_size() * n.scale.abs()
			var p = n.global_position - (sz * 0.5 if n.centered else Vector2.ZERO)
			return Rect2(p, sz).grow(pad)
	if n is Sprite2D and n.texture:
		var sz2 = n.texture.get_size() * n.scale.abs()
		var p2 = n.global_position - (sz2 * 0.5 if n.centered else Vector2.ZERO)
		return Rect2(p2, sz2).grow(pad)
	return Rect2()

func _hud_row(y0: float, h: float) -> Rect2:
	if L._hud_panel == null:
		return Rect2()
	return Rect2(L._hud_panel.position + Vector2(2, y0) * L.HUD_PX, Vector2(L.HUD_W - 4, h) * L.HUD_PX).grow(4.0)

func _hud_all() -> Rect2:
	if L._hud_panel == null:
		return Rect2()
	return Rect2(L._hud_panel.position, L._hud_panel.size).grow(6.0)

func _practice_item(st: int) -> Dictionary:
	var node = Node2D.new()
	node.name = "DreamSushi"
	var spr = Sprite2D.new()
	spr.name = "Sprite"
	spr.centered = false
	spr.scale = Vector2(L.SUSHI_SCALE, L.SUSHI_SCALE)
	node.add_child(spr)
	node.z_index = L.Z_FOOD
	node.position = Vector2(_belt_x, L.BELT_SURFACE_Y)
	L.add_child(node)
	# which slot of the belt this press stands at (the food looks like it does there)
	var slot := 1
	for k in L.SLOT_STATION.keys():
		if L.SLOT_STATION[k] == st:
			slot = k
	slot = min(slot, L.BELT_PACK_SLOT - 1)   # (a practice box never counts as packed)
	node.set_meta("sushi_stage", -1)
	L._apply_stage(node, max(0, slot - 1), false)
	node.modulate.a = 0.0
	node.create_tween().tween_property(node, "modulate:a", 1.0, 0.3)
	return {"node": node, "index": -1, "slot": slot, "broken": false, "done": false, "practice": true}

## Real jobs at the press that count for nothing; a miss simply starts over.
func practice(st: int, times: int, title: String, body: String) -> void:
	for i in range(times):
		var it = _practice_item(st)
		await _wait(0.35)
		L._player_item = it
		L._start_minigame(st, true)
		if i == 0:
			L._spot_show(title, body, [L._key_name("interact")], L._mg_screen_rect, false)
		await L.player_job_finished
		if L._spot and L._spot.is_shown():
			L._spot.done()
		var n = it["node"]
		if is_instance_valid(n):
			var tw = n.create_tween()
			tw.tween_property(n, "modulate:a", 0.0, 0.4).set_delay(0.3)
			tw.tween_callback(n.queue_free)
		await _wait(0.5)
	if L._spot:
		L._spot.hide_step()

func _appear(node: CanvasItem, at: Vector2) -> void:
	if node == null:
		return
	node.position = at
	node.visible = true
	node.modulate = Color(1, 1, 1, 0)
	var tw = node.create_tween()
	tw.tween_property(node, "modulate:a", 1.0, 0.6)
	await tw.finished

const MG_HOWTO := {
	0: "Ползунок бегает по полосе. Жми %s, когда он внутри ЗЕЛЁНОЙ зоны.",
	1: "Стрелка крутится по кругу. Жми %s, когда она на ЗЕЛЁНОЙ метке. Меток две: после первой стрелка поворачивает в другую сторону.",
	2: "Давление растёт само и раскачивается. Жми %s, чтобы остановить стрелку в ЗЕЛЁНОЙ полосе. Дойдёт до верха — лопнет.",
	3: "Кольцо сжимается к центру. Жми %s, когда оно совпадёт с меткой. Нужно два раза подряд.",
	4: "Нож едет вдоль ролла. Жми %s на каждой метке. Пропустил метку — брак.",
}

func _howto(st: int) -> String:
	var kind = int(L.STATION_MINIGAME.get(st, 0))
	return tr(MG_HOWTO.get(kind, MG_HOWTO[0])) % L._key_name("interact") + " " + tr("Во сне промахи не считаются.")

# ---------------------------------------------------------------- the first dream
func run_first() -> void:
	await white(true, 0.25)
	if not L.is_inside_tree():
		return
	enter(L.player_station)
	await _wait(0.8)
	await white(false, 1.6)
	var key = L._key_name("interact")
	await _read(tr("ГДЕ Я?"), tr("Удар тока выжег микрочип у тебя в голове. Впервые за долгое время ты думаешь сам. Но тело в меха-костюме чужое и тяжёлое — придётся заново учиться ходить, работать и выживать здесь."), Callable(), false)
	# moving
	var x0 = L.player.global_position.x
	var jumped := {"v": false}
	await _task(tr("ДВИЖЕНИЕ"), tr("A и D — идти, ПРОБЕЛ — прыжок. Пройдись и подпрыгни."), ["A", "D", tr("ПРОБЕЛ")], L._player_screen_rect,
		func():
			if L.player and L.player.velocity.y < -60.0:
				jumped["v"] = true
			return abs(L.player.global_position.x - x0) > 90.0 and jumped["v"])
	# the suit's interface
	L._show_gui()
	await _wait(0.6)
	await _read(tr("ПРОЧНОСТЬ КОСТЮМА"), tr("Это здоровье твоего меха-костюма. Удары охраны и аварии его снимают. Кончится — костюм рухнет, и тебя выбросит наружу."), _gui_rect.bind("HP_Bar", 6.0))
	await _read(tr("ВЫНОСЛИВОСТЬ"), tr("Оранжевая полоса под ней — силы. Прыжки и рывки их тратят, в покое они возвращаются."), func(): return Rect2(_gui_rect("HP_Bar", 0.0).position + Vector2(10, _gui_rect("HP_Bar", 0.0).size.y * 0.62), Vector2(_gui_rect("HP_Bar", 0.0).size.x * 0.7, _gui_rect("HP_Bar", 0.0).size.y * 0.45)))
	await _read(tr("ИНДИКАТОР КОСТЮМА"), tr("Значок показывает, что ты внутри костюма и дышишь его воздухом."), _gui_rect.bind("SuitIcon", 8.0))
	L._place_air_bar()
	await _read(tr("БАЛЛОН ВОЗДУХА"), tr("Ты — рыба. Если костюм разобьют, у тебя останется только этот баллон. Воздух в нём кончается за несколько секунд."), _gui_rect.bind("Air_Bar", 6.0))
	# to the press
	await _task(tr("К СТАНКУ"), tr("Справа стоит станок. Подойди к нему."), ["D"], L._zone_screen_rect, func(): return L._is_player_in_zone())
	await _read(tr("БЕЗОПАСНАЯ ЗОНА"), tr("Свечение у станка — твоё место. Стоишь внутри — оно ЗЕЛЁНОЕ, всё хорошо. Вышел — оно становится КРАСНЫМ, и охрана это видит."), L._zone_screen_rect)
	# the shift panel
	L._set_hud_visible(true)
	await _wait(0.5)
	await _read(tr("ПАНЕЛЬ СМЕНЫ"), tr("Справа вверху — всё о смене. Разберём по строчкам."), _hud_all)
	await _read(tr("ВРЕМЯ"), tr("Номер смены и часы. Смена идёт с 8:00 до 18:00."), _hud_row.bind(5.0, 10.0))
	await _read(tr("КОРОБКИ"), tr("Каждая клетка — одна коробка за смену. Зелёная — ты сделал хорошо, красная — твоя ошибка, серая — испортил кто-то другой."), _hud_row.bind(15.0, 7.0))
	await _read(tr("СТРЕСС"), tr("Чем выше стресс, тем чаще рука срывается, даже если ты нажал вовремя. Удары охраны поднимают стресс, серия хороших работ — снижает."), L._stress_screen_rect)
	# work
	await _read(tr("РАБОТА"), tr("Еда сама приезжает к станку. Твоё дело — вовремя нажать %s. Попробуй.") % key, L._zone_screen_rect)
	await practice(L.player_station, 2, tr("РАБОТА"), _howto(L.player_station))
	# the guard
	await _appear(L.guard_sprite, _guard_spot())
	await _read(tr("ОХРАНА"), tr("Охранник следит за работой. Иногда он устраивает ПРОВЕРКУ: смотрит на две твои работы подряд. Хорошо — стресс падает, плохо — получишь удар."), L._guard_screen_rect)
	await practice(L.player_station, 1, tr("ПРОВЕРКА"), tr("Охранник смотрит. Сделай работу как обычно."))
	await _read(tr("НЕ УХОДИ ИЗ ЗОНЫ"), tr("Ушёл со своего места во время работы — охранник кричит. Не вернулся — подходит и бьёт, пока не вернёшься."), L._guard_screen_rect)
	if L.sniper_sprite:
		L.sniper_sprite.flip_h = true   # looks left, at the fish (like on the real balcony)
	_balcony_a = 0.0
	create_tween().tween_property(self, "_balcony_a", 1.0, 0.6)
	await _appear(L.sniper_sprite, _sniper_spot())
	await _read(tr("СНАЙПЕР"), tr("Над цехом сидит снайпер. Если ты так и не вернулся к станку — он стреляет. Одного выстрела хватает."), func(): return L._sprite_screen_rect(L.sniper_sprite).grow(14.0))
	await _read(tr("КОНЕЦ СМЕНЫ"), tr("В 18:00 работа кончается, и все идут в комнату техобслуживания. Иди за остальными — стоять нельзя. Там можно спокойно отдохнуть и лечь спать на свою койку."), Callable(), false)
	await _read(tr("ПОРА ПРОСЫПАТЬСЯ"), tr("Ты приходишь в себя у станка. Смена продолжается — теперь ты знаешь, что делать."), Callable(), false)
	for f in ["basics", "dream1", "st_%d" % L.player_station]:
		L._tut_mark(f)
	await white(true, 1.0)
	leave()
	await _wait(0.5)
	await white(false, 1.2)

# ---------------------------------------------------------------- the nights
## What the night before shift sh teaches: the new accident of that shift.
func night_incident(sh: int) -> int:
	match sh:
		2: return L.MGE_FIRE
		3: return L.MGE_STUCK
		4: return L.MGE_SHORT
	return L.MGE_NONE

func night_has_lessons(sh: int, st: int) -> bool:
	var inc = night_incident(sh)
	return (sh >= 2 and not L._tut_done("inspect")) or not L._tut_done("st_%d" % st) \
		or (inc != L.MGE_NONE and not L._tut_done("inc_%d" % inc))

func run_night(sh: int, st: int) -> void:
	white(true, 0.0)
	L.fade_rect.color.a = 0.0
	enter(st)
	await _wait(0.4)
	await white(false, 1.4)
	var key = L._key_name("interact")
	await _read(tr("СОН"), tr("Опять это белое место. Пока все спят — учись. Здесь ошибки ничего не стоят."), Callable(), false)
	if sh >= 2 and not L._tut_done("inspect"):
		await _inspect_lesson()
	await _task(tr("К СТАНКУ"), tr("Справа — станок, за которым ты будешь работать в смену %d.") % sh, ["D"], L._zone_screen_rect, func(): return L._is_player_in_zone())
	if not L._tut_done("st_%d" % st):
		await _read(tr("НОВЫЙ СТАНОК: ") + tr(String(L.STATION_TITLE.get(st, ""))), _howto(st), L._zone_screen_rect)
		await practice(st, 2, tr(String(L.STATION_TITLE.get(st, ""))), _howto(st))
	var inc = night_incident(sh)
	if inc != L.MGE_NONE and not L._tut_done("inc_%d" % inc):
		var names = {L.MGE_FIRE: tr("ПОЖАР"), L.MGE_STUCK: tr("ЗАКЛИНИЛО КНОПКУ"), L.MGE_SHORT: tr("ЗАМЫКАНИЕ")}
		await _read(tr("АВАРИЯ: ") + String(names.get(inc, "")), tr("С этой смены у станка может случиться авария. Тогда работа встаёт, и её надо ликвидировать самому. Сейчас попробуешь — подсказка будет рядом с окном аварии."), L._zone_screen_rect)
		await L._run_incident(inc, true)
		L._tut_mark("inc_%d" % inc)
		await _wait(0.6)
	await _read(tr("ПОРА ВСТАВАТЬ"), tr("Скоро подъём. Впереди смена %d.") % sh, Callable(), false)
	await white(true, 1.0)
	leave()
	L.fade_rect.visible = true
	L.fade_rect.color = Color(0, 0, 0, 1)
	await white(false, 0.0)

# ---------------------------------------------------------------- inspect practice
## Things lit in the dream's inspect mode: {node, id, color, title, text}
var _targets: Array = []
var _clicked: Dictionary = {}

func _process(_d: float) -> void:
	if _props:
		_props.queue_redraw()
	var insp = L != null and L.state == L.State.INSPECT
	for t in _targets:
		var n = t["node"]
		if not is_instance_valid(n):
			continue
		L._ensure_outline(n, t["color"])
		if n.material is ShaderMaterial:
			n.material.set_shader_parameter("active", 1.0 if (insp and n.visible and not _clicked.has(t["id"] + "_off")) else 0.0)
			# on the white of the dream the usual pale outline melts away: deeper colours, wider line
			var dc = Color(0.62, 0.42, 0.0) if t["color"] == L.COLOR_HIGHLIGHT_YELLOW else Color(0.05, 0.24, 0.58)
			n.material.set_shader_parameter("outline_color", Color(dc.r, dc.g, dc.b, 1.0))
			n.material.set_shader_parameter("width", 2.0)

func _clear_targets() -> void:
	for t in _targets:
		var n = t["node"]
		if is_instance_valid(n) and n.material is ShaderMaterial:
			n.material.set_shader_parameter("active", 0.0)
			n.material.set_shader_parameter("width", 1.0)
	_targets.clear()

## Called by the level for a click in the dream's inspect mode.
func inspect_click(wp: Vector2) -> void:
	for t in _targets:
		var n = t["node"]
		if not is_instance_valid(n) or not n.visible:
			continue
		if L._node_hit(n, wp) >= 0.0:
			_clicked[t["id"]] = true
			L._show_inspect_text(t["title"], t["text"], "")
			return

func _inspect_lesson() -> void:
	L._dream_allow_inspect = true
	_clicked.clear()
	if L._act_strip:
		L._act_strip.visible = true
		L._act_strip.modulate.a = 1.0
	L._act_sig = []
	await _read(tr("РАЗВЕДКА"), tr("Чтобы сбежать, нужно знать, когда охрана и снайпер уходят с поста. Для этого есть режим осмотра и журнал."), Callable(), false)
	if L.guard_sprite and not L.guard_sprite.visible:
		await _appear(L.guard_sprite, _guard_spot())
	var press = L.presses[L.player_station] if L.player_station < L.presses.size() else null
	_targets = [
		{"node": press, "id": "press", "color": L.COLOR_HIGHLIGHT_BLUE, "title": tr("СТАНОК"),
			"text": tr("Мой пресс. Во сне он тихий — ни шипения, ни масла. Даже непривычно.")},
		{"node": L.guard_sprite, "id": "guard", "color": L.COLOR_HIGHLIGHT_YELLOW, "title": tr("ПЕРЕСМЕНКА"),
			"text": tr("Охранник уходит с поста. Запомню время — так и складывается расписание.")},
	]
	await _task(tr("РЕЖИМ ОСМОТРА"), tr("Нажми %s: время замедлится, а всё полезное вокруг подсветится.") % L._key_name("inspect"), [L._key_name("inspect")], L._act_screen_rect.bind(false),
		func(): return L.state == L.State.INSPECT)
	await _task(tr("ВЗГЛЯД"), tr("В осмотре рыба стоит на месте, а взгляд летает по всему цеху: W A S D."), ["W", "A", "S", "D"], Callable(),
		func(): return L.inspect_camera_offset.length() > 100.0)
	await _read(tr("ДВА ЦВЕТА"), tr("СИНЕЕ — по желанию: рабочие, вещи, места. Кликни — узнаешь что-то полезное или просто интересное.\nЖЁЛТОЕ — обязательно: так светится пересменка, когда охранник или снайпер уходит с поста. Кликни по жёлтому, пока он не вернулся, — время запишется в журнал. Без этого не узнать расписание."), Callable(), false)
	await _task(tr("СИНЕЕ"), tr("Кликни мышкой по станку — он подсвечен синим."), [tr("ЛКМ")], Callable(),
		func(): return _clicked.has("press"))
	await _wait(0.8)
	# the guard leaves his post: yellow - catch it before he is gone
	if L.guard_sprite:
		L.guard_sprite.flip_h = true
		if L.guard_sprite.sprite_frames and L.guard_sprite.sprite_frames.has_animation("jogging"):
			L.guard_sprite.play("jogging")
		var tw = L.guard_sprite.create_tween()
		tw.tween_property(L.guard_sprite, "position:x", L.guard_sprite.position.x - 120.0, 18.0)
	await _task(tr("ЖЁЛТОЕ"), tr("Охранник уходит с поста — это пересменка, она светится жёлтым. Кликни по нему, пока он не ушёл."), [tr("ЛКМ")], Callable(),
		func(): return _clicked.has("guard"))
	await _wait(0.8)
	await _task(tr("ВЫЙТИ ИЗ ОСМОТРА"), tr("Нажми %s ещё раз.") % L._key_name("inspect"), [L._key_name("inspect")], L._act_screen_rect.bind(false),
		func(): return L.state != L.State.INSPECT)
	_clear_targets()
	await _task(tr("ЖУРНАЛ"), tr("Всё, что ты узнаёшь, записывается в журнал. Открой его: %s.") % L._key_name("journal"), [L._key_name("journal")], L._act_screen_rect.bind(true),
		func(): return L.journal_open)
	await _until(func(): return not L.journal_open)
	await _read(tr("ЖУРНАЛ"), tr("Пересменки — галочками со временем, новые записи — со штампом НОВОЕ. Когда узнаешь всё про побег, наверху появится ВАЖНАЯ ПОМЕТКА."), L._act_screen_rect.bind(true))
	L._tut_mark("inspect")
	L._tut_mark("journal")
	L._dream_allow_inspect = false
	if L._act_strip:
		L._act_strip.visible = false
	if L.guard_sprite:
		var tw2 = L.guard_sprite.create_tween()
		tw2.tween_property(L.guard_sprite, "modulate:a", 0.0, 0.5)
