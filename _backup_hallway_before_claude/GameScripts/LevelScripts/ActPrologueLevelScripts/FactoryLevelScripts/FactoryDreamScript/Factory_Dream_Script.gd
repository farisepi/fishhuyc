extends Node

const DREAM_SHADER := "res://GameShaders/SharedShaders/Shared_DreamVoid_Shader.gdshader"
const FADE_SHADER := "res://GameShaders/SharedShaders/Shared_DreamFade_Shader.gdshader"
const HAZE_SHADER := "res://GameShaders/SharedShaders/Shared_DreamHaze_Shader.gdshader"
const DREAM_NOTE := "dream_"
var _haze_layer: CanvasLayer = null
var _haze: ColorRect = null
var _saved_ui_layer: int = -999
var _saved_mats: Dictionary = {}

var L = null
var _on: bool = false
var _saved_vis: Dictionary = {}
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

var _white_tw: Tween = null

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
		if _white_tw and _white_tw.is_valid():
			_white_tw.kill()
		_white.color.a = 1.0 if on else 0.0
		return
	if _white_tw and _white_tw.is_valid():
		_white_tw.kill()
	var tw = create_tween().set_ignore_time_scale(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_white_tw = tw
	tw.tween_property(_white, "color:a", 1.0 if on else 0.0, t).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

func enter(station: int, bare: bool = false) -> void:
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
	L.dream_counters(true)
	L.player_station = station
	L.state = L.State.WORKING
	L._update_escape_hint()
	var press: Node2D = L.presses[station] if station < L.presses.size() else null
	_belt_x = L._get_stop_zone_x(station)
	var keep: Array = [L.player, press, L.work_zone_rect, L._zone_marks, L.get_node_or_null("Background")]
	var belt: Array = []
	if bare:
		keep = [L.player, L.get_node_or_null("Background")]
	else:
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
	for a in [L.guard_sprite, L.sniper_sprite]:
		if a:
			if not _saved_vis.has(a):
				_saved_vis[a] = a.visible
			a.visible = false
	var bg = L.get_node_or_null("Background") as ColorRect
	if bg and ResourceLoader.exists(DREAM_SHADER):
		_saved_bg = bg.material
		var m = ShaderMaterial.new()
		m.shader = load(DREAM_SHADER)
		m.set_shader_parameter("floor_y", L.ZONE_FLOOR_Y)
		bg.material = m
	_set_walls(false)
	_props = Node2D.new()
	_props.name = "DreamProps"
	_props.z_as_relative = false
	_props.z_index = L.Z_FOOD - 2
	_props.draw.connect(_draw_props)
	set_process(true)
	L.add_child(_props)
	_props.queue_redraw()
	_set_haze(true)
	L._set_hud_visible(false)
	if L.player_gui:
		L.player_gui.visible = false
	if L._act_strip:
		L._act_strip.visible = false
	var spawn_x = _belt_x + L.NPC_PRESS_OFFSET_X
	L.player_turn_x = spawn_x
	L.player_zone_center = Vector2(spawn_x, L.PLAYER_ZONE_CENTER.y)
	L._update_work_zone_position()
	if L.player:
		L.player.global_position = Vector2(spawn_x if bare else max(spawn_x - 430.0, -280.0), 350.0)
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
	_set_walls(true)
	_set_haze(false)
	_drop_dream_notes()
	if L.journal_open:
		L._on_journal_close()
	if L.get("_tut_frozen"):
		L._tut_unfreeze()
	Engine.time_scale = 1.0
	AudioServer.playback_speed_scale = 1.0
	if L.pausemenu == null or not L.pausemenu.visible:
		get_tree().paused = false
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
	L.dream_counters(false)
	L._dream_allow_inspect = false
	L._update_escape_hint()
	if L._spot:
		L._spot.hide_step()
	_on = false

var _balcony_a: float = 0.0
const SNIPER_FEET := 314.0

func _zone_x() -> float:
	return L.player_zone_center.x

func _guard_spot() -> Vector2:
	return Vector2(_zone_x() - 190.0, L.GUARD_POSITION.y)

func _sniper_spot() -> Vector2:
	var half = 36.0
	var sn = L.sniper_sprite
	if sn and sn.sprite_frames and sn.sprite_frames.has_animation(sn.animation):
		var tex = sn.sprite_frames.get_frame_texture(sn.animation, 0)
		if tex:
			half = tex.get_height() * abs(sn.global_scale.y) * 0.5
	return Vector2(_zone_x() + 175.0, SNIPER_FEET - half + 2.0)

var _endless_floor: StaticBody2D = null

func _floor_top() -> float:
	var top = L.ZONE_FLOOR_Y
	if L.player and L.player.is_inside_tree():
		var from = L.player.global_position
		var q = PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 220), 1, [L.player.get_rid()])
		var r = L.player.get_world_2d().direct_space_state.intersect_ray(q)
		if not r.is_empty() and abs(r.position.y - L.ZONE_FLOOR_Y) < 12.0:
			top = r.position.y
	return top

func _set_walls(on: bool) -> void:
	for w in L.get_tree().get_nodes_in_group("hall_walls"):
		for cs in w.get_children():
			if cs is CollisionShape2D:
				cs.set_deferred("disabled", not on)
	if not on and _endless_floor == null:
		_endless_floor = StaticBody2D.new()
		_endless_floor.name = "DreamEndlessFloor"
		var cs2 = CollisionShape2D.new()
		cs2.shape = WorldBoundaryShape2D.new()
		cs2.position = Vector2(0.0, _floor_top())
		_endless_floor.add_child(cs2)
		L.add_child(_endless_floor)
	elif on and _endless_floor:
		_endless_floor.queue_free()
		_endless_floor = null

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
			_props.draw_rect(Rect2(x, y0 - 26.0, 4, 2), Color(0.42, 0.44, 0.5, a * 0.8))
			if i % 5 == 2:
				_props.draw_rect(Rect2(x + 1, y0 - 24.0, 2, 24), Color(0.36, 0.38, 0.44, a * 0.7))
			_props.draw_rect(Rect2(x, y0 + 6.0, 4, 10), Color(0.24, 0.25, 0.3, a * 0.18))

	pass

func _set_haze(on: bool) -> void:
	if on:
		if _haze == null and ResourceLoader.exists(HAZE_SHADER):
			_haze_layer = CanvasLayer.new()
			_haze_layer.layer = 1
			add_child(_haze_layer)
			var ui = L.get_node_or_null("UI") as CanvasLayer
			if ui:
				_saved_ui_layer = ui.layer
				ui.layer = max(ui.layer, 3)
			_haze = ColorRect.new()
			_haze.set_anchors_preset(Control.PRESET_FULL_RECT)
			_haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var m = ShaderMaterial.new()
			m.shader = load(HAZE_SHADER)
			m.set_shader_parameter("strength", 0.0)
			_haze.material = m
			_haze_layer.add_child(_haze)
		if _haze:
			var tw = create_tween().set_ignore_time_scale(true)
			tw.tween_method(func(v): if is_instance_valid(_haze): _haze.material.set_shader_parameter("strength", v), 0.0, 1.0, 1.2)
	elif _haze:
		_haze_layer.queue_free()
		_haze_layer = null
		_haze = null
		var ui = L.get_node_or_null("UI") as CanvasLayer
		if ui and _saved_ui_layer != -999:
			ui.layer = _saved_ui_layer
		_saved_ui_layer = -999

func _drop_dream_notes() -> void:
	for id in L.journal_notes.duplicate():
		if String(id).begins_with(DREAM_NOTE):
			L.journal_notes.erase(id)
			L.journal_notes_full.erase(id)
			L.journal_seen.erase(id)

func _t() -> SceneTree:
	return L._tree()

func _wait(sec: float) -> void:
	await _t().create_timer(sec, false, false, true).timeout

func _until(cond: Callable, max_t: float = 1e9) -> void:
	var t := 0.0
	while L.is_inside_tree() and not cond.call() and t < max_t:
		await _t().process_frame
		t += L.get_process_delta_time()

func _read(title: String, body: String, target: Callable = Callable(), dim: bool = true, keys: Array = []) -> void:
	await L._tut_read(title, body, target, dim, keys)

func _task(title: String, body: String, keys: Array, target: Callable, cond: Callable, dim: bool = false) -> void:
	L._spot_show(title, body, keys, target if target.is_valid() else func(): return Rect2(), dim)
	await _until(cond)
	if not is_instance_valid(L) or not L.is_inside_tree():
		return
	if L._spot:
		L._spot.hide_step()

func _air_bar() -> AnimatedSprite2D:
	if L.player_gui == null:
		return null
	var cont = L.player_gui.get_node_or_null("UI_Container")
	return cont.get_node_or_null("Air_Bar") as AnimatedSprite2D if cont else null

func _gui_rect(node_name: String, pad: float = 8.0) -> Rect2:
	if L.player_gui == null:
		return Rect2()
	var cont = L.player_gui.get_node_or_null("UI_Container")
	var n = cont.get_node_or_null(node_name) if cont else null
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
	var slot := 1
	for k in L.SLOT_STATION.keys():
		if L.SLOT_STATION[k] == st:
			slot = k
	slot = min(slot, L.BELT_PACK_SLOT - 1)
	node.set_meta("sushi_stage", -1)
	L._apply_stage(node, max(0, slot - 1), false)
	node.modulate.a = 0.0
	node.create_tween().tween_property(node, "modulate:a", 1.0, 0.3)
	return {"node": node, "index": -1, "slot": slot, "broken": false, "done": false, "practice": true}

func _back_to_station() -> void:
	if L._is_player_in_zone():
		return
	L._spot_show(tr("НАЗАД К ПРЕССУ"), tr("Работа приехала! Вернись в безопасную зону у своего пресса."), ["A", "D"], L._zone_screen_rect, false)
	await _until(func(): return L._is_player_in_zone())
	if L._spot:
		L._spot.hide_step()
	await _wait(0.25)

func practice(st: int, times: int, title: String, body: String) -> void:
	for i in range(times):
		await _back_to_station()
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

func run_first() -> void:
	await white(true, 0.25)
	if not L.is_inside_tree():
		return
	enter(L.player_station)
	await _wait(0.8)
	await white(false, 1.6)
	var key = L._key_name("interact")
	await _read(tr("ГДЕ Я?"), tr("Удар тока выжег микрочип у тебя в голове. Впервые за долгое время ты думаешь сам. Но тело в меха-костюме чужое и тяжёлое — придётся заново учиться ходить, работать и выживать здесь."), Callable(), false)
	var x0 = L.player.global_position.x
	var jumped := {"v": false}
	await _task(tr("ДВИЖЕНИЕ"), tr("A и D — идти, ПРОБЕЛ — прыжок. Пройдись и подпрыгни."), ["A", "D", tr("ПРОБЕЛ")], L._player_screen_rect,
		func():
			if L.player and L.player.velocity.y < -60.0:
				jumped["v"] = true
			return abs(L.player.global_position.x - x0) > 90.0 and jumped["v"])
	L._show_gui()
	await _wait(0.6)
	await _read(tr("ПРОЧНОСТЬ КОСТЮМА"), tr("Это здоровье твоего меха-костюма. Удары охраны и аварии его снимают. Кончится — костюм рухнет, и тебя выбросит наружу."), _gui_rect.bind("HP_Bar", 6.0))
	await _read(tr("ВЫНОСЛИВОСТЬ"), tr("Оранжевая полоса под ней — силы. Прыжки и рывки их тратят, в покое они возвращаются."), func(): return Rect2(_gui_rect("HP_Bar", 0.0).position + Vector2(10, _gui_rect("HP_Bar", 0.0).size.y * 0.62), Vector2(_gui_rect("HP_Bar", 0.0).size.x * 0.7, _gui_rect("HP_Bar", 0.0).size.y * 0.45)))
	await _read(tr("ИНДИКАТОР КОСТЮМА"), tr("Значок показывает, что ты внутри костюма и дышишь его воздухом."), _gui_rect.bind("SuitIcon", 8.0))
	L.show_air_bar(true)
	await _wait(0.35)
	await _read(tr("БАЛЛОН ВОЗДУХА"), tr("Ты — рыба. Если костюм разобьют, у тебя останется только этот баллон. Воздух в нём кончается за несколько секунд."), _gui_rect.bind("Air_Bar", 6.0))
	L.show_air_bar(false)
	await _task(tr("К СТАНКУ"), tr("Справа стоит станок. Подойди к нему."), ["D"], L._zone_screen_rect, func(): return L._is_player_in_zone())
	await _read(tr("БЕЗОПАСНАЯ ЗОНА"), tr("Свечение у станка — твоё место. Стоишь внутри — оно ЗЕЛЁНОЕ, всё хорошо. Вышел — оно становится КРАСНЫМ, и охрана это видит."), L._zone_screen_rect)
	L._set_hud_visible(true)
	await _wait(0.5)
	await _read(tr("ПАНЕЛЬ СМЕНЫ"), tr("Справа вверху — всё о смене. Разберём по строчкам."), _hud_all)
	await _read(tr("ВРЕМЯ"), tr("Номер смены и часы. Смена идёт с 8:00 до 18:00."), _hud_row.bind(5.0, 10.0))
	await _read(tr("КОРОБКИ"), tr("Каждая клетка — одна коробка за смену. Зелёная — ты сделал хорошо, красная — твоя ошибка, серая — испортил кто-то другой."), _hud_row.bind(15.0, 7.0))
	await _read(tr("СТРЕСС"), tr("Чем выше стресс, тем чаще рука срывается, даже если ты нажал вовремя. Удары охраны поднимают стресс, серия хороших работ — снижает."), L._stress_screen_rect)
	await _read(tr("РАБОТА"), tr("Еда сама приезжает к станку. Твоё дело — вовремя нажать %s. Попробуй.") % key, L._zone_screen_rect)
	await practice(L.player_station, 2, tr("РАБОТА"), _howto(L.player_station))
	await _appear(L.guard_sprite, _guard_spot())
	await _read(tr("ОХРАНА"), tr("Охранник следит за работой. Иногда он устраивает ПРОВЕРКУ: смотрит на две твои работы подряд. Хорошо — стресс падает, плохо — получишь удар."), L._guard_screen_rect)
	await practice(L.player_station, 1, tr("ПРОВЕРКА"), tr("Охранник смотрит. Сделай работу как обычно."))
	await _read(tr("НЕ УХОДИ ИЗ ЗОНЫ"), tr("Ушёл со своего места во время работы — охранник кричит. Не вернулся — подходит и бьёт, пока не вернёшься."), L._guard_screen_rect)
	if L.sniper_sprite:
		L.sniper_sprite.flip_h = true
	_balcony_a = 0.0
	create_tween().tween_property(self, "_balcony_a", 1.0, 0.6)
	await _appear(L.sniper_sprite, _sniper_spot())
	await _read(tr("СНАЙПЕР"), tr("Над цехом сидит снайпер. Если ты так и не вернулся к станку — он стреляет. Одного выстрела хватает."), func(): return L._world_to_screen(L._sprite_screen_rect(L.sniper_sprite)).grow(14.0))
	await _read(tr("КОНЕЦ СМЕНЫ"), tr("В 18:00 работа кончается, и все идут в комнату техобслуживания. Иди за остальными — стоять нельзя. Там можно спокойно отдохнуть и лечь спать на свою койку."), Callable(), false)
	await _read(tr("ПОРА ПРОСЫПАТЬСЯ"), tr("Ты приходишь в себя у станка. Смена продолжается — теперь ты знаешь, что делать."), Callable(), false)
	for f in ["basics", "dream1", "maint", "st_%d" % L.player_station]:
		L._tut_mark(f)
	await white(true, 1.0)
	leave()
	await _wait(0.5)
	await white(false, 1.2)

func run_elevator(black: ColorRect) -> void:
	white(true, 0.0)
	enter(L.player_station, true)
	var p = L.player
	if p:
		p.modulate.a = 1.0
		p.z_index = L.Z_CHARACTERS
		p.set_process_input(true)
		if p.has_method("set_movement_blocked"):
			p.set_movement_blocked(false)
		if "only_basic_moves" in p:
			p.only_basic_moves = false
		p.allow_block = true
		p.global_position = Vector2(_zone_x() - 60.0, 350.0)
		if L.camera and L.camera.has_method("snap_to"):
			L.camera.snap_to(p.global_position)
	if L.camera:
		L.camera.zoom = L.camera.camera_zoom if "camera_zoom" in L.camera else L.camera.zoom
	if L.sniper_sprite:
		L.sniper_sprite.flip_h = true
		L.sniper_sprite.position = _sniper_spot()
		L.sniper_sprite.modulate.a = 0.0
		L.sniper_sprite.visible = false
	if black:
		var tb = black.create_tween()
		tb.tween_property(black, "color:a", 0.0, 0.8)
		await tb.finished
	await white(false, 1.4)
	await _read(tr("СОН В ЛИФТЕ"), tr("Лифт гудит, и ты проваливаешься в сон. Там, наверху, по тебе будут стрелять. Научись выживать — здесь ошибки ничего не стоят."), Callable(), false)
	_balcony_a = 0.0
	create_tween().tween_property(self, "_balcony_a", 1.0, 0.6)
	await _appear(L.sniper_sprite, _sniper_spot())
	var sn_rect = func(): return L._world_to_screen(L._sprite_screen_rect(L.sniper_sprite)).grow(14.0)
	await _read(tr("УКЛОНЕНИЕ"), tr("Красный луч — снайпер целится. Когда он выстрелит, нажми %s в последний момент: рывок уведёт тебя из-под пули.") % L._key_name("dash"), sn_rect, false, [L._key_name("dash")])
	await _shots("dash", 2)
	await _read(tr("БЛОК"), tr("Можно и не убегать. Зажми %s перед выстрелом — рыба закроется, и пуля отскочит.") % L._key_name("block"), sn_rect, false, [L._key_name("block")])
	await _shots("block", 2)
	await _read(tr("ЛИФТ ОСТАНАВЛИВАЕТСЯ"), tr("Теперь ты знаешь, как выжить под огнём. Двери вот-вот откроются."), Callable(), false)
	L._tut_mark("dodge")
	if p and "only_basic_moves" in p:
		p.only_basic_moves = true
	if p:
		p._set_blocking(false)
	await white(true, 1.0)
	leave()
	if black:
		black.color.a = 1.0
	await white(false, 0.0)

func _shots(kind: String, need: int) -> void:
	var title = tr("УКЛОНЕНИЕ") if kind == "dash" else tr("БЛОК")
	var key = L._key_name("dash" if kind == "dash" else "block")
	var got := 0
	while got < need and _on and is_instance_valid(L) and L.is_inside_tree():
		L._spot_show(title, (tr("Увернись рывком: %s.") if kind == "dash" else tr("Зажми %s до выстрела.")) % key + "  %d / %d" % [got, need], [key], func(): return Rect2(), false)
		await _wait(0.9)
		var ok = await _one_shot(kind)
		if ok:
			got += 1
			L._float_text(tr("УВЕРНУЛСЯ!") if kind == "dash" else tr("ОТБИЛ!"), Color(0.5, 1.0, 0.55))
		else:
			L._float_text(tr("ПОПАЛ! ЕЩЁ РАЗ"), Color(1.0, 0.4, 0.35))
		await _wait(0.9)
	if L._spot:
		L._spot.hide_step()

func _one_shot(kind: String) -> bool:
	var p = L.player
	if p == null or L.sniper_sprite == null:
		return true
	p.stamina = 100.0
	p.dash_cooldown = 0.0
	L._laser_on(true)
	var aim := 1.7
	var t := 0.0
	var dashed_at := -10.0
	var hist: Array = []
	while t < aim:
		await _t().process_frame
		if not is_instance_valid(L) or not L.is_inside_tree():
			return false
		var d = get_process_delta_time()
		t += d
		if p.is_dashing and dashed_at < 0.0:
			dashed_at = t
		hist.append([t, p.global_position])
		if aim - t < 0.45:
			var beam = L._laser.get_node_or_null("Beam") if L._laser and is_instance_valid(L._laser) else null
			if beam:
				beam.default_color = Color(1.0, 0.15, 0.1, 0.9 if int(t * 16.0) % 2 == 0 else 0.3)
	var ok := false
	if kind == "dash":
		ok = p.is_dashing or (dashed_at > 0.0 and aim - dashed_at < 0.45)
	else:
		ok = p.is_blocking
	var from = L._sniper_muzzle()
	var to = p.global_position + Vector2(0, -22)
	if kind == "dash" and ok:
		for h in hist:
			if aim - h[0] <= 0.5:
				to = h[1] + Vector2(0, -22)
				break
	L._laser_off()
	if L.sniper_sprite.sprite_frames and L.sniper_sprite.sprite_frames.has_animation("fire"):
		L.sniper_sprite.play("fire")
	_shot_fx(from, to, kind == "block" and ok)
	if not ok:
		UISounds.play_hit()
		if L.camera and L.camera.has_method("add_trauma"):
			L.camera.add_trauma(0.4)
		var spr = L.player_sprite
		if spr:
			var tw = spr.create_tween()
			tw.tween_property(spr, "modulate", Color(1.0, 0.35, 0.3), 0.06)
			tw.tween_property(spr, "modulate", Color.WHITE, 0.3)
	elif kind == "block":
		UISounds.play_switch_on()
		if L.camera and L.camera.has_method("add_trauma"):
			L.camera.add_trauma(0.18)
	return ok

func _shot_fx(from: Vector2, to: Vector2, ricochet: bool) -> void:
	var fx = Node2D.new()
	fx.z_as_relative = false
	fx.z_index = 130
	L.add_child(fx)
	var line = Line2D.new()
	line.width = 3.0
	line.default_color = Color(1.0, 0.85, 0.45, 0.95)
	line.add_point(from)
	line.add_point(to)
	fx.add_child(line)
	var flash = Polygon2D.new()
	var star = PackedVector2Array()
	for k in range(10):
		star.append(Vector2.from_angle(k * TAU / 10.0) * (10.0 if k % 2 == 0 else 4.0))
	flash.polygon = star
	flash.color = Color(1.0, 0.97, 0.8)
	flash.position = from
	fx.add_child(flash)
	if ricochet:
		var r = Line2D.new()
		r.width = 2.0
		r.default_color = Color(1.0, 0.9, 0.5, 0.9)
		r.add_point(to)
		r.add_point(to + Vector2(-140, -120))
		fx.add_child(r)
		var spark = Polygon2D.new()
		var sp = PackedVector2Array()
		for k in range(8):
			sp.append(Vector2.from_angle(k * TAU / 8.0) * (9.0 if k % 2 == 0 else 3.0))
		spark.polygon = sp
		spark.color = Color(1.0, 1.0, 0.85)
		spark.position = to
		fx.add_child(spark)
	var tw = fx.create_tween()
	tw.tween_property(fx, "modulate:a", 0.0, 0.35).set_delay(0.08)
	tw.tween_callback(fx.queue_free)

func night_incident(sh: int) -> int:
	match sh:
		2: return L.MGE_FIRE
		3: return L.MGE_STUCK
		4: return L.MGE_SHORT
	return L.MGE_NONE

func night_has_lessons(sh: int, st: int) -> bool:
	var inc = night_incident(sh)
	return (sh >= 2 and not L._tut_done("inspect")) or not L._tut_done("st_%d" % st) \
		or sh >= L.ESCAPE_FROM_SHIFT \
		or (inc != L.MGE_NONE and not L._tut_done("inc_%d" % inc))

func run_night(sh: int, st: int) -> void:
	white(true, 0.0)
	L.fade_rect.color.a = 0.0
	enter(st)
	L._set_hud_visible(true)
	if L.player_gui:
		L.player_gui.visible = true
	L._place_air_bar()
	await _wait(0.4)
	await white(false, 1.4)
	await _read(tr("СОН"), tr("Опять это белое место. Пока все спят — учись. Здесь ошибки ничего не стоят."), Callable(), false)
	if sh >= 2 and not L._tut_done("inspect"):
		await _inspect_lesson()
	var inc0 = night_incident(sh)
	var work_lessons = not L._tut_done("st_%d" % st) or (inc0 != L.MGE_NONE and not L._tut_done("inc_%d" % inc0))
	if work_lessons:
		await _task(tr("К СТАНКУ"), tr("Справа — станок, за которым ты будешь работать в смену %d.") % sh, ["D"], L._zone_screen_rect, func(): return L._is_player_in_zone())
	if not L._tut_done("st_%d" % st):
		await _read(tr("НОВЫЙ СТАНОК: ") + tr(String(L.STATION_TITLE.get(st, ""))), _howto(st), L._zone_screen_rect)
		await practice(st, 2, tr(String(L.STATION_TITLE.get(st, ""))), _howto(st))
	var inc = night_incident(sh)
	if inc != L.MGE_NONE and not L._tut_done("inc_%d" % inc):
		var food = _practice_item(st)
		var names = {L.MGE_FIRE: tr("ПОЖАР"), L.MGE_STUCK: tr("ЗАКЛИНИЛО КНОПКУ"), L.MGE_SHORT: tr("ЗАМЫКАНИЕ")}
		await _read(tr("АВАРИЯ: ") + String(names.get(inc, "")), tr("С этой смены у станка может случиться авария. Тогда работа встаёт, и её надо ликвидировать самому. Сейчас попробуешь — подсказка будет рядом с окном аварии."), L._zone_screen_rect)
		await _back_to_station()
		await L._run_incident(inc, true)
		L._tut_mark("inc_%d" % inc)
		if is_instance_valid(food["node"]):
			var ftw = food["node"].create_tween()
			ftw.tween_property(food["node"], "modulate:a", 0.0, 0.4)
			ftw.tween_callback(food["node"].queue_free)
		await _wait(0.6)
	if sh >= L.ESCAPE_FROM_SHIFT and L._tut_done("escape_eve"):
		await _read(tr("ЗАВТРА ВАЖНЫЙ ДЕНЬ"), tr("Завтра снова есть шанс сбежать. Запиши, когда уходят охрана и снайпер, и дождись, пока пост опустеет. Не упусти момент."), Callable(), false)
	elif sh >= L.ESCAPE_FROM_SHIFT:
		await _read(tr("ЗАВТРА ВАЖНЫЙ ДЕНЬ"), tr("Следующая смена — очень важная. С неё снайпер тоже начинает уходить с поста. Если охрана и снайпер уйдут в одно и то же время — пост опустеет, и это единственный шанс сбежать. Смотри внимательно и не ошибись."), Callable(), false)
		L._tut_mark("escape_eve")
	await _read(tr("ПОРА ВСТАВАТЬ"), tr("Скоро подъём. Впереди смена %d.") % sh, Callable(), false)
	await white(true, 1.0)
	leave()
	L.fade_rect.visible = true
	L.fade_rect.color = Color(0, 0, 0, 1)
	await white(false, 0.0)

var _targets: Array = []
var _clicked: Dictionary = {}

const WRAP_HALF := 900.0

func _wrap_player() -> void:
	if not _on or L.player == null or L.state == L.State.INSPECT:
		return
	var cx = _zone_x()
	var p = L.player.global_position
	var d := 0.0
	if p.x < cx - WRAP_HALF:
		d = WRAP_HALF * 2.0
	elif p.x > cx + WRAP_HALF:
		d = -WRAP_HALF * 2.0
	if d == 0.0:
		return
	L.player.global_position.x += d
	if L.camera:
		L.camera.global_position.x += d

func _process(_d: float) -> void:
	if _props:
		_props.queue_redraw()
	_wrap_player()
	var insp = L != null and L.state == L.State.INSPECT
	for t in _targets:
		var n = t["node"]
		if not is_instance_valid(n):
			continue
		L._ensure_outline(n, t["color"])
		if n.material is ShaderMaterial:
			var col: Color = t["color"]
			var deep = Color(0.1, 0.32, 1.0) if (col.h > 0.4 and col.h < 0.8) else Color(1.0, 0.6, 0.0)
			var pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 4.0)
			n.material.set_shader_parameter("active", 1.0 if (insp and n.visible and not _clicked.has(t["id"])) else 0.0)
			n.material.set_shader_parameter("outline_color", deep.lerp(col, pulse * 0.5))
			n.material.set_shader_parameter("width", 2.0)
			n.material.set_shader_parameter("glow", 0.3 + 0.2 * pulse)

func _clear_targets() -> void:
	for t in _targets:
		var n = t["node"]
		if is_instance_valid(n) and n.material is ShaderMaterial:
			n.material.set_shader_parameter("active", 0.0)
			n.material.set_shader_parameter("width", 1.0)
			n.material.set_shader_parameter("glow", 0.24)
	_targets.clear()

func inspect_click(wp: Vector2) -> void:
	for t in _targets:
		var n = t["node"]
		if not is_instance_valid(n) or not n.visible:
			continue
		if L._node_hit(n, wp) != -1.0:
			_clicked[t["id"]] = true
			L._show_inspect_text(t["title"], t["text"], t.get("journal", ""))
			if t.has("journal"):
				L._add_journal_note(DREAM_NOTE + t["id"], t["title"] + ": " + t["journal"])
			return

func _guard_run_loop() -> void:
	var g = L.guard_sprite
	if g == null:
		return
	while is_instance_valid(g) and _on:
		g.position = _guard_spot()
		g.modulate.a = 1.0
		g.visible = true
		g.flip_h = true
		if g.sprite_frames and g.sprite_frames.has_animation("jogging"):
			g.play("jogging")
		var tw = g.create_tween().set_ignore_time_scale(true)
		tw.tween_property(g, "position:x", g.position.x - 280.0, 2.4)
		tw.tween_property(g, "modulate:a", 0.0, 0.25)
		await tw.finished
		if _clicked.has("guard") or not _on:
			break
		await _wait(0.9)

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
			"text": tr("Мой пресс. Во сне он тихий — ни шипения, ни масла. Даже непривычно."),
			"journal": tr("во сне он тихий — ни шипения, ни масла.")},
		{"node": L.guard_sprite, "id": "guard", "color": L.COLOR_HIGHLIGHT_YELLOW, "title": tr("ПЕРЕСМЕНКА"),
			"text": tr("Охранник уходит с поста. Запомню время — так и складывается расписание."),
			"journal": tr("во сне охранник тоже уходит с поста. Наяву такие уходы отмечаются галочками со временем.")},
	]
	await _task(tr("РЕЖИМ ОСМОТРА"), tr("Нажми %s: время замедлится, а всё полезное вокруг подсветится.") % L._key_name("inspect"), [L._key_name("inspect")], L._act_screen_rect.bind(false),
		func(): return L.state == L.State.INSPECT)
	await _task(tr("ВЗГЛЯД"), tr("В осмотре рыба стоит на месте, а взгляд летает по всему цеху: W A S D."), ["W", "A", "S", "D"], Callable(),
		func(): return L.inspect_camera_offset.length() > 100.0)
	await _read(tr("ДВА ЦВЕТА"), tr("СИНЕЕ — по желанию: рабочие, вещи, места. Кликни — узнаешь что-то полезное или просто интересное.\nЖЁЛТОЕ — обязательно: так светится пересменка, когда охранник или снайпер уходит с поста. Кликни по жёлтому, пока он не вернулся, — время запишется в журнал. Без этого не узнать расписание."), Callable(), false)
	await _task(tr("СИНЕЕ"), tr("Кликни мышкой по станку — он подсвечен синим."), [tr("ЛКМ")], Callable(),
		func(): return _clicked.has("press"))
	await _wait(0.8)
	_guard_run_loop()
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
