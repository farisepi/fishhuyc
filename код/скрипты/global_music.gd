extends Node

var music_player: AudioStreamPlayer

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "Master"
	music_player.volume_db = -20.0

func play_music(stream: AudioStream) -> void:
	if not music_player:
		return
	if music_player.playing:
		music_player.stop()
	music_player.stream = stream
	music_player.play()

func stop_music() -> void:
	if music_player and music_player.playing:
		music_player.stop()
