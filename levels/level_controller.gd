extends Node

## Level Controller for Mechanic I (Speed Moderation)
## Tracks lightnodes and triggers portal when all are fixed.
## Manages progressive world lighting as lightnodes are restored.

## Level bounds (in pixels) - used for camera limits
@export var level_bounds: Rect2i = Rect2i(0, 0, 1280, 720)

@onready var tint := get_node_or_null("%Tint")
@onready var background := get_node_or_null("%Background")
@onready var audio_player: AudioStreamPlayer = get_node_or_null("%Audio")

@warning_ignore("UNUSED_SIGNAL")
signal all_lightnodes_fixed

var remaining_lightnodes: int = 0
var total_lightnodes: int = 0
var started_with_lightnodes := false

# Progressive lighting settings
@export var dark_color: Color = Color(0.18, 0.18, 0.22)    # Starting darkness
@export var lit_color: Color = Color(0.35, 0.35, 0.45)     # Fully lit (still moody)


func _ready() -> void:
	# Connect signal to portal
	var portal := get_node_or_null("%Portal")
	if portal and not is_connected("all_lightnodes_fixed", Callable(portal, "open_portal")):
		connect("all_lightnodes_fixed", Callable(portal, "open_portal"))

	# Count lightnodes after all nodes are ready
	call_deferred("_late_count_lightnodes")

	# Start in darkness
	_apply_darkness()

	# Fit background to level bounds
	_configure_background()

	# Apply level bounds to camera
	_configure_camera_limits()


func _configure_camera_limits() -> void:
	var ictio := get_node_or_null("%Ictio")
	if not ictio:
		return
	var camera := ictio.get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.limit_left = level_bounds.position.x
		camera.limit_top = level_bounds.position.y
		camera.limit_right = level_bounds.position.x + level_bounds.size.x
		camera.limit_bottom = level_bounds.position.y + level_bounds.size.y


func _configure_background() -> void:
	if not background:
		return
	background.position = level_bounds.position
	background.size = level_bounds.size


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
