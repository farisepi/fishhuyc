extends PointLight2D
## Makes a PointLight2D pulse (alarm beacons) or flicker (dying lamps).

@export var speed: float = 3.0
@export var min_energy: float = 0.15
@export var max_energy: float = 1.0
@export var phase: float = 0.0
## 0 = smooth sine pulse, 1 = random flicker with short dropouts
@export_range(0, 1) var mode: int = 0

var _t: float = 0.0
var _flicker_timer: float = 0.0

func _ready() -> void:
	_t = phase

func _process(delta: float) -> void:
	_t += delta * speed
	if mode == 0:
		var s := 0.5 + 0.5 * sin(_t)
		energy = lerp(min_energy, max_energy, s * s)
	else:
		_flicker_timer -= delta
		if _flicker_timer <= 0.0:
			_flicker_timer = randf_range(0.03, 0.25)
			energy = max_energy if randf() > 0.18 else randf_range(min_energy, max_energy * 0.4)
