extends CanvasLayer

@onready var blue_icon: TextureRect = $BlueIcon
@onready var green_icon: TextureRect = $GreenIcon
@onready var cyan_icon: TextureRect = $CyanIcon
@onready var total_label: Label = $TotalLabel

const BLUE_TEX = preload("res://GameAssets/Sprites/EntitySprites/EnemySprites/EnemyShardTextures/Shard_MechaDog_Texture.png")
const GREEN_TEX = preload("res://GameAssets/Sprites/EntitySprites/EnemySprites/EnemyShardTextures/Shard_MechaMonkey_Texture.png")
const CYAN_TEX = preload("res://GameAssets/Sprites/EntitySprites/EnemySprites/EnemyShardTextures/Shard_MechaPigeon_Texture.png")

func _ready() -> void:
	blue_icon.texture = BLUE_TEX
	green_icon.texture = GREEN_TEX
	cyan_icon.texture = CYAN_TEX
	Global.shards_changed.connect(_on_shards_changed)
	_refresh()

func _on_shards_changed(_b: int, _g: int, _c: int) -> void:
	_refresh()

func _refresh() -> void:
	total_label.text = str(Global.get_total_shards())
