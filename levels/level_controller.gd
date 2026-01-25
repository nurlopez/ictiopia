extends Node

## Level Controller for Mechanic I (Speed Moderation)
## Tracks collectibles and triggers portal when all are solved.

@onready var tint := get_node_or_null("%Tint")
@onready var audio_player: AudioStreamPlayer = get_node_or_null("%Audio")

@warning_ignore("UNUSED_SIGNAL")
signal all_collectibles_cleared

var remaining_collectibles: int = 0
var started_with_collectibles := false

# Visual settings (static calm state for Level 1)
@export var calm_color: Color = Color(0.76, 0.93, 1.00)


func _ready() -> void:
	# Connect signal to portal
	var portal := get_node_or_null("%Portal")
	if portal and not is_connected("all_collectibles_cleared", Callable(portal, "open_portal")):
		connect("all_collectibles_cleared", Callable(portal, "open_portal"))

	# Count collectibles after all nodes are ready
	call_deferred("_late_count_collectibles")

	# Apply calm visuals
	_apply_visuals()


func _late_count_collectibles() -> void:
	remaining_collectibles = get_tree().get_nodes_in_group("collectibles").size()
	started_with_collectibles = remaining_collectibles > 0
	print("[LevelController] found collectibles: ", remaining_collectibles)


func notify_collectible_picked() -> void:
	remaining_collectibles = max(0, remaining_collectibles - 1)
	print("[LevelController] remaining: ", remaining_collectibles)
	if started_with_collectibles and remaining_collectibles == 0:
		_on_all_cleared()


func _on_all_cleared() -> void:
	print("[LevelController] all collectibles cleared!")
	emit_signal("all_collectibles_cleared")


func _apply_visuals() -> void:
	if tint:
		tint.color = calm_color
	if audio_player:
		audio_player.volume_db = -20.0
