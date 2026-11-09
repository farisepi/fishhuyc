extends Node

signal achievement_unlocked(id: String)

var coffee_unlocked: bool = false
var flashback_unlocked: bool = false
var pop_star_unlocked: bool = false
var rebel_unlocked: bool = false
var acrobat_unlocked: bool = false
var worker_of_month_unlocked: bool = false
var scout_unlocked: bool = false
var freedom_unlocked: bool = false
var chase_unlocked: bool = false
var handyman_unlocked: bool = false
## Factory stations the player has worked at (for "Разнорабочий"), kept between runs.
var stations_worked: Array = []
const ALL_STATIONS := [0, 1, 2, 3, 4]

## Achievements added after the menus were drawn: the menus build their rows from this list
## (copies of the last row). icon "" = no icon yet, a "?" badge is shown instead.
const EXTRA := [
	{"id": "chase", "name": "Погоня", "desc": "Пройти пролог", "icon": "Menu_AchivementMenu_Icon_Chase.png"},
	{"id": "handyman", "name": "Разнорабочий", "desc": "Поработать на всех станках", "icon": "Menu_AchivementMenu_Icon_Handyman.png"},
]

const TITLES := {
	"coffee": "Кофе бы...",
	"flashback": "Флешбек",
	"pop_star": "Поп-звезда",
	"rebel": "Бунтарь",
	"acrobat": "Акробат",
	"worker_of_month": "Работник месяца",
	"scout": "Разведчик",
	"freedom": "Свобода",
	"chase": "Погоня",
	"handyman": "Разнорабочий",
}
# these already play the sound inside unlock_*()
const SOUND_IN_UNLOCK := ["worker_of_month", "scout", "freedom"]

var _queue: Array = []
var _showing: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_achievements()
	achievement_unlocked.connect(_on_unlocked)


## Every new achievement gets the same pretty popup, wherever it was earned (scenes only
## add their own extras now - falling boxes, bubbles).
func _on_unlocked(id: String) -> void:
	_queue_popup.call_deferred(id)


func _queue_popup(id: String) -> void:
	_queue.append(id)
	if not _showing:
		_show_next()


func _show_next() -> void:
	_showing = true
	while not _queue.is_empty():
		var id: String = _queue.pop_front()
		if not (id in SOUND_IN_UNLOCK) and has_node("/root/UISounds"):
			UISounds.play_achievement()
		await _popup(tr(TITLES.get(id, id)), id)
	_showing = false


const FONT_PATH := "res://GameAssets/Fonts/MainFont/FontFiles/MainFont_Font.ttf"
const ICON_DIR := "res://GameAssets/Sprites/UserInterfaceSprites/AchievementMenuSprites/AchievementIconTextures/"
const ICONS := {
	"coffee": "Menu_AchivementMenu_Icon_Coffee.png",
	"flashback": "Menu_AchivementMenu_Icon_FlashBack.png",
	"pop_star": "Menu_AchivementMenu_Icon_PopStar.png",
	"rebel": "Menu_AchivementMenu_Icon_Rebel.png",
	"acrobat": "Menu_AchivementMenu_Icon_Acrobat.png",
	"worker_of_month": "Menu_AchivementMenu_Icon_EmployeeOfTheMonth.png",
	"scout": "Menu_AchivementMenu_Icon_Scout.png",
	"freedom": "Menu_AchivementMenu_Icon_Freedom.png",
	"chase": "Menu_AchivementMenu_Icon_Chase.png",
	"handyman": "Menu_AchivementMenu_Icon_Handyman.png",
}
const C_GOLD := Color(1.0, 0.78, 0.3)
const POPUP_SCALE := 0.5
const C_GOLD_D := Color(0.62, 0.38, 0.1)
const C_CARD := Color(0.07, 0.075, 0.1, 0.97)

## Popup: a dark card with a gold frame slides in from the right, a gold badge with a star
## pops in and glows, sparkles fly out of it, a shine runs across the card, the title types
## in, and a thin gold line at the bottom shows how long it stays.
var _popup_font: FontFile = null

func _popup(title: String, id: String = "") -> void:
	# own copy of the pixel font: the shared one is forced to a fixed size by Global, which
	# would ignore the sizes here (and the card is drawn at half scale)
	if _popup_font == null:
		_popup_font = ResourceLoader.load(FONT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as FontFile
		if _popup_font:
			_popup_font.fixed_size = 0
	var font: Font = _popup_font
	var canvas = CanvasLayer.new()
	canvas.layer = 1100   # above the global fade, so it is visible even on a black screen
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	var vp = get_viewport().get_visible_rect().size
	var card_size = Vector2(380, 86)

	var card = Panel.new()
	card.size = card_size
	card.clip_contents = true
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb = StyleBoxFlat.new()
	sb.bg_color = C_CARD
	sb.border_color = C_GOLD
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	card.add_theme_stylebox_override("panel", sb)
	canvas.add_child(card)
	# inner thin line
	var inner = Panel.new()
	inner.position = Vector2(6, 6)
	inner.size = card_size - Vector2(12, 12)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb2 = StyleBoxFlat.new()
	sb2.bg_color = Color(0, 0, 0, 0)
	sb2.border_color = Color(C_GOLD_D, 0.6)
	sb2.set_border_width_all(1)
	sb2.set_corner_radius_all(2)
	inner.add_theme_stylebox_override("panel", sb2)
	card.add_child(inner)

	# badge with glow and star
	var badge_c = Vector2(46, card_size.y * 0.5)
	var glow = Control.new()
	glow.position = badge_c
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.draw.connect(func():
		var tt = Time.get_ticks_msec() / 1000.0
		var p = 0.5 + 0.5 * sin(tt * 4.0)
		for i in range(4):
			glow.draw_circle(Vector2.ZERO, 34.0 - i * 6.0, Color(C_GOLD, (0.05 + 0.04 * i) * (0.6 + 0.4 * p)))
		# rays
		for r in range(8):
			var a = tt * 0.8 + r * TAU / 8.0
			glow.draw_line(Vector2.from_angle(a) * 22.0, Vector2.from_angle(a) * (30.0 + 4.0 * p), Color(C_GOLD, 0.35), 2.0)
	)
	card.add_child(glow)
	var badge = Panel.new()
	badge.size = Vector2(46, 46)
	badge.position = badge_c - badge.size * 0.5
	badge.pivot_offset = badge.size * 0.5
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_tex: Texture2D = null
	if ICONS.has(id) and ResourceLoader.exists(ICON_DIR + ICONS[id]):
		icon_tex = load(ICON_DIR + ICONS[id])
	var sb3 = StyleBoxFlat.new()
	sb3.bg_color = Color(0.13, 0.11, 0.08) if icon_tex else C_GOLD
	sb3.border_color = C_GOLD if icon_tex else Color(0.25, 0.14, 0.03)
	sb3.set_border_width_all(3)
	sb3.border_width_bottom = 5
	sb3.set_corner_radius_all(6)
	badge.add_theme_stylebox_override("panel", sb3)
	card.add_child(badge)
	var shine = ColorRect.new()
	shine.color = Color(1, 1, 1, 0.45)
	shine.position = Vector2(6, 5)
	shine.size = Vector2(34, 3)
	shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(shine)
	if icon_tex:
		# the achievement's own icon (the same one as in the achievements menu), pixel-crisp
		var ic = TextureRect.new()
		ic.texture = icon_tex
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.size = Vector2(40, 40)
		ic.position = (badge.size - ic.size) * 0.5
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(ic)
		shine.color = Color(1, 1, 1, 0.12)
	var star = Label.new()
	star.visible = icon_tex == null
	star.text = "★"
	star.size = badge.size
	star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	star.add_theme_font_size_override("font_size", 30)
	star.add_theme_color_override("font_color", Color(0.35, 0.18, 0.02))
	star.add_theme_color_override("font_shadow_color", Color(1, 0.95, 0.7, 0.8))
	star.add_theme_constant_override("shadow_offset_y", 2)
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(star)

	# texts
	var header = Label.new()
	header.text = "ДОСТИЖЕНИЕ ПОЛУЧЕНО"
	header.position = Vector2(84, 14)
	if font:
		header.add_theme_font_override("font", font)
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", C_GOLD)
	header.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(header)
	var line = ColorRect.new()
	line.color = Color(C_GOLD_D, 0.8)
	line.position = Vector2(84, 34)
	line.size = Vector2(card_size.x - 100, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(line)
	var name_l = Label.new()
	name_l.text = title
	name_l.position = Vector2(84, 40)
	if font:
		name_l.add_theme_font_override("font", font)
	name_l.add_theme_font_size_override("font_size", 20)
	name_l.add_theme_color_override("font_color", Color(1, 1, 1))
	name_l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	name_l.add_theme_constant_override("shadow_offset_x", 2)
	name_l.add_theme_constant_override("shadow_offset_y", 2)
	name_l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	name_l.visible_ratio = 0.0
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_l)
	# shine sweeping across the card
	var sweep = ColorRect.new()
	sweep.color = Color(1, 1, 1, 0.12)
	sweep.size = Vector2(26, card_size.y * 2.0)
	sweep.rotation = 0.35
	sweep.position = Vector2(-60, -card_size.y * 0.5)
	sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sweep)
	# time bar
	var bar = ColorRect.new()
	bar.color = C_GOLD
	bar.position = Vector2(3, card_size.y - 6)
	bar.size = Vector2(card_size.x - 6, 3)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(bar)

	var show_time := 3.6
	# half size: the whole card is drawn at 0.5 (same look, smaller on screen)
	card.scale = Vector2(POPUP_SCALE, POPUP_SCALE)
	var x_in = vp.x - card_size.x * POPUP_SCALE - 12
	card.position = Vector2(vp.x + 30, 12)
	badge.scale = Vector2(0.2, 0.2)
	badge.rotation = -0.6
	var tw = canvas.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(card, "position:x", x_in, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(badge, "scale", Vector2(1.15, 1.15), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(badge, "rotation", 0.0, 0.25).set_ease(Tween.EASE_OUT)
	tw.tween_property(badge, "scale", Vector2.ONE, 0.12)
	tw.parallel().tween_property(name_l, "visible_ratio", 1.0, 0.45)
	tw.parallel().tween_property(sweep, "position:x", card_size.x + 40, 0.7).set_delay(0.1)
	tw.parallel().tween_property(bar, "size:x", 0.0, show_time).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(card, "position:x", vp.x + 30, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	# sparkles out of the badge, glow redraw
	var t := 0.0
	var spark_t := 0.0
	while is_instance_valid(card) and tw.is_running():
		var dt = get_process_delta_time()
		t += dt
		spark_t -= dt
		glow.queue_redraw()
		if spark_t <= 0.0 and t < show_time:
			spark_t = 0.09 if t < 1.0 else 0.3
			_spark(card, badge_c)
		await get_tree().process_frame
	canvas.queue_free()


func _spark(parent: Control, at: Vector2) -> void:
	var s = ColorRect.new()
	s.size = Vector2(3, 3)
	s.color = C_GOLD.lightened(randf_range(0.0, 0.5))
	s.position = at
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(s)
	var dir = Vector2.from_angle(randf() * TAU) * randf_range(24.0, 48.0)
	var tw = s.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(s, "position", at + dir, randf_range(0.4, 0.7)).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.7)
	tw.parallel().tween_property(s, "scale", Vector2(0.3, 0.3), 0.7)
	tw.tween_callback(s.queue_free)

func load_achievements() -> void:
	var config = ConfigFile.new()
	if config.load("user://achievements.cfg") != OK:
		save_achievements()
		return
	
	coffee_unlocked = config.get_value("achievements", "coffee", false)
	flashback_unlocked = config.get_value("achievements", "flashback", false)
	pop_star_unlocked = config.get_value("achievements", "pop_star", false)
	rebel_unlocked = config.get_value("achievements", "rebel", false)
	acrobat_unlocked = config.get_value("achievements", "acrobat", false)
	worker_of_month_unlocked = config.get_value("achievements", "worker_of_month", false)
	scout_unlocked = config.get_value("achievements", "scout", false)
	freedom_unlocked = config.get_value("achievements", "freedom", false)
	chase_unlocked = config.get_value("achievements", "chase", false)
	handyman_unlocked = config.get_value("achievements", "handyman", false)
	stations_worked = config.get_value("progress", "stations_worked", [])

func save_achievements() -> void:
	var config = ConfigFile.new()
	config.set_value("achievements", "coffee", coffee_unlocked)
	config.set_value("achievements", "flashback", flashback_unlocked)
	config.set_value("achievements", "pop_star", pop_star_unlocked)
	config.set_value("achievements", "rebel", rebel_unlocked)
	config.set_value("achievements", "acrobat", acrobat_unlocked)
	config.set_value("achievements", "worker_of_month", worker_of_month_unlocked)
	config.set_value("achievements", "scout", scout_unlocked)
	config.set_value("achievements", "freedom", freedom_unlocked)
	config.set_value("achievements", "chase", chase_unlocked)
	config.set_value("achievements", "handyman", handyman_unlocked)
	config.set_value("progress", "stations_worked", stations_worked)
	config.save("user://achievements.cfg")

func unlock_coffee() -> void:
	if coffee_unlocked:
		return
	coffee_unlocked = true
	achievement_unlocked.emit("coffee")
	save_achievements()

func unlock_flashback() -> void:
	if flashback_unlocked:
		return
	flashback_unlocked = true
	achievement_unlocked.emit("flashback")
	save_achievements()

func unlock_pop_star() -> void:
	if pop_star_unlocked:
		return
	pop_star_unlocked = true
	achievement_unlocked.emit("pop_star")
	save_achievements()

func unlock_rebel() -> void:
	if rebel_unlocked:
		return
	rebel_unlocked = true
	achievement_unlocked.emit("rebel")
	save_achievements()

func unlock_acrobat() -> void:
	if acrobat_unlocked:
		return
	acrobat_unlocked = true
	achievement_unlocked.emit("acrobat")
	save_achievements()

func unlock_worker_of_month() -> void:
	if worker_of_month_unlocked:
		return
	worker_of_month_unlocked = true
	achievement_unlocked.emit("worker_of_month")
	if has_node("/root/UISounds"):
		UISounds.play_achievement()
	save_achievements()

func unlock_scout() -> void:
	if scout_unlocked:
		return
	scout_unlocked = true
	achievement_unlocked.emit("scout")
	if has_node("/root/UISounds"):
		UISounds.play_achievement()
	save_achievements()

func unlock_freedom() -> void:
	if freedom_unlocked:
		return
	freedom_unlocked = true
	achievement_unlocked.emit("freedom")
	if has_node("/root/UISounds"):
		UISounds.play_achievement()
	save_achievements()

func reset_all() -> void:
	coffee_unlocked = false
	flashback_unlocked = false
	pop_star_unlocked = false
	rebel_unlocked = false
	acrobat_unlocked = false
	worker_of_month_unlocked = false
	scout_unlocked = false
	freedom_unlocked = false
	chase_unlocked = false
	handyman_unlocked = false
	stations_worked = []
	save_achievements()


func unlock_chase() -> void:
	if chase_unlocked:
		return
	chase_unlocked = true
	achievement_unlocked.emit("chase")
	save_achievements()


func unlock_handyman() -> void:
	if handyman_unlocked:
		return
	handyman_unlocked = true
	achievement_unlocked.emit("handyman")
	save_achievements()


## A finished job at a factory station. All of them once -> "Разнорабочий".
func mark_station_worked(station: int) -> void:
	if not (station in stations_worked):
		stations_worked.append(station)
		save_achievements()
	for st in ALL_STATIONS:
		if not (st in stations_worked):
			return
	unlock_handyman()


func is_unlocked(id: String) -> bool:
	var v = get(id + "_unlocked")
	return v == true


func any_unlocked() -> bool:
	for id in TITLES.keys():
		if is_unlocked(id):
			return true
	return false


func total_count() -> int:
	return TITLES.size()


## Menu helper: adds a row for every EXTRA achievement under `list`, copied from `template`
## (the last row of the menu). Returns [{id, root, icon, check, name, desc}].
func build_extra_rows(list: Node, template: Control) -> Array:
	var rows: Array = []
	if list == null or template == null:
		return rows
	for e in EXTRA:
		var row = list.get_node_or_null(NodePath(e["id"].capitalize().replace(" ", "") + "Achievement"))
		if row == null:
			row = template.duplicate()
			row.name = e["id"].capitalize().replace(" ", "") + "Achievement"
			list.add_child(row)
		var icon = row.get_node_or_null("Icon") as TextureRect
		var nm = row.get_node_or_null("NameLabel") as Label
		var ds = row.get_node_or_null("DescLabel") as Label
		if nm:
			nm.text = e["name"]
		if ds:
			ds.text = e["desc"]
		for extra_child in ["ProgressLabel"]:
			var pc = row.get_node_or_null(extra_child)
			if pc:
				pc.visible = false
		if icon:
			if e["icon"] != "" and ResourceLoader.exists(ICON_DIR + e["icon"]):
				icon.texture = load(ICON_DIR + e["icon"])
			else:
				icon.texture = null
				var q = icon.get_node_or_null("NoIcon") as Label
				if q == null:
					q = Label.new()
					q.name = "NoIcon"
					q.text = "?"
					q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
					q.set_anchors_preset(Control.PRESET_FULL_RECT)
					q.add_theme_font_size_override("font_size", 40)
					q.add_theme_color_override("font_color", C_GOLD)
					q.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.03))
					q.add_theme_constant_override("outline_size", 6)
					icon.add_child(q)
		rows.append({"id": e["id"], "root": row, "icon": icon, "check": row.get_node_or_null("Check"), "name": nm, "desc": ds})
	return rows
