extends StorageRoom

const NOTE_TITLE := "ЗАПИСКА"

var _note: Node2D = null
var _note_area: Area2D = null

func room_ready(_first: bool) -> void:
	var vent = get_node_or_null("NoteVent")
	if vent:
		_build_grille(vent.global_position)
	for d in get_tree().get_nodes_in_group("storage_doors"):
		if d.lock == "keycard":
			d.locked_tried.connect(_on_keycard_locked)
	if StorageMap.flag("note_dropped"):
		_place_note(_note_floor_pos(), false)

func _build_grille(p: Vector2) -> void:
	var g = ColorRect.new()
	g.color = Color(0.08, 0.08, 0.09)
	g.size = Vector2(54, 16)
	g.position = p + Vector2(-27, 0)
	g.z_index = 6
	add_child(g)
	for i in range(5):
		var s = ColorRect.new()
		s.color = Color(0.32, 0.33, 0.35)
		s.size = Vector2(3, 14)
		s.position = Vector2(4 + i * 11, 1)
		g.add_child(s)

func _note_floor_pos() -> Vector2:
	var vent = get_node_or_null("NoteVent")
	var x = vent.global_position.x if vent else room_rect.get_center().x
	return Vector2(x - 40.0, GROUND_Y)

func _on_keycard_locked(_d) -> void:
	if StorageMap.flag("note_dropped"):
		return
	StorageMap.set_flag("note_dropped")
	var vent = get_node_or_null("NoteVent")
	var start: Vector2 = vent.global_position + Vector2(0, 16) if vent else _note_floor_pos() + Vector2(0, -250)
	_place_note(start, true)

func _make_paper() -> Node2D:
	var n = Node2D.new()
	var paper = ColorRect.new()
	paper.color = Color(0.9, 0.87, 0.76)
	paper.size = Vector2(14, 10)
	paper.position = Vector2(-7, -10)
	n.add_child(paper)
	var line = ColorRect.new()
	line.color = Color(0.4, 0.36, 0.3)
	line.size = Vector2(8, 1)
	line.position = Vector2(3, 3)
	paper.add_child(line)
	var line2 = line.duplicate()
	line2.position = Vector2(3, 6)
	paper.add_child(line2)
	n.z_index = 8
	return n

func _place_note(start: Vector2, falling: bool) -> void:
	_note = _make_paper()
	_note.global_position = start
	add_child(_note)
	var floor_p = _note_floor_pos()
	if falling:
		lock_player(true)
		if camera and camera.has_method("add_trauma"):
			camera.add_trauma(0.15)
		var tw = create_tween()
		var steps := 6
		var y0 = start.y
		for i in range(steps):
			var k = float(i + 1) / steps
			var x = lerp(start.x, floor_p.x, k) + (18.0 if i % 2 == 0 else -18.0) * (1.0 - k)
			tw.tween_property(_note, "global_position", Vector2(x, lerp(y0, floor_p.y, k)), 0.32).set_trans(Tween.TRANS_SINE)
			tw.parallel().tween_property(_note, "rotation", deg_to_rad(25.0 if i % 2 == 0 else -25.0) * (1.0 - k), 0.32)
		await tw.finished
		if not is_inside_tree():
			return
		lock_player(false)
		if player:
			float_text(player.global_position + Vector2(0, -70), tr("Что-то упало из вентиляции."), Color(0.9, 0.9, 1.0), 2.0)
	else:
		_note.global_position = floor_p
	_note_area = make_interact(floor_p, Vector2(70, 60), tr("Прочитать"), _read_note)

func _read_note() -> void:
	StorageMap.set_flag("note_read")
	StorageNote.open(self, tr(NOTE_TITLE), tr("Если ты это читаешь — ты не из охраны.\n\nЭту дверь открывает только ключ-карта. Она есть у одного человека — у бухгалтера.\n\nЕго кабинет над складом, и по коридорам туда не попасть. Только через вентиляцию: люк в заваленной комнате, наверху справа.\n\nНо дверь в завал под током. Щиток — в электрощитовой, под складом.\n\nУдачи. Не попадись."))
