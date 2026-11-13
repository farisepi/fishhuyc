@tool
extends RichTextEffect

var bbcode := "typein"
var times: PackedFloat64Array = PackedFloat64Array()
const DROP := 4.0
const DUR := 0.14


func _process_custom_fx(fx: CharFXTransform) -> bool:
	var i: int = fx.relative_index
	if i >= times.size():
		fx.visible = false
		return true
	var age: float = Time.get_ticks_msec() / 1000.0 - times[i]
	if age < 0.0:
		fx.visible = false
		return true
	if age >= DUR:
		return true
	var k: float = age / DUR
	var e: float = 1.0 - pow(1.0 - k, 3.0)
	fx.offset = Vector2(0.0, -DROP * (1.0 - e)).round()
	fx.color.a *= clamp(k * 1.6, 0.0, 1.0)
	return true


func start_steady(count: int, cps: float, delay: float = 0.0) -> void:
	times.resize(count)
	var t0 = Time.get_ticks_msec() / 1000.0 + delay
	for i in range(count):
		times[i] = t0 + float(i) / cps


func grow_to(count: int) -> void:
	if count < times.size():
		times.resize(count)
	var now = Time.get_ticks_msec() / 1000.0
	while times.size() < count:
		times.append(now)


func clear() -> void:
	times.resize(0)
