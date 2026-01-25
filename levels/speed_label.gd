extends Label

## Debug label showing current speed and Goldilocks zone status.
## Can be hidden in final build.

@onready var ictio := get_node_or_null("%Ictio")

# Match these to your collectible defaults for accurate feedback
@export var min_effective_speed: float = 60.0
@export var max_effective_speed: float = 140.0


func _process(_delta: float) -> void:
	if ictio == null:
		return

	var speed: float = ictio.velocity.length()
	var in_zone: bool = speed >= min_effective_speed and speed <= max_effective_speed

	if speed < min_effective_speed:
		text = "Speed: %.0f (too slow)" % speed
		modulate = Color(0.6, 0.6, 0.8)
	elif speed > max_effective_speed:
		text = "Speed: %.0f (too fast)" % speed
		modulate = Color(1.0, 0.5, 0.5)
	else:
		text = "Speed: %.0f (good)" % speed
		modulate = Color(0.5, 1.0, 0.5)
