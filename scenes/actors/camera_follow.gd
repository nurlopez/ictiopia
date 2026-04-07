extends Camera2D

## Look-ahead camera — offsets toward movement direction for better visibility.

@export var look_ahead_distance: float = 40.0
@export var look_ahead_lerp: float = 2.5

var _target_offset: Vector2 = Vector2.ZERO


func _process(delta: float) -> void:
	var parent := get_parent() as CharacterBody2D
	if parent == null:
		return

	if parent.velocity.length() > 10.0:
		_target_offset = parent.velocity.normalized() * look_ahead_distance
	else:
		_target_offset = Vector2.ZERO

	offset = offset.lerp(_target_offset, look_ahead_lerp * delta)
