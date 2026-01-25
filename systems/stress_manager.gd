extends Node
class_name StressManager

## Calculates stress level based on player speed relative to goldilocks zone.
## Stress rises when outside 40-160 px/s, decays when inside.

signal stress_changed(stress_level: float)

# Goldilocks zone boundaries (match lightnode.gd values)
@export var min_speed: float = 40.0
@export var max_speed: float = 160.0

# Stress change rates (per second)
@export var stress_decay_rate: float = 0.5      # decay in goldilocks
@export var stress_slow_rate: float = 0.3       # mild gain when too slow
@export var stress_fast_base: float = 0.6       # base gain when too fast
@export var stress_fast_scale: float = 0.003    # additional gain per excess px/s

# Current state
var stress_level: float = 0.0
var current_speed: float = 0.0


func _process(delta: float) -> void:
	var old_stress := stress_level

	if current_speed < min_speed:
		# Too slow: mild stress gain (inversely proportional to speed)
		var slowness := 1.0 - (current_speed / min_speed)
		stress_level += stress_slow_rate * slowness * delta
	elif current_speed > max_speed:
		# Too fast: strong stress gain (proportional to overspeed)
		var overspeed := current_speed - max_speed
		stress_level += (stress_fast_base + overspeed * stress_fast_scale) * delta
	else:
		# Goldilocks zone: stress decay
		stress_level -= stress_decay_rate * delta

	# Clamp to [0, 1]
	stress_level = clampf(stress_level, 0.0, 1.0)

	# Emit if changed significantly
	if absf(stress_level - old_stress) > 0.001:
		stress_changed.emit(stress_level)


func on_speed_changed(speed: float) -> void:
	current_speed = speed


func get_stress() -> float:
	return stress_level
