extends Control
const STYLED_DIALOG := preload("res://GameScripts/UIScripts/MenuDialogScripts/Menu_StyledDialog.gd")

@onready var back_btn: Button = $BackButton
@onready var reset_btn: Button = $ResetButton
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var progress_label: Label = $ProgressLabel

@onready var coffee_achievement: Control = $AchievementsScroll/AchievementsList/CoffeeAchievement
@onready var coffee_icon: TextureRect = $AchievementsScroll/AchievementsList/CoffeeAchievement/Icon
@onready var coffee_check: TextureRect = $AchievementsScroll/AchievementsList/CoffeeAchievement/Check
@onready var coffee_name: Label = $AchievementsScroll/AchievementsList/CoffeeAchievement/NameLabel
@onready var coffee_desc: Label = $AchievementsScroll/AchievementsList/CoffeeAchievement/DescLabel

@onready var flashback_achievement: Control = $AchievementsScroll/AchievementsList/FlashbackAchievement
@onready var flashback_icon: TextureRect = $AchievementsScroll/AchievementsList/FlashbackAchievement/Icon
@onready var flashback_check: TextureRect = $AchievementsScroll/AchievementsList/FlashbackAchievement/Check
@onready var flashback_name: Label = $AchievementsScroll/AchievementsList/FlashbackAchievement/NameLabel
@onready var flashback_desc: Label = $AchievementsScroll/AchievementsList/FlashbackAchievement/DescLabel

@onready var pop_star_achievement: Control = $AchievementsScroll/AchievementsList/PopStarAchievement
@onready var pop_star_icon: TextureRect = $AchievementsScroll/AchievementsList/PopStarAchievement/Icon
@onready var pop_star_check: TextureRect = $AchievementsScroll/AchievementsList/PopStarAchievement/Check
@onready var pop_star_name: Label = $AchievementsScroll/AchievementsList/PopStarAchievement/NameLabel
@onready var pop_star_desc: Label = $AchievementsScroll/AchievementsList/PopStarAchievement/DescLabel
@onready var pop_star_progress: Label = $AchievementsScroll/AchievementsList/PopStarAchievement/ProgressLabel

@onready var rebel_achievement: Control = $AchievementsScroll/AchievementsList/RebelAchievement
@onready var rebel_icon: TextureRect = $AchievementsScroll/AchievementsList/RebelAchievement/Icon
@onready var rebel_check: TextureRect = $AchievementsScroll/AchievementsList/RebelAchievement/Check
@onready var rebel_name: Label = $AchievementsScroll/AchievementsList/RebelAchievement/NameLabel
@onready var rebel_desc: Label = $AchievementsScroll/AchievementsList/RebelAchievement/DescLabel
@onready var rebel_progress: Label = $AchievementsScroll/AchievementsList/RebelAchievement/ProgressLabel

@onready var acrobat_achievement: Control = $AchievementsScroll/AchievementsList/AcrobatAchievement
@onready var acrobat_icon: TextureRect = $AchievementsScroll/AchievementsList/AcrobatAchievement/Icon
@onready var acrobat_check: TextureRect = $AchievementsScroll/AchievementsList/AcrobatAchievement/Check
@onready var acrobat_name: Label = $AchievementsScroll/AchievementsList/AcrobatAchievement/NameLabel
@onready var acrobat_desc: Label = $AchievementsScroll/AchievementsList/AcrobatAchievement/DescLabel

@onready var worker_achievement: Control = $AchievementsScroll/AchievementsList/WorkerOfMonthAchievement
@onready var worker_icon: TextureRect = $AchievementsScroll/AchievementsList/WorkerOfMonthAchievement/Icon
@onready var worker_check: TextureRect = $AchievementsScroll/AchievementsList/WorkerOfMonthAchievement/Check
@onready var worker_name: Label = $AchievementsScroll/AchievementsList/WorkerOfMonthAchievement/NameLabel
@onready var worker_desc: Label = $AchievementsScroll/AchievementsList/WorkerOfMonthAchievement/DescLabel

@onready var scout_achievement: Control = $AchievementsScroll/AchievementsList/ScoutAchievement
@onready var scout_icon: TextureRect = $AchievementsScroll/AchievementsList/ScoutAchievement/Icon
@onready var scout_check: TextureRect = $AchievementsScroll/AchievementsList/ScoutAchievement/Check
@onready var scout_name: Label = $AchievementsScroll/AchievementsList/ScoutAchievement/NameLabel
@onready var scout_desc: Label = $AchievementsScroll/AchievementsList/ScoutAchievement/DescLabel

@onready var freedom_achievement: Control = $AchievementsScroll/AchievementsList/FreedomAchievement
@onready var freedom_icon: TextureRect = $AchievementsScroll/AchievementsList/FreedomAchievement/Icon
@onready var freedom_check: TextureRect = $AchievementsScroll/AchievementsList/FreedomAchievement/Check
@onready var freedom_name: Label = $AchievementsScroll/AchievementsList/FreedomAchievement/NameLabel
@onready var freedom_desc: Label = $AchievementsScroll/AchievementsList/FreedomAchievement/DescLabel

var total_achievements: int = 8
var _extra_rows: Array = []
var unlocked_count: int = 0

func _ready() -> void:
	MenuHeader.style_scrolls.call_deferred(self, false, true)   # the game's scroll line + scroller
	MenuHeader.attach_grade(self)   # one screen grade so the UI sits in the room
	call_deferred("_add_header")
	if is_instance_valid(Fade) and Fade.has_method("fade_in"):
		Fade.fade_in()
	
	UISounds.stop_everything_gameplay()
	GlobalMusic.play_menu_music()
	
	ButtonEffects.setup(back_btn)
	ButtonEffects.setup(reset_btn)
	
	if not reset_btn.pressed.is_connected(_on_reset_pressed):
		reset_btn.pressed.connect(_on_reset_pressed)
	if not back_btn.pressed.is_connected(_on_back_button_pressed):
		back_btn.pressed.connect(_on_back_button_pressed)
	
	_extra_rows = Achievements.build_extra_rows(get_node_or_null("AchievementsScroll/AchievementsList"), freedom_achievement)
	_setup_icons()
	total_achievements = Achievements.total_count()
	_setup_progress_bar()
	update_achievements()

func _setup_progress_bar() -> void:
	if progress_bar:
		progress_bar.max_value = total_achievements
		progress_bar.value = 0
	if progress_label:
		progress_label.text = "0/" + str(total_achievements)

func update_achievements() -> void:
	unlocked_count = 0
	
	if Achievements.coffee_unlocked:
		unlocked_count += 1
		_set_bright(coffee_achievement, coffee_icon, coffee_check, coffee_name)
		coffee_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	else:
		_set_gray(coffee_achievement, coffee_icon, coffee_check, coffee_name)
		coffee_desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	
	if Achievements.flashback_unlocked:
		unlocked_count += 1
		_set_bright(flashback_achievement, flashback_icon, flashback_check, flashback_name)
		flashback_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	else:
		_set_gray(flashback_achievement, flashback_icon, flashback_check, flashback_name)
		flashback_desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	
	if Achievements.pop_star_unlocked:
		unlocked_count += 1
		_set_bright(pop_star_achievement, pop_star_icon, pop_star_check, pop_star_name)
		pop_star_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		if pop_star_progress:
			pop_star_progress.text = "100/100"
			pop_star_progress.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	else:
		_set_gray(pop_star_achievement, pop_star_icon, pop_star_check, pop_star_name)
		pop_star_desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		if pop_star_progress:
			var popped = min(Global.bubbles_popped, 100)
			pop_star_progress.text = str(popped) + "/100"
			pop_star_progress.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	
	if Achievements.rebel_unlocked:
		unlocked_count += 1
		_set_bright(rebel_achievement, rebel_icon, rebel_check, rebel_name)
		rebel_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		if rebel_progress:
			rebel_progress.text = "50/50"
			rebel_progress.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	else:
		_set_gray(rebel_achievement, rebel_icon, rebel_check, rebel_name)
		rebel_desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		if rebel_progress:
			var thrown = min(Global.boxes_thrown, 50)
			rebel_progress.text = str(thrown) + "/50"
			rebel_progress.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	
	if Achievements.acrobat_unlocked:
		unlocked_count += 1
		_set_bright(acrobat_achievement, acrobat_icon, acrobat_check, acrobat_name)
		acrobat_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	else:
		_set_gray(acrobat_achievement, acrobat_icon, acrobat_check, acrobat_name)
		acrobat_desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	
	if worker_achievement:
		if Achievements.worker_of_month_unlocked:
			unlocked_count += 1
			_set_bright(worker_achievement, worker_icon, worker_check, worker_name)
			if worker_desc:
				worker_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		else:
			_set_gray(worker_achievement, worker_icon, worker_check, worker_name)
			if worker_desc:
				worker_desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	
	if scout_achievement:
		if Achievements.scout_unlocked:
			unlocked_count += 1
			_set_bright(scout_achievement, scout_icon, scout_check, scout_name)
			if scout_desc:
				scout_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		else:
			_set_gray(scout_achievement, scout_icon, scout_check, scout_name)
			if scout_desc:
				scout_desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	
	if freedom_achievement:
		if Achievements.freedom_unlocked:
			unlocked_count += 1
			_set_bright(freedom_achievement, freedom_icon, freedom_check, freedom_name)
			if freedom_desc:
				freedom_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		else:
			_set_gray(freedom_achievement, freedom_icon, freedom_check, freedom_name)
			if freedom_desc:
				freedom_desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	
	for r in _extra_rows:
		if Achievements.is_unlocked(r["id"]):
			unlocked_count += 1
			_set_bright(r["root"], r["icon"], r["check"], r["name"])
			if r["desc"]:
				r["desc"].add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		else:
			_set_gray(r["root"], r["icon"], r["check"], r["name"])
			if r["desc"]:
				r["desc"].add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

	if progress_bar:
		progress_bar.value = unlocked_count
	if progress_label:
		progress_label.text = str(unlocked_count) + "/" + str(total_achievements)

func _set_bright(ach: Control, icon: TextureRect, check: TextureRect, name_label: Label) -> void:
	if ach:
		ach.modulate = Color.WHITE
		for ch in ach.get_children():
			if ch is CanvasItem:
				ch.modulate = Color.WHITE
	if icon:
		icon.modulate = Color.WHITE
		icon.set_meta("unlocked", true)
		if icon.material is ShaderMaterial:
			icon.material.set_shader_parameter("locked", 0.0)
			icon.material.set_shader_parameter("ring", Color(1.0, 0.78, 0.3))
	if check: check.visible = true
	if name_label: name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))

func _set_gray(ach: Control, icon: TextureRect, check: TextureRect, name_label: Label) -> void:
	if ach:
		ach.modulate = Color.WHITE
		for ch in ach.get_children():
			if ch is CanvasItem and ch != icon:
				ch.modulate = Color(0.4, 0.4, 0.4, 1.0)
	if icon:
		icon.modulate = Color.WHITE
		icon.set_meta("unlocked", false)
		if icon.material is ShaderMaterial:
			icon.material.set_shader_parameter("locked", 1.0)
			icon.material.set_shader_parameter("ring", Color(0.42, 0.44, 0.5))
	if check: check.visible = false
	if name_label: name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

func _on_reset_pressed() -> void:
	if not Achievements.any_unlocked():
		return
	
	var menu = STYLED_DIALOG.new()
	menu.style = "factory"
	menu.title = tr("Сброс достижений")
	menu.dialog_text = tr("Весь прогресс достижений будет сброшен. Восстановить нельзя. Придётся начинать сначала.")
	menu.add_button(tr("Да"), true, "yes")
	menu.add_cancel_button(tr("Нет"))
	var ok = menu.get_ok_button()
	if ok: ok.visible = false
	
	for child in menu.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(100, 40)
	
	menu.custom_action.connect(func(action):
		if action == "yes":
			Achievements.reset_all()
			Global.bubbles_popped = 0
			Global.boxes_thrown = 0
			update_achievements()
		menu.hide()
		menu.queue_free()
	)
	
	add_child(menu)
	menu.popup_centered()

func _on_back_button_pressed() -> void:
	Global.goto_scene("res://GameScenes/MenuScenes/FactoryMenuScenes/FactoryMainMenuScene/Menu_Factory_MainMenu_Scene.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()

## A big title like in the pause menu instead of the small label.
func _add_header() -> void:
	var acc = MenuHeader.accent_for(self)
	var old_c := -1.0
	for n in ["Title", "TitleLabel"]:
		var t = get_node_or_null(n) as Control
		if t:
			t.visible = false
			old_c = t.position.y + t.size.y * 0.5   # the new title sits where the old one was
	MenuHeader.attach(self, tr("ДОСТИЖЕНИЯ"), acc, 16.0, 26, 180.0)
	var pb = get_node_or_null("ProgressBar") as Control
	var pl2 = get_node_or_null("ProgressLabel") as Control
	for c in [pb, pl2]:
		if c:
			c.position.y = 64.0
			c.size.y = 26.0
	for n in ["DividingLine1", "DividingLine2"]:
		var d = get_node_or_null(n) as ColorRect
		if d:
			d.color = Color(acc, 0.35)


# ---------------------------------------------------------------- icons
## Every achievement gets its pixel icon (x2, crisp) on a round badge: unlocked - a gold
## ring with a soft breathing glow and two sparkles running around it; locked - a dim ring
## (no extra marks: grey is enough).
var _badges: Array = []

const ICON_SHADER := """
shader_type canvas_item;
// round pixel badge: the 20x20 icon cut to a circle on its own pixel grid, a 1-texel ring
// (gold when unlocked, steel when locked), locked ones grey and dim
uniform float locked = 0.0;
uniform vec4 ring : source_color = vec4(1.0, 0.78, 0.3, 1.0);
void fragment() {
	vec2 n = vec2(textureSize(TEXTURE, 0));
	vec2 px = floor(UV * n) + 0.5;
	float d = length(px - n * 0.5);
	float r = n.x * 0.5;
	vec4 c = texture(TEXTURE, UV);
	float g = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	c.rgb = mix(c.rgb, vec3(g) * vec3(0.75, 0.78, 0.9) * 0.7, locked);
	if (d >= r) { c.a = 0.0; }
	else if (d >= r - 1.0) { c = ring; }
	else if (d >= r - 2.0) { c.rgb *= 0.55; }   // a dark inner edge under the ring
	COLOR = c;
}
"""
var _icon_shader: Shader = null

func _setup_icons() -> void:
	var map = [[coffee_icon, "coffee"], [flashback_icon, "flashback"], [pop_star_icon, "pop_star"],
		[rebel_icon, "rebel"], [acrobat_icon, "acrobat"], [worker_icon, "worker_of_month"],
		[scout_icon, "scout"], [freedom_icon, "freedom"]]
	for r in _extra_rows:
		map.append([r["icon"], r["id"]])
	for m in map:
		_style_icon(m[0], m[1])

func _style_icon(icon: TextureRect, id: String) -> void:
	if icon == null:
		return
	var p = Achievements.ICON_DIR + String(Achievements.ICONS.get(id, ""))
	if Achievements.ICONS.has(id) and ResourceLoader.exists(p):
		icon.texture = load(p)
		var q = icon.get_node_or_null("NoIcon")
		if q:
			q.queue_free()
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _icon_shader == null:
		_icon_shader = Shader.new()
		_icon_shader.code = ICON_SHADER
	if not (icon.material is ShaderMaterial):
		var m = ShaderMaterial.new()
		m.shader = _icon_shader
		icon.material = m
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# inside the banner, on its left; the texts move right to make room
	icon.position = Vector2(78, 15)
	icon.size = Vector2(44, 44)
	var row = icon.get_parent()
	if row and not row.has_meta("text_moved"):
		row.set_meta("text_moved", true)
		for n in ["NameLabel", "DescLabel"]:
			var l = row.get_node_or_null(n) as Control
			if l:
				l.offset_left += 48.0
	icon.pivot_offset = icon.size * 0.5
	if icon.get_node_or_null("Badge") == null:
		var back = Control.new()
		back.name = "Badge"
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back.show_behind_parent = true
		back.size = icon.size
		back.draw.connect(_draw_badge.bind(back, icon, false))
		icon.add_child(back)
		var front = Control.new()
		front.name = "BadgeFront"
		front.mouse_filter = Control.MOUSE_FILTER_IGNORE
		front.size = icon.size
		front.draw.connect(_draw_badge.bind(front, icon, true))
		icon.add_child(front)
		_badges.append(back)
		_badges.append(front)
	# a little pop when the row comes into view, unlocked ones a bit later and bouncier
	icon.scale = Vector2(0.6, 0.6)
	var tw = create_tween()
	tw.tween_interval(0.05 * _badges.size() / 2.0)
	tw.tween_property(icon, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _draw_badge(c: Control, icon: TextureRect, front: bool) -> void:
	var on = bool(icon.get_meta("unlocked", false))
	var t = Time.get_ticks_msec() / 1000.0
	var ctr = c.size * 0.5
	var gold = Color(1.0, 0.78, 0.3)
	if not front:
		if on:
			var k = 0.5 + 0.5 * sin(t * 2.2 + icon.get_instance_id() % 7)
			for i in range(4):
				c.draw_circle(ctr, 26.0 + i * 2.5, Color(gold, (0.10 - i * 0.022) * (0.6 + 0.6 * k)))
		# a soft drop shadow under the round badge
		c.draw_circle(ctr + Vector2(2, 3), 22.5, Color(0, 0, 0, 0.45))
		return
	# ring
	if on:
		for s in range(2):
			var a = t * 1.3 + s * PI
			var p = (ctr + Vector2.from_angle(a) * 22.0).round()
			c.draw_rect(Rect2(p - Vector2(1, 1), Vector2(3, 3)), Color(1, 0.95, 0.75))
			c.draw_rect(Rect2(p - Vector2(3, 0), Vector2(7, 1)), Color(1, 0.9, 0.6, 0.6))
			c.draw_rect(Rect2(p - Vector2(0, 3), Vector2(1, 7)), Color(1, 0.9, 0.6, 0.6))

func _process(_delta: float) -> void:
	for b in _badges:
		if is_instance_valid(b):
			b.queue_redraw()
