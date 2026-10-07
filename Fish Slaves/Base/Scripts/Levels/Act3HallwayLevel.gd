func get_chatter_state():
	return {
		"queue": chatter_queue.duplicate(),
		"current_text": chatter_full_text,
		"char_index": chatter_char_index
	}

func set_chatter_state(state: Dictionary):
	if state.is_empty():
		return
	
	chatter_queue = state["queue"].duplicate()
	chatter_full_text = state["current_text"]
	chatter_char_index = state["char_index"]
	chatter_active = true
	chatter_typing = false
	
	chatter_label.text = chatter_full_text
	chatter_label_far.text = chatter_full_text
	chatter_typed_text = chatter_full_text
	chatter_panel.visible = true
	chatter_panel.modulate.a = 1.0
	
	for phrase in chatter_phrases:
		var text = ""
		if phrase.has("text"):
			text = phrase["text"]
		elif phrase.has("parts"):
			for p in phrase["parts"]:
				text += p
		if text == chatter_full_text:
			chatter_speaker = phrase["speaker"]
			chatter_panel_height = phrase.get("height", 28.0)
			_update_speaker_icons()
			break
	
	update_chatter_panel()
	timer.start(2.5)

#func _update_glitch(delta: float) -> void:
	#var player_pos = player.global_position
	#var safe_zone_min = Vector2(672, 488)
	#var safe_zone_max = Vector2(864, 520)
	#
	#var dist_to_safe_zone = 0.0
	#if player_pos.x < safe_zone_min.x:
		#dist_to_safe_zone += safe_zone_min.x - player_pos.x
	#if player_pos.x > safe_zone_max.x:
		#dist_to_safe_zone += player_pos.x - safe_zone_max.x
	#if player_pos.y < safe_zone_min.y:
		#dist_to_safe_zone += safe_zone_min.y - player_pos.y
	#if player_pos.y > safe_zone_max.y:
		#dist_to_safe_zone += player_pos.y - safe_zone_max.y
	#
	#var max_dist = 500.0
	#var t = clamp(dist_to_safe_zone / max_dist, 0.0, 1.0)
	#var glitch_intensity = clamp(t * t, 0.0, 0.9)
	#
	#text_glitch_timer += delta
	#var interval = clamp(randf_range(0.8, 1.8) - glitch_intensity * 1.2, 0.3, 1.8)
	#
	#if text_glitch_timer > interval and glitch_intensity > 0.02:
		#text_glitch_timer = 0.0
		#_apply_text_glitch(glitch_intensity)
	#
	#if glitch_intensity > 0.1 and randf() < glitch_intensity * 0.6:
		#_apply_visual_glitch(glitch_intensity)
	#
	#UISounds.set_glitch(glitch_intensity)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if cutscene_active:
			return
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	
	if get_tree().paused:
		return
	
	if event.is_action_pressed("interact") and in_zone and not dialogue_done and not cutscene_active:
		_show_interact_pressed()
		stop_chatter()
		hit_sequence()

func update_chatter_panel() -> void:
	if fading_chatter:
		return
	
	if not chatter_active:
		chatter_panel.visible = false
		chatter_panel_far.visible = false
		phantom_left.visible = false
		phantom_left_label.visible = false
		phantom_right.visible = false
		phantom_right_label.visible = false
		return
	
	var cam: Camera2D = player_camera
	if not cam:
		return
	
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var zoom = cam.zoom.x
	
	var cam_left = cam.global_position.x - viewport_size.x / 2.0 / zoom
	var cam_right = cam.global_position.x + viewport_size.x / 2.0 / zoom
	var cam_top = cam.global_position.y - viewport_size.y / 2.0 / zoom
	var cam_bottom = cam.global_position.y + viewport_size.y / 2.0 / zoom
	
	var scientist_x = scientist.global_position.x
	var scientist_y = scientist.global_position.y
	
	var scientist_visible = (scientist_x >= cam_left and scientist_x <= cam_right and 
							 scientist_y >= cam_top and scientist_y <= cam_bottom)
	
	var dist_to_visible = 0.0
	if not scientist_visible:
		var dx = 0.0
		if scientist_x < cam_left:
			dx = cam_left - scientist_x
		if scientist_x > cam_right:
			dx = scientist_x - cam_right
		
		var dy = 0.0
		if scientist_y < cam_top:
			dy = cam_top - scientist_y
		if scientist_y > cam_bottom:
			dy = scientist_y - cam_bottom
		
		dist_to_visible = max(dx, dy)
	
	var fade = clamp(dist_to_visible / 300.0, 0.0, 1.0)
	if scientist_visible:
		fade = 0.0
	
	var phantom_alpha = fade * 0.25
	current_phantom_offset = lerp(current_phantom_offset, fade, 0.03)
	
	if fade < 0.05:
		_show_chatter_near()
	else:
		_show_chatter_far(fade, phantom_alpha, viewport_size)

func _show_chatter_near() -> void:
	chatter_panel_far.visible = false
	phantom_left.visible = false
	phantom_left_label.visible = false
	phantom_right.visible = false
	phantom_right_label.visible = false
	chatter_panel.visible = true
	chatter_panel.z_index = 100
	current_phantom_offset = 0.0
	
	chatter_panel.size = Vector2(PANEL_WIDTH_NEAR, chatter_panel_height)
	chatter_label.position = Vector2(4, 4)
	chatter_label.size = chatter_panel.size - Vector2(8, 8)
	
	if chatter_speaker == "mechanic":
		chatter_panel.position = mechanic.global_position + Vector2(22, -30)
	else:
		chatter_panel.position = scientist.global_position + Vector2(-120, -25)
	
	_clamp_chatter_to_viewport()

func _show_chatter_far(fade: float, phantom_alpha: float, viewport_size: Vector2) -> void:
	chatter_panel.visible = false
	
	var margin = 20.0
	var panel_width = PANEL_WIDTH_FAR
	var panel_height = PANEL_HEIGHT_FAR
	
	var target_x = viewport_size.x / 2.0 - panel_width / 2.0
	var target_y = viewport_size.y - margin - panel_height
	
	chatter_panel_far.visible = true
	chatter_panel_far.z_index = 100
	chatter_panel_far.size = Vector2(panel_width, panel_height)
	chatter_panel_far.position = Vector2(target_x, target_y)
	chatter_panel_far.modulate.a = fade
	
	chatter_label_far.text = chatter_label.text
	chatter_label_far.position = Vector2(70, 10)
	chatter_label_far.size = chatter_panel_far.size - Vector2(80, 20)
	
	var icon_size = 60.0
	var icon_y = (panel_height - icon_size) / 2.0
	
	if speaker_icon_far:
		speaker_icon_far.position = Vector2(5, icon_y)
		speaker_icon_far.size = Vector2(icon_size, icon_size)
	
	var zoom = player_camera.zoom.x if player_camera else 1.0
	var offset_x_phantom = int(35 * current_phantom_offset) / zoom
	var offset_y_phantom = int(25 * current_phantom_offset) / zoom
	
	phantom_left.visible = true
	phantom_left.size = chatter_panel_far.size
	phantom_left.position = chatter_panel_far.position + Vector2(-offset_x_phantom, offset_y_phantom)
	phantom_left.modulate.a = phantom_alpha
	phantom_left.z_index = 99
	phantom_left_label.visible = true
	phantom_left_label.text = chatter_label.text
	phantom_left_label.position = Vector2(70, 10)
	phantom_left_label.size = phantom_left.size - Vector2(80, 20)
	
	if speaker_icon_left:
		speaker_icon_left.position = Vector2(5, icon_y)
		speaker_icon_left.size = Vector2(icon_size, icon_size)
	
	phantom_right.visible = true
	phantom_right.size = chatter_panel_far.size
	phantom_right.position = chatter_panel_far.position + Vector2(offset_x_phantom, -offset_y_phantom)
	phantom_right.modulate.a = phantom_alpha
	phantom_right.z_index = 99
	phantom_right_label.visible = true
	phantom_right_label.text = chatter_label.text
	phantom_right_label.position = Vector2(70, 10)
	phantom_right_label.size = phantom_right.size - Vector2(80, 20)
	
	if speaker_icon_right:
		speaker_icon_right.position = Vector2(5, icon_y)
		speaker_icon_right.size = Vector2(icon_size, icon_size)

func _clamp_chatter_to_viewport() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var panel_size: Vector2 = chatter_panel.size
	chatter_panel.position.x = clamp(chatter_panel.position.x, 0.0, viewport_size.x - panel_size.x)
	chatter_panel.position.y = clamp(chatter_panel.position.y, 0.0, viewport_size.y - panel_size.y)

func _generate_chatter_queue() -> void:
	chatter_queue.clear()
	for phrase in chatter_phrases:
		chatter_queue.append(phrase)

func _update_speaker_icons() -> void:
	var icon = scientist_icon if chatter_speaker == "scientist" else mechanic_icon
	if speaker_icon_far:
		speaker_icon_far.texture = icon
		speaker_icon_far.modulate = Color(1.0, 1.0, 1.0, 0.8)
	if speaker_icon_left:
		speaker_icon_left.texture = icon
		speaker_icon_left.modulate = Color(1.0, 1.0, 1.0, 0.8)
	if speaker_icon_right:
		speaker_icon_right.texture = icon
		speaker_icon_right.modulate = Color(1.0, 1.0, 1.0, 0.8)

func _show_next_chatter_line() -> void:
	if chatter_silence:
		return
	
	if chatter_queue.is_empty():
		chatter_queue = chatter_phrases.duplicate()
	
	var data: Dictionary = chatter_queue.pop_front()
	chatter_speaker = data["speaker"]
	_update_speaker_icons()
	
	if data.has("parts"):
		chatter_segments.clear()
		for part in data["parts"]:
			var upper = part.to_upper()
			var swear_list = ["БЛЯТЬ", "ЗАЕБАЛ", "НАХУЙ", "ЕБАННЫЙ", "ПИЗДЕТЬ"]
			var is_swear = upper in swear_list
			chatter_segments.append({"text": part, "swear": is_swear})
		chatter_segment_index = 0
		chatter_char_in_segment = 0
		chatter_full_text = ""
		for p in data["parts"]:
			chatter_full_text += p
	else:
		chatter_segments.clear()
		chatter_full_text = data["text"]
		chatter_segments.append({"text": chatter_full_text, "swear": false})
		chatter_segment_index = 0
		chatter_char_in_segment = 0
	
	if chatter_full_text == "...":
		chatter_silence = true
		chatter_panel.visible = false
		chatter_panel_far.visible = false
		phantom_left.visible = false
		phantom_right.visible = false
		stop_chatter()
		Achievements.unlock_coffee()
		UISounds.play_achievement()
		_show_achievement("Кофе бы...")
		return
	
	chatter_panel_height = data.get("height", 28.0)
	
	chatter_label.clear()
	chatter_label_far.clear()
	chatter_label.text = ""
	chatter_label_far.text = ""
	chatter_typed_text = ""
	chatter_panel.visible = false
	chatter_panel_far.visible = false
	chatter_typing = true
	update_chatter_panel()
	timer.start(typing_speed)

func start_chatter() -> void:
	if chatter_queue.is_empty():
		_generate_chatter_queue()
	
	chatter_active = true
	chatter_typing = true
	chatter_panel.visible = true
	chatter_panel.modulate.a = 1.0
	chatter_panel_far.visible = false
	phantom_left.visible = false
	phantom_right.visible = false
	current_phantom_offset = 0.0
	
	if chatter_queue.is_empty():
		chatter_queue = chatter_phrases.duplicate()
	
	var data: Dictionary = chatter_queue.pop_front()
	chatter_speaker = data["speaker"]
	_update_speaker_icons()
	
	if data.has("parts"):
		chatter_segments.clear()
		for part in data["parts"]:
			var upper = part.to_upper()
			var swear_list = ["БЛЯТЬ", "ЗАЕБАЛ", "НАХУЙ", "ЕБАННЫЙ", "ПИЗДЕТЬ"]
			var is_swear = upper in swear_list
			chatter_segments.append({"text": part, "swear": is_swear})
		chatter_segment_index = 0
		chatter_char_in_segment = 0
	else:
		chatter_segments.clear()
		chatter_full_text = data.get("text", "")
		chatter_segments.append({"text": chatter_full_text, "swear": false})
		chatter_segment_index = 0
		chatter_char_in_segment = 0
	
	chatter_panel_height = data.get("height", 28.0)
	chatter_label.clear()
	chatter_label_far.clear()
	chatter_label.text = ""
	chatter_label_far.text = ""
	chatter_typed_text = ""
	
	update_chatter_panel()
	
	timer.stop()
	timer.wait_time = typing_speed
	timer.start()

func stop_chatter() -> void:
	chatter_active = false
	chatter_typing = false
	chatter_panel.visible = false
	chatter_panel_far.visible = false
	phantom_left.visible = false
	phantom_left_label.visible = false
	phantom_right.visible = false
	phantom_right_label.visible = false
	if glitch_tween and glitch_tween.is_valid():
		glitch_tween.kill()

func _apply_text_glitch(intensity: float) -> void:
	if not chatter_active or cutscene_active or not chatter_label or is_glitching:
		return

	var original = chatter_typed_text
	if original.length() == 0:
		return

	is_glitching = true

	if intensity > 0.03:
		var chars_main = []
		for c in original:
			chars_main.append(c)

		var up_count = max(1, int(intensity * chars_main.size() * 0.12))
		for i in range(up_count):
			var pos = randi() % chars_main.size()
			if chars_main[pos] != " ":
				chars_main[pos] = chars_main[pos].to_upper()

		var rm_count = max(1, int(intensity * chars_main.size() * 0.08))
		for i in range(rm_count):
			var pos = randi() % chars_main.size()
			if chars_main[pos] != " ":
				chars_main[pos] = ""

		var glitched_main = ""
		for c in chars_main:
			glitched_main += c

		chatter_label.text = glitched_main
		chatter_label.add_theme_color_override("default_color", Color(1.0, 0.4, 0.4))

		if chatter_label_far:
			chatter_label_far.text = glitched_main
			chatter_label_far.add_theme_color_override("default_color", Color(1.0, 0.4, 0.4))

		await get_tree().create_timer(0.06).timeout

		if chatter_active and not cutscene_active and is_instance_valid(chatter_label):
			
			chatter_label.text = chatter_typed_text
			chatter_label.add_theme_color_override("default_color", Color(0.0, 0.0, 0.0, 1.0))
			if chatter_label_far:
				chatter_label_far.text = chatter_typed_text
				chatter_label_far.add_theme_color_override("default_color", Color(0.0, 0.0, 0.0, 1.0))

	is_glitching = false


func shake_panel() -> void:
	if not dialogue_panel:
		return
	var orig = dialogue_panel.position
	var t = create_tween()
	t.set_loops(3)
	t.tween_property(dialogue_panel, "position:x", orig.x + 5, 0.04)
	t.tween_property(dialogue_panel, "position:x", orig.x - 5, 0.04)
	t.tween_property(dialogue_panel, "position:x", orig.x, 0.04)

func shake_chatter_panel() -> void:
	var tp = chatter_panel if chatter_panel.visible else (chatter_panel_far if chatter_panel_far.visible else null)
	if not tp:
		return
	var orig = tp.position
	var t = create_tween()
	t.set_loops(3)
	t.tween_property(tp, "position:x", orig.x + 5, 0.04)
	t.tween_property(tp, "position:x", orig.x - 5, 0.04)
	t.tween_property(tp, "position:x", orig.x, 0.04)
	
func _apply_visual_glitch(intensity: float) -> void:
	var panels_to_shake: Array[Panel] = []

func scientist_say(p1: String, m: String, p2: String) -> void:
	if not text_label or not dialogue_panel or not scientist or not timer:
		return
	
	UISounds.stop_all_dialog()
	timer.stop()
	dialogue_panel.modulate.a = 1.0
	text_label.text = ""
	
	var full = p1 + m + p2
	var lines = ceil(full.length() / 11.0) + 1
	var h = max(28.0, lines * 15.0)
	
	dialogue_panel.size = Vector2(100, h)
	text_label.size = dialogue_panel.size - Vector2(8, 8)
	text_label.position = Vector2(4, 4)
	dialogue_panel.position = scientist.global_position + Vector2(-120, -25)
	_clamp_panel_to_viewport()
	dialogue_panel.visible = true
	
	part1 = p1
	mate = m
	part2 = p2
	typing_index = 0
	mate_shown = false
	waiting_for_next = false
	timer.start(typing_speed)

func mechanic_say(text: String, h_override: float = 0.0) -> void:
	if not text_label or not dialogue_panel or not mechanic or not timer:
		return
	
	UISounds.stop_all_dialog()
	timer.stop()
	dialogue_panel.modulate.a = 1.0
	text_label.text = ""
	
	var h: float
	if h_override > 0:
		h = h_override
	else:
		var lines = ceil(text.length() / 14.0) + 1
		h = max(28.0, lines * 15.0)
	
	dialogue_panel.size = Vector2(100, h)
	text_label.size = dialogue_panel.size - Vector2(8, 8)
	text_label.position = Vector2(4, 4)
	dialogue_panel.position = mechanic.global_position + Vector2(22, -30)
	_clamp_panel_to_viewport()
	dialogue_panel.visible = true
	
	part1 = text
	mate = ""
	part2 = ""
	typing_index = 0
	mate_shown = false
	waiting_for_next = false
	timer.start(typing_speed)

func _clamp_panel_to_viewport() -> void:
	var vp = get_viewport().get_visible_rect().size
	dialogue_panel.position.x = clamp(dialogue_panel.position.x, 0.0, vp.x - dialogue_panel.size.x)
	dialogue_panel.position.y = clamp(dialogue_panel.position.y, 0.0, vp.y - dialogue_panel.size.y)

func _on_timer_timeout() -> void:
	if get_tree().paused:
		return
	
	if cutscene_active:
		_on_cutscene_timer()
		return
	
	if chatter_active and chatter_typing:
		_on_chatter_typing_timer()
		return
	
	if chatter_active and not chatter_typing:
		_show_next_chatter_line()

func _on_cutscene_timer() -> void:
	if waiting_for_next:
		timer.stop()
		waiting_for_next = false
		_advance_cutscene()
		return
	
	if mate != "" and not mate_shown:
		if typing_index < part1.length():
			text_label.text += part1[typing_index]
			typing_index += 1
			UISounds.play_scientist()
			timer.start(typing_speed)
		else:
			text_label.text += "[color=#FF3333]" + mate + "[/color]"
			mate_shown = true
			shake_panel()
			UISounds.play_scientist()
			timer.start(typing_speed)
		return
	
	if mate != "" and mate_shown:
		if typing_index - part1.length() < part2.length():
			text_label.text += part2[typing_index - part1.length()]
			typing_index += 1
			UISounds.play_scientist()
			timer.start(typing_speed)
		else:
			timer.stop()
			waiting_for_next = true
			timer.start(0.6)
		return
	
	if typing_index < part1.length():
		text_label.text += part1[typing_index]
		typing_index += 1
		UISounds.play_mechanic()
		timer.start(typing_speed)
	else:
		timer.stop()
		waiting_for_next = true
		timer.start(0.6)

func _on_chatter_typing_timer() -> void:
	if chatter_segment_index < chatter_segments.size():
		var seg: Dictionary = chatter_segments[chatter_segment_index]
		if seg["swear"]:
			chatter_typed_text += "[color=#FF3333]" + seg["text"] + "[/color]"
			chatter_label.text = chatter_typed_text
			shake_chatter_panel()
			chatter_segment_index += 1
			chatter_char_in_segment = 0
			timer.start(typing_speed * 2)
		else:
			var seg_text = seg["text"]
			if chatter_char_in_segment < seg_text.length():
				chatter_typed_text += seg_text[chatter_char_in_segment]
				chatter_label.text = chatter_typed_text
				chatter_char_in_segment += 1
				timer.start(typing_speed)
			else:
				chatter_segment_index += 1
				chatter_char_in_segment = 0
				timer.start(typing_speed)
		if chatter_speaker == "scientist":
			UISounds.play_scientist()
		else:
			UISounds.play_mechanic()
		return
	else:
		chatter_typing = false
		timer.start(2.5)

func _on_dialogue_timer_timeout() -> void:
	pass

func hit_sequence() -> void:
	if interact_icon:
		interact_icon.visible = false
	cutscene_active = true
	if player and player.has_method("hit_glass"):
		player.hit_glass()
	
	await get_tree().create_timer(1.0).timeout
	
	var target_global_pos = cutscene_cam.global_position
	var target_zoom = cutscene_cam.zoom
	
	player_camera.enabled = false
	
	var temp_cam = Camera2D.new()
	temp_cam.name = "CutsceneCameraTemp"
	var viewport_size = get_viewport().get_visible_rect().size
	var offset_x = viewport_size.x / 16.0 - 16.25
	temp_cam.global_position = player.global_position - Vector2(offset_x, 0)
	temp_cam.zoom = player_camera.zoom
	temp_cam.enabled = true
	temp_cam.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(temp_cam)
	
	await get_tree().process_frame
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(temp_cam, "global_position", target_global_pos, 1.5)
	tween.tween_property(temp_cam, "zoom", target_zoom, 1.5)
	
	await get_tree().create_timer(1.8).timeout
	
	temp_cam.enabled = false
	cutscene_cam.enabled = true
	cutscene_cam.global_position = target_global_pos
	cutscene_cam.zoom = target_zoom
	temp_cam.queue_free()
	
	start_cutscene()

func _transition_to_cutscene_camera() -> void:
	if not player_camera or not cutscene_cam:
		return
	
	var target_pos = player.global_position + Vector2(0, -100)
	
	cutscene_cam.global_position = player_camera.global_position
	cutscene_cam.zoom = player_camera.zoom
	cutscene_cam.enabled = true
	player_camera.enabled = false
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(cutscene_cam, "global_position", target_pos, 1.2).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(cutscene_cam, "zoom", Vector2(1.5, 1.5), 1.2).set_ease(Tween.EASE_IN_OUT)

func start_cutscene() -> void:
	if not player or not interact_icon:
		return
	
	chatter_active = false
	chatter_typing = false
	stop_chatter()
	timer.stop()
	
	cutscene_active = true
	dialogue_done = true
	if interact_icon:
		interact_icon.visible = false
	player.set_physics_process(false)
	player.set_process(false)
	
	cutscene_step = 1
	_scientist_play_angry()
	scientist_say("Проснулся ", "БЛЯТЬ", " наконец...")

func _advance_cutscene() -> void:
	UISounds.stop_all_dialog()
	timer.stop()
	
	match cutscene_step:
		1:
			cutscene_step = 2
			scientist_say("Пол комплекса чуть не ", "РАЗЪЕБАЛ", "")
		2:
			cutscene_step = 3
			mechanic_say("Во-во...", 42.0)
		3:
			cutscene_step = 4
			mechanic_say("А простым работягам это все чинить...", 56.0)
		4:
			cutscene_step = 5
			dialogue_panel.visible = false
			_start_earthquake()

func _wait_for_cutscene_line() -> void:
	while not waiting_for_next:
		await get_tree().create_timer(0.05).timeout
	waiting_for_next = false

func _start_earthquake() -> void:
	UISounds.play_earthquake()
	
	if player_camera:
		player_camera.enabled = false
	cutscene_cam.enabled = true
	cutscene_cam.trauma = 0.8
	
	var quake_tween = create_tween()
	quake_tween.set_loops()
	quake_tween.tween_callback(func(): 
		if is_instance_valid(cutscene_cam):
			cutscene_cam.trauma = 0.8
	)
	quake_tween.tween_interval(0.05)
	
	scientist_say("", "ЕБАНЫЙ", " РОТ, ОПЯТЬ НАЧАЛОСЬ")
	await _wait_dialog()
	
	mechanic_say("ОНО СИЛЬНЕЕ ВСЕХ, ЧТО БЫЛИ ЗА ПОСЛЕДНИЙ ГОД", 85.0)
	await _wait_dialog()
	
	scientist_say("", "БЫСТРЕЕ", " ЭВАКУИРУЙ ПЕРСОНАЛ И ЗАКЛЮЧЕННЫХ")
	await _wait_dialog()
	
	mechanic_say("МЫ НЕ УСПЕ...", 56.0)
	await get_tree().create_timer(0.8).timeout
	
	_knockout_fish()
	_spawn_falling_debris()
	await get_tree().create_timer(0.6).timeout
	
	UISounds.stop_earthquake()
	
	quake_tween.kill()
	
	cutscene_cam.trauma = 0.0
	cutscene_cam.set_external_offset(Vector2.ZERO)
	cutscene_cam.enabled = false
	if player_camera:
		player_camera.enabled = true
	
	_show_blackout_title()

func _knockout_fish() -> void:
	if not player:
		return
	
	player.can_move = false
	player.velocity = Vector2.ZERO
	
	var player_sprite = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if not player_sprite:
		return
	
	player_sprite.play("wake")
	player_sprite.speed_scale = -1.0
	player_sprite.frame = player_sprite.sprite_frames.get_frame_count("wake") - 1
	
	var fade_tween = create_tween()
	fade_tween.tween_property(player_sprite, "modulate", Color(0.4, 0.4, 0.5, 1.0), 1.5)
	
	await get_tree().create_timer(1.5).timeout
	player_sprite.pause()

func _spawn_falling_debris() -> void:
	var view_size = get_viewport().get_visible_rect().size
	var debris = Control.new()
	debris.z_index = 200
	debris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(debris)
	
	var body = Polygon2D.new()
	var bw = 340
	var bh = 200
	var tw = 90
	var antialias = 1
	
	body.polygon = PackedVector2Array([
		Vector2(-60, -1500),
		Vector2(view_size.x + 60, -1500),
		Vector2(view_size.x + 60, -bh + antialias),
		Vector2(view_size.x - tw + 60, -bh + antialias),
		Vector2(view_size.x - tw + 60, -tw + antialias),
		Vector2(view_size.x - bw + 60, -tw + antialias),
		Vector2(view_size.x - bw + 60, antialias),
		Vector2(-60, antialias),
	])
	body.color = Color(0.06, 0.06, 0.08)
	body.antialiased = true
	debris.add_child(body)
	
	var crack = Line2D.new()
	crack.width = 2
	crack.default_color = Color(0.15, 0.15, 0.18)
	crack.antialiased = true
	crack.points = [
		Vector2(view_size.x - 80, -bh),
		Vector2(view_size.x - 40, -bh + 50),
		Vector2(view_size.x - 70, -bh + 90),
		Vector2(view_size.x - 120, -bh + 130),
	]
	debris.add_child(crack)
	
	var crack2 = Line2D.new()
	crack2.width = 1.5
	crack2.default_color = Color(0.12, 0.12, 0.15)
	crack2.antialiased = true
	crack2.points = [
		Vector2(view_size.x - bw + 20, -30),
		Vector2(view_size.x - bw + 80, -10),
		Vector2(view_size.x - bw + 60, 0),
	]
	debris.add_child(crack2)
	
	var rebars_data = [
		{"from": Vector2(view_size.x - bw + 60, 0), "to": Vector2(view_size.x - bw + 40, 70)},
		{"from": Vector2(view_size.x - bw + 120, 0), "to": Vector2(view_size.x - bw + 110, 100)},
		{"from": Vector2(view_size.x - bw + 220, 0), "to": Vector2(view_size.x - bw + 240, 80)},
		{"from": Vector2(view_size.x - tw + 60, -tw), "to": Vector2(view_size.x - tw + 120, -tw - 60)},
		{"from": Vector2(view_size.x - 40, -bh), "to": Vector2(view_size.x, -bh - 50)},
	]
	for r in rebars_data:
		var rebar = Line2D.new()
		rebar.width = 4
		rebar.default_color = Color(0.35, 0.25, 0.2)
		rebar.antialiased = true
		rebar.points = [r["from"], r["to"]]
		debris.add_child(rebar)
	
	for i in range(10):
		var chip = ColorRect.new()
		chip.color = Color(0.08, 0.08, 0.1)
		chip.size = Vector2(randf_range(6, 20), randf_range(6, 20))
		chip.position = Vector2(randf_range(60, view_size.x - 60), randf_range(-140, -40))
		debris.add_child(chip)
		
		var ct = create_tween()
		ct.tween_property(chip, "position:y", view_size.y + 
