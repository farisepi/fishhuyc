extends RefCounted
class_name StorageMap

const ROOT := "res://GameScenes/LevelScenes/ActStorageLevelScenes/"

const ROOMS := {
	"nearfactory": "NearFactory",
	"room_a": "RoomA",
	"room_b": "RoomB",
	"room_e": "RoomE",
	"room_f": "RoomF",
	"room_g": "RoomG",
	"room_h": "RoomH",
	"room_i": "RoomI",
	"room_j": "RoomJ",
	"room_k": "RoomK",
	"room_l": "RoomL",
	"room_m": "RoomM",
	"electro": "Electro",
	"exit": "ExitRoom",
	"cluttered": "Cluttered",
	"vent": "Vent",
	"accountant": "Accountant",
	"motherbird": "Motherbird",
}

static func scene_path(room_id: String) -> String:
	var n: String = ROOMS.get(room_id, "")
	if n == "":
		return ""
	return ROOT + n + "LevelScenes/" + n + "LevelMainScene/ActStorage_Level" + n + "_Scene.tscn"

static func title(room_id: String) -> String:
	match room_id:
		"nearfactory":
			return TranslationServer.translate("У ЗАВОДА")
		"electro":
			return TranslationServer.translate("ЭЛЕКТРОЩИТОВАЯ")
		"exit":
			return TranslationServer.translate("ВЫХОД СО СКЛАДА")
		"cluttered":
			return TranslationServer.translate("ЗАВАЛ")
		"vent":
			return TranslationServer.translate("ВЕНТИЛЯЦИЯ")
		"accountant":
			return TranslationServer.translate("БУХГАЛТЕРИЯ")
		"motherbird":
			return TranslationServer.translate("???")
	return TranslationServer.translate("СКЛАД") + " · " + room_id.trim_prefix("room_").to_upper()

static func state() -> Dictionary:
	return Global.storage_state

static func flag(key: String) -> bool:
	return bool(Global.storage_state.get(key, false))

static func set_flag(key: String, v: bool = true) -> void:
	Global.storage_state[key] = v
	Global.save_factory_state()

static func is_dead(room_id: String, marker: String) -> bool:
	var d = Global.storage_state.get("dead", {})
	return d is Dictionary and (d.get(room_id, []) as Array).has(marker)

static func mark_dead(room_id: String, markers: Array) -> void:
	if markers.is_empty():
		return
	var d = Global.storage_state.get("dead", {})
	if not d is Dictionary:
		d = {}
	var arr: Array = (d.get(room_id, []) as Array).duplicate()
	for m in markers:
		if not arr.has(m):
			arr.append(m)
	d[room_id] = arr
	Global.storage_state["dead"] = d
