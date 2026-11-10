## UI-нода диалогового окна. Отрисовывает near и far режимы.
## Путь: res://GameScripts/Dialogue/ChatterBox.gd
##
## Ожидаемая структура нод (все опциональны — если нет, скипается):
##
## ChatterBox [Node2D или CanvasLayer]
## ├── NearPanel      [NinePatchRect]  — маленькая панель у персонажа
## │   └── NearLabel  [RichTextLabel]
## ├── FarCanvas      [CanvasLayer]    — всё дальнее рисуется поверх
## │   ├── FarPanel         [NinePatchRect]
## │   │   ├── FarLabel     [RichTextLabel]
## │   │   └── FarPortrait  [TextureRect]
## │   ├── PhantomLeft      [NinePatchRect]
## │   │   ├── PhantomLeftLabel    [RichTextLabel]
## │   │   └── PhantomLeftPortrait [TextureRect]
## │   └── PhantomRight     [NinePatchRect]
## │       ├── PhantomRightLabel    [RichTextLabel]
## │       └── PhantomRightPortrait [TextureRect]
##
## Имена строго по схеме выше — ищутся через find_child().

class_name ChatterBox
extends Node

@export var controller_path: NodePath = NodePath()

# ---------------------------------------------------------------------------
# Ноды (найдутся автоматически)
# ---------------------------------------------------------------------------

var _near_panel:  NinePatchRect = null
var _near_label:  RichTextLabel = null

var _far_panel:    NinePatchRect = null
var _far_label:    RichTextLabel = null
var _far_portrait: TextureRect   = null

var _phantom_left:         NinePatchRect = null
var _phantom_left_label:   RichTextLabel = null
var _phantom_left_portrait: TextureRect  = null

var _phantom_right:         NinePatchRect = null
var _phantom_right_label:   RichTextLabel = null
var _phantom_right_portrait: TextureRect  = null

var _controller: ChatterController = null

# Плавный переход near <-> far
var _current_phantom_offset: float = 0.0

# Украшения near-панели: тень, хвостик к говорящему, табличка с именем
var _shadow: NinePatchRect = null
const TYPEIN_EFFECT := preload("res://GameScripts/UIScripts/DialogScripts/Dialog_TypeIn_Effect.gd")
var _typein = null
var _typein_line = null
var _tail_outline: Polygon2D = null
var _tail_fill: Polygon2D = null
var _name_tag: Label = null
const PAD_X := 7
const PAD_TOP := 6
const PAD_BOTTOM := 6
const NAME_H := 0           # no speaker names in the boxes
const NEAR_FONT := 8
const NEAR_MAX_W := 150.0
var _measured_w: float = 120.0
var _near_fonts_set: bool = false
const SWEAR_SHAKE := 0.45
const REF_ZOOM := 2.3         # at this camera zoom the bubble has its normal size
## Size of the bubbles; the aquarium sets 1.0 for its cutscene.
var bubble_scale: float = 0.67
var _scale_cur: float = 0.0
## true in a cutscene: always the full "near" bubble, no shrinking with distance
var force_near: bool = false
var _side: float = 1.0
const SIDE_GAP := 4.0
var _far_k: float = 0.0       # 0 = the speakers are on screen, 1 = far away
var _measured_line = null
var _measured_h: float = 30.0
@warning_ignore("unused_private_class_variable")
var _measured_shift: float = 0.0
var _far_measured_line = null
var _far_measured_h: float = 0.0
var _pop: float = 1.0
var _shake: float = 0.0
var _time: float = 0.0
const NAME_SCIENTIST := "УЧЁНЫЙ"
const NAME_MECHANIC := "МЕХАНИК"
const COLOR_SCIENTIST := Color(0.45, 0.85, 0.95)
const COLOR_MECHANIC := Color(1.0, 0.68, 0.3)

# ---------------------------------------------------------------------------

func _ready() -> void:
	_near_panel  = find_child("NearPanel",  true, false) as NinePatchRect
	_near_label  = find_child("NearLabel",  true, false) as RichTextLabel

	_far_panel    = find_child("FarPanel",    true, false) as NinePatchRect
	_far_label    = find_child("FarLabel",    true, false) as RichTextLabel
	_far_portrait = find_child("FarPortrait", true, false) as TextureRect

	_phantom_left          = find_child("PhantomLeft",         true, false) as NinePatchRect
	_phantom_left_label    = find_child("PhantomLeftLabel",    true, false) as RichTextLabel
	_phantom_left_portrait = find_child("PhantomLeftPortrait", true, false) as TextureRect

	_phantom_right          = find_child("PhantomRight",         true, false) as NinePatchRect
	_phantom_right_label    = find_child("PhantomRightLabel",    true, false) as RichTextLabel
	_phantom_right_portrait = find_child("PhantomRightPortrait", true, false) as TextureRect

	_make_decorations()
	_hide_all()
	
	if controller_path:
		var node = get_node_or_null(controller_path)
		if node is ChatterController:
			bind(node)

func _process(delta: float) -> void:
	_time += delta
	# the size glides to its target instead of jumping (line change, zoom, distance, cutscene)
	var st = _bubble_scale_target()
	if _scale_cur <= 0.0:
		_scale_cur = st
	_scale_cur = lerp(_scale_cur, st, 1.0 - exp(-7.0 * delta))
	_pop = move_toward(_pop, 1.0, delta * 7.0)
	_shake = max(0.0, _shake - delta)
	if _controller == null or not _controller.is_active():
		return
	_update_display()


## Тень, хвостик и табличка с именем делаются из той же текстуры, что и панель.
func _make_decorations() -> void:
	if not _near_panel:
		return
	# shadow and tail are children of the panel, so they scale / shake together with it
	_shadow = NinePatchRect.new()
	_shadow.texture = _near_panel.texture
	_shadow.patch_margin_left = _near_panel.patch_margin_left
	_shadow.patch_margin_right = _near_panel.patch_margin_right
	_shadow.patch_margin_top = _near_panel.patch_margin_top
	_shadow.patch_margin_bottom = _near_panel.patch_margin_bottom
	_shadow.modulate = Color(0, 0, 0, 0.35)
	_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow.show_behind_parent = true
	_shadow.position = Vector2(2, 2)
	_near_panel.add_child(_shadow)
	_tail_outline = Polygon2D.new()
	_tail_outline.color = Color(0.06, 0.07, 0.1)
	_tail_outline.show_behind_parent = true
	_near_panel.add_child(_tail_outline)
	_tail_fill = Polygon2D.new()
	_tail_fill.color = Color(0.96, 0.97, 0.98)
	_near_panel.add_child(_tail_fill)
	# имя говорящего — внутри окна, первой строкой (тот же шрифт, что и у текста)
	_name_tag = Label.new()
	if _near_label:
		var f = _near_label.get_theme_font("normal_font")
		if f:
			_name_tag.add_theme_font_override("font", f)
		_name_tag.add_theme_font_size_override("font_size", _near_label.get_theme_font_size("normal_font_size"))
	_name_tag.position = Vector2(PAD_X, PAD_TOP - 1)
	_name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_near_panel.add_child(_name_tag)


## A tiny space-bar key under the bottom-right corner of the bubble when the line can be
## skipped (the cutscene).
var _skip_icon: Control = null

func _update_skip_icon() -> void:
	var on = _controller != null and _controller.skippable and _near_panel != null and _near_panel.visible
	if not on:
		if _skip_icon:
			_skip_icon.visible = false
		return
	if _skip_icon == null:
		_skip_icon = Control.new()
		_skip_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_skip_icon.size = Vector2(17, 8)
		_skip_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_skip_icon.draw.connect(func():
			var c = _skip_icon
			var k = 0.5 + 0.5 * sin(_time * 4.0)
			c.draw_rect(Rect2(0, 1, 17, 7), Color(0.06, 0.07, 0.1, 0.9))
			c.draw_rect(Rect2(1, 0, 15, 6), Color(0.06, 0.07, 0.1))
			c.draw_rect(Rect2(2, 1, 13, 4), Color(0.93, 0.94, 0.96))
			c.draw_rect(Rect2(2, 4, 13, 1), Color(0.7, 0.72, 0.78))
			# the space sign: a little bracket lying on its back
			var ink = Color(0.2, 0.24, 0.32).lerp(Color(0.1, 0.45, 0.7), k)
			c.draw_rect(Rect2(5, 2, 1, 2), ink)
			c.draw_rect(Rect2(11, 2, 1, 2), ink)
			c.draw_rect(Rect2(5, 3, 7, 1), ink))
		_near_panel.add_child(_skip_icon)
	_skip_icon.visible = true
	_skip_icon.position = Vector2(_near_panel.size.x - 19, _near_panel.size.y + 1)
	_skip_icon.queue_redraw()


func _on_line_shown(_line: ChatterLine, _index: int) -> void:
	_pop = 0.0


const SWEAR_SOUND := "res://GameAssets/Audio/SoundEffects/NPCVoiceSounds/SwearSounds/NPC_Swear_Censor_Sound.wav"
var _swear_player: AudioStreamPlayer = null

func _on_swear() -> void:
	_shake = SWEAR_SHAKE
	# a soft low thud under the swear word - it plays together with the voice blips, so it
	# stays below them (~55-115 Hz body, the voices are at ~550+ Hz) and does not mask them
	if _swear_player == null and ResourceLoader.exists(SWEAR_SOUND):
		_swear_player = AudioStreamPlayer.new()
		_swear_player.stream = load(SWEAR_SOUND)
		_swear_player.bus = "SFX"
		_swear_player.volume_db = -5.0
		add_child(_swear_player)
	if _swear_player:
		_swear_player.pitch_scale = randf_range(0.92, 1.05)
		_swear_player.play()

# ---------------------------------------------------------------------------
# Публичный API
# ---------------------------------------------------------------------------

func bind(controller: ChatterController) -> void:
	if _controller:
		_controller.chatter_stopped.disconnect(_on_stopped)
	_controller = controller
	_controller.chatter_stopped.connect(_on_stopped)
	if not _controller.line_shown.is_connected(_on_line_shown):
		_controller.line_shown.connect(_on_line_shown)
	if _controller.has_signal("swear_typed") and not _controller.swear_typed.is_connected(_on_swear):
		_controller.swear_typed.connect(_on_swear)

# ---------------------------------------------------------------------------

func _on_stopped() -> void:
	if _skip_icon:
		_skip_icon.visible = false
	_measured_line = null
	_far_measured_line = null
	_hide_all()

func _update_display() -> void:
	var mode = _controller.compute_display_mode()
	var text = _controller.get_typed_text()
	
	_current_phantom_offset = lerp(_current_phantom_offset, mode["fade"], 0.03)
	
	# Same bubble near and far (like in the factory): when the speakers are off screen the
	# bubble stays at the screen edge on their side and its tail points at them. No portrait.
	_show_near(text)

# ---------------------------------------------------------------------------
# Near mode
# ---------------------------------------------------------------------------

## Near mode looks like the factory bubbles: crisp 8 px pixel font, the box hugs the text
## (up to NEAR_MAX_W wide), the name sits inside on the first line, left-aligned text.
## The size is measured once per line on the FULL text, so the box never jumps while typing
## and every phrase fits. The box keeps its bottom where the old one had it (over the speaker).
func _show_near(text: String) -> void:
	_hide_far()
	
	if not _near_panel or not _near_label:
		return
	
	_near_panel.visible = true
	_near_panel.z_index = 100
	_current_phantom_offset = 0.0
	_apply_near_fonts()
	
	var line = _controller._current_line
	var is_mech = _controller.get_current_speaker() == ChatterLine.Speaker.MECHANIC
	_near_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	if line != _measured_line:
		_measured_line = line
		var full = (tr(line.text) if line else text).replace("-", "-\u2060")
		var f: Font = _near_label.get_theme_font("normal_font")
		var plain = _strip_bbcode(full)
		var tw = NEAR_MAX_W - PAD_X * 2
		var name_w = 30.0
		if f:
			var ts = f.get_multiline_string_size(plain, HORIZONTAL_ALIGNMENT_LEFT, tw - 8.0, NEAR_FONT)
			tw = min(tw, ts.x + 12.0)   # a few px of slack: the box is never a hair too narrow
			name_w = 0.0
		_measured_w = ceil(max(max(tw, name_w) + PAD_X * 2, 46.0))
		var th = _text_height(_near_label, full, _measured_w - PAD_X * 2)
		_measured_h = ceil(th + PAD_TOP + NAME_H + PAD_BOTTOM)
	
	# The bubble stands BESIDE the speaker at head height: the scientist's on his left,
	# the mechanic's on his right; the tail comes out of the inner side towards the face.
	# The inner bottom corner is the anchor (and the pivot for scaling), so the bubble
	# never drifts away from its speaker when it grows or shrinks.
	var sz = Vector2(_measured_w, _measured_h)
	var s = _bubble_scale()
	var speaker: Node2D = _controller._mechanic if is_mech else _controller._scientist
	var side = 1.0 if is_mech else -1.0
	_side = side
	var anchor: Vector2 = _controller.get_near_panel_position()
	if speaker:
		var hh = _head_height(speaker)
		anchor = speaker.global_position + Vector2(side * (_half_width(speaker) + SIDE_GAP), -hh * 0.15)
	anchor = _clamp_corner(anchor, sz * s, side)
	_near_panel.size = sz
	_near_panel.pivot_offset = Vector2(0.0 if side > 0.0 else sz.x, sz.y)
	_near_panel.position = (anchor - _near_panel.pivot_offset).round()
	_near_label.position = Vector2(PAD_X, PAD_TOP + NAME_H)
	_near_label.size = _near_panel.size - Vector2(PAD_X * 2, PAD_TOP + NAME_H + PAD_BOTTOM)
	
	# type-in: each new letter drops in as it is printed
	if _typein == null:
		_typein = TYPEIN_EFFECT.new()
		_near_label.custom_effects = [_typein]
		_near_label.bbcode_enabled = true
	if line != _typein_line:
		_typein_line = line
		_typein.clear()
	# the WHOLE line is laid out from the first letter (the type-in effect hides what is not
	# printed yet), so a word never jumps to the next line while it is being typed
	text = text.replace("-", "-\u2060")   # no line break after a hyphen
	var full_line = _full_line_bbcode(line, text)
	var wrapped = "[typein]" + full_line + "[/typein]"
	if _near_label.text != wrapped:
		_near_label.text = wrapped
	_typein.grow_to(_strip_bbcode(text).length())
	_decorate_near()
	_update_skip_icon()


## The full text of the current line with the same red colour on the swears as the typed one.
func _full_line_bbcode(line, typed: String) -> String:
	if line == null or not ("text" in line):
		return typed
	var full: String = tr(line.text).replace("-", "-\u2060")
	if "swear_words" in line:
		for sw0 in line.swear_words:
			var sw = tr(sw0)
			if sw != "":
				full = full.replace(sw, "[color=#FF3333]" + sw + "[/color]")
	return full


## Height from the node's origin to the top of the head (sprite frame height, a bit of the
## transparent top of the frame is skipped).
func _head_height(n: Node2D) -> float:
	if n is AnimatedSprite2D and n.sprite_frames and n.sprite_frames.has_animation(n.animation):
		var tex = n.sprite_frames.get_frame_texture(n.animation, n.frame)
		if tex:
			return tex.get_height() * abs(n.global_scale.y) * 0.36
	if n is Sprite2D and n.texture:
		return n.texture.get_height() * abs(n.global_scale.y) * 0.36
	return 28.0


## Where the camera looks, WITHOUT its shake / look-around offset - so a shaking camera
## does not make the bubbles twitch or change size.
func _cam_center(cam: Camera2D) -> Vector2:
	return cam.global_position


func _bubble_scale() -> float:
	return _scale_cur


func _half_width(n: Node2D) -> float:
	if n is AnimatedSprite2D and n.sprite_frames and n.sprite_frames.has_animation(n.animation):
		var tex = n.sprite_frames.get_frame_texture(n.animation, n.frame)
		if tex:
			return tex.get_width() * abs(n.global_scale.x) * 0.28
	return 18.0


## Keeps the scaled bubble inside the view; anchor = its inner bottom corner.
func _clamp_corner(a: Vector2, vis: Vector2, side: float) -> Vector2:
	var cam = get_viewport().get_camera_2d()
	if cam == null:
		return a
	var half = get_viewport().get_visible_rect().size / cam.zoom / 2.0
	var c = _cam_center(cam)
	var l = c.x - half.x + 4.0
	var r = c.x + half.x - 4.0
	if side > 0.0:
		a.x = clamp(a.x, l, max(l, r - vis.x))
	else:
		a.x = clamp(a.x, min(r, l + vis.x), r)
	var t = c.y - half.y + 4.0 + vis.y
	var b = c.y + half.y - 6.0
	a.y = clamp(a.y, t, max(t, b))
	return a


var _arrow_on: bool = false
var _arrow_k: float = 0.0
var _far_arrow: Node2D = null
var _far_arrow_col: Color = Color.WHITE
var _far_arrow_dir: Vector2 = Vector2.RIGHT

## The "too far" arrow: a little pointer with an outline in the speaker's colour, hugging the
## screen edge on the speaker's side, with three dots blinking in it while he talks.
func _update_far_arrow(speaker: Node2D, cam: Camera2D, is_mech: bool) -> void:
	if _far_arrow == null:
		if _near_panel == null or _near_panel.get_parent() == null:
			return
		_far_arrow = Node2D.new()
		_far_arrow.name = "FarArrow"
		_far_arrow.z_index = 101
		_far_arrow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_far_arrow.draw.connect(_draw_far_arrow)
		_near_panel.get_parent().add_child(_far_arrow)
	_far_arrow.visible = _arrow_k > 0.01 and speaker != null and cam != null and _near_panel.visible
	if not _far_arrow.visible:
		return
	var c = _cam_center(cam)
	var half = get_viewport().get_visible_rect().size / cam.zoom / 2.0
	var d = speaker.global_position - c
	_far_arrow_dir = d.normalized() if d.length() > 1.0 else Vector2.RIGHT
	var m = 16.0 / cam.zoom.x
	var k = min((half.x - m) / max(0.001, abs(d.x)), (half.y - m) / max(0.001, abs(d.y)))
	_far_arrow.global_position = c + d * min(1.0, k)
	_far_arrow.scale = Vector2.ONE / cam.zoom.x * 2.0
	_far_arrow.modulate.a = _arrow_k
	_far_arrow_col = COLOR_MECHANIC if is_mech else COLOR_SCIENTIST
	_far_arrow.queue_redraw()

func _draw_far_arrow() -> void:
	var dir = _far_arrow_dir
	var sd = Vector2(-dir.y, dir.x)
	var tip = dir * 9.0
	var poly = PackedVector2Array([tip, -dir * 5.0 + sd * 7.0, -dir * 2.0, -dir * 5.0 - sd * 7.0])
	var outl = PackedVector2Array([tip + dir * 1.5, -dir * 6.5 + sd * 8.5, -dir * 2.0 - dir * 1.0, -dir * 6.5 - sd * 8.5])
	_far_arrow.draw_colored_polygon(outl, Color(0.08, 0.09, 0.12))
	_far_arrow.draw_colored_polygon(poly, _far_arrow_col)
	# "talking" dots behind the pointer
	var t = _time
	for i in range(3):
		var on = int(t * 4.0) % 3 == i
		var pp = -dir * (12.0 + i * 4.0)
		_far_arrow.draw_rect(Rect2(pp - Vector2(1, 1), Vector2(2, 2)), Color(_far_arrow_col, 1.0 if on else 0.35))

## Same size on screen at any zoom, smaller when the speakers are far away.
func _bubble_scale_target() -> float:
	var cam = get_viewport().get_camera_2d()
	var zoom_k := 1.0
	if cam:
		zoom_k = clamp(REF_ZOOM / max(0.01, cam.zoom.x), 0.3, 1.4) * bubble_scale
	return zoom_k * lerp(1.0, 0.62, _far_k)


## Keeps the whole (scaled) bubble, given by its bottom centre, inside the camera view.
func _clamp_bottom_center(bc: Vector2, vis: Vector2) -> Vector2:
	var cam = get_viewport().get_camera_2d()
	if cam == null:
		return bc
	var half = get_viewport().get_visible_rect().size / cam.zoom / 2.0
	var c = _cam_center(cam)
	var lo_x = c.x - half.x + 4.0 + vis.x * 0.5
	var hi_x = c.x + half.x - 4.0 - vis.x * 0.5
	var lo_y = c.y - half.y + 4.0 + vis.y
	var hi_y = c.y + half.y - 10.0
	bc.x = clamp(bc.x, lo_x, max(lo_x, hi_x))
	bc.y = clamp(bc.y, lo_y, max(lo_y, hi_y))
	return bc


func _clamp_to_view(pos: Vector2, sz: Vector2) -> Vector2:
	var cam = get_viewport().get_camera_2d()
	if cam == null:
		return pos
	var half = get_viewport().get_visible_rect().size / cam.zoom / 2.0
	var c = _cam_center(cam)
	pos.x = clamp(pos.x, c.x - half.x + 6.0, max(c.x - half.x + 6.0, c.x + half.x - sz.x - 6.0))
	pos.y = clamp(pos.y, c.y - half.y + 8.0, max(c.y - half.y + 8.0, c.y + half.y - sz.y - 14.0))
	return pos


func _apply_near_fonts() -> void:
	if _near_fonts_set:
		return
	_near_fonts_set = true
	for key in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]:
		_near_label.add_theme_font_size_override(key, NEAR_FONT)
	_near_label.add_theme_constant_override("line_separation", 2)
	_near_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# wrap only between whole words (WORD_SMART used to cut a dot or a letter off a word that
	# was a hair too wide for the box)
	_near_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	for fl in [_far_label]:
		if fl:
			fl.autowrap_mode = TextServer.AUTOWRAP_WORD
	if _name_tag:
		_name_tag.add_theme_font_size_override("font_size", NEAR_FONT)
		_name_tag.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


static var _bb_re: RegEx = null

func _strip_bbcode(s: String) -> String:
	if _bb_re == null:
		_bb_re = RegEx.new()
		_bb_re.compile("\\[[^\\]]*\\]")
	return _bb_re.sub(s, "", true)

## Pop-in, a slight bob, a hard jolt on swear words; the bubble keeps the same size on
## screen whatever the zoom (no giant bubble during the intro zoom), and when the speakers
## are far away it shrinks and its text fades out (and comes back when you swim closer).
func _decorate_near() -> void:
	var p = _near_panel
	var e = 1.0 - pow(1.0 - _pop, 3.0)
	var cam = get_viewport().get_camera_2d()
	var is_mech = _controller.get_current_speaker() == ChatterLine.Speaker.MECHANIC
	var speaker: Node2D = _controller._mechanic if is_mech else _controller._scientist
	var target_far := 0.0
	var r_far := 0.0
	if cam:
		if speaker:
			var half = get_viewport().get_visible_rect().size / cam.zoom / 2.0
			var d = speaker.global_position - _cam_center(cam)
			r_far = max(abs(d.x) / max(1.0, half.x), abs(d.y) / max(1.0, half.y))
			target_far = clamp((r_far - 0.85) / 0.6, 0.0, 1.0)
	if force_near:
		target_far = 0.0
		r_far = 0.0
	_far_k = move_toward(_far_k, target_far, get_process_delta_time() * 2.5)
	# farther away the bubble only gets smaller (the text stays readable, it shrinks with it);
	# REALLY far away the bubble turns into an arrow at the screen edge pointing at the speaker
	if r_far > 2.3:
		_arrow_on = true
	elif r_far < 2.0:
		_arrow_on = false
	_arrow_k = move_toward(_arrow_k, 1.0 if _arrow_on else 0.0, get_process_delta_time() * 4.0)
	_update_far_arrow(speaker, cam, is_mech)
	var text_a = 1.0

	var base = p.position
	base.y += round(sin(_time * 2.2) * 1.0) - (1.0 - e) * 6.0
	var rot := 0.0
	var jolt := 0.0
	if _shake > 0.0:
		var s = _shake / SWEAR_SHAKE
		base.x += round(sin(_time * 90.0) * 5.0 * s)
		base.y += round(cos(_time * 70.0) * 2.0 * s)
		rot = sin(_time * 60.0) * 0.08 * s
		jolt = 0.15 * s
	p.position = base
	p.rotation = rot
	p.scale = Vector2.ONE * (0.8 + 0.2 * e + jolt) * _bubble_scale()
	p.modulate.a = e * lerp(1.0, 0.9, _far_k) * (1.0 - _arrow_k)
	_near_label.modulate.a = text_a
	if _shadow:
		_shadow.visible = true
		_shadow.size = p.size
		_shadow.position = Vector2(2, 2)
	# tail toward the speaker (in panel space, so it follows the scale)
	if _tail_fill and _tail_outline:
		# the tail comes out of whichever edge faces the speaker (side, top or bottom - the box
		# can be pushed to a screen edge when he is off screen) and points at his face
		var face = speaker.global_position + Vector2(_side * _half_width(speaker) * 0.6, -_head_height(speaker) * 0.15) if speaker else p.global_position
		var lf = p.get_global_transform().affine_inverse() * face
		var tb: Vector2
		var dir: Vector2
		var dx = -lf.x if lf.x < 0.0 else max(0.0, lf.x - p.size.x)
		var dy = -lf.y if lf.y < 0.0 else max(0.0, lf.y - p.size.y)
		var go_side = dx >= dy
		if dx == 0.0 and dy == 0.0:
			go_side = true
		if go_side:
			var left = lf.x < p.size.x * 0.5 if dx > 0.0 else _side > 0.0
			tb = Vector2(2.0 if left else p.size.x - 2.0, clamp(lf.y, 6.0, p.size.y - 6.0))
			dir = Vector2(-1, 0) if left else Vector2(1, 0)
		elif lf.y > p.size.y * 0.5:
			tb = Vector2(clamp(lf.x, 8.0, p.size.x - 8.0), p.size.y - 2.0)
			dir = Vector2(0, 1)
		else:
			tb = Vector2(clamp(lf.x, 8.0, p.size.x - 8.0), 2.0)
			dir = Vector2(0, -1)
		var sd = Vector2(-dir.y, dir.x)
		var lean = clamp((lf - tb).dot(sd) * 0.12, -3.0, 3.0)
		_tail_outline.polygon = PackedVector2Array([tb + sd * 5.0, tb - sd * 5.0, tb + dir * 9.0 + sd * lean])
		_tail_fill.polygon = PackedVector2Array([tb + sd * 3.0 - dir, tb - sd * 3.0 - dir, tb + dir * 5.0 + sd * lean * 0.7])
		_tail_outline.visible = true
		_tail_fill.visible = true
	if _name_tag:
		_name_tag.visible = false
		_name_tag.text = tr(NAME_MECHANIC if is_mech else NAME_SCIENTIST)
		_name_tag.add_theme_color_override("font_color", (COLOR_MECHANIC if is_mech else COLOR_SCIENTIST).darkened(0.45))
		_name_tag.position = Vector2(PAD_X, PAD_TOP - 1)
		_name_tag.size = Vector2(_near_panel.size.x - PAD_X * 2, NEAR_FONT + 2)
		_name_tag.modulate.a = lerp(1.0, 0.0, smoothstep(0.5, 0.9, _far_k))

func _text_height(lbl: RichTextLabel, full: String, width: float) -> float:
	var plain = _strip_bbcode(full)
	lbl.size = Vector2(width, 400)
	lbl.text = full
	var h = lbl.get_content_height()
	var f: Font = lbl.get_theme_font("normal_font")
	var fs: int = lbl.get_theme_font_size("normal_font_size")
	if f:
		var m = f.get_multiline_string_size(plain, HORIZONTAL_ALIGNMENT_LEFT, width - 6.0, fs)
		h = max(h, m.y)
		h += f.get_height(fs) * 0.35
	return ceil(h)


func _show_far(text: String, fade: float, phantom_alpha: float) -> void:
	if _near_panel:
		_near_panel.visible = false
	_hide_decorations()
	
	if not _far_panel:
		return
	
	var vp = get_viewport().get_visible_rect().size
	var pw = _controller.far_panel_width
	var ph = _controller.far_panel_height
	var margin = _controller.far_panel_margin_bottom
	
	if _far_label:
		var line = _controller._current_line
		if line != _far_measured_line:
			_far_measured_line = line
			_far_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			_far_measured_h = _text_height(_far_label, tr(line.text) if line else text, pw - 80) + 22.0
		ph = max(ph, _far_measured_h)
	var target_x = vp.x * 0.5 - pw * 0.5
	var target_y = vp.y - margin - ph
	
	_far_panel.visible = true
	_far_panel.z_index = 100
	_far_panel.size = Vector2(pw, ph)
	_far_panel.position = Vector2(target_x, target_y)
	_far_panel.modulate.a = fade
	
	if _far_label:
		if _far_label.text != text:
			_far_label.text = text
		_far_label.position = Vector2(70, 10)
		_far_label.size = Vector2(pw - 80, ph - 20)
	
	var icon_size = 60.0
	var icon_y = (ph - icon_size) * 0.5
	if _far_portrait:
		_far_portrait.texture = _controller.get_current_portrait()
		_far_portrait.position = Vector2(5, icon_y)
		_far_portrait.size = Vector2(icon_size, icon_size)
		_far_portrait.modulate = Color(1, 1, 1, 0.8)
	
	# Фантомы
	var zoom = 1.0
	if _controller._camera:
		zoom = _controller._camera.zoom.x
	var ox = int(35.0 * _current_phantom_offset) / zoom
	var oy = int(25.0 * _current_phantom_offset) / zoom
	
	_update_phantom(_phantom_left, _phantom_left_label, _phantom_left_portrait,
		Vector2(target_x - ox, target_y + oy), pw, ph, phantom_alpha, text, icon_size, icon_y)
	
	_update_phantom(_phantom_right, _phantom_right_label, _phantom_right_portrait,
		Vector2(target_x + ox, target_y - oy), pw, ph, phantom_alpha, text, icon_size, icon_y)

func _update_phantom(panel: NinePatchRect, label: RichTextLabel, portrait: TextureRect,
		pos: Vector2, pw: float, ph: float, alpha: float, text: String,
		icon_size: float, icon_y: float) -> void:
	if not panel:
		return
	panel.visible = true
	panel.size = Vector2(pw, ph)
	panel.position = pos
	panel.modulate.a = alpha
	panel.z_index = 99
	if label:
		label.visible = true
		if label.text != text:
			label.text = text
		label.modulate.a = 0.4
		label.position = Vector2(70, 10)
		label.size = Vector2(pw - 80, ph - 20)
	if portrait:
		portrait.texture = _controller.get_current_portrait()
		portrait.position = Vector2(5, icon_y)
		portrait.size = Vector2(icon_size, icon_size)
		portrait.modulate = Color(1, 1, 1, 0.3)

# ---------------------------------------------------------------------------

func _hide_far() -> void:
	if _far_panel:    _far_panel.visible = false
	if _phantom_left:  _phantom_left.visible = false
	if _phantom_right: _phantom_right.visible = false

func _hide_decorations() -> void:
	for n in [_shadow, _tail_outline, _tail_fill, _name_tag]:
		if n:
			n.visible = false

func _hide_all() -> void:
	if _near_panel:    _near_panel.visible = false
	if _far_arrow:     _far_arrow.visible = false
	_hide_decorations()
	_hide_far()

# ---------------------------------------------------------------------------
# Глитч-эффект текста (вызывай извне когда нужен глитч)
# ---------------------------------------------------------------------------

func apply_glitch(intensity: float) -> void:
	if intensity <= 0.03:
		return
	var original = _controller.get_typed_text() if _controller else ""
	if original.is_empty():
		return
	
	var chars = original.split("")
	var up_count = max(1, int(intensity * chars.size() * 0.12))
	for i in range(up_count):
		var pos = randi() % chars.size()
		if chars[pos] != " ":
			chars[pos] = chars[pos].to_upper()
	var rm_count = max(1, int(intensity * chars.size() * 0.08))
	for i in range(rm_count):
		var pos = randi() % chars.size()
		if chars[pos] != " ":
			chars[pos] = ""
	
	var glitched = "".join(chars)
	var red = Color(1.0, 0.4, 0.4)
	
	for lbl in [_near_label, _far_label, _phantom_left_label, _phantom_right_label]:
		if lbl and lbl.visible:
			lbl.text = glitched
			lbl.add_theme_color_override("default_color", red)
	
	await get_tree().create_timer(0.06).timeout
	
	var restored = _controller.get_typed_text() if _controller else ""
	for lbl in [_near_label, _far_label, _phantom_left_label, _phantom_right_label]:
		if lbl and lbl.visible:
			lbl.text = restored
			lbl.remove_theme_color_override("default_color")

# ---------------------------------------------------------------------------
# Встряска панели
# ---------------------------------------------------------------------------

func shake_panel() -> void:
	_shake = SWEAR_SHAKE
