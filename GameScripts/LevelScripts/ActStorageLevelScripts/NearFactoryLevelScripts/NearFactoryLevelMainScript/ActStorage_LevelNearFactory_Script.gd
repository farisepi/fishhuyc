extends StorageRoom

func room_ready(_first: bool) -> void:
	if not StorageMap.flag("intro"):
		Global.storage_state["intro"] = true
		show_title(tr("АКТ 1. СКЛАД."))
