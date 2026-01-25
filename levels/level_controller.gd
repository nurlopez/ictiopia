extends Node

## Level Controller for Mechanic I (Speed Moderation)
## Tracks lightnodes and triggers portal when all are fixed.
## Manages progressive world lighting as lightnodes are restored.

@onready var tint := get_node_or_null("%Tint")
@onready var audio_player: AudioStreamPlayer = get_node_or_null("%Audio")

@warning_ignore("UNUSED_SIGNAL")
signal all_lightnodes_fixed

var remaining_lightnodes: int = 0
var total_lightnodes: int = 0
var started_with_lightnodes := false

# Progressive lighting settings
@export var dark_color: Color = Color(0.15, 0.15, 0.2)    # Starting darkness
@export var lit_color: Color = Color(0.5, 0.55, 0.65)     # Fully lit (still moody)


func _ready() -> void:
	# Connect signal to portal
	var portal := get_node_or_null("%Portal")
	if portal and not is_connected("all_lightnodes_fixed", Callable(portal, "open_portal")):
		connect("all_lightnodes_fixed", Callable(portal, "open_portal"))

	# Count lightnodes after all nodes are ready
	call_deferred("_late_count_lightnodes")

	# Start in darkness
	_apply_darkness()


func _late_count_lightnodes() -> void:
	total_lightnodes = get_tree().get_nodes_in_group("lightnodes").size()
	remaining_lightnodes = total_lightnodes
	started_with_lightnodes = remaining_lightnodes > 0
	print("[LevelController] found lightnodes: ", remaining_lightnodes)


func notify_lightnode_fixed() -> void:
	remaining_lightnodes = max(0, remaining_lightnodes - 1)
	print("[LevelController] remaining lightnodes: ", remaining_lightnodes)

	# Update world lighting based on progress
	_update_world_lighting()

	if started_with_lightnodes and remaining_lightnodes == 0:
		_on_all_fixed()


func _on_all_fixed() -> void:
	print("[LevelController] all lightnodes fixed!")
	emit_signal("all_lightnodes_fixed")


func _apply_darkness() -> void:
	# Start the world in darkness
	if tint:
		tint.color = dark_color
	if audio_player:
		audio_player.volume_db = -20.0


func _update_world_lighting() -> void:
	# Calculate how lit the world should be based on fixed lightnodes
	if total_lightnodes == 0:
		return

	var fixed_count: int = total_lightnodes - remaining_lightnodes
	var progress: float = float(fixed_count) / float(total_lightnodes)

	# Smoothly transition the world tint
	if tint:
		var target_color: Color = dark_color.lerp(lit_color, progress)
		var tween := create_tween()
		tween.tween_property(tint, "color", target_color, 0.5).set_ease(Tween.EASE_OUT)
