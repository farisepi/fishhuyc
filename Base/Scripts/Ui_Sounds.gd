extends Node

@onready var click_player: AudioStreamPlayer = $ClickPlayer
@onready var scientist_player: AudioStreamPlayer = $ScientistPlayer
@onready var mechanic_player: AudioStreamPlayer = $MechanicPlayer
@onready var noise_player: AudioStreamPlayer = $NoisePlayer
@onready var factory_ambience: AudioStreamPlayer = $FactoryAmbience
@onready var earthquake_player: AudioStreamPlayer = $EarthquakePlayer
@onready var hit_player: AudioStreamPlayer = $HitPlayer
@onready var aquarium_player: AudioStreamPlayer = $AquariumPlayer
@onready var swim_player: AudioStreamPlayer = $SwimPlayer

var pitch_variation: float = 0.1
var scientist_queue: float = 0.0
var mechanic_queue: float = 0.0
var glitch_intensity: float = 0.0
var current_noise_volume: float = -80.0

func _ready() -> void:
	if scientist_player:
		scientist_player.volume_db = -10.0
		scientist_player.finished.connect(_on_scientist_finished)
	if mechanic_player:
		mechanic_player.volume_db = -10.0
		mechanic_player.finished.connect(_on_mechanic_finished)
	if noise_player:
		noise_player.volume_db = -80.0
		noise_player.play()
	if factory_ambience:
		factory_ambience.volume_db = -30.0
		factory_ambience.stop()

func start_factory_ambience() -> void:
	if factory_ambience and not factory_ambience.playing:
		factory_ambience.play()

func stop_factory_ambience() -> void:
	if factory_ambience and factory_ambience.playing:
		factory_ambience.stop()

func set_glitch(intensity: float) -> void:
	glitch_intensity = intensity
	
	var base_volume = lerp(-10.0, -30.0, intensity)
	if scientist_player:
		scientist_player.volume_db = base_volume
	if mechanic_player:
		mechanic_player.volume_db = base_volume
	
	if noise_player:
		var target_volume = lerp(-80.0, -35.0, intensity)
		current_noise_volume = lerp(current_noise_volume, target_volume, 0.02)
		noise_player.volume_db = current_noise_volume

func play_click() -> void:
	if not click_player:
		return
	click_player.volume_db = -15.0
	click_player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	click_player.play()

func play_scientist() -> void:
	if not scientist_player:
		return
	
	var pitch = 1.0 + randf_range(-pitch_variation * (1.0 + glitch_intensity * 4.0), pitch_variation * (1.0 + glitch_intensity * 4.0))
	
	if scientist_player.playing:
		scientist_queue = pitch
	else:
		scientist_player.pitch_scale = pitch
		scientist_player.play()

func _on_scientist_finished() -> void:
	if scientist_queue != 0.0:
		scientist_player.pitch_scale = scientist_queue
		scientist_queue = 0.0
		scientist_player.play()

func play_mechanic() -> void:
	if not mechanic_player:
		return
	
	var pitch = 1.0 + randf_range(-pitch_variation * (1.0 + glitch_intensity * 4.0), pitch_variation * (1.0 + glitch_intensity * 4.0))
	
	if mechanic_player.playing:
		mechanic_queue = pitch
	else:
		mechanic_player.pitch_scale = pitch
		mechanic_player.play()

func _on_mechanic_finished() -> void:
	if mechanic_queue != 0.0:
		mechanic_player.pitch_scale = mechanic_queue
		mechanic_queue = 0.0
		mechanic_player.play()

func play_earthquake() -> void:
	if earthquake_player:
		earthquake_player.play()

func stop_all_dialog() -> void:
	if scientist_player:
		scientist_player.stop()
		scientist_queue = 0.0
	if mechanic_player:
		mechanic_player.stop()
		mechanic_queue = 0.0

func play_hit() -> void:
	if hit_player:
		hit_player.play()

func start_aquarium() -> void:
	if aquarium_player and not aquarium_player.playing:
		aquarium_player.play()

func stop_aquarium() -> void:
	if aquarium_player and aquarium_player.playing:
		aquarium_player.stop()

func start_swim_sound() -> void:
	if swim_player and not swim_player.playing:
		swim_player.play()

func stop_swim_sound() -> void:
	if swim_player and swim_player.playing:
		swim_player.stop()

func set_swim_volume(volume: float) -> void:
	if swim_player:
		swim_player.volume_db = volume

func stop_earthquake():
	if earthquake_player and earthquake_player.playing:
		earthquake_player.stop()
