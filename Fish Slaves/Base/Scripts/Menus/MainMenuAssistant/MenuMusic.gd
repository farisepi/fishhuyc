extends Node

var music_player: AudioStreamPlayer
var menu_music: AudioStream = preload("res://Fish Slaves/Sounds/Music/MenuMusic/AquariumMenuMusic.mp3")
var level_music: AudioStream = preload("res://Fish Slaves/Sounds/Music/Act1Music/Act1AquariumMusic.mp3")

var current_type: String = ""
var level_playback_pos: float = 0.0
var fading: bool = false

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	music_player.volume_db = -15.0

func play_menu_music() -> void:
	if current_type == "menu" and music_player.playing:
		return
	
	if current_type == "level" and music_player.playing:
		level_playback_pos = music_player.get_playback_position()
	
	current_type = "menu"
	
	if not music_player.playing:
		music_player.stream = menu_music
		music_player.volume_db = -15.0
		music_player.play()
	else:
		_crossfade_to(menu_music)

func play_level_music() -> void:
	if current_type == "level" and music_player.playing:
		return
	
	current_type = "level"
	music_player.stream = level_music
	music_player.volume_db = -15.0
	music_player.play()
	level_playback_pos = 0.0

func resume_level_music() -> void:
	if current_type != "level":
		current_type = "level"
		music_player.stream = level_music
	
	music_player.volume_db = -15.0
	music_player.play(level_playback_pos)

func pause_level_music() -> void:
	if current_type == "level" and music_player.playing:
		level_playback_pos = music_player.get_playback_position()
		music_player.stop()

func crossfade_to_menu() -> void:
	if current_type == "menu":
		return
	
	if current_type == "level" and music_player.playing:
		level_playback_pos = music_player.get_playback_position()
	
	current_type = "menu"
	_crossfade_to(menu_music)

func stop_music() -> void:
	if music_player and music_player.playing:
		music_player.stop()
	current_type = ""

func _crossfade_to(new_stream: AudioStream) -> void:
	if fading:
		return
	
	if not music_player.playing:
		music_player.stream = new_stream
		music_player.volume_db = -15.0
		music_player.play()
		return
	
	fading = true
	
	var fade_out = create_tween()
	fade_out.tween_property(music_player, "volume_db", -80.0, 0.5)
	await fade_out.finished
	
	music_player.stop()
	music_player.stream = new_stream
	music_player.volume_db = -80.0
	music_player.play()
	
	var fade_in = create_tween()
	fade_in.tween_property(music_player, "volume_db", -15.0, 0.5)
	await fade_in.finished
	
	fading = false