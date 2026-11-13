extends Node

const BUSES := ["Music", "SFX", "Ambience"]
const VIGNETTE_SHADER := """
shader_type canvas_item;
uniform float amount = 0.0;
uniform float beat = 0.0;
void fragment() {
	vec2 d = UV - 0.5;
	float r = length(d * vec2(1.25, 1.0));
	float v = smoothstep(0.32, 0.78, r);
	float a = v * amount * (0.75 + 0.25 * beat);
	COLOR = vec4(0.22, 0.0, 0.02, a);
}
"""

var L = null
var k := 0.0
var _t := 0.0
var _filters: Dictionary = {}
var _layer: CanvasLayer = null
var _vig: ColorRect = null

func setup(level) -> void:
	L = level
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 2
	add_child(_layer)
	_vig = ColorRect.new()
	_vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh = Shader.new()
	sh.code = VIGNETTE_SHADER
	var m = ShaderMaterial.new()
	m.shader = sh
	_vig.material = m
	_layer.add_child(_vig)

func _target() -> float:
	if L == null or not is_instance_valid(L):
		return 0.0
	if L._dream_on or L._room_on or L.state == L.State.DEAD or L.state == L.State.SHIFT_END:
		return 0.0
	var s = clamp(float(L.stress_level) / 100.0, 0.0, 1.0)
	var p = clamp(float(L._stress_escape) / 65.0, 0.0, 1.0)
	return max(s * 0.85, p)

func _process(delta: float) -> void:
	_t += delta
	var tgt = _target()
	k = move_toward(k, tgt, delta * (0.6 if tgt > k else 0.9))
	_apply_audio()
	var beat_hz = lerp(1.1, 2.1, k)
	var ph = fmod(_t * beat_hz, 1.0)
	var beat = exp(-ph * 9.0) + (0.6 * exp(-(ph - 0.18) * 9.0) if ph >= 0.18 else 0.0)
	if _vig:
		_vig.visible = k > 0.01
		_vig.material.set_shader_parameter("amount", pow(k, 1.3) * 0.55)
		_vig.material.set_shader_parameter("beat", clamp(beat, 0.0, 1.0))
	if L and L.camera and "breath_offset" in L.camera:
		var a = 3.2 * k
		var breath = Vector2(sin(_t * 0.85) * 0.5, sin(_t * TAU / 3.4)) * a
		if k > 0.55:
			breath += Vector2(0, -1.0) * beat * (k - 0.55) * 2.0
		L.camera.breath_offset = breath

func _apply_audio() -> void:
	for b in BUSES:
		var idx = AudioServer.get_bus_index(b)
		if idx < 0:
			continue
		var f: AudioEffectLowPassFilter = _filters.get(b, null)
		if f == null:
			if k < 0.02:
				continue
			f = AudioEffectLowPassFilter.new()
			f.resonance = 0.6
			AudioServer.add_bus_effect(idx, f)
			_filters[b] = f
		f.cutoff_hz = lerp(20500.0, 650.0, pow(clamp(k, 0.0, 1.0), 0.9))
		var ei = _effect_index(idx, f)
		if ei >= 0:
			AudioServer.set_bus_effect_enabled(idx, ei, k >= 0.02)

func _effect_index(bus: int, f: AudioEffect) -> int:
	for i in range(AudioServer.get_bus_effect_count(bus)):
		if AudioServer.get_bus_effect(bus, i) == f:
			return i
	return -1

func _exit_tree() -> void:
	for b in _filters.keys():
		var idx = AudioServer.get_bus_index(b)
		if idx < 0:
			continue
		var ei = _effect_index(idx, _filters[b])
		if ei >= 0:
			AudioServer.remove_bus_effect(idx, ei)
	_filters.clear()
	if L and is_instance_valid(L) and L.camera and "breath_offset" in L.camera:
		L.camera.breath_offset = Vector2.ZERO
