extends Node

const MENU_AQUARIUM = "res://Fish Slaves/Sounds/Music/MenuMusic/AquariumMenuMusic.mp3"
const LEVEL_ACT1 = "res://Fish Slaves/Sounds/Music/Act1Music/Act1AquariumMusic.mp3"

const VOLUME_NORMAL: float = -15.0
const VOLUME_PAUSED: float = -25.0
const VOLUME_SILENT: float = -80.0

var music_player: AudioStreamPlayer
var current_track: String = ""
var is_paused_for_menu: bool = false
var fading: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.volume_db = VOLUME_NORMAL
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)

# ==================== PUBLIC API ====================

func play_menu_music() -> void:
	play_track(MENU_AQUARIUM)

func play_level_music() -> void:
	play_track(LEVEL_ACT1)

func pause_level_music() -> void:
	if music_player and music_player.playing:
		music_player.stream_paused = true

func resume_level_music() -> void:
	if music_player and music_player.playing:
		music_player.stream_paused = false

func play_track(path: String) -> void:
	if path == "":
		return
	
	if current_track == path and music_player.playing:
		if is_paused_for_menu:
			restore_volume()
		return
	
	current_track = path
	
	var stream = load(path)
	if not stream:
		push_warning("GlobalMusic: не найден трек " + path)
		return
	
	if path != "res://Fish Slaves/Sounds/Music/IntroMusic/IntroMusic.mp3":
		if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
			stream.loop = true
	
	if not music_player.playing:
		music_player.stream = stream
		music_player.volume_db = VOLUME_NORMAL
		music_player.play()
		is_paused_for_menu = false
		return
	
	_crossfade_to(stream)

func stop_music() -> void:
	if music_player and music_player.playing:
		music_player.stop()
	current_track = ""
	is_paused_for_menu = false

# ==================== PAUSE MENU ====================

func lower_volume() -> void:
	if not music_player:
		return
	is_paused_for_menu = true
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(music_player, "volume_db", VOLUME_PAUSED, 0.4)

func restore_volume() -> void:
	if not music_player:
		return
	is_paused_for_menu = false
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(music_player, "volume_db", VOLUME_NORMAL, 0.4)

# ==================== PRIVATE ====================

func _crossfade_to(new_stream: AudioStream) -> void:
	if fading:
		return
	fading = true
	
	var fade_out = create_tween()
	fade_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(music_player, "volume_db", VOLUME_SILENT, 0.5)
	await fade_out.finished
	
	music_player.stop()
	music_player.stream = new_stream
	music_player.volume_db = VOLUME_SILENT
	music_player.play()
	is_paused_for_menu = false
	
	var fade_in = create_tween()
	fade_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(music_player, "volume_db", VOLUME_NORMAL, 0.5)
	await fade_in.finished
	
	fading = false
