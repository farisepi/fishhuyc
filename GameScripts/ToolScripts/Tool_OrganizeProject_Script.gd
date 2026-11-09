@tool
extends EditorScript
## Puts the loose files from the project root into their folders.
## Run once: open this script in the Godot script editor -> File -> Run (Ctrl+Shift+X).
##  - the dialog scripts / scene go to GameScripts/UIScripts/ChatterScripts and
##    GameScenes/UIScenes/ChatterScenes (their .uid files move with them, so every scene
##    keeps working; the old "res://..." paths in the files are rewritten too);
##  - the unused hallway obstacle scene goes to the hallway scenes;
##  - the game icon goes to GameAssets/Sprites/IconSprites (project.godot is updated);
##  - the !!OLD!! aquarium copies are deleted;
##  - backups, the second project file and the built .exe go to res://_Archive
##    (with a .gdignore, so Godot does not load anything from there). Delete it when sure.
## Only project.godot and export_presets.cfg stay in the root: Godot reads them only from there.
## Prints every step to the Output panel. Running it twice is harmless.

const MOVES := {
	"res://ChatterBox.gd": "res://GameScripts/UIScripts/ChatterScripts/ChatterBox.gd",
	"res://ChatterController.gd": "res://GameScripts/UIScripts/ChatterScripts/ChatterController.gd",
	"res://ChatterLine.gd": "res://GameScripts/UIScripts/ChatterScripts/ChatterLine.gd",
	"res://DialogueNode.tscn": "res://GameScenes/UIScenes/ChatterScenes/DialogueNode.tscn",
	"res://obstacle_variants_2.tscn": "res://GameScenes/LevelScenes/ActPrologueLevelScenes/HallwayLevelScenes/obstacle_variants_2.tscn",
	"res://icon.PNG": "res://GameAssets/Sprites/IconSprites/icon.PNG",
}
## old copies that are simply deleted
const DELETE := [
	"res://!!OLD!!ActPrologue_AquariumLevel_Script.gd",
	"res://!!OLD!!ActPrologue_AquariumLevel_Script.gd.uid",
	"res://!!OLD!!ActPrologue_LevelAquarium_Scene.tscn",
]
const ARCHIVE := [
	"res://project-1.godot",
	"res://FishSlaves - DEMO2.console.exe",
	"res://_backup_hallway_before_claude",
	"res://Claude outputs",
]
const ARCHIVE_DIR := "res://_Archive"

var _moved: Dictionary = {}

func _run() -> void:
	var moved := 0
	# files moved by an earlier run still get their paths fixed
	for from in MOVES.keys():
		if not FileAccess.file_exists(from) and FileAccess.file_exists(MOVES[from]):
			_moved[from] = MOVES[from]
	for from in MOVES.keys():
		var to: String = MOVES[from]
		if not FileAccess.file_exists(from):
			print("[organize] skip (already moved?): ", from)
			continue
		DirAccess.make_dir_recursive_absolute(to.get_base_dir())
		if _move(from, to):
			moved += 1
			_moved[from] = to
			for ext in [".uid", ".import"]:
				if FileAccess.file_exists(from + ext):
					_move(from + ext, to + ext)
	# the old paths written inside scenes / scripts / project.godot
	if not _moved.is_empty():
		_rewrite_paths("res://")
	for p in DELETE:
		if FileAccess.file_exists(p):
			var e = DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
			print("[organize] deleted ", p, ("" if e == OK else "  FAILED (%d)" % e))
	# archive
	DirAccess.make_dir_recursive_absolute(ARCHIVE_DIR)
	var gi = FileAccess.open(ARCHIVE_DIR + "/.gdignore", FileAccess.WRITE)
	if gi:
		gi.close()
	for p in ARCHIVE:
		if FileAccess.file_exists(p) or DirAccess.dir_exists_absolute(p):
			_move(p, ARCHIVE_DIR + "/" + p.get_file())
	EditorInterface.get_resource_filesystem().scan()
	print("[organize] done: ", moved, " files moved. Restart the editor once to be safe.")

func _move(from: String, to: String) -> bool:
	var err = DirAccess.rename_absolute(ProjectSettings.globalize_path(from), ProjectSettings.globalize_path(to))
	print("[organize] ", from, " -> ", to, ("" if err == OK else "  FAILED (%d)" % err))
	return err == OK

func _rewrite_paths(dir: String) -> void:
	var d = DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var n = d.get_next()
	while n != "":
		var p = dir.path_join(n)
		if d.current_is_dir():
			if not n.begins_with(".") and n != "_Archive" and n != "ToolScripts":
				_rewrite_paths(p)
		elif n.get_extension() in ["tscn", "tres", "gd", "godot", "cfg"]:
			var f = FileAccess.open(p, FileAccess.READ)
			if f:
				var s = f.get_as_text()
				f.close()
				var s2 = s
				for from in _moved.keys():
					s2 = s2.replace('"' + from + '"', '"' + _moved[from] + '"')
				if s2 != s:
					var w = FileAccess.open(p, FileAccess.WRITE)
					if w:
						w.store_string(s2)
						w.close()
						print("[organize] paths fixed in ", p)
		n = d.get_next()
	d.list_dir_end()
